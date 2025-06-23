import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart';
import 'dog_profile.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String userEmail = '';
  String dogName = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Redirect to login screen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }

    setState(() {
      userEmail = user.email ?? 'No email';
    });

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/dog');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;

      setState(() {
        dogName = data['name']?.toString() ?? '';
      });
    }
  }

  void navigateToProfileDog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DogProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Logged in as:", style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text(userEmail, style: TextStyle(fontSize: 18)),
            SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Dog:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),

            Expanded(
              child: dogName.isEmpty
                  ? Text("No dogs registered yet.")
                  : Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.pets, color: Colors.blue),
                        title: Text(dogName),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
