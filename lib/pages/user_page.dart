import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:julia/providers/authentication_provider.dart';
import 'package:julia/widgets/top_bar.dart'; // Make sure this import is correct for your project

class UserPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // The AuthenticationProvider will be initialized in the build method.

  @override
  Widget build(BuildContext context) {
    // Initialize AuthenticationProvider here
    AuthenticationProvider _auth =
        Provider.of<AuthenticationProvider>(context, listen: false);

    return Scaffold(
      // Use the TopBar custom widget
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.0), // Default AppBar height
        child: TopBar(
          'User',
          primaryAction: IconButton(
            icon: Icon(
              Icons.notifications_none,
            ), // Bell icon
            onPressed: () {
              // Handle notifications action
            },
          ),
          // Include additional actions if needed
        ),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.account_circle, color: Colors.blue[300]),
            title: Text('Account'),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
            onTap: () {
              // Handle account tap
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.blue[300]),
            title: Text('FAQ'),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
            onTap: () {
              // Handle FAQ tap
            },
          ),
          ListTile(
            leading: Icon(Icons.contact_mail, color: Colors.blue[300]),
            title: Text('Contact Our Team'),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
            onTap: () {
              // Handle contact tap
            },
          ),
          ListTile(
            leading: Icon(Icons.add_to_home_screen, color: Colors.blue[300]),
            title: Text('How to Add Widget?'),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
            onTap: () {
              // Handle widget information tap
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.description, color: Colors.blue[300]),
            title: Text('Terms of Service'),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
            onTap: () {
              // Handle terms of service tap
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: Colors.blue[300]),
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
            onTap: () {
              // Handle privacy policy tap
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.blue[300]),
            title: Text('Logout'),
            onTap: () {
              _auth.logout();
              Navigator.of(context).pushReplacementNamed(
                  '/login'); // Replace with your login route
            },
          ),
        ],
      ),
      backgroundColor:
          Color(0xFFFFFFF0), // Set the background color to match the design
    );
  }
}
