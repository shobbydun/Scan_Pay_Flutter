import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:scan_pay/components/scanning_page.dart';

List<String> categories = [
  'All Products',
  'Fruits',
  'Vegetables',
  'Dairy',
  'Snacks',
  'Beverages',
];

Future<List<Map<String, dynamic>>> fetchProducts() async {
  try {
    // Fetching products collection from Firestore
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('products').get();

    // Mapping the documents to a List of Maps
    return snapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'category': doc['category'],
        'price': doc['price'],
        'image': doc['image'], // image URL from Firestore
        'rating': doc['rating'],
        'availability': doc['availability'],
        'discount': doc['discount'],
        'reviews': List<String>.from(doc['reviews'] ?? []),
        'barcode': doc['barcode'], // New field: barcode
        'description': doc['description'], // New field: description
        'map': doc['map'], // New field: map (location)
      };
    }).toList();
  } catch (e) {
    print('Error fetching products: $e');
    return [];
  }
}

class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String selectedCategory =
      'All Products'; // Default category is 'All Products'
  String selectedSortingOption = 'Price: Low to High';
  double minPrice = 0.0;
  double maxPrice = 1000.0; // Changed maxPrice to allow higher range
  String searchQuery = '';
  late Future<List<Map<String, dynamic>>> productsFuture;
  List<Map<String, dynamic>> allProducts = [];

  @override
  void initState() {
    super.initState();
    productsFuture =
        fetchProducts(); // Fetching products when the page is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.orange.shade800,
        actions: [
          // Sorting button removed from app bar, will go into search bar
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar with Sorting Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    _showSortingOptions();
                  },
                ),
              ],
            ),
          ),

          // Featured Products Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Featured Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Display featured products
          SizedBox(
            height: 150,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // Featured products
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error fetching data'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No products available.'));
                } else {
                  var featuredProducts =
                      snapshot.data!
                          .where(
                            (product) =>
                                product['category'] == selectedCategory ||
                                selectedCategory == 'All Products',
                          )
                          .take(5) // Showing top 5 featured products
                          .toList();

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredProducts.length,
                    itemBuilder: (context, index) {
                      var product = featuredProducts[index];
                      return GestureDetector(
                        onTap: () {
                          _navigateToProductDetails(context, product);
                        },
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  product['image'] ??
                                      'https://via.placeholder.com/150', // Placeholder if no image
                                  fit:
                                      BoxFit
                                          .contain, // Changed to BoxFit.contain
                                  width: 100,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  product['name'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Price
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Kshs ${product['price'].toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),

          // Category Navigation (Horizontal list of categories)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = categories[index];
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Chip(
                        label: Text(categories[index]),
                        backgroundColor:
                            selectedCategory == categories[index]
                                ? Colors.orange.shade800
                                : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Price Range Slider
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Range: Kshs ${minPrice.toStringAsFixed(0)} - Kshs ${maxPrice.toStringAsFixed(0)}',
                ),
                RangeSlider(
                  values: RangeValues(minPrice, maxPrice),
                  min: 0.0,
                  max: 1000.0,
                  divisions: 10,
                  labels: RangeLabels(
                    'Kshs ${minPrice.toStringAsFixed(0)}',
                    'Kshs ${maxPrice.toStringAsFixed(0)}',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      minPrice = values.start;
                      maxPrice = values.end;
                    });
                  },
                ),
              ],
            ),
          ),

          // Product Grid (Showing filtered products)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // Product grid displaying filtered products
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error fetching data'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No products available.'));
                } else {
                  // Filter products by the selected category, price range, and search query
                  List<Map<String, dynamic>> filteredProducts =
                      snapshot.data!
                          .where(
                            (product) =>
                                (selectedCategory == 'All Products' ||
                                    product['category'] == selectedCategory) &&
                                product['price'] >= minPrice &&
                                product['price'] <= maxPrice &&
                                product['name'].toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();

                  // Apply sorting based on the selected option
                  if (selectedSortingOption == 'Price: Low to High') {
                    filteredProducts.sort(
                      (a, b) => a['price'].compareTo(b['price']),
                    );
                  } else if (selectedSortingOption == 'Price: High to Low') {
                    filteredProducts.sort(
                      (a, b) => b['price'].compareTo(a['price']),
                    );
                  } else if (selectedSortingOption == 'Alphabetical') {
                    filteredProducts.sort(
                      (a, b) => a['name'].compareTo(b['name']),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      var product = filteredProducts[index];
                      return GestureDetector(
                        onTap: () {
                          _navigateToProductDetails(context, product);
                        },
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  product['image'] ??
                                      'https://via.placeholder.com/150', // Placeholder if no image
                                  fit:
                                      BoxFit
                                          .contain, // Ensures image is displayed properly
                                  width: double.infinity,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Kshs ${product['price'].toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < product['rating']
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.yellow,
                                          size: 18,
                                        );
                                      }),
                                    ),
                                    Text(
                                      product['availability'],
                                      style: TextStyle(
                                        color:
                                            product['availability'] ==
                                                    'In Stock'
                                                ? Colors.green
                                                : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Add to Cart Button
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to the Scan page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ScanPage(),
                                    ),
                                  );
                                },
                                child: Text("Scan"),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to product details page
  void _navigateToProductDetails(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(product: product),
      ),
    );
  }

  // Show Sorting options
  void _showSortingOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sort by'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Price: Low to High'),
                  onTap: () {
                    setState(() {
                      selectedSortingOption = 'Price: Low to High';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('Price: High to Low'),
                  onTap: () {
                    setState(() {
                      selectedSortingOption = 'Price: High to Low';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('Alphabetical'),
                  onTap: () {
                    setState(() {
                      selectedSortingOption = 'Alphabetical';
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Function to format price into Kshs format
    String formatPrice(int price) {
      return 'Kshs ${price.toString().replaceAll(RegExp(r'(?<=\d)(?=(\d{3})+(\.))'), ',')}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name']),
        backgroundColor: Colors.orange.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // To handle content overflow if it's too long
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Carousel
              Container(
                height: 250,
                child: PageView(
                  children: [
                    Image.network(
                      product['image'],
                      fit: BoxFit.cover,
                    ), // Use image URL
                    // Add more images if available
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Product Name
              Text(
                product['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Product Price
              Text(
                formatPrice(product['price']),
                style: const TextStyle(color: Colors.green, fontSize: 20),
              ),
              const SizedBox(height: 16),
              // Product Rating (Stars)
              Row(
                children: [
                  RatingBar.builder(
                    initialRating: product['rating'].toDouble(),
                    minRating: 1,
                    itemSize: 20,
                    itemBuilder:
                        (context, index) =>
                            Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {},
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${product['rating']})', // Display the rating number
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Product Description
              Text(
                product['description'] ?? 'No description available.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // Product Location (Map/Location in store)
              Text(
                'Find Me: ${product['map']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Add to Cart Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to the Scan page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScanPage()),
                  );
                },
                child: const Text(
                  'Scan Me!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 30,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Reviews Section
              Text(
                'Reviews:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Display reviews in a ListView or Column
              ...product['reviews'].map<Widget>((review) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
