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
import '../../services/authHeader.dart';

// === THEME CONSISTENT (Yoomie) ===
const Color kBackgroundColor = Color(0xFFF3F6FD);
const Color kPrimaryGradientStart = Color(0xFF3B82F6);
const Color kPrimaryGradientEnd = Color(0xFF4F46E5);
const Color kTextGrey = Color(0xFF6B7280);

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

  // Payment method:
  // "cash" | "mandiri" | "bca"
  String _selectedPaymentMethod = 'cash';

  static const String _apiBaseUrl = 'http://10.0.2.2:8080';
  final checkoutService = CheckoutService(baseUrl: _apiBaseUrl);

  final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // ✅ formatter untuk angka input manual (1.000.000)
  final NumberFormat _thousand = NumberFormat.decimalPattern('id_ID');

  // preset cash selected (0 = none/custom)
  int _selectedCashPreset = 0;

  // ✅ cash rounding preset (angka “terdekat” di atasnya)
  // contoh: 1.130.000 -> 1.150.000, 1.170.000 -> 1.200.000
  static const int _cashRoundingMultiple = 50000;

  @override
  void initState() {
    super.initState();
    _loadCashierData();

    // Default: cash + exact amount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedPaymentMethod = 'cash';
      _selectCashPreset(_totalInt);
    });
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('cashierId');
    await prefs.remove('cashierName');

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
        if (e.toString().contains('UNAUTHORIZED')) {
          await _forceLogout();
          return;
        }
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

  // ===== Helpers (cash/change) =====
  int _parseCashPaid() {
    final raw = _cashPaidController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }

  int get _totalInt => widget.totalPrice.round();
  int get _change => _parseCashPaid() - _totalInt;

  int _roundUpToMultiple(int value, int multiple) {
    if (multiple <= 0) return value;
    return ((value + multiple - 1) ~/ multiple) * multiple;
  }

  // ✅ tombol quick amount kanan = pembulatan ke atas
  // kalau total sudah pas kelipatan, buat jadi total + multiple biar tidak sama
  int get _roundedUpCashPreset {
    final r = _roundUpToMultiple(_totalInt, _cashRoundingMultiple);
    return (r == _totalInt) ? (_totalInt + _cashRoundingMultiple) : r;
  }

  String _formatThousand(int value) => _thousand.format(value);

  void _selectCashPreset(int amount) {
    setState(() {
      _selectedCashPreset = amount;
      // ✅ tampilkan format 1.000.000 di input
      _cashPaidController.text = _formatThousand(amount);
    });
  }

  void _clearCashPreset() {
    setState(() => _selectedCashPreset = 0);
  }

  // ===== Checkout stock on server =====
  Future<bool> _checkoutCartOnServer(int cashierId) async {
    final uri = Uri.parse('$_apiBaseUrl/api/cart/checkout?cashierId=$cashierId');

    try {
      final response = await http.post(
        uri,
        headers: await authHeader(),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        await _forceLogout();
        return false;
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

  // ===== Validate cash =====
  bool _validateCashIfCashPayment() {
    if (_selectedPaymentMethod != 'cash') return true;

    final cashPaid = _parseCashPaid();
    if (cashPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the customer cash amount.')),
      );
      return false;
    }

    if (cashPaid < _totalInt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer cash is not enough.')),
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

    // Validate transfer method (must choose bank)
    if (_selectedPaymentMethod != 'cash' &&
        _selectedPaymentMethod != 'mandiri' &&
        _selectedPaymentMethod != 'bca') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    // Validate cash if cash
    if (!_validateCashIfCashPayment()) return;

    // STEP 1: Validate & update stock
    final stockOk = await _checkoutCartOnServer(cashierId);
    if (!stockOk) return;

    // STEP 2: Submit checkout payment
    try {
      final cashPaid =
      _selectedPaymentMethod == 'cash' ? _parseCashPaid().toDouble() : null;

      final changeAmount =
      _selectedPaymentMethod == 'cash' ? _change.toDouble() : null;

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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(
          paid: _selectedPaymentMethod == 'cash' ? _parseCashPaid() : _totalInt,
          change:
          _selectedPaymentMethod == 'cash' ? (_change >= 0 ? _change : 0) : 0,
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
      if (e.toString().contains('UNAUTHORIZED')) {
        await _forceLogout();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final itemKinds = widget.cartItems.length;
    final totalQty =
    widget.cartItems.fold<int>(0, (sum, it) => sum + it.quantity);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            _buildGradientHeader(),
            Expanded(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 120 + bottomInset),
                  child: Column(
                    children: [
                      _buildOrderSummaryCard(
                          itemKinds: itemKinds, totalQty: totalQty),
                      const SizedBox(height: 14),
                      _buildPaymentMethodCard(),
                      const SizedBox(height: 14),
                      if (_selectedPaymentMethod == 'cash')
                        _buildCashCard()
                      else
                        _buildTransferCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // ================= HEADER =================

  Widget _buildGradientHeader() {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review the order and complete payment.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARDS =================

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  Widget _buildOrderSummaryCard(
      {required int itemKinds, required int totalQty}) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _infoPill('Items', itemKinds.toString()),
              const SizedBox(width: 10),
              _infoPill('Qty', totalQty.toString()),
              const Spacer(),
              Text(
                _rupiah.format(widget.totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF041761),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Item list (compact)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cartItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = widget.cartItems[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      it.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'x${it.quantity}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: kTextGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _rupiah.format(it.totalPrice),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose how the customer pays.',
            style: TextStyle(fontSize: 12.5, color: kTextGrey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MethodChip(
                  label: 'Cash',
                  icon: Icons.payments_outlined,
                  selected: _selectedPaymentMethod == 'cash',
                  onTap: () {
                    setState(() => _selectedPaymentMethod = 'cash');
                    _selectCashPreset(_totalInt);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MethodChip(
                  label: 'Mandiri',
                  icon: Icons.account_balance_outlined,
                  selected: _selectedPaymentMethod == 'mandiri',
                  onTap: () =>
                      setState(() => _selectedPaymentMethod = 'mandiri'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MethodChip(
                  label: 'BCA',
                  icon: Icons.account_balance_outlined,
                  selected: _selectedPaymentMethod == 'bca',
                  onTap: () => setState(() => _selectedPaymentMethod = 'bca'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard() {
    final roundedPreset = _roundedUpCashPreset;
    final paid = _parseCashPaid();

    final bool showChange = paid > 0;
    final bool enough = showChange && _change >= 0;

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash Payment',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a quick amount or input manually.',
            style: TextStyle(fontSize: 12.5, color: kTextGrey),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _AmountButton(
                  label: _rupiah.format(_totalInt),
                  selected: _selectedCashPreset == _totalInt,
                  onTap: () {
                    _selectCashPreset(_totalInt);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AmountButton(
                  label: _rupiah.format(roundedPreset),
                  selected: _selectedCashPreset == roundedPreset,
                  onTap: () {
                    _selectCashPreset(roundedPreset);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _cashPaidController,
            keyboardType: TextInputType.number,
            // ✅ format otomatis jadi 1.000.000 saat mengetik
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: InputDecoration(
              hintText: _rupiah.format(roundedPreset),
              prefixIcon: const Icon(Icons.payments_outlined, color: kTextGrey),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onTap: () {
              _clearCashPreset();
              setState(() {});
            },
            onChanged: (_) {
              _clearCashPreset();
              setState(() {});
            },
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_exchange,
                    size: 18, color: kTextGrey),
                const SizedBox(width: 8),
                const Text(
                  'Change',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: kTextGrey),
                ),
                const Spacer(),
                Text(
                  showChange ? (enough ? _rupiah.format(_change) : '-') : '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: showChange
                        ? (enough ? Colors.green : Colors.red)
                        : kTextGrey,
                  ),
                ),
              ],
            ),
          ),

          if (showChange && !enough) ...[
            const SizedBox(height: 8),
            const Text(
              'Cash is not enough.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferCard() {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank Transfer',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose the bank and add an optional note.',
            style: TextStyle(fontSize: 12.5, color: kTextGrey),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _BankButton(
                  label: 'Mandiri',
                  selected: _selectedPaymentMethod == 'mandiri',
                  onTap: () =>
                      setState(() => _selectedPaymentMethod = 'mandiri'),
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

          const SizedBox(height: 12),

          TextField(
            controller: _transferNoteController,
            decoration: InputDecoration(
              hintText: 'Optional note',
              prefixIcon:
              const Icon(Icons.edit_note_rounded, color: kTextGrey),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12.5,
              color: kTextGrey,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.black87,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM ACTION BAR =================

  Widget _buildBottomActionBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  color: kTextGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _rupiah.format(widget.totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF041761),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: const Color(0xFFF9FAFB),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _onChargePressed,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Charge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= SMALL UI COMPONENTS =================

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
          border: Border.all(
            color: selected ? kPrimaryGradientEnd : Colors.transparent,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? kPrimaryGradientEnd : kTextGrey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: selected ? kPrimaryGradientEnd : Colors.black87,
              ),
            ),
          ],
        ),
      ),
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
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? kPrimaryGradientEnd : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black87,
          side: BorderSide(
            color: selected ? kPrimaryGradientEnd : const Color(0xFFE5E7EB),
            width: selected ? 1.2 : 1,
          ),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
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
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFEFF6FF) : Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(
            color: selected ? kPrimaryGradientEnd : const Color(0xFFE5E7EB),
            width: selected ? 1.4 : 1,
          ),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

// ================= SUCCESS DIALOG (Yoomie style) =================

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Payment Successful',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                        border:
                        Border.all(color: Colors.white.withOpacity(0.22)),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  _row('Paid', rupiah.format(paid)),
                  const SizedBox(height: 10),
                  _row('Change', rupiah.format(change)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Ink(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryGradientStart, kPrimaryGradientEnd],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Back to Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
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
      ),
    );
  }

  Widget _row(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: kTextGrey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= INPUT FORMATTER: 1.000.000 =================

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final number = int.tryParse(digitsOnly) ?? 0;
    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
