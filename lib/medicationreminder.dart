import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MedicationReminderPage extends StatefulWidget {
  @override
  _MedicationReminderPageState createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  final Map<String, String> frequencyLabels = {
    'Hourly': 'hours',
    'Daily': 'days',
    'Weekly': 'weeks',
    'Monthly': 'months',
    'Yearly': 'years',
  };

  List<Map<String, dynamic>> _reminders = [];
  late DatabaseReference _dbRef;
  String? _userUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserAndDb();
  }

  Future<void> _initializeUserAndDb() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userUid = user.uid;
    _dbRef = FirebaseDatabase.instance.ref(
      'users/$_userUid/dog/medicationReminders',
    );

    _loadRemindersFromFirebase();
    setState(() {
      _isLoading = false;
    });
  }

  void _loadRemindersFromFirebase() {
    _dbRef.onValue.listen((event) {
      try {
        final data = event.snapshot.value;

        if (data != null && data is Map) {
          List<Map<String, dynamic>> loadedReminders = [];
          data.forEach((key, value) {
            loadedReminders.add({
              'name': value['name'],
              'startTime': DateTime.parse(value['startTime']),
              'type': value['type'],
              'frequency': value['frequency'],
              'intervalHours': value['intervalHours'],
            });
          });
          setState(() {
            _reminders = loadedReminders;
          });
        } else {
          setState(() {
            _reminders = [];
          });
        }
      } catch (e, st) {
        print('[Firebase Error] $e\n$st');
      }
    });
  }

  DateTime calculateNextReminder(DateTime start, String freq, int? interval) {
    DateTime now = DateTime.now();
    final int step = interval ?? 1;
    DateTime next = start;

    if (now.isBefore(start)) return start;

    if (freq == 'Hourly') {
      final passed = now.difference(start).inHours;
      final skips = (passed ~/ step) + 1;
      next = start.add(Duration(hours: skips * step));
    } else if (freq == 'Daily') {
      final passed = now.difference(start).inDays;
      final skips = (passed ~/ step) + 1;
      next = start.add(Duration(days: skips * step));
    } else if (freq == 'Weekly') {
      final passed = now.difference(start).inDays;
      final skips = (passed ~/ (7 * step)) + 1;
      next = start.add(Duration(days: skips * 7 * step));
    } else if (freq == 'Monthly') {
      int skips = 0;
      while (true) {
        int newMonth = start.month + (step * skips);
        int newYear = start.year + (newMonth - 1) ~/ 12;
        newMonth = (newMonth - 1) % 12 + 1;
        try {
          next = DateTime(
            newYear,
            newMonth,
            start.day,
            start.hour,
            start.minute,
          );
        } catch (_) {
          // Use the last valid day if day overflow occurs
          next = DateTime(newYear, newMonth + 1, 0, start.hour, start.minute);
        }
        if (next.isAfter(now)) break;
        skips++;
      }
    } else if (freq == 'Yearly') {
      int skips = 0;
      while (true) {
        try {
          next = DateTime(
            start.year + step * skips,
            start.month,
            start.day,
            start.hour,
            start.minute,
          );
        } catch (_) {
          next = DateTime(
            start.year + step * skips,
            start.month + 1,
            0,
            start.hour,
            start.minute,
          );
        }
        if (next.isAfter(now)) break;
        skips++;
      }
    }

    return next;
  }

  void _saveRemindersToFirebase() {
    if (_userUid == null) return;
    Map<String, dynamic> dataToSave = {};
    for (int i = 0; i < _reminders.length; i++) {
      final r = _reminders[i];
      dataToSave['reminder_$i'] = {
        'name': r['name'],
        'startTime': (r['startTime'] as DateTime).toIso8601String(),
        'type': r['type'],
        'frequency': r['frequency'],
        'intervalHours': r['intervalHours'],
      };
    }
    _dbRef.set(dataToSave);
  }

  void _showReminderDialog({
    Map<String, dynamic>? existingReminder,
    int? index,
  }) async {
    TextEditingController nameController = TextEditingController(
      text: existingReminder?['name'] ?? '',
    );
    DateTime? selectedDateTime = existingReminder?['startTime'];
    String selectedType = existingReminder?['type'] ?? 'Medicine';
    String selectedFrequency = existingReminder?['frequency'] ?? 'Daily';
    int? intervalHours = existingReminder?['intervalHours'];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            existingReminder == null ? 'Add Reminder' : 'Edit Reminder',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Medication Name'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          selectedDateTime ?? DateTime.now(),
                        ),
                      );
                      if (time != null) {
                        setStateDialog(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Text(
                    selectedDateTime == null
                        ? 'Pick Start Time'
                        : DateFormat(
                            'yyyy-MM-dd – kk:mm',
                          ).format(selectedDateTime!),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: 'Type'),
                  items: ['Medicine', 'Vaccine']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selectedType = val!),
                ),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: InputDecoration(labelText: 'Frequency'),
                  items: frequencyLabels.keys
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) =>
                      setStateDialog(() => selectedFrequency = val!),
                ),
                if (selectedFrequency.isNotEmpty)
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          'Every how many ${frequencyLabels[selectedFrequency]}?',
                    ),
                    controller: TextEditingController(
                      text: intervalHours?.toString() ?? '',
                    ),
                    onChanged: (val) => intervalHours = int.tryParse(val),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    selectedDateTime != null) {
                  final reminder = {
                    'name': nameController.text,
                    'startTime': selectedDateTime!,
                    'type': selectedType,
                    'frequency': selectedFrequency,
                    'intervalHours': intervalHours,
                  };
                  setState(() {
                    if (existingReminder == null) {
                      _reminders.add(reminder);
                    } else {
                      _reminders[index!] = reminder;
                    }
                  });
                  _saveRemindersToFirebase();
                  Navigator.pop(context);
                }
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
    _saveRemindersToFirebase();
  }

  // Main UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // App's theme background
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[300],
        foregroundColor: Colors.white,
        title: Text("Medication Reminders"),
      ),

      // If no reminders, show empty state
      body: _reminders.isEmpty
          ? Center(child: Text("No reminders yet"))
          : ListView.builder(
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final r = _reminders[index];

                // Calculate when the next reminder is due
                final nextTime = calculateNextReminder(
                  r['startTime'],
                  r['frequency'],
                  r['intervalHours'],
                );
                final isVaccine = r['type'] == 'Vaccine';

                // Vaccines: show reminder 5 days before, medicines: same time
                final reminderTime = isVaccine
                    ? nextTime.subtract(Duration(days: 5))
                    : nextTime;
                return Card(
                  child: ListTile(
                    title: Text(r['name']),
                    subtitle: Text(
                      isVaccine
                          ? "Next Vaccine: ${DateFormat('yyyy-MM-dd').format(nextTime)} (Reminder: ${DateFormat('yyyy-MM-dd').format(reminderTime)})"
                          : "Next Dose: ${DateFormat('yyyy-MM-dd – kk:mm').format(reminderTime)}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showReminderDialog(
                            existingReminder: r,
                            index: index,
                          ),
                        ),

                        // Delete button
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteReminder(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      // Floating Add button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 179, 231, 255),
        onPressed: () => _showReminderDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
