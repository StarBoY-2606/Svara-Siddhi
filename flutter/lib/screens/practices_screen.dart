import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';

class Practice {
  final String id, name, sanskrit, guna, type, duration, description, benefit;
  final List<String> steps;
  const Practice(
      {required this.id,
      required this.name,
      required this.sanskrit,
      required this.guna,
      required this.type,
      required this.duration,
      required this.description,
      required this.benefit,
      required this.steps});
}

const _practices = [
  Practice(
      id: 'anulom',
      name: 'Anulom Vilom',
      sanskrit: 'अनुलोम विलोम',
      guna: 'Sattvic',
      type: 'Pranayama',
      duration: '5–15 min',
      description:
          'Alternate Nostril Breathing that balances Ida and Pingala Nadis, bringing clarity and equanimity.',
      benefit:
          'Balances the nervous system, reduces anxiety, and cultivates Sattvic clarity.',
      steps: [
        'Sit in a comfortable upright posture.',
        'Close the right nostril with your right thumb. Inhale through the left for 4 counts.',
        'Close both nostrils. Hold for 4 counts.',
        'Release the right nostril. Exhale for 8 counts.',
        'Inhale through the right for 4 counts. Hold. Exhale through the left for 8.',
        'Repeat for 5–15 minutes.'
      ]),
  Practice(
      id: 'dhyana',
      name: 'Dhyana',
      sanskrit: 'ध्यान',
      guna: 'Sattvic',
      type: 'Meditation',
      duration: '10–30 min',
      description:
          'Silent meditation — uninterrupted flow of concentration. The mind becomes still like a lamp in a windless place.',
      benefit:
          'Cultivates deep inner peace, self-awareness, and Sattvic consciousness.',
      steps: [
        'Sit in Padmasana or Sukhasana with eyes closed.',
        'Place hands in Chin Mudra (thumb and index finger touching).',
        'Focus awareness on the breath or a single point (Trataka).',
        'When thoughts arise, gently return awareness without judgment.',
        'Remain in this state for 10–30 minutes.'
      ]),
  Practice(
      id: 'om',
      name: 'OM Chanting',
      sanskrit: 'ॐ',
      guna: 'Rajasic',
      type: 'Mantra',
      duration: '5–10 min',
      description:
          'The primordial sound of the universe. Sustained OM vibrations calm the Rajasic mind and dissolve restlessness.',
      benefit:
          'Reduces hyperactivity, lowers cortisol, and transitions Rajasic energy to Sattvic peace.',
      steps: [
        'Sit comfortably with spine erect.',
        'Take a deep inhalation.',
        "Exhale slowly, producing a low 'OOOO' for 70% of the breath.",
        "Seal with 'MMM' for the remaining 30%, feeling vibration in the skull.",
        'Pause in silence after each chant.',
        'Repeat 7–21 times.'
      ]),
  Practice(
      id: 'shitali',
      name: 'Shitali Pranayama',
      sanskrit: 'शीतली प्राणायाम',
      guna: 'Rajasic',
      type: 'Pranayama',
      duration: '5–10 min',
      description:
          'Cooling breath. Roll the tongue into a tube, inhale across it to draw cool air in, calming Rajasic heat.',
      benefit:
          'Reduces body heat, anger, and Rajasic agitation. Cools the nervous system.',
      steps: [
        'Sit comfortably with eyes closed.',
        'Roll the tongue lengthwise into a tube.',
        'Inhale slowly through the rolled tongue.',
        'Withdraw the tongue and close the mouth.',
        'Exhale slowly through both nostrils.',
        'Repeat 8–15 cycles.'
      ]),
  Practice(
      id: 'kapalbhati',
      name: 'Kapalbhati',
      sanskrit: 'कपालभाति',
      guna: 'Tamasic',
      type: 'Pranayama',
      duration: '5–10 min',
      description:
          'Skull-shining breath. Rapid, forceful exhalations energize the brain and burn off Tamasic inertia and lethargy.',
      benefit:
          'Energizes the body and mind, clears Tamasic dullness, and activates Prana Shakti.',
      steps: [
        'Sit in Sukhasana with hands on knees.',
        'Take a slow, passive inhalation.',
        'Perform a sharp, forceful exhalation by contracting the abdomen inward.',
        'Allow the inhalation to happen naturally and passively.',
        'Start with 30 strokes/min. Rest 30s. Repeat 3 rounds.'
      ]),
  Practice(
      id: 'bija',
      name: 'Bija Mantras',
      sanskrit: 'बीज मंत्र',
      guna: 'Tamasic',
      type: 'Mantra',
      duration: '5–15 min',
      description:
          'Seed syllables Ram and Hum carry elemental fire and protective energy, breaking through Tamasic stagnation.',
      benefit:
          'Activates Agni (digestive fire), dispels Tamasic heaviness, and energizes Prana.',
      steps: [
        'Sit comfortably with eyes closed and spine erect.',
        "Chant 'RAM' (rahm) — associated with fire and transformation.",
        "Follow with 'HUM' (hoom) — protective, energizing.",
        'Chant each 7 times with full resonance.',
        'Feel vibration in the solar plexus (Ram) and heart center (Hum).',
        'Alternate for 5–15 minutes.'
      ]),
];

const _typeIcons = {
  'Pranayama': Icons.air_rounded,
  'Mantra': Icons.volume_up_rounded,
  'Meditation': Icons.visibility_rounded
};

class PracticesScreen extends StatefulWidget {
  const PracticesScreen({super.key});
  @override
  State<PracticesScreen> createState() => _PracticesScreenState();
}

class _PracticesScreenState extends State<PracticesScreen> {
  String _filter = 'All';
  final Set<String> _expanded = {};

  List<Practice> get _filtered => _filter == 'All'
      ? _practices
      : _practices.where((p) => p.guna == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF0D0820), Color(0xFF160D35), Color(0xFF0D0820)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Practices',
                        style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 26,
                            fontWeight: FontWeight.w700)),
                    Text('Yogic interventions by Guna state',
                        style: TextStyle(
                            color: AppColors.mutedForeground, fontSize: 14)),
                  ])),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              for (final f in ['All', 'Sattvic', 'Rajasic', 'Tamasic']) ...[
                _FilterChip(
                    label: f,
                    active: _filter == f,
                    color: _filterColor(f),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _filter = f);
                    }),
                const SizedBox(width: 8),
              ]
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
              child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = _filtered[i];
              final isExpanded = _expanded.contains(p.id);
              final accent = AppColors.gunaColor(p.guna);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => isExpanded
                      ? _expanded.remove(p.id)
                      : _expanded.add(p.id));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isExpanded
                            ? accent.withOpacity(0.4)
                            : AppColors.border),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(
                                      _typeIcons[p.type] ?? Icons.wind_power,
                                      color: accent,
                                      size: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Row(children: [
                                      Text(p.name,
                                          style: const TextStyle(
                                              color: AppColors.foreground,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15)),
                                      const SizedBox(width: 8),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: accent.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text(p.type,
                                              style: TextStyle(
                                                  color: accent,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                    ]),
                                    Text(p.sanskrit,
                                        style: TextStyle(
                                            color: accent, fontSize: 13)),
                                    Row(children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 13,
                                          color: AppColors.mutedForeground),
                                      const SizedBox(width: 4),
                                      Text(p.duration,
                                          style: const TextStyle(
                                              color: AppColors.mutedForeground,
                                              fontSize: 12))
                                    ]),
                                  ])),
                              Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.mutedForeground),
                            ]),
                        const SizedBox(height: 10),
                        Text(p.description,
                            style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                                height: 1.5),
                            maxLines: isExpanded ? 99 : 2,
                            overflow: TextOverflow.ellipsis),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: accent.withOpacity(0.25))),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: accent, size: 14),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(p.benefit,
                                            style: TextStyle(
                                                color: accent,
                                                fontSize: 13,
                                                height: 1.4,
                                                fontWeight: FontWeight.w500))),
                                  ])),
                          const SizedBox(height: 12),
                          const Text('How to Practice',
                              style: TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          for (int j = 0; j < p.steps.length; j++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                            color: accent.withOpacity(0.15),
                                            shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text('${j + 1}',
                                            style: TextStyle(
                                                color: accent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700))),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(p.steps[j],
                                            style: const TextStyle(
                                                color:
                                                    AppColors.mutedForeground,
                                                fontSize: 13,
                                                height: 1.45))),
                                  ]),
                            ),
                        ],
                      ]),
                ),
              );
            },
          )),
        ])),
      ),
    );
  }

  Color _filterColor(String f) => f == 'Sattvic'
      ? AppColors.sattva
      : f == 'Rajasic'
          ? AppColors.rajas
          : f == 'Tamasic'
              ? AppColors.tamas
              : AppColors.primary;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? color : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? color : AppColors.mutedForeground,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      );
}
