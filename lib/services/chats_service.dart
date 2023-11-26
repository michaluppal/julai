import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  final String endpointUrl; //  backend endpoint URL

  ChatService(this.endpointUrl);

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(endpointUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['reply'];
    } else {
      throw Exception('Failed to connect to the backend');
    }
  }
}
