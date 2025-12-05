import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helloworld/presentation/pages/cartProvider.dart';
import '../../services/cartService.dart';
import '../../models/CartItem.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helloworld/presentation/pages/checkoutPayment.dart';

// === THEME CONST BIAR KONSISTEN DENGAN LOGIN / REGISTER / POS ===
// Kalau sudah punya di file lain, boleh hapus bagian ini dan pakai import.
const Color kBackgroundColor = Color(0xFFF3F6FD);
const Color kPrimaryGradientStart = Color(0xFF3B82F6);
const Color kPrimaryGradientEnd = Color(0xFF4F46E5);
const Color kTextGrey = Color(0xFF6B7280);

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  Future<int?>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeCartData();
  }

  Future<int?> _initializeCartData() async {
    final prefs = await SharedPreferences.getInstance();
    final cashierId = prefs.getInt('cashierId');

    if (cashierId == null) {
      return null;
    }

    try {
      final initialCartItems = await _cartService.getCartItems(cashierId);
      if (!mounted) {
        return cashierId;
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.clearCart();

      if (initialCartItems.isNotEmpty) {
        for (var item in initialCartItems) {
          cartProvider.addExistingItem(item.product, item.quantity);
        }
      }
      return cashierId;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cart data: ${e.toString()}')),
        );
      }
      return cashierId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kBackgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: kBackgroundColor,
            body: Center(child: Text("Error loading data: ${snapshot.error}")),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: _buildGradientAppBar(),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Silakan login terlebih dahulu untuk melihat keranjang Anda.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: kTextGrey),
                ),
              ),
            ),
          );
        }

        final cashierId = snapshot.data!;

        return Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            List<CartItem> cartItems = cartProvider.items;
            double totalPrice = cartProvider.totalPrice;

            if (cartItems.isEmpty) {
              return Scaffold(
                backgroundColor: kBackgroundColor,
                appBar: _buildGradientAppBar(),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 40,
                            color: kPrimaryGradientEnd,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Keranjang masih kosong",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tambah produk dari halaman katalog untuk mulai membuat pesanan.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: kTextGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Scaffold(
                backgroundColor: kBackgroundColor,
                appBar: _buildGradientAppBar(),
                body: Column(
                  children: [
                    // Ringkasan kecil di atas list
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    kPrimaryGradientStart,
                                    kPrimaryGradientEnd,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${cartItems.length} item dalam keranjang",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Total sementara: Rp ${_formatRupiah(totalPrice)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: kTextGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          return _buildCartItem(
                            context,
                            cartItems[index],
                            cashierId,
                          );
                        },
                      ),
                    ),
                    // Bagian total + tombol Checkout
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kBackgroundColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  "Standard Shipping • Free",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kTextGrey,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Subtotal: Rp ${_formatRupiah(totalPrice)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kTextGrey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTotalRow(
                            'Estimated Total',
                            "Rp ${_formatRupiah(totalPrice)} + Tax",
                            isBold: true,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero, // biar padding diatur di Container dalam
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutPage(
                                      cartItems: cartItems,
                                      totalPrice: totalPrice,
                                    ),
                                  ),
                                );
                              },
                              child: Ink(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      kPrimaryGradientStart,
                                      kPrimaryGradientEnd,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(14)),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: const Text(
                                    'Lanjut ke Pembayaran',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      title: const Text(
        'Keranjang',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // ==== BOTTOM SHEET QTY PICKER (TIDAK DIUBAH BANYAK, SUDAH BAGUS) ====
  Future<int?> _showQuantityPicker(BuildContext context, int currentQuantity) async {
    final double itemHeight = 50;

    final FixedExtentScrollController scrollController =
    FixedExtentScrollController(initialItem: currentQuantity - 1);
    int selectedQuantity = currentQuantity;

    return await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInner) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.45,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      "Hapus dari keranjang",
                      style: TextStyle(color: Colors.red[700], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      Navigator.pop(context, 0);
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: itemHeight,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        ListWheelScrollView.useDelegate(
                          controller: scrollController,
                          itemExtent: itemHeight,
                          perspective: 0.003,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setStateInner(() {
                              selectedQuantity = index + 1;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (BuildContext context, int index) {
                              final int qty = index + 1;
                              final bool isSelected = (qty == selectedQuantity);

                              return Center(
                                child: Text(
                                  '$qty',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? kPrimaryGradientEnd
                                        : Colors.grey[700],
                                  ),
                                ),
                              );
                            },
                            childCount: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, selectedQuantity);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF041761),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==== ITEM CART BARU DENGAN CARD & LAYOUT LEBIH RAPI ====
  Widget _buildCartItem(BuildContext context, CartItem cartItem, int cashierId) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: kBackgroundColor,
              child: Image.network(
                cartItem.product.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: kTextGrey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Detail Produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + kategori
                Text(
                  cartItem.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cartItem.product.category,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextGrey,
                  ),
                ),
                const SizedBox(height: 8),
                // Qty + harga
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final int? selectedQuantity =
                        await _showQuantityPicker(context, cartItem.quantity);

                        if (selectedQuantity != null) {
                          if (selectedQuantity == 0) {
                            try {
                              await _cartService.removeProductFromCart(
                                  cashierId, cartItem.product.id!);
                              cartProvider.removeItem(cartItem.product);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to remove item: ${e.toString()}',
                                    ),
                                  ),
                                );
                              }
                            }
                          } else if (selectedQuantity != cartItem.quantity) {
                            try {
                              await _cartService.updateProductQuantity(
                                  cashierId, cartItem.product.id!, selectedQuantity);
                              cartProvider.updateQuantity(
                                  cartItem.product, selectedQuantity);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update quantity: ${e.toString()}',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: kBackgroundColor),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Qty ${cartItem.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "Rp ${_formatRupiah(cartItem.totalPrice)}",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isBold ? Colors.black87 : kTextGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              color: isBold ? const Color(0xFF041761) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRupiah(double value) {
    final str = value.toStringAsFixed(0);
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );
  }
}
