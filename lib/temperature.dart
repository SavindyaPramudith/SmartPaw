import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'login.dart';

// ✅ Correct global declaration
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class TemperaturePage extends StatefulWidget {
  @override
  _TemperaturePageState createState() => _TemperaturePageState();
 
}


class _TemperaturePageState extends State<TemperaturePage> {
  double _currentTemp = 0.0;
  late DatabaseReference _tempRef;
  Stream<DatabaseEvent>? _tempStream;

   Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

   await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle the user's interaction with the notification (if needed)
      print('Notification tapped with payload: ${response.payload}');
    },
    onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
      // Handle background notification tap (optional, can be left empty)
    },
  );
}

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupTemperatureListener();
  }

  void _setupTemperatureListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Redirect to login screen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }

    // Reference to temperature under single dog
    _tempRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/dog/temperature/currentTemp',
    );

    _tempStream = _tempRef.onValue;

    _tempStream!.listen((event) {
      final tempVal = event.snapshot.value;
      if (tempVal != null) {
        double newTemp;
        if (tempVal is double) {
          newTemp = tempVal;
        } else if (tempVal is int) {
          newTemp = tempVal.toDouble();
        } else if (tempVal is String) {
          newTemp = double.tryParse(tempVal) ?? 0.0;
        } else {
          newTemp = 0.0;
        }

        setState(() {
          _currentTemp = newTemp;
        });

        _checkTemperatureAlert(newTemp);
      }
    });
  }

  void _checkTemperatureAlert(double temp) {
    if (temp < 36.0 || temp > 39.2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            temp < 36.0
                ? '⚠️ Temperature too low! Seek help.'
                : '⚠️ High temperature! See a vet.',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  String _getStatusMessage() {
    if (_currentTemp < 36.0) {
      return "⚠️ Too Low! Seek help.";
    } else if (_currentTemp > 39.2) {
      return "⚠️ High Temp! See a vet.";
    } else {
      return "✅ Temperature is Normal";
    }
  }

  Color _getStatusColor() {
    if (_currentTemp < 36.0 || _currentTemp > 39.2) {
      return Colors.redAccent;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text("Body Temperature"),
        centerTitle: true,
        backgroundColor: Colors.lightBlue[300],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Text(
              "🩺 Monitor Your Dog's Health",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              "Healthy temperature range: 36.0°C – 39.2°C\nAlways keep track for early detection.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Temperature Display Card
            Container(
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.thermostat_outlined,
                    size: 80,
                    color: Colors.orange[600],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "${_currentTemp.toStringAsFixed(1)} °C",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    _getStatusMessage(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),

            // Callout Message
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Seek veterinary help immediately if temperature is out of safe range.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.redAccent[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
