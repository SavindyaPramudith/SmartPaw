import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      return;
    }

    final ref = FirebaseDatabase.instance.ref(
      'users/${user.uid}/dog/geofenceBreaches',
    );
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      final list = map.entries.map((e) {
        final v = e.value as Map;
        return {
          'time': v['time'] ?? '',
          'location': v['location'] ?? '',
          'status': v['status'] ?? '',
        };
      }).toList();

      list.sort((a, b) => b['time'].compareTo(a['time']));

      setState(() {
        _historyList = list;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Icon _getStatusIcon(String status) => status == 'breached'
      ? Icon(Icons.warning, color: Colors.red)
      : Icon(Icons.check_circle, color: Colors.green);

  String _getReadableStatus(String status) => status == 'breached'
      ? 'Dog Left The Safe Area'
      : 'Dog Returned to The Safe Area';

  Color _getCardColor(String status) =>
      status == 'breached' ? Colors.red[50]! : Colors.green[50]!;

  Color _getIconBgColor(String status) =>
      status == 'breached' ? Colors.red[100]! : Colors.green[100]!;

  /// Split timestamp into readable date and time
  String _formatDate(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return dateTime.toIso8601String().split('T')[0]; // e.g., 2025-07-09
    } catch (_) {
      return 'Invalid Date';
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return dateTime
          .toIso8601String()
          .split('T')[1]
          .split('.')[0]; // e.g., 15:31:20
    } catch (_) {
      return 'Invalid Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Geofence History'),
        backgroundColor: Colors.lightBlue[300],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
          ? Center(child: Text('No history available'))
          : ListView.builder(
              itemCount: _historyList.length,
              itemBuilder: (_, i) {
                final h = _historyList[i];
                final date = _formatDate(h['time']);
                final time = _formatTime(h['time']);

                return Card(
                  color: _getCardColor(h['status']),
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getIconBgColor(h['status']),
                      child: _getStatusIcon(h['status']),
                    ),
                    title: Text(
                      _getReadableStatus(h['status']),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: h['status'] == 'breached'
                            ? Colors.red[900]
                            : Colors.green[800],
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: $date', style: TextStyle(fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Time: $time', style: TextStyle(fontSize: 13)),
                          SizedBox(height: 2),
                          Text(
                            'Location: ${h['location']}',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
