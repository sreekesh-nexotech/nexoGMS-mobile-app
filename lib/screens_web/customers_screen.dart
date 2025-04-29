import 'dart:ui';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Import DashboardScreen
import 'attendance_screen.dart'; // Import AttendanceScreen
import 'plans_screen.dart'; // Import PlansScreen
import 'payments_screen.dart'; // Import PaymentsScreen

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  // Placeholder data for the table (will be replaced with backend data later)
  final List<Map<String, String>> customers = const [
    {
      'sino': '1',
      'name': 'Hari',
      'paymentDue': '12-03-2025',
      'schedule': 'name 1',
      'plan': 'Gold annual',
    },
    {
      'sino': '2',
      'name': 'Vishnu',
      'paymentDue': '12-03-2025',
      'schedule': 'name 2',
      'plan': 'Cardio monthly',
    },
    {
      'sino': '3',
      'name': 'Jade',
      'paymentDue': '12-03-2025',
      'schedule': 'name 1',
      'plan': 'WT monthly',
    },
    {
      'sino': '4',
      'name': 'Anil',
      'paymentDue': '12-03-2025',
      'schedule': 'name 2',
      'plan': 'WT monthly',
    },
    {
      'sino': '5',
      'name': 'Neeraja',
      'paymentDue': '12-03-2025',
      'schedule': 'name 5',
      'plan': 'Cardio annual',
    },
    {
      'sino': '6',
      'name': 'Manu',
      'paymentDue': '12-03-2025',
      'schedule': 'name 3',
      'plan': 'Transformation',
    },
  ];

void _showAddCustomerDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur effect
        child: Dialog(
          backgroundColor: Color(0xFF101004), // Dark background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Curved edges
            side: BorderSide(color: Colors.white, width: 2), // White border
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5, // Set width to 50% of screen width
            padding: EdgeInsets.symmetric(horizontal: 100, vertical: 20), // Inner padding
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Customer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Customer Name
                  _buildTextFieldBox('Customer Name'),
                  SizedBox(height: 10),
                  // Email
                  _buildTextFieldBox('Email'),
                  SizedBox(height: 10),
                  // Password and Mobile Number
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFieldBox('Password'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildTextFieldBox('Mob No'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Height and Emergency Contact
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFieldBox('Height'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildTextFieldBox('Emergency Contact'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Weight and Emergency Contact No
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFieldBox('Weight'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildTextFieldBox('Emergency Contact No'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Next and Cancel Buttons (centered at the bottom with SizedBox of width 20)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Ensure the Row takes minimum space
                      children: [
                        // Next Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the first dialog
                            _showMembershipPlanDialog(context); // Open the second dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFaedd40), // Green color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Curved edges
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(width: 20), // Space between buttons
                        // Cancel Button
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
void _showMembershipPlanDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur effect
        child: Dialog(
          backgroundColor: Color(0xFF101004), // Dark background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Curved edges
            side: BorderSide(color: Colors.white, width: 2), // White border
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5, // Set width to 50% of screen width
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20), // Inner padding
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Customer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Membership Plan (Dropdown) - First Line
                  _buildDropdownBox('Membership Plan'),
                  SizedBox(height: 10),
                  // Workout Schedule (Dropdown) - Second Line
                  _buildDropdownBox('Workout Schedule (Optional)'),
                  SizedBox(height: 10),
                  // DOJ and Amount Paid - Third Line
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFieldBox('DOJ'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildTextFieldBox('Amount Paid'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Passcode and Authentication Type - Fourth Line
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFieldBox('Passcode'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildTextFieldBox('Authentication Type'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Next and Cancel Buttons (centered at the bottom with SizedBox of width 20)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Ensure the Row takes minimum space
                      children: [
                        // Next Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the second dialog
                            _showNewViewDialog(context); // Open the third dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFaedd40), // Green color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Curved edges
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(width: 20), // Space between buttons
                        // Cancel Button
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _showNewViewDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur effect
        child: Dialog(
          backgroundColor: Color(0xFF101004), // Dark background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Curved edges
            side: BorderSide(color: Colors.white, width: 2), // White border
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5, // Set width to 50% of screen width
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Inner padding
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Customer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Placeholder for Webcam/Camera Image
                  Container(
                    width: double.infinity,
                    height: 200, // Set a fixed height for the image placeholder
                    decoration: BoxDecoration(
                      color: Colors.grey[800], // Grey background
                      borderRadius: BorderRadius.circular(10), // Curved edges
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera_alt, // Camera icon as a placeholder
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Capture Image Now Button
                  ElevatedButton(
                    onPressed: () {
                      // Handle the Capture Image action
                      print('Capture Image Now tapped');
                      // Add logic to access the webcam/camera here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFaedd40), // Green color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Curved edges
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Capture Image Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Save and Cancel Buttons (placed next to each other)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Save Button
                      ElevatedButton(
                        onPressed: () {
                          // Handle the Save action
                          print('Save tapped');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFaedd40), // Green color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Curved edges
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Cancel Button
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
// Helper method to build dropdown boxes
Widget _buildDropdownBox(String label) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[800], // Grey background
      
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white, fontSize: 14),
          border: InputBorder.none, // Remove default border
        ),
        items: <String>['Option 1', 'Option 2', 'Option 3'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          // Handle dropdown value change
          print('Selected: $newValue');
        },
      ),
    ),
  );
}
// Helper method to build text fields with grey square boxes
Widget _buildTextFieldBox(String label) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[800], // Grey background
      
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white, fontSize: 10,),
          border: InputBorder.none,// Remove default border
        ),
        style: TextStyle(color: Colors.white,
        fontSize: 10,),
      ),
    ),
  );
}
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
                // Customers Button (Permanently Green)
                _buildAppBarButton(context, 'Customers', '/customers', isActive: true),
                SizedBox(width: 10), // Spacing between buttons
                // Plans Button
                _buildAppBarButton(context, 'Plans', '/plans'),
                SizedBox(width: 10), // Spacing between buttons
                // Payments Button
                _buildAppBarButton(context, 'Payments', '/payments'),
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
      body: Column(
        children: [
          // Add New Customer Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align button to the right
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showAddCustomerDialog(context); // Show the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Green color for the button
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Square padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Curved edges
                    ),
                    minimumSize: Size(70, 40), // Square size
                  ),
                  child: Text(
                    'Add New Customer',
                    style: TextStyle(
                      color:  Color(0xFF101004),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table for Customers
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('SINo', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Customer Name', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Payment Due', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Schedule', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Plan', style: TextStyle(color: Colors.white))),
                  ],
                  rows: customers.map((customer) {
                    return DataRow(cells: [
                      DataCell(Text(customer['sino']!, style: TextStyle(color: Colors.white))),
                      DataCell(Text(customer['name']!, style: TextStyle(color: Colors.white))),
                      DataCell(Text(customer['paymentDue']!, style: TextStyle(color: Colors.white))),
                      DataCell(Text(customer['schedule']!, style: TextStyle(color: Colors.white))),
                      DataCell(Text(customer['plan']!, style: TextStyle(color: Colors.white))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
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