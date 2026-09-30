import 'package:googleapis/gmail/v1.dart' as gmail;
import 'dart:convert';

class GoogleMailService {
  final gmail.GmailApi _gmailApi;

  GoogleMailService(this._gmailApi);

  Future<List<String>> getUnreadEmails() async {
    try {
      final response = await _gmailApi.users.messages.list(
        'me',
        q: 'is:unread category:primary',
        maxResults: 5,
      );

      if (response.messages == null || response.messages!.isEmpty) {
        return [];
      }

      List<String> unreadSummaries = [];
      for (var msg in response.messages!) {
        final fullMsg = await _gmailApi.users.messages.get('me', msg.id!);
        final headers = fullMsg.payload?.headers;
        
        String subject = "Sans objet";
        String from = "Inconnu";
        
        if (headers != null) {
          for (var header in headers) {
            if (header.name == 'Subject') subject = header.value ?? subject;
            if (header.name == 'From') {
              from = header.value?.split('<').first.trim() ?? from;
            }
          }
        }
        unreadSummaries.add("De \$from : \$subject");
      }
      return unreadSummaries;
    } catch (e) {
      print("Erreur Gmail : \$e");
      return [];
    }
  }

  Future<bool> sendEmail(String to, String subject, String body) async {
    try {
      final emailContent = 
          "To: \$to\r\n"
          "Subject: \$subject\r\n"
          "Content-Type: text/plain; charset=utf-8\r\n\r\n"
          "\$body";
      
      final base64Email = base64UrlEncode(utf8.encode(emailContent));
      final message = gmail.Message()..raw = base64Email;
      
      await _gmailApi.users.messages.send(message, 'me');
      return true;
    } catch (e) {
      print("Erreur Envoi Email : \$e");
      return false;
    }
  }
}
