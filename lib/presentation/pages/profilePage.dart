import 'package:flutter/material.dart';
import '../../services/CashierService.dart';
import '../../services/authService.dart';
import '../../models/cashier.dart';
import 'editProfilePage.dart';
import 'login.dart';

// === THEME CONST BIAR KONSISTEN DENGAN LOGIN / REGISTER / POS ===
const Color kBackgroundColor = Color(0xFFF3F6FD);
const Color kPrimaryGradientStart = Color(0xFF3B82F6);
const Color kPrimaryGradientEnd = Color(0xFF4F46E5);
const Color kTextGrey = Color(0xFF6B7280);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Cashier? cashier;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCashierProfile();
  }

  Future<void> loadCashierProfile() async {
    try {
      final fetchedCashier = await CashierService().fetchCashierProfile();

      if (!mounted) return;
      setState(() {
        cashier = fetchedCashier;
        isLoading = false;
      });
    } catch (e) {
      // ✅ if 401, force logout
      if (!mounted) return;

      await AuthService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // === CONFIRM + LOGOUT ===
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text(
            'Are you sure you want to sign out from your Yoomie cashier account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    // Call logout service (clear SharedPreferences + hit API /logout)
    await AuthService.logout();

    if (!mounted) return;

    // Navigate to LoginPage and remove previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: isLoading || cashier == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),

              // ✅ REMOVED (as requested): Quick Actions card
              // _buildQuickActionsCard(),
              // const SizedBox(height: 16),

              _buildAccountInfoCard(),
              const SizedBox(height: 24),

              // ✅ REMOVED (as requested): Tips card
              // _buildTipsCard(),
              // const SizedBox(height: 24),

              _buildLogoutButton(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // === HEADER GRADIENT WITH AVATAR & EDIT BUTTON ===
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.12),
            backgroundImage: cashier!.profileImage != null &&
                cashier!.profileImage!.isNotEmpty
                ? NetworkImage(cashier!.profileImage!)
                : null,
            child: (cashier!.profileImage == null ||
                cashier!.profileImage!.isEmpty)
                ? const Icon(
              Icons.person,
              size: 36,
              color: Colors.white,
            )
                : null,
          ),
          const SizedBox(width: 16),

          // Name + username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cashier!.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${cashier!.cashierName}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage your cashier profile and preferences.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Edit button
          TextButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
              if (result == true) {
                await loadCashierProfile();
                if (mounted) {
                  _showSuccessMessage();
                }
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              backgroundColor: Colors.white,
              foregroundColor: kPrimaryGradientEnd,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === ACCOUNT SUMMARY CARD ===
  Widget _buildAccountInfoCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE0ECFF),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: kPrimaryGradientEnd,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yoomie Cashier Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Use this account to manage orders, cart, and transactions securely.',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTextGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === LOGOUT BUTTON ===
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryGradientStart.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Sign out',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// BELOW: kept as-is (not used anymore) to avoid breaking code
// You can delete them later if you want cleaner file.
// ======================================================

// === QUICK ACTIONS (unused now) ===
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: kTextGrey,
            ),
          ),
        ],
      ),
    );
  }
}
