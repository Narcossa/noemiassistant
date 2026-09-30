import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/google_auth_service.dart';
import '../services/voice_assistant_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late VideoPlayerController _videoController;
  
  final GoogleAuthService _authService = GoogleAuthService();
  late VoiceAssistantService _voiceService;
  
  bool _isConnected = false;
  bool _isListening = false;
  bool _isThinking = false;
  String _currentText = "En attente de connexion...";

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceAssistantService(_authService);
    
    try {
      _videoController = VideoPlayerController.asset('assets/videos/avatar_video.mp4')
        ..initialize().then((_) {
          setState(() {});
        }).catchError((error) {
          print("Erreur vidéo: $error");
        });
    } catch (e) {
      print("Erreur initialisation vidéo: $e");
    }

    _voiceService.onSpeakingStateChanged = (bool isSpeaking) {
      if (mounted) {
        if (isSpeaking) {
          _videoController.play();
          _videoController.setLooping(true);
        } else {
          _videoController.pause();
          _videoController.seekTo(Duration.zero);
        }
      }
    };
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _connectToGoogle() async {
    try {
      await _authService.signIn();
      if (_authService.currentUser != null) {
        await _voiceService.initialize();
        setState(() {
          _isConnected = true;
          _currentText = "Bonjour, je suis Noemi. Comment puis-je vous aider ?";
        });
        _voiceService.speak("Bonjour, je suis Noemi. Vos systèmes sont en ligne.");
      } else {
        setState(() {
          _currentText = "Connexion annulée ou échouée.";
        });
      }
    } catch (e) {
      setState(() {
        _currentText = "Erreur: $e";
      });
    }
  }

  Future<void> _toggleListening() async {
    if (!_isConnected) return;
    
    if (_isListening) {
      _voiceService.stopListening();
      setState(() {
        _isListening = false;
        _isThinking = true;
      });
      
      String response = await _voiceService.askNoemi(_currentText);
      
      setState(() {
        _isThinking = false;
        _currentText = response;
      });
      
      _voiceService.speak(response);
      
    } else {
      setState(() {
        _isListening = true;
        _currentText = "J'écoute...";
      });
      
      _voiceService.listen((recognizedText) {
        setState(() {
          _currentText = recognizedText;
        });
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.blueAccent.withOpacity(0.15), Colors.black],
                radius: 1.2,
                center: Alignment.center,
              ),
            ),
          ),
          
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening || _isThinking ? _pulseAnimation.value * 1.2 : _pulseAnimation.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isListening ? Colors.redAccent.withOpacity(0.4) : Colors.cyanAccent.withOpacity(0.3),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Center(
            child: _videoController.value.isInitialized
                ? SizedBox(
                    width: 250,
                    height: 250,
                    child: ClipOval(
                      child: AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  )
                : const Icon(Icons.smart_toy, size: 100, color: Colors.cyan),
          ),
          
          Positioned(
            bottom: 150,
            left: 20,
            right: 20,
            child: Text(
              _currentText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.cyan, blurRadius: 10)],
              ),
            ),
          ),
          
          Positioned(
            bottom: 50,
            child: !_isConnected 
              ? ElevatedButton.icon(
                  onPressed: _connectToGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text("Initialiser les systèmes (Google)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                )
              : GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.redAccent.withOpacity(0.2) : Colors.cyanAccent.withOpacity(0.2),
                      border: Border.all(color: _isListening ? Colors.redAccent : Colors.cyanAccent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _isListening ? Colors.redAccent.withOpacity(0.5) : Colors.cyanAccent.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening ? Colors.redAccent : Colors.cyanAccent,
                      size: 32,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
