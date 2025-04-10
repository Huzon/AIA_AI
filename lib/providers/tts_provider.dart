import 'package:aia/services/tts_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider((ref) => TTSService());
