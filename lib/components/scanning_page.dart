import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String barcode = '';
  Map<String, dynamic>? scannedProduct;
  int quantity = 1;
  String scanningMessage = '';

  // Function to format the price to Kshs currency format
  String formatPrice(double price) {
    final formatter = NumberFormat.currency(name: 'Kshs ', symbol: '', decimalDigits: 0);
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    _scanBarcode(); // Automatically start scanning when the page is loaded
  }

  Future<void> _scanBarcode() async {
    setState(() {
      scanningMessage = 'Scanning...'; // Show the scanning message
    });

    var result = await BarcodeScanner.scan();
    setState(() {
      barcode = result.rawContent;
      scanningMessage = ''; // Clear the scanning message once done
    });

    // Fetch product details from Firestore based on the barcode
    _fetchProduct(barcode);
  }

  Future<void> _fetchProduct(String barcode) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // If product exists
        setState(() {
          scannedProduct = snapshot.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        // Handle barcode not found - show message immediately during scan
        setState(() {
          scanningMessage = 'Product not found for this barcode';
        });
      }
    } catch (e) {
      print('Error fetching product: $e');
    }
  }

  void incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decrementQuantity() {
    setState(() {
      if (quantity > 1) quantity--;
    });
  }

Future<void> addToCart(Map<String, dynamic> product, int quantity) async {
  try {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var cartRef = FirebaseFirestore.instance.collection('carts').doc(user.uid);

      // Check if product exists in the cart
      var cartSnapshot = await cartRef.get();
      if (cartSnapshot.exists) {
        var cartItems = List<Map<String, dynamic>>.from(cartSnapshot.data()!['items']);
        
        // Check if product already exists in the cart
        var cartItemIndex = cartItems.indexWhere((item) => item['product']['barcode'] == product['barcode']);
        
        if (cartItemIndex != -1) {
          // Product already in cart, update the quantity
          cartItems[cartItemIndex]['quantity'] += quantity;
          await cartRef.update({
            'items': cartItems, // Update the cart with the new quantity
          });
        } else {
          // Product not in cart, add it as a new entry
          await cartRef.update({
            'items': FieldValue.arrayUnion([
              {'product': product, 'quantity': quantity},
            ]),
          });
        }
      } else {
        // If cart is empty, create a new cart
        await cartRef.set({
          'items': [
            {'product': product, 'quantity': quantity},
          ],
        });
      }

      // Update the product stock
      var productRef = FirebaseFirestore.instance.collection('products').where('barcode', isEqualTo: product['barcode']);
      await productRef.get().then((productData) {
        productData.docs.forEach((doc) {
          doc.reference.update({
            'stock': FieldValue.increment(-quantity),
          });
        });
      });

      Navigator.pop(context); // Close the scan page after adding to cart
    }
  } catch (e) {
    print('Error adding to cart: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Product'),
        backgroundColor: Colors.orange.shade800,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (scanningMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    scanningMessage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              if (scannedProduct == null)
                Container(
                  height: 200,
                  width: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Column(
                  children: [
                    Image.network(scannedProduct!['image'], height: 150, fit: BoxFit.cover),
                    SizedBox(height: 16),
                    Text(
                      scannedProduct!['name'],
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Price: ${formatPrice(scannedProduct!['price'].toDouble())}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Description: ${scannedProduct!['description']}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, color: Colors.orange),
                          onPressed: decrementQuantity,
                        ),
                        Text('Quantity: $quantity', style: TextStyle(fontSize: 18)),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.orange),
                          onPressed: incrementQuantity,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        addToCart(scannedProduct!, quantity);
                      },
                      child: Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
