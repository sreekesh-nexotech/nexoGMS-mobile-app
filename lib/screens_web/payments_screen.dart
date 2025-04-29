import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Import DashboardScreen
import 'attendance_screen.dart'; // Import AttendanceScreen
import 'customers_screen.dart'; // Import CustomersScreen
import 'plans_screen.dart'; // Import PlansScreen

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101004), // Set background color
      appBar: AppBar(
        title: Center(
          child: Container(
            padding: EdgeInsets.all(8), // Padding inside the box
            decoration: BoxDecoration(
              color: Color(0xFF101004), // Background color of the box (dark grey)
              borderRadius: BorderRadius.circular(20), // Curved edges
              border: Border.all(
                color: Colors.white, // White border color
                width: 2, // Border width
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Fit the content
              children: [
                // Dashboard Button
                _buildAppBarButton(context, 'Dashboard', '/dashboard'),
                SizedBox(width: 10), // Spacing between buttons
                // Attendance Button
                _buildAppBarButton(context, 'Attendance', '/attendance'),
                SizedBox(width: 10), // Spacing between buttons
                // Customers Button
                _buildAppBarButton(context, 'Customers', '/customers'),
                SizedBox(width: 10), // Spacing between buttons
                // Plans Button
                _buildAppBarButton(context, 'Plans', '/plans'),
                SizedBox(width: 10), // Spacing between buttons
                // Payments Button (Permanently Green)
                _buildAppBarButton(context, 'Payments', '/payments', isActive: true),
              ],
            ),
          ),
        ),
        backgroundColor: Color(0xFF101004), // Set AppBar background to black
        elevation: 0, // Remove shadow
        iconTheme: IconThemeData(color: Colors.white), // Set icons (e.g., back button) to white
        titleTextStyle: TextStyle(
          color: Colors.white, // Set AppBar text color to white
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu), // Menu icon to open the sidebar
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open the drawer
            },
          ),
        ),
      ),
      drawer: _buildSidebar(context), // Custom sidebar
      body: Center(
        child: Text(
          'Welcome to the Payments Page!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Main content text color
          ),
        ),
      ),
    );
  }
  // Helper method to build the sidebar
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF101004), // Sidebar background color
      child: Column(
        children: [
          // Close Button at the Top
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white), // Close icon
              onPressed: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
          ),
          // Profile Picture at the Top
          Container(
            margin: EdgeInsets.only(top: 32, bottom: 16), // Add margin for spacing
            child: CircleAvatar(
              radius: 50, // Size of the profile picture
              backgroundImage: AssetImage('assets/images/bird.png'), // Add your profile picture asset
              backgroundColor: Colors.grey[800], // Fallback color if no image is provided
              child: Icon(
                Icons.person, // Fallback icon if no image is provided
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          // Centered Buttons
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                children: [
                  _buildMenuItem(context, 'Exercises'),
                  _buildMenuItem(context, 'Exercise Groups'),
                  _buildMenuItem(context, 'Exercise Schedules'),
                  _buildMenuItem(context, 'Gym Reports'),
                  _buildMenuItem(context, 'Settings'),
                ],
              ),
            ),
          ),
          // Logout Button at the Bottom
          Container(
            margin: EdgeInsets.symmetric(horizontal: 100, vertical: 50), // Add margin around the Logout button
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Curved edges
              border: Border(
                top: BorderSide(
                  color: Colors.white, // White top border
                  width: 1, // Border width
                ),
              ),
            ),
            child: _buildMenuItem(context, 'Logout'),
          ),
        ],
      ),
    );
  }

  // Helper method to build menu items
  Widget _buildMenuItem(BuildContext context, String title) {
    return Container(
      width: double.infinity, // Make the button take full width
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white, // White bottom border
            width: 1, // Border width
          ),
        ),
      ),
      child: ListTile(
        tileColor: Color(0xFF101004), // Background color of the ListTile
        title: Center(
          child: Text(
            title,
            style: TextStyle(color: Colors.white), // Menu item text color
          ),
        ),
        onTap: () {
          // Handle menu item tap
          print('$title tapped');
          Navigator.pop(context); // Close the drawer after tapping
        },
      ),
    );
  }
  // Helper method to build AppBar buttons
  Widget _buildAppBarButton(BuildContext context, String title, String route, {bool isActive = false}) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to the specified route
        if (title == 'Dashboard') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        } else if (title == 'Attendance') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AttendanceScreen()),
          );
        } else if (title == 'Customers') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CustomersScreen()),
          );
        } else if (title == 'Plans') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlansScreen()),
          );
        } else if (title == 'Payments') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PaymentsScreen()),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Color(0xFFaedd40) : Color(0xFF101004), // Green if active, otherwise black
        elevation: 0, // Remove shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Curved edges
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding inside the button
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Text color
        ),
      ),
    );
  }
}