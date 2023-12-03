import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:julia/providers/authentication_provider.dart'; // Replace with the correct import path
import 'package:julia/widgets/top_bar.dart'; // Import TopBar

// Define custom colors
const Color customIvoryColor = Color(0xFFFFFFF0); // Ivory color hex code
const Color customBlueColor =
    Color.fromARGB(255, 64, 129, 182); // Custom blue color

class GoalsPage extends StatefulWidget {
  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  String userId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthenticationProvider>(context);
    if (authProvider.user != null) {
      userId = authProvider.user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.of(context).size.height * 0.1),
        child: TopBar(
          'Daily Goals',
          primaryAction: IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Handle settings action
            },
          ),
          // Add secondaryAction if needed
        ),
      ),
      body: userId.isEmpty
          ? Center(child: Text("You're not logged in"))
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('meal_info')
                  .doc(userId)
                  .collection('meals')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No meals found.'));
                }

                Map<DateTime, List<QueryDocumentSnapshot>> groupedMeals = {};
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data.containsKey('timestamp') &&
                      data.containsKey('calories') &&
                      data.containsKey('meal_title') &&
                      data.containsKey('meal_type')) {
                    DateTime date = (data['timestamp'] as Timestamp).toDate();
                    DateTime dateOnly =
                        DateTime(date.year, date.month, date.day);
                    groupedMeals.putIfAbsent(dateOnly, () => []).add(doc);
                  }
                }

                var sortedKeys = groupedMeals.keys.toList()
                  ..sort((a, b) => a.compareTo(b));

                return ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    DateTime date = sortedKeys[index];
                    List<QueryDocumentSnapshot> dailyMeals =
                        groupedMeals[date]!;
                    int totalCalories = dailyMeals.fold(0, (sum, doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return sum + (data['calories'] as int);
                    });

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      elevation: 2.0,
                      child: ExpansionTile(
                        leading:
                            Icon(Icons.restaurant_menu, color: customBlueColor),
                        title: Text(
                          DateFormat('EEEE, MMMM d').format(date),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Total Calories: $totalCalories',
                          style:
                              TextStyle(color: Colors.black.withOpacity(0.6)),
                        ),
                        children: dailyMeals.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['meal_title']),
                            subtitle: Text(data['meal_type']),
                            trailing: Text('${data['calories']} cal'),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
      backgroundColor: customIvoryColor, // Use the custom ivory color
    );
  }
}
