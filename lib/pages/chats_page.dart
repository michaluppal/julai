import 'dart:convert'; // Import for jsonEncode
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:julia/providers/authentication_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:julia/models/chat_messages.dart';
import 'package:http/http.dart' as http;
import 'package:julia/widgets/top_bar.dart';
import 'package:intl/intl.dart';

class ChatsPage extends StatefulWidget {
  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late AuthenticationProvider _auth;
  final TextEditingController _chatController = TextEditingController();
  bool _isAwaitingResponse = false;
  List<Map<String, String>> _conversationHistory = [];
  Map<String, dynamic> meal_information = {};

  @override
  void initState() {
    super.initState();
    _auth = Provider.of<AuthenticationProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(AppBar().preferredSize.height),
        child: TopBar(
          'Chat',
          primaryAction: IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          fontSize: 35,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChat,
        child: Column(
          children: <Widget>[
            Expanded(
              child: _chatListView(),
            ),
            _sendMessageArea(),
          ],
        ),
      ),
      backgroundColor: Color(0xFFFFFFF0),
    );
  }

  Future<void> _refreshChat() async {
    setState(() {});
  }

  Widget _chatListView() {
    final String userId = _auth.user.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(userId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyChatPlaceholder();
        }

        List<DocumentSnapshot> docs = snapshot.data!.docs;
        List<Widget> messageWidgets = [];
        DateTime? previousMessageDate;

        for (int i = 0; i < docs.length; i++) {
          Message message =
              Message.fromFirestore(docs[i].data() as Map<String, dynamic>);
          DateTime messageDate = message.timestamp;
          if (previousMessageDate == null ||
              messageDate.day != previousMessageDate.day) {
            if (i != 0) {
              messageWidgets.add(_buildDateDivider(messageDate));
            }
            previousMessageDate = messageDate;
          }
          messageWidgets.add(_buildMessageBubble(message));
        }

        return ListView(
          reverse: true,
          children: messageWidgets,
        );
      },
    );
  }

  Widget _emptyChatPlaceholder() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'No messages yet. What did you have to eat today?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.0,
            color: Color.fromARGB(255, 47, 47, 47),
          ),
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            DateFormat('MMMM d').format(date),
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    bool isUserMessage = message.isUserMessage;
    String messageTime = DateFormat('h:mm a').format(message.timestamp);

    TextStyle messageTextStyle = TextStyle(
      color: isUserMessage ? Colors.white : Colors.black87,
      fontSize: 16.0,
    );

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: isUserMessage
              ? Colors.blue[300]
              : Color.fromARGB(193, 255, 255, 240),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.text, style: messageTextStyle),
            const SizedBox(height: 4.0),
            Text(messageTime,
                style: TextStyle(fontSize: 10.0, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _sendMessageArea() {
    double screenWidth = MediaQuery.of(context).size.width;
    double sendMessageAreaHeight = MediaQuery.of(context).size.height * 0.1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      color: Color(0xFFFFFFF0),
      height: sendMessageAreaHeight,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _chatController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Send a message...',
                border: InputBorder.none,
                filled: true,
                fillColor: Color(0xFFFFFFF0),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue[300]!, width: 3.0),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue[300]!, width: 3.0),
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send,
                color: Color.fromARGB(255, 64, 129, 182)),
            onPressed: _handleSendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    if (_chatController.text.isNotEmpty) {
      final messageText = _chatController.text;
      _chatController.clear();

      _conversationHistory.add({'role': 'user', 'content': messageText});
      await saveMessageToFirestore(_auth.user.uid, messageText, true);

      var response = await sendMessageToServer(_conversationHistory);
      if (response['reply'].isNotEmpty) {
        _conversationHistory
            .add({'role': 'assistant', 'content': response['reply']});

        await saveMessageToFirestore(_auth.user.uid, response['reply'], false);

        if (response.containsKey('meal_info')) {
          meal_information = response['meal_info'];
          await saveMealInfoToFirestore(_auth.user.uid, meal_information);
        }
      }

      if (mounted) {
        setState(() {
          _isAwaitingResponse = false;
        });
      }
    }
  }

  /// Sends a message to the server and awaits a response.
  Future<Map<String, dynamic>> sendMessageToServer(
      List<Map<String, String>> conversationHistory) async {
    try {
      // Updated JSON encoding to handle the new conversationHistory structure
      String jsonBody = jsonEncode(
          {'user_id': _auth.user.uid, 'conversation': conversationHistory});

      final response = await http.post(
        Uri.parse(
            'https://us-central1-julia-5999f.cloudfunctions.net/chatFunction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return the entire response
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return {'reply': ''};
      }
    } catch (e) {
      print('Error sending message to server: $e');
      return {'reply': ''};
    }
  }

  /// Saves a message to Firestore.
  Future<void> saveMessageToFirestore(
      String userId, String message, bool isUserMessage) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(userId)
          .collection('messages')
          .add({
        'text': message,
        'isUserMessage': isUserMessage, // Ensure this is correctly set
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving message to Firestore: $e');
    }
  }

  /// Saves meal info to Firestore.
  Future<void> saveMealInfoToFirestore(
      String userId, Map<String, dynamic> mealInfo) async {
    try {
      await FirebaseFirestore.instance
          .collection('meal_info')
          .doc(userId)
          .collection('meals')
          .add({
        ...mealInfo,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving meal info to Firestore: $e');
    }
  }
}
