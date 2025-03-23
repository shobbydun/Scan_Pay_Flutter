import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scan_pay/components/bottom_nav_bar.dart';
import 'package:scan_pay/components/scanning_page.dart';
import 'package:scan_pay/components/store_map_page.dart';
import 'package:scan_pay/pages/carts_page.dart';
import 'package:scan_pay/pages/shopping_list_page.dart';
import 'package:url_launcher/url_launcher.dart';

import 'products_page.dart'; // Import the Products Page
import 'profile_page.dart'; // Import the Profile Page

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? businessName;
  bool isLoading = true;
  bool showScanIcon = false;
  int cartItemCount = 0;
  int _currentIndex = 0; // To track the currently selected tab

  // Variables to store fetched data
  DateTime? flashSaleEndsIn; // Change from String to DateTime
  double flashSaleDiscount = 0;
  List<Map<String, dynamic>> offers = [];
  List<Map<String, dynamic>> popularProducts = [];
  Timer? _timer;
  String countdown = "";

  @override
  void initState() {
    super.initState();
    _fetchBusinessName();
    _fetchFlashSaleData();
    _fetchOffersData();
    _fetchPopularProducts();
    _fetchCartItemCount();
  }

  Future<void> _fetchCartItemCount() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        FirebaseFirestore.instance
            .collection('carts')
            .doc(user.uid)
            .snapshots()
            .listen((cartSnapshot) {
              if (cartSnapshot.exists) {
                // Get the list of items from the snapshot and count unique products
                var cartItems = List<Map<String, dynamic>>.from(
                  cartSnapshot['items'],
                );
                int totalQuantity = 0;

                // Iterate through the items and add their quantity
                for (var item in cartItems) {
                  // Explicitly convert the quantity to int using `toInt()`
                  totalQuantity +=
                      (item['quantity'] is num)
                          ? (item['quantity'] as num).toInt()
                          : 0;
                }

                setState(() {
                  cartItemCount = totalQuantity;
                });
              }
            });
      } catch (e) {
        print('Error fetching cart item count: $e');
      }
    }
  }

  // Fetch business name from Firestore
  Future<void> _fetchBusinessName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          setState(() {
            businessName = userDoc['businessName'];
            isLoading = false; // Update loading status
          });
        }
      } catch (e) {
        print('Error fetching business name: $e');
      }
    }
  }

  // Fetch flash sale data from Firestore
  Future<void> _fetchFlashSaleData() async {
    try {
      DocumentSnapshot flashSaleDoc =
          await FirebaseFirestore.instance
              .collection('flashSales')
              .doc('OXNT1Ps1zM35mNpxWOaP') // Replace with the correct ID
              .get();

      if (flashSaleDoc.exists) {
        var data = flashSaleDoc.data() as Map<String, dynamic>;

        // Handle Timestamp field for the end time
        Timestamp timestamp =
            data['endsIn']; // Assuming 'endsIn' is a Timestamp field
        DateTime endsInDate =
            timestamp.toDate(); // Convert Timestamp to DateTime

        // Fix the issue with the flashSaleDiscount (type mismatch)
        setState(() {
          flashSaleEndsIn = endsInDate;
          // Ensure discount is treated as double, even if it's an int
          flashSaleDiscount =
              (data['discount'] ?? 0)
                  .toDouble(); // Convert to double if it's int
        });

        _startCountdown();
      }
    } catch (e) {
      print('Error fetching flash sale data: $e');
    }
  }

  // Start countdown timer
  void _startCountdown() {
    if (flashSaleEndsIn == null) return;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = flashSaleEndsIn!.difference(now);

      if (difference.isNegative) {
        setState(() {
          countdown = "Expired"; // Sale expired
        });
        _timer?.cancel();
      } else {
        setState(() {
          countdown =
              "${difference.inHours.toString().padLeft(2, '0')}:${(difference.inMinutes % 60).toString().padLeft(2, '0')}:${(difference.inSeconds % 60).toString().padLeft(2, '0')}";
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Fetch offers data from Firestore
  Future<void> _fetchOffersData() async {
    try {
      QuerySnapshot offerSnapshot =
          await FirebaseFirestore.instance.collection('offers').get();
      List<Map<String, dynamic>> offersList = [];
      for (var doc in offerSnapshot.docs) {
        offersList.add(doc.data() as Map<String, dynamic>);
      }
      setState(() {
        offers = offersList;
      });
    } catch (e) {
      print('Error fetching offers data: $e');
    }
  }

  // Fetch popular products from Firestore
  Future<void> _fetchPopularProducts() async {
    try {
      QuerySnapshot productSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('popular', isEqualTo: true)
              .get();
      List<Map<String, dynamic>> productsList = [];
      for (var doc in productSnapshot.docs) {
        productsList.add(doc.data() as Map<String, dynamic>);
      }
      setState(() {
        popularProducts = productsList;
      });
    } catch (e) {
      print('Error fetching popular products: $e');
    }
  }

  // Function to handle navigation
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Function to launch a URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Function to call or text a phone number
  Future<void> _launchPhone(String phoneNumber, {bool isText = false}) async {
    final Uri phoneUri =
        isText
            ? Uri(scheme: 'sms', path: phoneNumber)
            : Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      throw 'Could not launch phone app';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _currentIndex == 0
              ? AppBar(
                backgroundColor: Colors.orange.shade800,
                title: const Text('Welcome to Scan & Pay'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      // Show notifications logic
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app, color: Colors.white),
                    onPressed: () => _logout(context),
                  ),
                ],
              )
              : null,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                index: _currentIndex,
                children: [
                  _buildDashboardPage(),
                  ProductsPage(),
                  CartPage(),
                  ProfilePage(),
                ],
              ),
      bottomNavigationBar: SafeArea(
        child: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          cartItemCount: cartItemCount,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanPage()),
            );
          });
        },
        backgroundColor: Colors.orange.shade800,
        child: const Icon(Icons.qr_code_scanner), // QR code scanner icon
      ),
    );
  }

  Widget _buildDashboardPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, ${businessName ?? "User"}!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildSearchBar(context), // Pass the context here
            const SizedBox(height: 20),
            _buildCarousel(),
            const SizedBox(height: 20),
            _buildFlashSale(),
            const SizedBox(height: 20),
            _buildPopularProducts(),
            const SizedBox(height: 20),
            _buildInStoreNavigationAndShoppingLists(),
            const SizedBox(height: 20),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // Flash Sale Section
  Widget _buildFlashSale() {
    return Container(
      width: 720,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color.fromARGB(182, 255, 205, 210),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flash Sale - ${flashSaleDiscount}% Off Today Only!',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Hurry, limited time offer!',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            flashSaleEndsIn == null
                ? 'Loading...'
                : 'Ends in: $countdown', // Display the countdown
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Carousel for Offers
  Widget _buildCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 180.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: true,
          ),
          items:
              offers.map((offer) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(offer['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Exclusive Offers for Today!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Check out the best deals of the day with up to 50% off!',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // Popular Products Horizontal Scrolling
  Widget _buildPopularProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                popularProducts.map((product) {
                  return _buildProductCard(product['image'], product['name']);
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(String image, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildSearchBar(BuildContext context) {
  return GestureDetector(
    onTap: () {
      // Navigate to products page when search field is tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProductsPage()), // Replace with your actual products page
      );
    },
    child: AbsorbPointer(  // Prevent interaction with the TextField, but allow the gesture
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Search for products or categories...',
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.orange),
          ),
          readOnly: true,  // Make the TextField read-only so the keyboard doesn't show up
        ),
      ),
    ),
  );
}


  // In-Store Navigation and Shopping Lists in One Line
  Widget _buildInStoreNavigationAndShoppingLists() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            color: Colors.green.shade100, // Green accent for navigation
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'In-Store Navigation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StoreMapPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Find The Products!',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.orange.shade800, // Orange accent color
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            color: Colors.blue.shade100, // Blue accent for shopping lists
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Your Shopping Lists',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShoppingListPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'With Calculator',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blue.shade800, // Blue accent color
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Footer Section
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  // Navigate to Terms & Conditions page (replace with actual URL)
                  _launchURL(
                    'https://github.com/shobbydun/login_signup_pages_FlaskAPP/blob/main/README.md',
                  );
                },
                child: const Text('Terms & Conditions'),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to Privacy Policy page (replace with actual URL)
                  _launchURL(
                    'https://github.com/shobbydun/login_signup_pages_FlaskAPP/blob/main/README.md',
                  );
                },
                child: const Text('Privacy Policy'),
              ),
              TextButton(
                onPressed: () {
                  // Call or Text your phone number
                  _launchPhone(
                    '+254710285209',
                    isText: true,
                  ); // Set to `false` for call
                },
                child: const Text('Contact Us'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '© 2025 Your Company. All Rights Reserved.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Function to determine the time of day for greeting
String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good Morning';
  } else if (hour < 17) {
    return 'Good Afternoon';
  } else {
    return 'Good Evening';
  }
}

Future<void> _logout(BuildContext context) async {
  bool? confirmLogout = await showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
  );
  if (confirmLogout == true) {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/');
  }
}
