import 'dart:ui';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Import DashboardScreen
import 'attendance_screen.dart'; // Import AttendanceScreen
import 'customers_screen.dart'; // Import CustomersScreen
import 'payments_screen.dart'; // Import PaymentsScreen

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  PlansScreenState createState() => PlansScreenState();
}

class PlansScreenState extends State<PlansScreen> {
  // Placeholder data for the table (will be replaced with backend data later)
  final List<Map<String, String>> plans = const [
    {
      'sino': '1',
      'planName': 'Weight training',
      'description': 'Weight training',
      'amount': '1000',
      'duration': '30 days',
    },
    {
      'sino': '2',
      'planName': 'Cardio',
      'description': 'Cardio',
      'amount': '1000',
      'duration': '30 days',
    },
    {
      'sino': '3',
      'planName': 'Weight training + cardio',
      'description': 'Weight training + cardio',
      'amount': '1500',
      'duration': '30 days',
    },
    {
      'sino': '4',
      'planName': 'Personal weight training',
      'description': 'Personal weight training',
      'amount': '4000',
      'duration': '30 days',
    },
    {
      'sino': '5',
      'planName': 'Personal training complete package',
      'description': 'Personal training complete package',
      'amount': '6000',
      'duration': '30 days',
    },
    {
      'sino': '6',
      'planName': 'Guest membership',
      'description': 'Guest membership',
      'amount': '250',
      'duration': '2 days',
    },
  ];

  // Track hover state for each row
  List<bool> isHovered = [];

  @override
  void initState() {
    super.initState();
    // Initialize hover state for each row
    isHovered = List.generate(plans.length, (index) => false);
  }

  void _showAddPlanDialog(BuildContext context) {
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
                      'Add New Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Plan Name
                    _buildTextFieldBox('Plan Name'),
                    SizedBox(height: 10),
                    // Description
                    _buildTextFieldBox('Description'),
                    SizedBox(height: 10),
                    // Amount and Duration
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFieldBox('Amount'),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildTextFieldBox('Duration'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Save and Cancel Buttons (centered at the bottom with SizedBox of width 20)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Ensure the Row takes minimum space
                        children: [
                          // Save Button
                          ElevatedButton(
                            onPressed: () {
                              // Handle the Save action
                              print('Save tapped');
                              Navigator.pop(context); // Close the dialog
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFaedd40), // Green color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), // Curved edges
                              ),
                            ),
                            child: Text(
                              'Save',
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

  void _showEditPlanDialog(BuildContext context, Map<String, String> plan) {
    TextEditingController planNameController = TextEditingController(text: plan['planName']);
    TextEditingController descriptionController = TextEditingController(text: plan['description']);
    TextEditingController amountController = TextEditingController(text: plan['amount']);
    TextEditingController durationController = TextEditingController(text: plan['duration']);

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
                      'Edit Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Plan Name
                    _buildTextFieldBox('Plan Name', controller: planNameController),
                    SizedBox(height: 10),
                    // Description
                    _buildTextFieldBox('Description', controller: descriptionController),
                    SizedBox(height: 10),
                    // Amount and Duration
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFieldBox('Amount', controller: amountController),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildTextFieldBox('Duration', controller: durationController),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Save and Cancel Buttons (centered at the bottom with SizedBox of width 20)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Ensure the Row takes minimum space
                        children: [
                          // Save Button
                          ElevatedButton(
                            onPressed: () {
                              // Handle the Save action
                              setState(() {
                                plan['planName'] = planNameController.text;
                                plan['description'] = descriptionController.text;
                                plan['amount'] = amountController.text;
                                plan['duration'] = durationController.text;
                              });
                              Navigator.pop(context); // Close the dialog
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFaedd40), // Green color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), // Curved edges
                              ),
                            ),
                            child: Text(
                              'Save',
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

  // Helper method to build text fields with grey square boxes
  Widget _buildTextFieldBox(String label, {TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800], // Grey background
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white, fontSize: 10),
            border: InputBorder.none, // Remove default border
          ),
          style: TextStyle(color: Colors.white, fontSize: 10),
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
                // Customers Button
                _buildAppBarButton(context, 'Customers', '/customers'),
                SizedBox(width: 10), // Spacing between buttons
                // Plans Button (Permanently Green)
                _buildAppBarButton(context, 'Plans', '/plans', isActive: true),
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
          // Add New Plan Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align button to the right
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showAddPlanDialog(context); // Show the dialog
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
                    'Add New Plan',
                    style: TextStyle(
                      color: Color(0xFF101004),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table for Plans
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('SINo', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Plan Name', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Description', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Duration', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                  ],
                  rows: plans.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> plan = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text(plan['sino']!, style: TextStyle(color: Colors.white))),
                        DataCell(Text(plan['planName']!, style: TextStyle(color: Colors.white))),
                        DataCell(Text(plan['description']!, style: TextStyle(color: Colors.white))),
                        DataCell(Text(plan['amount']!, style: TextStyle(color: Colors.white))),
                        DataCell(Text(plan['duration']!, style: TextStyle(color: Colors.white))),
                        DataCell(
                          MouseRegion(
                            onEnter: (_) => setState(() => isHovered[index] = true),
                            onExit: (_) => setState(() => isHovered[index] = false),
                            child: Visibility(
                              visible: isHovered[index],
                              child: IconButton(
                                icon: Icon(Icons.edit, color: Colors.white),
                                onPressed: () {
                                  _showEditPlanDialog(context, plan);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
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