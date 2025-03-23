import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the price

class ShoppingListPage extends StatefulWidget {
  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> shoppingList = [];
  bool isLoading = true;
  String selectedProductName = '';
  int selectedQuantity = 1;
  TextEditingController customNameController = TextEditingController();
  TextEditingController customPriceController = TextEditingController();
  bool isFormVisible = false;

  // Function to fetch products from Firestore
  Future<void> fetchProducts() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('products').get();
      setState(() {
        products = snapshot.docs.map((doc) {
          return {
            'name': doc['name'],
            'price': doc['price'],
            'barcode': doc['barcode'],
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  // Function to fetch the shopping list data
  Future<void> fetchShoppingList() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var shoppingListRef = FirebaseFirestore.instance.collection('shopping_lists').doc(user.uid);
        var shoppingListSnapshot = await shoppingListRef.get();
        if (shoppingListSnapshot.exists) {
          setState(() {
            shoppingList = List<Map<String, dynamic>>.from(shoppingListSnapshot.data()!['items']);
            isLoading = false;
          });
        } else {
          setState(() {
            shoppingList = [];
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching shopping list: $e");
      }
    }
  }

  // Function to add item to shopping list (including custom items)
  Future<void> addItemToList(Map<String, dynamic> product, int quantity) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var shoppingListRef = FirebaseFirestore.instance.collection('shopping_lists').doc(user.uid);
        var shoppingListSnapshot = await shoppingListRef.get();
        if (shoppingListSnapshot.exists) {
          List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(shoppingListSnapshot.data()!['items']);
          
          var existingItemIndex = items.indexWhere((item) => item['product']['barcode'] == product['barcode']);
          if (existingItemIndex != -1) {
            items[existingItemIndex]['quantity'] += quantity;
          } else {
            items.add({'product': product, 'quantity': quantity, 'checked': false});
          }

          await shoppingListRef.update({'items': items});
        } else {
          await shoppingListRef.set({
            'items': [{'product': product, 'quantity': quantity, 'checked': false}],
          });
        }

        fetchShoppingList();
      } catch (e) {
        print('Error adding item to list: $e');
      }
    }
  }

  // Function to add custom item to shopping list
  Future<void> addCustomItemToList(String name, double price, int quantity) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var shoppingListRef = FirebaseFirestore.instance.collection('shopping_lists').doc(user.uid);
        var shoppingListSnapshot = await shoppingListRef.get();
        if (shoppingListSnapshot.exists) {
          List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(shoppingListSnapshot.data()!['items']);
          
          items.add({
            'product': {'name': name, 'price': price, 'barcode': ''},
            'quantity': quantity,
            'checked': false
          });

          await shoppingListRef.update({'items': items});
        } else {
          await shoppingListRef.set({
            'items': [{
              'product': {'name': name, 'price': price, 'barcode': ''},
              'quantity': quantity,
              'checked': false,
            }],
          });
        }

        fetchShoppingList();
        customNameController.clear();
        customPriceController.clear();
      } catch (e) {
        print('Error adding custom item to list: $e');
      }
    }
  }

  // Format price in Ksh
  String formatPrice(dynamic price) {
    double priceInDouble = price is int ? price.toDouble() : price;
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'Ksh ${formatter.format(priceInDouble)}';
  }

  // Calculate total for checked and unchecked items
  double calculateTotal(bool checked) {
    double total = 0.0;
    shoppingList.forEach((item) {
      if (item['checked'] == checked) {
        total += item['product']['price'] * item['quantity'];
      }
    });
    return total;
  }

  // Update the checked status in Firestore
  Future<void> updateCheckedStatus(int index, bool isChecked) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var shoppingListRef = FirebaseFirestore.instance.collection('shopping_lists').doc(user.uid);
        var shoppingListSnapshot = await shoppingListRef.get();
        if (shoppingListSnapshot.exists) {
          List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(shoppingListSnapshot.data()!['items']);
          items[index]['checked'] = isChecked;

          await shoppingListRef.update({'items': items});
        }
      } catch (e) {
        print("Error updating checked status: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchShoppingList(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Shopping List', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: showClearAllConfirmation,
            tooltip: 'Clear All Items',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: EdgeInsets.only(bottom: 16),
                    color: Colors.orange.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Total Unchecked: ${formatPrice(calculateTotal(false))}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.orange.shade800),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Total Checked: ${formatPrice(calculateTotal(true))}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  if (isFormVisible) ...[
                    DropdownButtonFormField<String>(
                      hint: Text("Select a product"),
                      value: selectedProductName.isEmpty ? null : selectedProductName,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedProductName = newValue!;
                        });
                      },
                      items: products.map((product) {
                        return DropdownMenuItem<String>(
                          value: product['name'],
                          child: Text(product['name']),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedQuantity = int.tryParse(value) ?? 1;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        var selectedProduct = products.firstWhere(
                          (product) => product['name'] == selectedProductName,
                        );
                        addItemToList(selectedProduct, selectedQuantity);
                      },
                      child: Text('Add to Shopping List',style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32), backgroundColor: Colors.orange.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    Divider(),
                    TextField(
                      controller: customNameController,
                      decoration: InputDecoration(
                        labelText: 'Custom Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: customPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Custom Item Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Custom Item Quantity',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedQuantity = int.tryParse(value) ?? 1;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        String customName = customNameController.text;
                        double customPrice = double.tryParse(customPriceController.text) ?? 0.0;
                        addCustomItemToList(customName, customPrice, selectedQuantity);
                      },
                      child: Text('Add Custom Item',style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32), backgroundColor: Colors.orange.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: shoppingList.length,
                      itemBuilder: (context, index) {
                        var item = shoppingList[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            title: Text(item['product']['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Price: ${formatPrice(item['product']['price'])}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: item['checked'],
                                  onChanged: (value) {
                                    setState(() {
                                      item['checked'] = value!;
                                    });
                                    updateCheckedStatus(index, value!);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDeleteItemConfirmation(index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isFormVisible = !isFormVisible;
          });
        },
        child: Icon(isFormVisible ? Icons.close : Icons.add),
        tooltip: 'Add Items',
        backgroundColor: Colors.orange,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to clear all items from the shopping list?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Clear All'),
              onPressed: () async {
                var user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('shopping_lists').doc(user.uid).update({'items': []});
                  setState(() {
                    shoppingList = [];
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show confirmation before deleting an item
  void showDeleteItemConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to delete this item from the shopping list?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                setState(() {
                  shoppingList.removeAt(index);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
