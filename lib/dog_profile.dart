import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DogProfilePage extends StatefulWidget {
  @override
  _DogProfilePageState createState() => _DogProfilePageState();
}

class _DogProfilePageState extends State<DogProfilePage> {
  Map<String, dynamic>? dogData;
  bool loading = true;

  final _formKey = GlobalKey<FormState>();

  // Controllers for editing
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController ageController;
  late TextEditingController weightController;
  String gender = 'Male';
  DateTime? dob;

  @override
  void initState() {
    super.initState();
    _fetchDogData();
  }

  Future<void> _fetchDogData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        loading = false;
        dogData = null;
      });
      return;
    }

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/dog');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      dogData = Map<String, dynamic>.from(snapshot.value as Map);

      // Initialize controllers with existing data
      nameController = TextEditingController(text: dogData!['name'] ?? '');
      breedController = TextEditingController(text: dogData!['breed'] ?? '');
      ageController = TextEditingController(
        text: dogData!['age']?.toString() ?? '',
      );
      weightController = TextEditingController(
        text: dogData!['weight']?.toString() ?? '',
      );
      gender = dogData!['gender'] ?? 'Male';
      dob = dogData!['dob'] != null ? DateTime.tryParse(dogData!['dob']) : null;
    } else {
      // Initialize empty controllers for new data
      nameController = TextEditingController();
      breedController = TextEditingController();
      ageController = TextEditingController();
      weightController = TextEditingController();
      gender = 'Male';
      dob = null;
      dogData = null;
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> _updateDogData() async {
    if (!_formKey.currentState!.validate() || dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all fields correctly including DOB"),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updatedData = {
      'name': nameController.text.trim(),
      'breed': breedController.text.trim(),
      'age': int.parse(ageController.text.trim()),
      'weight': double.parse(weightController.text.trim()),
      'gender': gender,
      'dob': dob!.toIso8601String(),
    };

    try {
      final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/dog');
      await dbRef.update(updatedData);

      setState(() {
        dogData = updatedData;
      });

      Navigator.pop(context); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dog profile updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update profile: $e")));
    }
  }

  Future<void> _showEditDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            'Edit Dog Profile',
            style: TextStyle(
              color: Colors.lightBlue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter dog name'
                        : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: breedController,
                    decoration: InputDecoration(labelText: 'Breed'),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter breed'
                        : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: ageController,
                    decoration: InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Please enter age';
                      final n = int.tryParse(val);
                      if (n == null || n < 0) return 'Enter valid age';
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: weightController,
                    decoration: InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Please enter weight';
                      final d = double.tryParse(val);
                      if (d == null || d <= 0) return 'Enter valid weight';
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        gender = val ?? 'Male';
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dob == null
                              ? 'Select Date of Birth'
                              : 'DOB: ${dob!.toLocal().toString().split(' ')[0]}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dob ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              dob = pickedDate;
                            });
                          }
                        },
                        child: Text('Pick Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[800],
              ),
              child: Text('Save'),
              onPressed: _updateDogData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog Profile'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.lightBlue[300],
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: loading ? null : _showEditDialog,
            tooltip: 'Edit Dog Profile',
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dogData!['name'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildDetailRow('Breed', dogData!['breed']),
                      _buildDetailRow('Age', dogData!['age']?.toString()),
                      _buildDetailRow('Weight', dogData!['weight']?.toString()),
                      _buildDetailRow('Gender', dogData!['gender']),
                      _buildDetailRow(
                        'Date of Birth',
                        dogData!['dob'] != null
                            ? DateTime.tryParse(
                                dogData!['dob'],
                              )?.toLocal().toString().split(' ')[0]
                            : 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
