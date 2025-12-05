// lib/presentation/mainLayout.dart
import 'package:flutter/material.dart';
import 'pages/posPage.dart';
import 'pages/transactionsPage.dart';
import 'pages/cartpage.dart';
import 'pages/profilePage.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  final int cashierId; // <-- tambahkan

  const MainLayout({
    super.key,
    this.initialIndex = 0,
    required this.cashierId, // <-- wajib diisi
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  // tidak bisa lagi final + langsung diisi, karena butuh widget.cashierId
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      PoSPage(cashierId: widget.cashierId), // <-- kirim cashierId
      const TransactionsPage(),
      const CartPage(),
      const ProfilePage(),
    ];

    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialIndex != oldWidget.initialIndex) {
      _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    }

    // Kalau suatu saat cashierId berubah, kita rebuild PoSPage
    if (widget.cashierId != oldWidget.cashierId) {
      _pages[0] = PoSPage(cashierId: widget.cashierId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'PoS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
