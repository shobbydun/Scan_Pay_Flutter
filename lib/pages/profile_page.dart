import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = _firestore.collection('users').doc(user.uid).snapshots();
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      await updateProfileImage(image);
    }
  }

  Future<String> uploadImageToFirebase(File image) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return '';
    }
  }

  Future<void> updateProfileImage(File image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String imageUrl = await uploadImageToFirebase(image);
      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': imageUrl,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No data available'));
          }

          var userDoc = snapshot.data!;
          var data = userDoc.data() as Map<String, dynamic>;

          String userName = data['businessName'] ?? 'Unknown';
          String userEmail = data['email'] ?? 'No email';
          String userPhone = data['phone'] ?? 'Not provided';
          String userProfileImage = data['profileImage'] ?? '';
          String userAddress = data['address'] ?? 'Not set';
          String userPaymentMethod = data['paymentMethod'] ?? 'Not set';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture and Basic Info with camera icon
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              userProfileImage.isNotEmpty
                                  ? NetworkImage(userProfileImage)
                                  : null,
                          child: userProfileImage.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                          backgroundColor: Colors.orange.shade800,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // User Info Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        userEmail,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Phone: $userPhone',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),

                  // Edit Profile Section inside a More Vertical Icon
                  _buildEditableSection('Phone Number', userPhone, 'phone'),
                  _buildEditableSection('Address', userAddress, 'address'),
                  _buildEditableSection('Payment Method', userPaymentMethod, 'paymentMethod'),

                  // Logout Button
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                    ),
                    child: Text('Logout', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Method to dynamically build editable sections
  Widget _buildEditableSection(String title, String currentValue, String field) {
    TextEditingController controller = TextEditingController(text: currentValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(Icons.more_vert, color: Colors.orange.shade800),
          title: Text(title),
          subtitle: Text(currentValue),
          onTap: () async {
            String? newValue = await _showEditDialog(context, controller, title);
            if (newValue != null && newValue.isNotEmpty) {
              _updateFieldInFirestore(field, newValue);
            }
          },
        ),
        Divider(),
      ],
    );
  }

  Future<String?> _showEditDialog(
    BuildContext context,
    TextEditingController controller,
    String title,
  ) async {
    String? newValue;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new $title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                newValue = controller.text.trim();
                Navigator.of(context).pop(newValue);
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
    return newValue;
  }

  void _updateFieldInFirestore(String field, String newValue) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        field: newValue,
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/');
    }
  }
}


class EditProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;

  EditProfilePage({
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers for editing user data
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
    _phoneController.text = widget.userPhone;
  }

  // Update user data in Firestore
  void updateProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'businessName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      // After updating, go back to ProfilePage
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Name TextField
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Email TextField
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Phone Number TextField
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
              ),
              child: Text('Save Changes', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
