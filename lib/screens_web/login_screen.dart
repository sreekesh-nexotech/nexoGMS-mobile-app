import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Add the key parameter
  LoginScreen({super.key});

  void _login(BuildContext context) {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // Replace with your actual login validation logic
    if (username == 'admin' && password == 'nexotech') {
       Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()), // Navigate to DashboardScreen
    );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101004), // Set background color using hex code
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Part 1: Nexotech, Admin Panel, Gym Management System           
            
            Expanded(
              flex: 1, // Takes 1/3 of the screen width
              child: Column(
                 
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                children: [
                  Text(
                    'Nexotech',
                    style: TextStyle(
                      fontSize: 50, // Font size 36px
                      fontWeight: FontWeight.bold, // Bold font weight
                      color: Colors.white, // Text color
                    ),
                  ),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 25  , // Font size 36px
                      fontWeight: FontWeight.bold, // Bold font weight
                      color: Colors.white, // Text color
                    ),
                  ),
                  SizedBox(height: 10), // Margin bottom 10px
                  Text(
                    'Gym Management System',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Adjust text color for visibility
                    ),
                  ),
                ],
              ),
            ),
            // Part 2: Empty space (1/3 of the screen)
            Expanded(
              flex: 1, // Takes 1/3 of the screen width
              child: Container(), // Empty container
            ),

            // Part 3: Username, Password, Login Button (center of the 3rd part)
            Expanded(
              flex: 1, 
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20), // Add padding inside the box
                  decoration: BoxDecoration(
                    
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey, // Border color
                      width: 1, // Border width
                    ), // Curved corners
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Fit the content
                     
                children: [
                      Container(
                        padding: const EdgeInsets.all(50),
                      child: Image.asset(
                        'assets/images/bird.png', // Path to your logo image
                        width: 50, // Set logo width
                        height: 50, // Set logo height
                      ),
                      ),
                  SizedBox(
                    width: 200,
                   
                    child:
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 60),
                      
                      
                      )
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                        width: 200,
                        
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                
                            contentPadding: EdgeInsets.symmetric(horizontal: 60),
                          ),
                        ),
                      ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => _login(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(100, 40),
                      backgroundColor: Colors.blue, // Customize button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            )
            )
          ],
        ),
      ),
    );
  }
}