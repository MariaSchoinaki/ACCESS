import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/cupertino.dart';

import '../blocs/search_bloc/search_bloc.dart';
import '../theme/app_colors.dart';
import '../utils/WaveformPainter.dart';


///VoiceInputModal is a StatefulWidget that provides a modal bottom sheet
///for voice input, allowing users to speak their search queries.
///It integrates with the speech_to_text plugin to capture audio and display
///a visual representation of sound levels.
class VoiceInputModal extends StatefulWidget {
  /// TextEditingController to update the search bar's text with recognized words.
  final TextEditingController controller;

  const VoiceInputModal({super.key, required this.controller});

  @override
  State<VoiceInputModal> createState() => _VoiceInputModalState();
}
///The State class for VoiceInputModal.
/// It manages the speech recognition lifecycle, listening state,
/// sound level visualization, and microphone pulsing animation.
class _VoiceInputModalState extends State<VoiceInputModal> with SingleTickerProviderStateMixin {
  /// Instance of the speech_to_text plugin.
  late final stt.SpeechToText _speech;
  /// Boolean to track if the microphone is currently listening.
  bool _isListening = false;
  /// The locale ID for speech recognition (e.g., 'el_GR' for Greek).
  String _localeId = 'el_GR';
  /// A list to store the most recent sound level values.
  /// The current implementation of WaveformPainter seems to use only the first element.
  final List<double> _soundLevels = [0.1, 0.1, 0.1, 0.1];

  /// AnimationController for controlling the pulsing effect of the microphone icon.
  late AnimationController _pulseController;
  /// Animation for the scaling effect of the microphone icon.
  late Animation<double> _pulseAnimation;
  double _currentLevel = 0.2;

  @override
  /// Initializes the state, including the SpeechToText instance and
  /// the animation controller for the pulsing effect.
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech(); // Initialize speech recognition.

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400), // Duration for one pulse cycle.
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),// Smooth ease-in-out curve.
    );
    // Listener to reverse or forward the animation when it completes or dismisses.
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
  }

  /// Asynchronously initializes the speech_to_text plugin.
  /// It checks for availability and sets the preferred locale (Greek, then English fallback).
  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onError: (err) => print('Speech error: $err'),// Callback for speech errors.
      onStatus: (status) => print('Speech status: $status'),// Callback for status changes.
    );
    if (available) {
      final locales = await _speech.locales();// Get available locales.
      // Find Greek locale, or fallback to English.
      final elLocale = locales.firstWhere(
            (locale) => locale.localeId.startsWith('el'),
        orElse: () => locales.firstWhere((locale) => locale.localeId.startsWith('en')),
      );
      setState(() {
        _localeId = elLocale.localeId; // Set the determined locale.
      });
    }
  }

  /// Starts the speech recognition process.
  /// Updates the listening state, resets sound levels, starts the pulsing animation,
  /// and configures the speech_to_text listener.
  void _startListening() {
    setState(() {
      _isListening = true;// Set listening state to true.
      // Reset sound levels to initial low values.
      _soundLevels.setAll(0, [0.1, 0.1, 0.1, 0.1]);
    });
    _pulseController.forward();// Start the pulsing animation.
    _speech.listen(
      localeId: _localeId,
      onResult: (result) {
        // Callback when speech is recognized.
        widget.controller.text = result.recognizedWords;// Update text field.
        context.read<SearchBloc>().add(SearchQueryChanged(result.recognizedWords));
      },
      onSoundLevelChange: (level) {
        // Callback when sound level changes. 'level' is in dB.
        setState(() {
          _currentLevel += (level - _currentLevel) * 0.1;
          _soundLevels.removeAt(0);
          _soundLevels.add(level);
        });
      },
      cancelOnError: true, // Cancel listening if an error occurs.
      listenFor: const Duration(seconds: 5), // Listen for a maximum of 5 seconds.
    );
  }

  /// Stops the speech recognition process.
  /// Updates the listening state, resets sound levels, and stops the pulsing animation.
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _soundLevels.setAll(0, [0.1, 0.1, 0.1, 0.1]);
    });
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  ///Disposes of the animation controller when the widget is removed from the tree.
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  /// Builds the UI for the voice input modal bottom sheet.
  /// Includes a prompt text, a microphone button with pulsing animation,
  /// a waveform visualization, and a close button.
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Informative text for the user.
        children: [
          Text(
            'Προσπάθησε να πεις καφετερίες ή φαρμακείο',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          // GestureDetector for the microphone icon, toggles listening state.
          GestureDetector(
            onTap: () {
              if (_isListening) {
                _stopListening();// Stop if already listening.
              } else {
                _startListening(); // Start if not listening.
              }
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation, // Animate the microphone icon.
              builder: (context, child) {
                return Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,// Apply pulse scale if listening.
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Add shadow effect if listening.
                      boxShadow: _isListening
                          ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: _isListening ? AppColors.primary : Colors.grey[300],
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: _isListening
                ? AnimatedBuilder(
              animation: _pulseController,// Rebuilds when pulse animation updates.
              builder: (context, child) {
                return CustomPaint(
                  painter: WaveformPainter(
                    isListening:_isListening,
                    targetSoundLevel: _isListening && _soundLevels.isNotEmpty ? _soundLevels[0] : 0.2,
                    currentLevel: _currentLevel,
                  ),
                );
              },
            )
                : CustomPaint(
              painter: WaveformPainter(isListening:_isListening, targetSoundLevel: 0.3, currentLevel: _currentLevel),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_isListening) _stopListening(); // Stop listening before closing.
              Navigator.of(context).pop(); // Close the modal.
            },
            child: const Text('Κλείσιμο'),
          ),
        ],
      ),
    );
  }
}
