import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart';

class HistoryPage extends StatefulWidget {
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
      : Icon(Icons.check, color: Colors.green);

  String _getReadableStatus(String status) => status == 'breached'
      ? 'Dog Left The Safe Area'
      : 'Dog Returned to The Safe Area';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geofence History'),
        backgroundColor: Colors.lightBlue[300],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
          ? Center(child: Text('No history available'))
          : ListView.builder(
              itemCount: _historyList.length,
              itemBuilder: (_, i) {
                final h = _historyList[i];
                return ListTile(
                  leading: _getStatusIcon(h['status']),
                  title: Text(_getReadableStatus(h['status'])),
                  subtitle: Text(
                    'Time: ${h['time']}\nLocation: ${h['location']}',
                  ),
                );
              },
            ),
    );
  }
}
