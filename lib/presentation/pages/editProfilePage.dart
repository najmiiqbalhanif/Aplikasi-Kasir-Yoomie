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

  // ✅ Password section (opsional)
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  File? _selectedImage;
  Cashier? _cashier;
  bool _isLoading = true;
  bool _isSaving = false;

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

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
    } else {
      setState(() => _isLoading = false);
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

  bool _wantsPasswordChange() {
    return _currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  String? _validateNewPassword(String pw) {
    if (pw.length < 8) return 'Password minimal 8 karakter.';
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(pw);
    if (!hasSpecial) return 'Password harus mengandung 1 karakter spesial (contoh: !@#\$%).';
    return null;
  }

  Future<void> _saveProfile() async {
    if (_cashier == null) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hasProfileChanges =
        _fullNameController.text != (_cashier!.fullName ?? '') ||
            _cashierNameController.text != (_cashier!.cashierName ?? '') ||
            _emailController.text != (_cashier!.email ?? '') ||
            _selectedImage != null;

    final wantsPw = _wantsPasswordChange();

    // ✅ Validasi password kalau user ingin ganti
    if (wantsPw) {
      final current = _currentPasswordController.text;
      final nw = _newPasswordController.text;
      final cf = _confirmPasswordController.text;

      if (current.isEmpty || nw.isEmpty || cf.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jika ingin ganti password, semua field password wajib diisi.')),
        );
        return;
      }

      final pwErr = _validateNewPassword(nw);
      if (pwErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pwErr)));
        return;
      }

      if (nw != cf) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfirmasi password tidak sama.')),
        );
        return;
      }
    }

    if (!hasProfileChanges && !wantsPw) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSaving = true);

    // 1) Update profil jika ada perubahan
    bool profileOk = true;
    if (hasProfileChanges) {
      profileOk = await _cashierService.updateCashierProfile(
        cashierName: _cashierNameController.text,
        email: _emailController.text,
        fullName: _fullNameController.text,
        profileImage: _selectedImage?.path,
      );
    }

    if (!mounted) return;

    if (!profileOk) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil')),
      );
      return;
    }

    // 2) Change password jika user isi
    if (wantsPw) {
      final err = await _cashierService.changeCashierPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (err != null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }

    setState(() => _isSaving = false);
    Navigator.pop(context, true);
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
                        ? NetworkImage(_cashier!.profileImage!) as ImageProvider
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
            const Text('Informasi Profil', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Pastikan data di bawah sudah sesuai.', style: TextStyle(fontSize: 12.5, color: kTextGrey)),
            const SizedBox(height: 16),

            const Text('Nama lengkap', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _fullNameController,
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              decoration: _pillInputDecoration(hintText: 'Nama lengkap kasir'),
            ),

            const SizedBox(height: 12),

            const Text('Nama kasir (username)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _cashierNameController,
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              decoration: _pillInputDecoration(hintText: 'Contoh: kasir1, kasir_toko'),
            ),

            const SizedBox(height: 12),

            const Text('Email', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _emailController,
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              keyboardType: TextInputType.emailAddress,
              decoration: _pillInputDecoration(hintText: 'kasir@tokoanda.com'),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            const Text('Ubah Password (opsional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Isi hanya jika ingin mengganti password. Minimal 8 karakter & 1 karakter spesial.',
              style: TextStyle(fontSize: 12.5, color: kTextGrey),
            ),
            const SizedBox(height: 14),

            const Text('Password saat ini', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: _passwordDecoration(
                hintText: 'Masukkan password saat ini',
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),

            const SizedBox(height: 12),

            const Text('Password baru', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: _passwordDecoration(
                hintText: 'Buat password baru',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),

            const SizedBox(height: 12),

            const Text('Konfirmasi password baru', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: _passwordDecoration(
                hintText: 'Ulangi password baru',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
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
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text(
                  'Simpan Perubahan',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _pillInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12.5, color: kTextGrey),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12.5, color: kTextGrey),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: kTextGrey,
        ),
        onPressed: onToggle,
      ),
    );
  }
}
