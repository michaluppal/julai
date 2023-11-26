//packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

class GoalsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GoalsPageState();
  }
}

class _GoalsPageState extends State<GoalsPage> {
  @override
  Widget build(BuildContext context) {
    return _buildUI();
  }

  Widget _buildUI() {
    return Scaffold(
      backgroundColor: Colors.lightGreen,
    );
  }
}
