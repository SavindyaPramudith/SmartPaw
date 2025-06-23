import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'homepage.dart';

class RegisterDogPage extends StatefulWidget {
  @override
  _RegisterDogPageState createState() => _RegisterDogPageState();
}

class _RegisterDogPageState extends State<RegisterDogPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();

  String gender = 'Male';
  DateTime? selectedDob;

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDob = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && selectedDob != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;

        // Ensure user is logged in
        if (user == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('User not logged in')));
          return;
        }

        final dogName = nameController.text.trim();
        // Prepare the dog data to save
        final dogData = {
          'name': dogName,
          'breed': breedController.text.trim(),
          'age': int.tryParse(ageController.text.trim()) ?? 0,
          'weight': double.tryParse(weightController.text.trim()) ?? 0.0,
          'gender': gender,
          'dob': selectedDob!.toIso8601String(),
        };

        // Save data under this user's UID in Realtime Database
        final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/dog');
        await dbRef.set(dogData);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Dog registered successfully")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } catch (e) {
        print("Error saving dog: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to Register Dog")));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[300],
        foregroundColor: Colors.white,
        title: Text('Register Your Dog'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: _buildInputDecoration("Dog's Name"),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: breedController,
                decoration: _buildInputDecoration("Breed"),
                validator: (value) => value!.isEmpty ? 'Enter breed' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration("Age (years)"),
                validator: (value) => value!.isEmpty ? 'Enter age' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration("Weight (kg)"),
                validator: (value) => value!.isEmpty ? 'Enter weight' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: _buildInputDecoration("Gender"),
                items: ['Male', 'Female']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => gender = val!),
              ),
              SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  selectedDob == null
                      ? "Pick Date of Birth"
                      : "DOB: ${selectedDob!.toLocal().toString().split(' ')[0]}",
                  style: TextStyle(fontSize: 16),
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDateOfBirth,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Register Dog",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
