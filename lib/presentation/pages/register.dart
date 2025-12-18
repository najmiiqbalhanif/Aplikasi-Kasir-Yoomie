import 'package:flutter/material.dart';
import 'login.dart';
import '../../models/cashier.dart';
import '../../services/authService.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // === FORM KEY untuk validasi ===
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController cashierNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool _obscurePassword = true;

  // === VALIDASI PASSWORD (minimal 8 karakter) ===
  String? _passwordValidator(String? value) {
    final pw = (value ?? '');

    if (pw.trim().isEmpty) return 'Password wajib diisi.';
    if (pw.length < 8) return 'Password minimal 8 karakter.';

    // WAJIB ADA KARAKTER SPESIAL
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(pw);
    if (!hasSpecial) return 'Password harus mengandung minimal 1 karakter.';

    return null;
  }

  bool get _isPasswordInvalid {
    final err = _passwordValidator(passwordController.text);
    return err != null;
  }

  Future<void> registerCashier() async {
    setState(() {
      // setelah user klik submit, validasi langsung aktif untuk semua field
      _autoValidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_formKey.currentState!.validate()) return;

    final cashier = Cashier(
      fullName: fullNameController.text.trim(),
      cashierName: cashierNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    final success = await authService.register(cashier);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register berhasil! Silakan login.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register gagal. Coba lagi.')),
      );
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    cashierNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF3F6FD);
    const textGrey = Color(0xFF6B7280);
    const primaryGradientStart = Color(0xFF3B82F6);
    const primaryGradientEnd = Color(0xFF4F46E5);

    final double maxCardWidth = 400;

    InputDecoration pillDecoration({
      required String hintText,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12.5, color: textGrey),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

        // normal border (tidak terlihat)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),

        // ERROR border merah (sesuai yang kamu mau)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.red, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Colors.red, width: 1.6),
        ),

        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12.5,
          height: 1,
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PANEL GRADASI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      gradient: LinearGradient(
                        colors: [primaryGradientStart, primaryGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFBBF24),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Yoomie Cashier',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Buat akun kasir baru dan mulai kelola transaksi di Yoomie.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Daftarkan kasir agar dapat login ke aplikasi dan mengelola penjualan dengan aman.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FORM REGISTER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidateMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Cashier Account',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Isi data kasir untuk membuat akun baru.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textGrey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textGrey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginPage()),
                                  );
                                },
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: primaryGradientEnd,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            'Nama lengkap',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: fullNameController,
                            decoration: pillDecoration(
                              hintText: 'Nama lengkap kasir',
                            ),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Nama lengkap wajib diisi.'
                                : null,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Nama kasir (username)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: cashierNameController,
                            decoration: pillDecoration(
                              hintText: 'Contoh: kasir1, kasir_toko',
                            ),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Nama kasir wajib diisi.'
                                : null,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: pillDecoration(
                              hintText: 'kasir@tokoanda.com',
                            ),
                            validator: (v) {
                              final val = (v ?? '').trim();
                              if (val.isEmpty) return 'Email wajib diisi.';
                              final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(val);
                              if (!ok) return 'Format email tidak valid.';
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // === PASSWORD (border merah + icon error ketika invalid) ===
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            onChanged: (_) {
                              // biar icon/error berubah realtime
                              setState(() {});
                            },
                            validator: _passwordValidator,
                            decoration: pillDecoration(
                              hintText: 'Buat password',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // icon merah (!) muncul kalau invalid
                                  if (_autoValidateMode ==
                                      AutovalidateMode.onUserInteraction &&
                                      passwordController.text.isNotEmpty &&
                                      _isPasswordInvalid)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),

                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: textGrey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: registerCashier,
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: [
                                    primaryGradientStart,
                                    primaryGradientEnd,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGradientStart.withOpacity(0.32),
                                    blurRadius: 16,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Center(
                            child: Text(
                              'Dengan membuat akun, Anda menyetujui ketentuan penggunaan Yoomie.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: textGrey,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
