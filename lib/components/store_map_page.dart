import 'package:flutter/material.dart';

class StoreMapPage extends StatelessWidget {
  const StoreMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade800, // Accent color for map page
        title: const Text('Store Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality if required
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Floor Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Placeholder for Store Map (can replace with an interactive map)
            Stack(
              children: [
                // Static image as the store floor plan map
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/map.jpg'), // Replace with your store map image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Markers or other visual elements to show locations
                Positioned(
                  top: 50,
                  left: 80,
                  child: _buildMarker('Aisle 1', Colors.red),
                ),
                Positioned(
                  top: 150,
                  left: 150,
                  child: _buildMarker('Aisle 2', Colors.blue),
                ),
                Positioned(
                  top: 200,
                  left: 250,
                  child: _buildMarker('Aisle 3', Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to show product location (you can make this dynamic)
                _showProductLocation(context);
              },
              child: const Text('Show Product Location',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800, // Accent color
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show a simple marker
  Widget _buildMarker(String text, Color color) {
    return Column(
      children: [
        Icon(
          Icons.location_on,
          color: color,
          size: 30,
        ),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  void _showProductLocation(BuildContext context) {
    // This is a mock of showing a specific product's location on the map
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Location'),
        content: const Text('Your product is located in Aisle 2, Shelf 3.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
