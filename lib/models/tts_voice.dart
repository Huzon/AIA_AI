class TtsVoice {
  final String name;
  final String locale;
  final bool? isFemale;

  TtsVoice({required this.name, required this.locale, this.isFemale});

  factory TtsVoice.fromMap(Map<dynamic, dynamic> map) {
    return TtsVoice(
      name: map['name']?.toString() ?? '',
      locale: map['locale']?.toString() ?? '',
      isFemale: map['name']?.toString().toLowerCase().contains('female'),
    );
  }
}
