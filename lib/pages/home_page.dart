import 'package:flutter/material.dart';

// Import your pages
import 'chats_page.dart';
import 'user_page.dart';
import 'goals_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 1;

  // Your page widgets
  final List<Widget> _pages = [
    GoalsPage(), // Your GoalsPage widget
    ChatsPage(), // Your ChatsPage widget
    UserPage(), // Your UserPage widget
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentPage],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      child: Icon(Icons.chat_bubble_sharp, color: Colors.white),
      onPressed: () {
        setState(() {
          _currentPage = 1; // Set to the index of ChatsPage
        });
      },
      backgroundColor: _currentPage == 1
          ? Color.fromARGB(255, 35, 149, 243) // Chat page color
          : Color.fromARGB(255, 158, 158, 158), // Other pages color
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 65, // Adjust this value to change the height of the BottomAppBar
      child: BottomAppBar(
        color: Color.fromARGB(204, 255, 240, 225), // Ivory white color
        shape: CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildTabItem(
              icon: Icons.flag_circle_sharp,
              index: 0,
            ),
            SizedBox(width: 40), // Placeholder to balance the row
            _buildTabItem(
              icon: Icons.supervised_user_circle_sharp,
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required int index,
  }) {
    return IconButton(
      iconSize: 40.0,
      icon: Icon(icon),
      color: _currentPage == index
          ? Colors.blue // Selected item color
          : Color.fromARGB(255, 158, 158, 158), // Unselected item color
      onPressed: () {
        setState(() {
          _currentPage = index;
        });
      },
    );
  }
}
