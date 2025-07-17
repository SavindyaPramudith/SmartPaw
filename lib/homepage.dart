import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'login.dart';
import 'medicationreminder.dart';
import 'temperature.dart';
import 'geofence.dart';
import 'dog_profile.dart';
import 'userProfile.dart';
import 'history.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? dogName;
  final List<_FeatureItem> features = [
    _FeatureItem('Profile', Icons.pets, Colors.deepPurple),
    _FeatureItem('Dog Location & Geofence', Icons.map_outlined, Colors.orange),
    _FeatureItem('Temperature', Icons.thermostat, Colors.redAccent),
    _FeatureItem('Medication', Icons.medication, Colors.blue),
    _FeatureItem('History', Icons.history, Colors.blue),
  ];

  @override
  void initState() {
    super.initState();
    _loadDogName();
  }

  Future<void> _loadDogName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Redirect to login screen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/dog/name');
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      setState(() {
        dogName = snapshot.value.toString();
      });
    } else {
      setState(() {
        dogName = null; // Or 'No Dog Registered'
      });
    }
  }

  void _navigateToFeature(BuildContext context, String title) {
    switch (title) {
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DogProfilePage()),
        );
        break;
      case 'Dog Location & Geofence':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GeofenceScreen()),
        );
        break;
      case 'Temperature':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TemperaturePage()),
        );
        break;
      case 'Medication':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedicationReminderPage()),
        );
        break;
      case 'History':
        ElevatedButton(
          child: Text("View History"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryPage()),
            );
          },
        );

      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPage()));

    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[300],
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'SmartPaw',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            if (dogName != null)
              Text(
                '🐶 Meet ${dogName!}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) {
              if (value == 'profile') {
                _openProfile(context);
              } else if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.lightBlue),
                    SizedBox(width: 8),
                    Text("User Profile"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/dog_home.jpg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(width: 8),
                  Text(
                    "Discover SmartPaw Features",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey[800],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final item = features[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _navigateToFeature(context, item.title),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 36, color: item.color),
                          SizedBox(height: 12),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final IconData icon;
  final Color color;

  _FeatureItem(this.title, this.icon, this.color);
}
