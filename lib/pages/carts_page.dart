import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isProcessingPayment = false;  // To track if payment is being processed

  // Function to format the price to Kshs currency format
  String formatPrice(double price) {
    final formatter = NumberFormat.currency(
      name: 'Kshs ',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  void updateCartQuantity(
    Map<String, dynamic> product,
    int newQuantity,
    int oldQuantity,
  ) async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var cartRef = FirebaseFirestore.instance
            .collection('carts')
            .doc(user.uid);
        var productRef = FirebaseFirestore.instance
            .collection('products')
            .where('barcode', isEqualTo: product['barcode']);

        // Begin a batch write to update both cart and product stock atomically
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // Get cart items
        var cartSnapshot = await cartRef.get();
        if (cartSnapshot.exists) {
          var cartItems = List<Map<String, dynamic>>.from(
            cartSnapshot.data()!['items'],
          );
          var cartItemIndex = cartItems.indexWhere(
            (item) => item['product']['barcode'] == product['barcode'],
          );

          if (cartItemIndex != -1) {
            // Update the cart item quantity
            cartItems[cartItemIndex]['quantity'] = newQuantity;
            batch.update(cartRef, {
              'items': cartItems,
            }); // Apply changes to the cart
          }
        }

        // Update the product stock
        int stockDifference = newQuantity - oldQuantity;
        await productRef.get().then((productData) {
          productData.docs.forEach((doc) {
            batch.update(doc.reference, {
              'stock': FieldValue.increment(-stockDifference),
            });
          });
        });

        // Commit the batch operation to ensure both updates are atomic
        await batch.commit();
      }
    } catch (e) {
      print('Error updating cart quantity: $e');
    }
  }

  void deleteCartItem(Map<String, dynamic> product) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Show a confirmation dialog before deleting the cart item
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete Item'),
            content: Text(
              'Are you sure you want to delete this item from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmDelete != null && confirmDelete) {
        try {
          var cartRef = FirebaseFirestore.instance
              .collection('carts')
              .doc(user.uid);
          var cartSnapshot = await cartRef.get();
          if (cartSnapshot.exists) {
            var cartItems = List<Map<String, dynamic>>.from(
              cartSnapshot.data()!['items'],
            );
            cartItems.removeWhere(
              (item) => item['product']['barcode'] == product['barcode'],
            );
            await cartRef.update({'items': cartItems});
          }
        } catch (e) {
          print('Error deleting cart item: $e');
        }
      }
    }
  }

  void clearCart() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Show a confirmation dialog before clearing all cart items
      bool? confirmClear = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Clear Cart'),
            content: Text(
              'Are you sure you want to clear all items from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Clear All'),
              ),
            ],
          );
        },
      );

      if (confirmClear != null && confirmClear) {
        try {
          var cartRef = FirebaseFirestore.instance
              .collection('carts')
              .doc(user.uid);
          await cartRef.update({'items': []});
        } catch (e) {
          print('Error clearing cart: $e');
        }
      }
    }
  }

  void showPaymentProcessingMessage(String paymentMethod) {
    setState(() {
      _isProcessingPayment = true;
    });

    // Simulate payment processing time
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isProcessingPayment = false;
      });
      // You can add different actions based on the selected payment method
      if (paymentMethod == 'M-Pesa') {
        // Show PIN input dialog for M-Pesa
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Enter your M-Pesa PIN'),
            content: TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: 'PIN'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Submit')),
            ],
          ),
        );
      }
      // Add more actions for other payment methods here...
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.orange.shade800,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.delete_forever), onPressed: clearCart),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('carts')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.data() == null) {
            return const Center(child: Text('Your cart is empty'));
          }

          var cartItems = List<Map<String, dynamic>>.from(
            snapshot.data!['items'],
          );
          if (cartItems.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          // Combine quantities of the same product
          Map<String, Map<String, dynamic>> combinedItems = {};
          double totalAmount = 0.0;
          int totalItems = 0;
          for (var item in cartItems) {
            var barcode = item['product']['barcode'];
            if (combinedItems.containsKey(barcode)) {
              combinedItems[barcode]!['quantity'] += item['quantity'];
            } else {
              combinedItems[barcode] = item;
            }

            // Ensure 'price' is treated as a double, and 'quantity' as an int
            double price =
                (item['product']['price'] is int)
                    ? (item['product']['price'] as int).toDouble()
                    : item['product']['price'] as double;
            totalAmount += price * (item['quantity'] as int);

            totalItems += item['quantity'] as int; // Ensure quantity is an int
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Items: $totalItems', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Total Amount: ${formatPrice(totalAmount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: combinedItems.length,
                  itemBuilder: (context, index) {
                    var item = combinedItems.values.toList()[index];
                    double totalPrice =
                        (item['product']['price'] * item['quantity'])
                            .toDouble();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: Image.network(
                          item['product']['image'],
                          width: 50,
                          height: 50,
                        ),
                        title: Text(item['product']['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity: ${item['quantity']}'),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.remove,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    if (item['quantity'] > 1) {
                                      // Update cart and product stock when decreasing
                                      updateCartQuantity(
                                        item['product'],
                                        item['quantity'] - 1,
                                        item['quantity'],
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.add, color: Colors.orange),
                                  onPressed: () {
                                    if (item['quantity'] <
                                        item['product']['stock']) {
                                      // Update cart and product stock when increasing
                                      updateCartQuantity(
                                        item['product'],
                                        item['quantity'] + 1,
                                        item['quantity'],
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    deleteCartItem(item['product']);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${formatPrice(totalPrice)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _isProcessingPayment
                  ? Center(child: CircularProgressIndicator())
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Select Payment Method'),
                                      ListTile(
                                        title: Text('PayPal'),
                                        onTap: () {
                                          showPaymentProcessingMessage('PayPal');
                                        },
                                      ),
                                      ListTile(
                                        title: Text('M-Pesa'),
                                        onTap: () {
                                          showPaymentProcessingMessage('M-Pesa');
                                        },
                                      ),
                                      ListTile(
                                        title: Text('Visa'),
                                        onTap: () {
                                          showPaymentProcessingMessage('Visa');
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Text('Checkout'),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
