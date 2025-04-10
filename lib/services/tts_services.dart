// tts_service.dart
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  final androidFemaleVoices = [
    'female', // Generic fallback
    'en-us-x-sfg', // Android's standard female
    'en-gb-x-gba', // British female
    'smt', // Samsung devices
    'l02', // Samsung female variant
    'google', // Google TTS
    'cmu', // CMU voices
    'ivona', // IVONA voices (older devices)
  ];

  final iosFemaleVoices = [
    'samantha', // Default iOS female
    'karen', // Australian female
    'moira', // Irish female
    'tessa', // South African female
    'ava', // US female
    'susan', // British female
    'serena', // Canadian French female
  ];
  TTSService();
  Future<void> initTts() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(.5);
    await _flutterTts.setPitch(.5); // Slightly higher pitch for female sound

    try {
      final femaleVoiceKeywords =
          Platform.isIOS ? iosFemaleVoices : androidFemaleVoices;
      // Try to find the best matching female voice
      final voices = await _flutterTts.getVoices;

      Map<String, dynamic>? selectedVoice;

      for (final keyword in femaleVoiceKeywords) {
        final voice = voices.firstWhere(
          (v) => v['name'].toString().toLowerCase().contains(keyword),
          orElse: () => null,
        );

        if (voice != null) {
          print(voice['name']);
          selectedVoice = {"name": voice['name'], "locale": voice['locale']};
          break;
        }
      }
      if (selectedVoice != null) {
        await _flutterTts.setVoice({
          'name': selectedVoice['name'],
          'locale': selectedVoice['locale'],
        });
        print('Using female voice: ${selectedVoice['name']}');
      } else {
        print('No female voice found, using default');
        await _flutterTts.setLanguage(Platform.isIOS ? 'en-US' : 'en-GB');
      }
      _isInitialized = true;
    } catch (e) {
      print('Error setting female voice: $e');
      // Fall back to default voice
    }
  }

  Future<void> speak(String text) async {
    await initTts(); // Ensure initialization before each speak
    // await _flutterTts.stop(); // Stop any ongoing speech
    await _debugTtsSettings();
    await _flutterTts.awaitSpeakCompletion(true); // Wait for completion
    final cleanText = _cleanTextForTts(text);
    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  String _cleanTextForTts(String text) {
    // Remove Markdown symbols
    final noMarkdown =
        text
            .replaceAll('e.g.', 'Example')
            .replaceAllMapped(
              RegExp(r'```[a-z]*\n([\s\S]*?)\n```'),
              (match) => '\n${match.group(1)}\n',
            )
            // Convert headers to pauses
            .replaceAllMapped(
              RegExp(r'^#+\s+(.*)$', multiLine: true),
              (match) => '\n${match.group(1)}.\n',
            )
            // Handle bold/italic naturally
            .replaceAllMapped(
              RegExp(r'(\*{1,3}|_{1,3})(.*?)\1'),
              (match) => match.group(2) ?? '',
            )
            // Simplify links (keep the description)
            .replaceAllMapped(
              RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
              (match) => match.group(1) ?? 'link',
            )
            // Remove remaining Markdown artifacts
            .replaceAll(RegExp(r'^[>\-]\s*', multiLine: true), '')
            .replaceAll(RegExp(r'`{1,3}'), '')
            // Normalize whitespace
            .replaceAll(RegExp(r'\s+\.'), '.')
            .replaceAll(RegExp(r'\n{2,}'), '\n\n')
            .replaceAll(RegExp(r' {2,}'), ' ')
            .replaceAll(RegExp(r'[\*\#\>\<\`\~\|\_]'), '')
            .trim();

    return noMarkdown;
  }

  Future<void> _debugTtsSettings() async {
    // final rate = await _flutterTts.get;
    // print('Current speech rate: '+rate.); // Should be 0.5
  }
}
