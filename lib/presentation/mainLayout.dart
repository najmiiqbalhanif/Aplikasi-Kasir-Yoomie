// lib/mainLayout.dart
import 'package:flutter/material.dart';
import 'pages/homepage.dart';
import 'pages/posPage.dart'; // Ini akan menjadi tab yang memuat Navigator bersarang
import 'pages/transactionsPage.dart';
import 'pages/cartpage.dart';
import 'pages/profilePage.dart';

class MainLayout extends StatefulWidget {
  // Tambahkan parameter initialIndex
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0}); // Default ke Home (indeks 0)

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Gunakan 'late' karena akan diinisialisasi di initState
  late int _selectedIndex;

  // Daftar halaman untuk BottomNavigationBar
  final List<Widget> _pages = [
    const HomePage(),
    const PoSPage(),
    const TransactionsPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Inisialisasi dari parameter
  }

  // Jika Anda ingin dapat mengubah tab dari luar (misalnya, setelah notifikasi),
  // Anda bisa menambahkan didUpdateWidget, tetapi untuk kasus ini, initState cukup.
  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
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
          // Ketika berpindah tab, pastikan untuk kembali ke root dari Navigator internal
          if (_selectedIndex != index) {
            // Ini untuk memastikan bahwa ketika Anda beralih tab, stack navigasi tab sebelumnya direset
            // Misalnya, jika Anda ada di ProductPage di tab PoS, dan beralih ke Home,
            // saat kembali ke PoS, Anda akan kembali ke halaman utama PoS, bukan ProductPage.
            // Anda bisa menyesuaikan perilaku ini jika ingin mempertahankan stack.
            // Untuk mereset stack, Anda bisa menggunakan Navigator.popUntil(context, (route) => route.isFirst);
            // Tapi ini memerlukan GlobalKey untuk setiap Navigator, yang akan kita lakukan di PoSPage.
          }
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
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