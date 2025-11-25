import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/cashier.dart';
import '../../services/CashierService.dart';

// Theme warna biar konsisten dengan halaman lain
const Color kBackgroundColor = Color(0xFFF3F6FD);
const Color kPrimaryGradientStart = Color(0xFF3B82F6);
const Color kPrimaryGradientEnd = Color(0xFF4F46E5);
const Color kTextGrey = Color(0xFF6B7280);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _cashierService = CashierService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cashierNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _selectedImage;
  Cashier? _cashier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCashierData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cashierNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCashierData() async {
    final cashier = await _cashierService.fetchCashierProfile();
    if (!mounted) return;
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
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final hasChanges = _fullNameController.text != _cashier!.fullName ||
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

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true); // Ada perubahan dan berhasil
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan profil')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFormCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Header dengan gradient + tombol back + judul
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris back + title
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Edit Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 12.0, right: 12),
            child: Text(
              'Perbarui informasi akun kasir dan foto profilmu.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Avatar di tengah
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_cashier?.profileImage != null &&
                        _cashier!.profileImage!.isNotEmpty
                        ? NetworkImage(_cashier!.profileImage!)
                    as ImageProvider
                        : null),
                    child: (_selectedImage == null &&
                        (_cashier?.profileImage == null ||
                            _cashier!.profileImage!.isEmpty))
                        ? const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    )
                        : null,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(5),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: kPrimaryGradientEnd,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _cashier?.fullName ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '@${_cashier?.cashierName ?? ''}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card putih berisi form dengan input pill
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Profil',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pastikan data di bawah sudah sesuai.',
              style: TextStyle(
                fontSize: 12.5,
                color: kTextGrey,
              ),
            ),
            const SizedBox(height: 16),

            // Nama lengkap
            const Text(
              'Nama lengkap',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _fullNameController,
              validator: (value) =>
              (value == null || value.isEmpty) ? 'Required' : null,
              decoration: _pillInputDecoration(
                hintText: 'Nama lengkap kasir',
              ),
            ),

            const SizedBox(height: 12),

            // Nama kasir
            const Text(
              'Nama kasir (username)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _cashierNameController,
              validator: (value) =>
              (value == null || value.isEmpty) ? 'Required' : null,
              decoration: _pillInputDecoration(
                hintText: 'Contoh: kasir1, kasir_toko',
              ),
            ),

            const SizedBox(height: 12),

            // Email
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _emailController,
              validator: (value) =>
              (value == null || value.isEmpty) ? 'Required' : null,
              keyboardType: TextInputType.emailAddress,
              decoration: _pillInputDecoration(
                hintText: 'kasir@tokoanda.com',
              ),
            ),

            const SizedBox(height: 20),

            // Tombol simpan (gradient)
            GestureDetector(
              onTap: _saveProfile,
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGradientStart.withOpacity(0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable decoration untuk input pill
  InputDecoration _pillInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 12.5,
        color: kTextGrey,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
    );
  }
}
