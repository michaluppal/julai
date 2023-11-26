import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:julia/providers/authentication_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:julia/models/chat_messages.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:julia/widgets/top_bar.dart';
import 'package:julia/widgets/typing_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

/// This class represents the chat page in the application.
class ChatsPage extends StatefulWidget {
  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late AuthenticationProvider _auth;
  final TextEditingController _chatController = TextEditingController();
  bool _isAwaitingResponse = false;
  List<Map<String, String>> _conversationHistory = []; // Changed the type here

  @override
  void initState() {
    super.initState();
    _auth = Provider.of<AuthenticationProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen height and width for responsive UI design.
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double _appBarHeight = AppBar().preferredSize.height * 0.8;
    double _sendMessageAreaHeight = screenHeight * 0.1;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_appBarHeight),
        child: TopBar(
          'Chat',
          primaryAction: IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _auth.logout();
            },
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
            //SizedBox(height: screenHeight * 0.001),
            _sendMessageArea(screenWidth, _sendMessageAreaHeight),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
      backgroundColor: Color(0xFFFFF0F5),
    );
  }

  /// Refreshes the chat.
  Future<void> _refreshChat() async {
    setState(() {});
  }

  /// Builds the list view of chat messages.
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

        List<Message> messages = snapshot.data!.docs
            .map((doc) =>
                Message.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList();

        if (_isAwaitingResponse) {
          messages.insert(
              0,
              Message(
                text: '',
                isUserMessage: false,
                timestamp: DateTime.now(),
              ));
        }

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index];
            bool isTypingIndicator = index == 0 && _isAwaitingResponse;
            return isTypingIndicator
                ? _buildTypingIndicator()
                : _buildMessageBubble(message);
          },
        );
      },
    );
  }

  /// Returns a placeholder widget when chat is empty.
  Widget _emptyChatPlaceholder() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'No messages yet. What did you have to eat today?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.0,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  /// Builds individual message bubble.
  Widget _buildMessageBubble(Message message) {
    bool isUserMessage = message.isUserMessage;
    String messageTime = DateFormat('h:mm a').format(message.timestamp);

    TextStyle messageTextStyle = TextStyle(
      color: isUserMessage ? Colors.white : Colors.black87,
      fontSize: 16.0,
    );

    TextStyle messageTimeStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 10.0,
    );

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: isUserMessage ? Colors.blue[300] : Colors.grey[300],
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
            Text(messageTime, style: messageTimeStyle),
          ],
        ),
      ),
    );
  }

  /// Builds the typing indicator.
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TypingIndicator(),
    );
  }

  /// Builds the area where the user types and sends messages.
  Widget _sendMessageArea(double screenWidth, double areaHeight) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      color: Color(0xFFFFF0F5),
      height: areaHeight,
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
                fillColor: Colors.grey[200],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 3.0),
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
            onPressed: () {
              _handleSendMessage();
            },
          ),
        ],
      ),
    );
  }

  /// Handles sending a message.
  Future<void> _handleSendMessage() async {
    if (_chatController.text.isNotEmpty) {
      final messageText = _chatController.text;
      _chatController.clear();

      // Add the user's message to the conversation history with updated structure
      // When the user sends a message
      _conversationHistory.add({'role': 'user', 'content': messageText});

      // Save user's message to Firestore
      await saveMessageToFirestore(_auth.user.uid, messageText, true);

      // Send the entire conversation history to the server
      String response = await sendMessageToServer(_conversationHistory);

      if (response.isNotEmpty) {
        // Add the assistant's response to the conversation history with updated structure
        _conversationHistory.add({'role': 'assistant', 'content': response});
        // Save assistant's response to Firestore
        await saveMessageToFirestore(_auth.user.uid, response, false);
      }

      setState(() {
        _isAwaitingResponse = false;
      });
    }
  }

  /// Sends a message to the server and awaits a response.
  Future<String> sendMessageToServer(
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
        final responseBody = jsonDecode(response.body);
        return responseBody['reply'];
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return '';
      }
    } catch (e) {
      print('Error sending message to server: $e');
      return '';
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
        'isUserMessage': isUserMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving message to Firestore: $e');
    }
  }
}
