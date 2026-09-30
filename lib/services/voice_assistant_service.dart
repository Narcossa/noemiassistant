import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'google_auth_service.dart';
import 'google_calendar_service.dart';
import 'google_mail_service.dart';
import 'google_tasks_service.dart';

class VoiceAssistantService {
  late GenerativeModel _model;
  late ChatSession _chat;
  
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool isListening = false;
  
  final GoogleAuthService _authService;
  late GoogleCalendarService _calendarService;
  late GoogleMailService _mailService;
  late GoogleTasksService _tasksService;

  // Clef masquee
  String get _apiKey => utf8.decode(base64Decode('QVEuQWI4Uk42TGN0YTZvYXpvNU9ob2tuMGhtVkNnaHprSnNublFoTjc1T19VSFoxS1ViYmc='));

  VoiceAssistantService(this._authService) {
    _initTts();
  }

  Function(bool)? onSpeakingStateChanged;

  void _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setPitch(1.1); 
    await _flutterTts.setSpeechRate(0.5); 
    await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
        ],
        IosTextToSpeechAudioMode.defaultMode
    );
    
    _flutterTts.setStartHandler(() {
      if (onSpeakingStateChanged != null) onSpeakingStateChanged!(true);
    });
    _flutterTts.setCompletionHandler(() {
      if (onSpeakingStateChanged != null) onSpeakingStateChanged!(false);
    });
    _flutterTts.setCancelHandler(() {
      if (onSpeakingStateChanged != null) onSpeakingStateChanged!(false);
    });
  }

  Future<void> initialize() async {
    if (_authService.calendarApi != null) {
      _calendarService = GoogleCalendarService(_authService.calendarApi!);
    }
    if (_authService.gmailApi != null) {
      _mailService = GoogleMailService(_authService.gmailApi!);
    }
    if (_authService.tasksApi != null) {
      _tasksService = GoogleTasksService(_authService.tasksApi!);
    }

    final noemiTools = Tool(
      functionDeclarations: [
        FunctionDeclaration('get_upcoming_events', 'Récupère les événements à venir dans l\'agenda', Schema(SchemaType.object, properties: {})),
        FunctionDeclaration('get_unread_emails', 'Récupère les derniers emails non lus', Schema(SchemaType.object, properties: {})),
        FunctionDeclaration('get_pending_tasks', 'Récupère les tâches en cours', Schema(SchemaType.object, properties: {})),
        FunctionDeclaration('add_task', 'Ajoute une tâche à la liste', Schema(SchemaType.object, properties: {
          'title': Schema(SchemaType.string, description: 'Le nom de la tâche à ajouter')
        }, requiredProperties: ['title'])),
      ],
    );

    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
      tools: [noemiTools],
      systemInstruction: Content.system('''
Tu es Noemi, une assistante virtuelle intelligente, chaleureuse, amicale et très efficace (façon Jarvis).
Tu parles à voix haute à l'utilisateur, donc tes phrases doivent être naturelles, concises, sans tirets ni markdown.
Tu as accès à son agenda, ses emails et ses tâches.
'''),
    );
    _chat = _model.startChat();
  }

  Future<String> askNoemi(String prompt) async {
    try {
      final response = await _chat.sendMessage(Content.text(prompt));
      
      if (response.functionCalls.isNotEmpty) {
        final call = response.functionCalls.first;
        String resultStr = "Action non reconnue.";
        
        if (call.name == 'get_upcoming_events') {
          final events = await _calendarService.getUpcomingEvents();
          resultStr = events.isEmpty ? "Aucun événement prévu." : events.map((e) => "\${e.summary} à \${e.start?.dateTime?.toLocal()}").join(', ');
        } 
        else if (call.name == 'get_unread_emails') {
          final emails = await _mailService.getUnreadEmails();
          resultStr = emails.isEmpty ? "Aucun nouveau mail." : emails.join('. ');
        }
        else if (call.name == 'get_pending_tasks') {
          final tasks = await _tasksService.getPendingTasks();
          resultStr = tasks.isEmpty ? "Aucune tâche en cours." : tasks.join(', ');
        }
        else if (call.name == 'add_task') {
          final title = call.args['title'] as String;
          final success = await _tasksService.addTask(title);
          resultStr = success ? "Tâche ajoutée avec succès." : "Échec de l'ajout de la tâche.";
        }

        final functionResponse = await _chat.sendMessage(
          Content.functionResponse(call.name, {'result': resultStr})
        );
        return functionResponse.text ?? "Voici le résultat.";
      }

      return response.text ?? "Désolé, je n'ai pas compris.";
    } catch (e) {
      print("Erreur Gemini: \$e");
      return "Une erreur est survenue lors de la communication avec le réseau neuronal.";
    }
  }

  void speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> listen(Function(String) onResult) async {
    if (!isListening) {
      bool available = await _speech.initialize();
      if (available) {
        isListening = true;
        _speech.listen(
          onResult: (val) {
            if (val.hasConfidenceRating && val.confidence > 0) {
              onResult(val.recognizedWords);
            }
          },
          localeId: "fr_FR"
        );
      }
    } else {
      isListening = false;
      _speech.stop();
    }
  }
  
  void stopListening() {
    isListening = false;
    _speech.stop();
  }
}
