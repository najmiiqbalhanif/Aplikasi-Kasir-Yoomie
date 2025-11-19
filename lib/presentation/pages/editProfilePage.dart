import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/cashier.dart';
import '../../services/CashierService.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _cashierService = CashierService();

  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _cashierNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  File? _selectedImage;
  Cashier? _cashier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCashierData();
  }

  Future<void> _loadCashierData() async {
    final cashier = await _cashierService.fetchCashierProfile();
    if (cashier != null) {
      setState(() {
        _cashier = cashier;
        _fullNameController.text = cashier.fullName ?? '';
        _cashierNameController.text = cashier.cashierName ?? '';
        _emailController.text = cashier.email ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final hasChanges =
          _fullNameController.text != _cashier!.fullName ||
              _cashierNameController.text != _cashier!.cashierName ||
              _emailController.text != _cashier!.email ||
              _selectedImage != null;

      if (!hasChanges) {
        Navigator.pop(context, false); // Tidak ada perubahan
        return;
      }

      final success = await _cashierService.updateCashierProfile(
        cashierName: _cashierNameController.text,
        email: _emailController.text,
        fullName: _fullNameController.text,
        profileImage: _selectedImage?.path,
      );
      if (success) {
        Navigator.pop(context, true); // Ada perubahan dan berhasil
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text("Edit Profil")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Edit Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_cashier?.profileImage != null
                          ? NetworkImage(_cashier!.profileImage!) as ImageProvider
                          : AssetImage('assets/default_profile.png')),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cashierNameController,
                decoration: InputDecoration(labelText: 'CashierName'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF041761),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: _saveProfile,
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}