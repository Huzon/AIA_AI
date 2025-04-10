import 'package:aia/services/stt_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sttServiceProvider = Provider((ref) => STTService());
