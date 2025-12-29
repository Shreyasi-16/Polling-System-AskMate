import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widget/logout_button.dart';
import 'chart_admin.dart';

/* 🎨 ColorHunt Palette */

const Color blue = Color(0xFF547792);
const Color lightBlue = Color(0xFF94B4C1);


class AddPollPage extends StatefulWidget {
  const AddPollPage({super.key});

  @override
  State<AddPollPage> createState() => _AddPollPageState();
}

class _AddPollPageState extends State<AddPollPage> {
  final _question = TextEditingController();
  final _op1 = TextEditingController();
  final _op2 = TextEditingController();
  final _op3 = TextEditingController();

  bool _saving = false;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _editingPollId;

  User? get _user => FirebaseAuth.instance.currentUser;

  // ------------------ DATE PICKER ------------------
  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 19, 88, 141),
              onPrimary: Colors.white,
              surface: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startTime = dt;
      } else {
        _endTime = dt;
      }
    });
  }

  // ------------------ SAVE / UPDATE ------------------
  Future<void> _addOrUpdatePoll() async {
    final q = _question.text.trim();
    final a = _op1.text.trim();
    final b = _op2.text.trim();
    final c = _op3.text.trim();

    if (q.isEmpty || a.isEmpty || b.isEmpty || c.isEmpty || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields and select start/end time')),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (_editingPollId != null) {
        await FirebaseFirestore.instance.collection('polls').doc(_editingPollId).update({
          'question': q,
          'op1': a,
          'op2': b,
          'op3': c,
          'startTime': Timestamp.fromDate(_startTime!),
          'endTime': Timestamp.fromDate(_endTime!),
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Poll updated successfully')));
      } else {
        await FirebaseFirestore.instance.collection('polls').add({
          'question': q,
          'op1': a,
          'op2': b,
          'op3': c,
          'votes': {},
          'createdBy': _user?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'startTime': Timestamp.fromDate(_startTime!),
          'endTime': Timestamp.fromDate(_endTime!),
        });
      }

      _editingPollId = null;
      _question.clear();
      _op1.clear();
      _op2.clear();
      _op3.clear();
      _startTime = null;
      _endTime = null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------ EDIT ------------------
  Future<void> _editPoll(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingPollId = doc.id;
      _question.text = data['question'] ?? '';
      _op1.text = data['op1'] ?? '';
      _op2.text = data['op2'] ?? '';
      _op3.text = data['op3'] ?? '';
      _startTime = (data['startTime'] as Timestamp?)?.toDate();
      _endTime = (data['endTime'] as Timestamp?)?.toDate();
    });
  }

  String formatDateTime(DateTime? dt) {
    if (dt == null) return 'Select date & time';
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      
      appBar: AppBar(
        iconTheme: const IconThemeData(
    color: Colors.white, // 👈 drawer icon color
  ),
        backgroundColor: const Color.fromARGB(255, 11, 73, 139),
        title: const Text(
          'Manage Polls',
          style: TextStyle(color: Colors.white,fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),

      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 232, 230, 227),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: const Color.fromARGB(255, 11, 73, 139)),
              accountName: const Text('Admin',style: TextStyle(color: const Color.fromARGB(255, 244, 244, 245) , fontSize: 22,fontWeight: FontWeight.w800),),
              accountEmail: Text(user?.email ?? '' , style: TextStyle(color: const Color.fromARGB(255, 244, 244, 245) , fontWeight: FontWeight.w800),),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: lightBlue,
                child: Icon(Icons.person, color: const Color.fromARGB(255, 11, 73, 139)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Color.fromARGB(255, 8, 33, 53)),
              title: const Text('Poll Stats',style: TextStyle(color: Color.fromARGB(255, 3, 3, 71) , fontWeight: FontWeight.w700),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChartAdminPage()),
                );
              },
            ),
            const Spacer(),
            const LogoutButton(),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- FORM CARD ----------------
            Card(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Create / Update Poll',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 11, 73, 139),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _input(_question, 'Poll Question', Icons.help_outline),
                    _input(_op1, 'Option 1', Icons.looks_one),
                    _input(_op2, 'Option 2', Icons.looks_two),
                    _input(_op3, 'Option 3', Icons.looks_3),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _dateBtn('Start', formatDateTime(_startTime), () => _pickDateTime(isStart: true)),
                        const SizedBox(width: 12),
                        _dateBtn('End', formatDateTime(_endTime), () => _pickDateTime(isStart: false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:Color.fromARGB(255, 8, 54, 102),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saving ? null : _addOrUpdatePoll,
                        child: Text(
                          _editingPollId != null ? 'Update Poll' : 'Add Poll',
                          style: const TextStyle(color: Colors.white,fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Your Polls',
              style: TextStyle(fontSize:22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 8, 54, 102)),
            ),
            const SizedBox(height: 8),

            // ---------------- POLL LIST ----------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('polls')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['createdBy'] == user?.uid;
                }).toList();

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('You have not created any polls yet.'),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(data['question'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Start: ${formatDateTime((data['startTime'] as Timestamp?)?.toDate())}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: blue),
                              onPressed: () => _editPoll(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('polls')
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- INPUT ----------------
  Widget _input(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color.fromARGB(255, 8, 54, 102)),
          labelText: label,
          labelStyle: const TextStyle(color: Color.fromARGB(255, 8, 54, 102)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: blue, width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ---------------- DATE BUTTON ----------------
  Widget _dateBtn(String title, String value, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color.fromARGB(255, 8, 54, 102)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 8, 54, 102))),
            const SizedBox(height: 4),
            Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Color.fromARGB(255, 8, 54, 102))),
          ],
        ),
      ),
    );
  }
}
