class AnalysisResult {
  final String gunaState;
  final int sattvicScore;
  final int rajasicScore;
  final int tamasicScore;
  final int vataScore;
  final int pittaScore;
  final int kaphaScore;
  final int pitch;
  final int energy;
  final int clarity;
  final String prescription;
  final String technique;
  final String? transcript;
  final List<double> mfccs;
  final DateTime timestamp;

  AnalysisResult({
    required this.gunaState,
    required this.sattvicScore,
    required this.rajasicScore,
    required this.tamasicScore,
    required this.vataScore,
    required this.pittaScore,
    required this.kaphaScore,
    required this.pitch,
    required this.energy,
    required this.clarity,
    required this.prescription,
    required this.technique,
    this.transcript,
    required this.mfccs,
    required this.timestamp,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      gunaState: json['guna_state'] as String,
      sattvicScore: json['sattvic_score'] as int,
      rajasicScore: json['rajasic_score'] as int,
      tamasicScore: json['tamas_score'] as int,
      vataScore: json['vata_score'] as int,
      pittaScore: json['pitta_score'] as int,
      kaphaScore: json['kapha_score'] as int,
      pitch: (json['pitch'] as num).toInt(),
      energy: (json['energy'] as num).toInt(),
      clarity: (json['clarity'] as num).toInt(),
      prescription: json['prescription'] as String,
      technique: json['technique'] as String,
      transcript: json['transcript'] as String?,
      mfccs: (json['mfccs'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'guna_state': gunaState,
        'sattvic_score': sattvicScore,
        'rajasic_score': rajasicScore,
        'tamas_score': tamasicScore,
        'vata_score': vataScore,
        'pitta_score': pittaScore,
        'kapha_score': kaphaScore,
        'pitch': pitch,
        'energy': energy,
        'clarity': clarity,
        'prescription': prescription,
        'technique': technique,
        'transcript': transcript,
        'mfccs': mfccs,
        'timestamp': timestamp.toIso8601String(),
      };
}

class VpiSubmission {
  final List<String> answers;

  VpiSubmission({required this.answers});

  Map<String, dynamic> toJson() => {'answers': answers};
}

class VpiResult {
  final String baseline;
  final int sattvicCount;
  final int rajasicCount;
  final int tamasicCount;

  VpiResult({
    required this.baseline,
    required this.sattvicCount,
    required this.rajasicCount,
    required this.tamasicCount,
  });

  factory VpiResult.fromJson(Map<String, dynamic> json) {
    return VpiResult(
      baseline: json['baseline'] as String,
      sattvicCount: json['sattvic_count'] as int,
      rajasicCount: json['rajasic_count'] as int,
      tamasicCount: json['tamas_count'] as int,
    );
  }
}
