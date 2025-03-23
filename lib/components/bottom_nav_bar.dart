import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int cartItemCount;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.cartItemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow, // Yellow background for the container
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),  // Curved top-left corner
          topRight: Radius.circular(30), // Curved top-right corner
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200, // Orange shadow for the nav bar
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -3), // Shadow position (downward)
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent, // Transparent background for the BottomNavigationBar
        selectedItemColor: Colors.black, // Color for selected item
        unselectedItemColor: Colors.black.withOpacity(0.6), // Color for unselected items
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        cartItemCount.toString(),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
