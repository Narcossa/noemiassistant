import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? '257305674390-ustnsknbla480b54g5qae9ras7afs700.apps.googleusercontent.com' 
        : '257305674390-9tibj31i222053hamcbs19nk09va3mg5.apps.googleusercontent.com',
    scopes: [
      calendar.CalendarApi.calendarScope,
      calendar.CalendarApi.calendarEventsScope,
      gmail.GmailApi.gmailReadonlyScope,
      gmail.GmailApi.gmailSendScope,
      tasks.TasksApi.tasksScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleAuthClient? _httpClient;

  Future<void> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        final headers = await _currentUser!.authHeaders;
        _httpClient = GoogleAuthClient(headers);
        print("Connecté avec succès : ${_currentUser!.email}");
      }
    } catch (error) {
      print("Erreur de connexion Google: $error");
      throw error;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    _httpClient = null;
  }

  GoogleSignInAccount? get currentUser => _currentUser;
  
  calendar.CalendarApi? get calendarApi {
    if (_httpClient != null) {
      return calendar.CalendarApi(_httpClient!);
    }
    return null;
  }
  
  gmail.GmailApi? get gmailApi {
    if (_httpClient != null) {
      return gmail.GmailApi(_httpClient!);
    }
    return null;
  }

  tasks.TasksApi? get tasksApi {
    if (_httpClient != null) {
      return tasks.TasksApi(_httpClient!);
    }
    return null;
  }
}
