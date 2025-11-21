import 'package:flutter/material.dart';
import 'package:helloworld/presentation/pages/profilePage.dart';
import '../../models/Payment.dart';
import '../../services/CheckoutService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/CartItem.dart'; // Import CartItem
import '../../models/cashier.dart';
import '../mainLayout.dart'; // Import MainLayout

String fullName = '';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalPrice;

  const CheckoutPage({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
  }) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();


  String? _selectedPaymentMethod = 'credit';

  bool isDelivery = true;
  String? selectedLocation;
  String? selectedTime;

  List<String> pickupLocations = ['Bandung Store', 'Jakarta Store'];
  List<String> pickupTimes = ['10:00 AM', '1:00 PM', '4:00 PM'];
  final checkoutService = CheckoutService(baseUrl: 'http://10.0.2.2:8080'); // **IMPORTANT:** Update your base URL

  @override
  void initState() {
    super.initState();
    _loadCashierData();
  }

  Future<void> _loadCashierData() async {
    final prefs = await SharedPreferences.getInstance();
    final cashierId = prefs.getInt('cashierId'); // Get cashier ID from shared preferences

    if (cashierId != null) {
      try {
        final Cashier cashier = await checkoutService.getCashierById(cashierId); // Fetch cashier data
        setState(() {
          // Assume fullname from backend is "First Last"
          _fullNameController.text = cashier.fullName;
          _emailController.text = cashier.email;

        });
      } catch (e) {
        print('Error loading cashier data: $e');
        // Optionally show a snackbar or error message
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Text("AthleteZone",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
            Spacer(),
            Icon(Icons.search, color: Colors.black),
            SizedBox(width: 20),
            Icon(Icons.shopping_cart_outlined, color: Colors.black),
            SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.account_circle_outlined, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) { // Only validate form on step 0
            if (_formKey.currentState!.validate()) {
              setState(() {
                if (_currentStep < 2) _currentStep += 1;
              });
            }
          } else if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {

          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                if (!isLastStep)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text('Continue', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                    ),
                  ),
                if (!isLastStep) SizedBox(width: 20),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text('Back', style: TextStyle(color: Colors.blue[900])),
                ),
                // For the last step, the submit button is inside the step content
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text("1. Delivery Options"),
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isDelivery = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDelivery ? const Color(0xFF041761) : Colors.white,
                            side: BorderSide(color: const Color(0xFF041761)),
                          ),
                          child: Text(
                            "Delivery",
                            style: TextStyle(
                              color: isDelivery ? Colors.white : const Color(0xFF041761),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isDelivery = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isDelivery ? const Color(0xFF041761) : Colors.white,
                            side: BorderSide(color: const Color(0xFF041761)),
                          ),
                          child: Text(
                            "Pick Up",
                            style: TextStyle(
                              color: !isDelivery ? Colors.white : const Color(0xFF041761),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  if (isDelivery) ...[
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(labelText: "Full Name"),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      // onChanged is not needed if using controller and validation is done on continue
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: "Email"),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Pickup Location"),
                      value: selectedLocation, // Set initial value
                      items: pickupLocations.map((location) {
                        return DropdownMenuItem(value: location, child: Text(location));
                      }).toList(),
                      onChanged: (value) => setState(() => selectedLocation = value),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Pickup Time"),
                      value: selectedTime, // Set initial value
                      items: pickupTimes.map((time) {
                        return DropdownMenuItem(value: time, child: Text(time));
                      }).toList(),
                      onChanged: (value) => setState(() => selectedTime = value),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ],
                ],
              ),
            ),
            isActive: _currentStep == 0,
            state: _currentStep == 0 ? StepState.editing : StepState.indexed,
          ),
          Step(
            title: Text("2. Payment"),
            content: Column(
              children: [
                RadioListTile(
                  title: Text("Credit Card"),
                  value: "credit",
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value.toString()),
                ),
                RadioListTile(
                  title: Text("PayPal"),
                  value: "paypal",
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value.toString()),
                ),
                RadioListTile(
                  title: Text("Cash on Delivery"),
                  value: "cod",
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value.toString()),
                ),
              ],
            ),
            isActive: _currentStep == 1,
            state: _currentStep == 1 ? StepState.editing : StepState.indexed,
          ),
          Step(
            title: Text("3. Transaction Review"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Cart Items dynamically here
                Text('Transaction Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 10),
                // Using a Column and iterating through cartItems
                // Consider using ListView.builder if the list can be very long and needs to scroll independently
                // For a potentially shorter list within a Stepper, Column is fine.
                ...widget.cartItems.map((item) => Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Assuming your CartItem has a product object with photoUrl
                        // If not, adjust `item.product.photoUrl` accordingly
                        Image.network(item.product.photoUrl, width: 80, height: 80, fit: BoxFit.cover),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Qty: ${item.quantity}'),
                              // Add other product details from CartItem as needed, e.g., size, color
                              // Text('Size: ${item.product.size}'),
                              // Text('Color: ${item.product.color}'),
                              SizedBox(height: 5),
                              Text(
                                'Rp ${item.totalPrice.toStringAsFixed(0).replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (match) => '${match[1]}.',
                                )}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(), // Convert iterable to List of Widgets
                Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: Rp ${widget.totalPrice.toStringAsFixed(0).replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (match) => '${match[1]}.',
                    )}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Final validation for pick-up fields if applicable
                      if (!isDelivery && (selectedLocation == null || selectedTime == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select pickup location and time.')),
                        );
                        return;
                      }

                      // Retrieve cashier ID
                      final prefs = await SharedPreferences.getInstance();
                      final cashierId = prefs.getInt('cashierId');

                      if (cashierId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cashier not logged in.')),
                        );
                        return;
                      }

                      try {
                        final payment = PaymentDTO(
                          cashierId: cashierId,
                          paymentMethod: _selectedPaymentMethod ?? 'credit',
                          totalAmount: widget.totalPrice,
                        );

                        final items = widget.cartItems.map((cartItem) => PaymentItemDTO(
                          cashierId: cashierId,
                          name: cartItem.product.name,
                          quantity: cartItem.quantity,
                          price: cartItem.product.price,
                          subTotal: cartItem.totalPrice,
                        )).toList();

                        print("Submitting checkout...");
                        await checkoutService.submitCheckout(payment, items);
                        print("Checkout submitted!");

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Transaction Confirmed"),
                            content: Text("Thank you for your purchase!"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Tutup AlertDialog

                                  // Ganti baris ini:
                                  // Navigator.pushAndRemoveUntil(
                                  //   context,
                                  //   MaterialPageRoute(builder: (context) => TransactionsPage()),
                                  //       (route) => false,
                                  // );

                                  // Dengan ini: Kembali ke MainLayout dan set indeks ke tab Transactions (indeks 2)
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MainLayout(initialIndex: 2)),
                                        (Route<dynamic> route) => false, // Ini akan menghapus semua rute di bawah MainLayout
                                  );
                                },
                                child: Text("OK"),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        print('Checkout submission failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to submit transaction: $e')),
                        );
                      }

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF041761),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text("Submit Transaction", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            isActive: _currentStep == 2,
          ),
        ],
      ),
    );
  }
}