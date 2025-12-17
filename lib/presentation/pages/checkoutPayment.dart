import 'package:flutter/material.dart';
import 'package:helloworld/presentation/pages/profilePage.dart';
import '../../models/Payment.dart';
import '../../services/CheckoutService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/CartItem.dart';
import '../../models/cashier.dart';
import '../mainLayout.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalPrice;

  const CheckoutPage({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // CASH input
  final TextEditingController _cashPaidController = TextEditingController();

  // Transfer note (optional)
  final TextEditingController _transferNoteController = TextEditingController();

  // Metode pembayaran:
  // "cash" | "mandiri" | "bca"
  String _selectedPaymentMethod = 'cash';

  static const String _apiBaseUrl = 'http://10.0.2.2:8080';
  final checkoutService = CheckoutService(baseUrl: _apiBaseUrl);

  final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  int _selectedCashPreset = 0; // nilai preset cash yang dipilih (0 = none/custom)

  @override
  void initState() {
    super.initState();
    _loadCashierData();

    // Default: preset = total (seperti di foto tombol Rp.95.000 ter-select)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectCashPreset(_totalInt);
    });
  }

  Future<void> _loadCashierData() async {
    final prefs = await SharedPreferences.getInstance();
    final cashierId = prefs.getInt('cashierId');

    if (cashierId != null) {
      try {
        final Cashier cashier = await checkoutService.getCashierById(cashierId);
        setState(() {
          _fullNameController.text = cashier.fullName;
          _emailController.text = cashier.email;
        });
      } catch (e) {
        // ignore: avoid_print
        print('Error loading cashier data: $e');
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _cashPaidController.dispose();
    _transferNoteController.dispose();
    super.dispose();
  }

  // ====== Helper uang/kembalian ======
  int _parseCashPaid() {
    final raw = _cashPaidController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }

  int get _totalInt => widget.totalPrice.round();
  int get _change => _parseCashPaid() - _totalInt;

  void _selectCashPreset(int amount) {
    setState(() {
      _selectedCashPreset = amount;
      _cashPaidController.text = amount.toString();
    });
  }

  void _clearCashPreset() {
    setState(() => _selectedCashPreset = 0);
  }

  // ====== Checkout stok di server ======
  Future<bool> _checkoutCartOnServer(int cashierId) async {
    final uri = Uri.parse('$_apiBaseUrl/api/cart/checkout?cashierId=$cashierId');

    try {
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      } else {
        final message = response.body.isNotEmpty
            ? response.body
            : 'Failed to checkout cart. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: $e')),
      );
      return false;
    }
  }

  // ====== Validasi cash ======
  bool _validateCashIfCashPayment() {
    if (_selectedPaymentMethod != 'cash') return true;

    final cashPaid = _parseCashPaid();
    if (cashPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan uang customer terlebih dahulu.')),
      );
      return false;
    }

    if (cashPaid < _totalInt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang customer kurang.')),
      );
      return false;
    }

    return true;
  }

  Future<void> _onChargePressed() async {
    final prefs = await SharedPreferences.getInstance();
    final cashierId = prefs.getInt('cashierId');

    if (cashierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cashier not logged in.')),
      );
      return;
    }

    // Validasi metode transfer (pastikan pilih bank)
    if (_selectedPaymentMethod != 'cash' &&
        _selectedPaymentMethod != 'mandiri' &&
        _selectedPaymentMethod != 'bca') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu.')),
      );
      return;
    }

    // Validasi cash bila cash
    if (!_validateCashIfCashPayment()) return;

    // STEP 1: Validasi stok & update stok
    final stockOk = await _checkoutCartOnServer(cashierId);
    if (!stockOk) return;

    // STEP 2: Submit checkout payment
    try {
      final cashPaid = _selectedPaymentMethod == 'cash'
          ? _parseCashPaid().toDouble()
          : null;

      final changeAmount = _selectedPaymentMethod == 'cash'
          ? _change.toDouble()
          : null;

      final payment = PaymentDTO(
        cashierId: cashierId,
        paymentMethod: _selectedPaymentMethod,
        totalAmount: widget.totalPrice,
        cashPaid: cashPaid,
        changeAmount: changeAmount,
      );

      final items = widget.cartItems
          .map(
            (cartItem) => PaymentItemDTO(
          cashierId: cashierId,
          name: cartItem.product.name,
          quantity: cartItem.quantity,
          price: cartItem.product.price,
          subTotal: cartItem.totalPrice,
        ),
      )
          .toList();

      await checkoutService.submitCheckout(payment, items);

      if (!mounted) return;

      // Popup Success seperti foto
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(
          paid: _selectedPaymentMethod == 'cash'
              ? _parseCashPaid()
              : _totalInt,
          change: _selectedPaymentMethod == 'cash'
              ? (_change >= 0 ? _change : 0)
              : 0,
          rupiah: _rupiah,
          onClose: () {
            Navigator.pop(context);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MainLayout(
                  initialIndex: 2,
                  cashierId: cashierId,
                ),
              ),
                  (route) => false,
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // agar rapi seperti tampilan tablet/desktop pada foto
    final maxWidth = 920.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Text(
              "AtheleteZone",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            const Icon(Icons.search, color: Colors.black),
            const SizedBox(width: 20),
            const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: _buildPaymentLayout(context),
          ),
        ),
      ),
      bottomNavigationBar: _MockBottomNav(currentIndex: 2),
    );
  }

  Widget _buildPaymentLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: icon + Transaction
        Row(
          children: const [
            Icon(Icons.shopping_cart_checkout, size: 26, color: Color(0xFF0B5FA5)),
            SizedBox(width: 10),
            Text(
              'Transaction',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Top bar: Cancel | Total | Charge
        // Top bar: Cancel & Charge (row) + Total (center under)
        Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 140,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _onChargePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F6BC2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Charge',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _rupiah.format(widget.totalPrice),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),


        const SizedBox(height: 10),
        const Divider(),

        // CASH section
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 120,
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Cash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _AmountButton(
                          label: _rupiah.format(_totalInt),
                          selected: _selectedPaymentMethod == 'cash' && _selectedCashPreset == _totalInt,
                          onTap: () {
                            setState(() => _selectedPaymentMethod = 'cash');
                            _selectCashPreset(_totalInt);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AmountButton(
                          label: _rupiah.format(100000),
                          selected: _selectedPaymentMethod == 'cash' && _selectedCashPreset == 100000,
                          onTap: () {
                            setState(() => _selectedPaymentMethod = 'cash');
                            _selectCashPreset(100000);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cashPaidController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: _rupiah.format(100000),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black26),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2F6BC2), width: 1.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onTap: () {
                      // user ingin custom input -> lepas preset
                      if (_selectedPaymentMethod != 'cash') {
                        setState(() => _selectedPaymentMethod = 'cash');
                      }
                      _clearCashPreset();
                    },
                    onChanged: (_) {
                      if (_selectedPaymentMethod != 'cash') {
                        setState(() => _selectedPaymentMethod = 'cash');
                      }
                      _clearCashPreset();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),

                  // Kembalian kecil (optional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Change: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        _selectedPaymentMethod == 'cash' && _parseCashPaid() > 0
                            ? (_change >= 0 ? _rupiah.format(_change) : '-')
                            : '-',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: (_selectedPaymentMethod == 'cash' && _change >= 0) ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(),

        // TRANSFER section
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 120,
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _BankButton(
                          label: 'Mandiri',
                          selected: _selectedPaymentMethod == 'mandiri',
                          onTap: () => setState(() => _selectedPaymentMethod = 'mandiri'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BankButton(
                          label: 'BCA',
                          selected: _selectedPaymentMethod == 'bca',
                          onTap: () => setState(() => _selectedPaymentMethod = 'bca'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _transferNoteController,
                    decoration: const InputDecoration(
                      hintText: 'Optional Note',
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black26),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2F6BC2), width: 1.6),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmountButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AmountButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFF2F6BC2) : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black,
          side: BorderSide(color: selected ? const Color(0xFF2F6BC2) : Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _BankButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BankButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: BorderSide(color: selected ? const Color(0xFF2F6BC2) : Colors.black26, width: selected ? 1.6 : 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final int paid;
  final int change;
  final NumberFormat rupiah;
  final VoidCallback onClose;

  const _SuccessDialog({
    required this.paid,
    required this.change,
    required this.rupiah,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 14),
                const Text('SUCCESS', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Expanded(child: Text('Paid', style: TextStyle(fontWeight: FontWeight.w600))),
                    Text(rupiah.format(paid), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(child: Text('Change', style: TextStyle(fontWeight: FontWeight.w600))),
                    Text(rupiah.format(change), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),

          // tombol close (X) merah seperti foto
          Positioned(
            right: 8,
            top: 8,
            child: InkWell(
              onTap: onClose,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom navbar pada foto (ikon saja).
/// Silakan sambungkan onTap ke navigasi asli Anda bila sudah ada.
class _MockBottomNav extends StatelessWidget {
  final int currentIndex;
  const _MockBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black45,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.lock_outline), label: 'PoS'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transaction'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}








