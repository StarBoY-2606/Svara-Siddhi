import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../services/api_service.dart';
import 'record_screen.dart';

const _questions = [
  {
    'category': 'Stress Response',
    'question': 'How do you typically react under high pressure?',
    'A': 'Remain calm and find a solution.',
    'B': 'Become anxious, irritable, or hyperactive.',
    'C': 'Shut down, avoid the problem, or feel overwhelmed.'
  },
  {
    'category': 'Energy Levels',
    'question': 'Describe your daily physical energy:',
    'A': 'Steady, light, and consistent throughout the day.',
    'B': 'Restless, intense bursts followed by sudden crashes.',
    'C': 'Heavy, lethargic, difficult to get moving in the morning.'
  },
  {
    'category': 'Sleep Patterns',
    'question': 'How do you sleep?',
    'A': 'Deep, wake up easily and feeling completely refreshed.',
    'B': 'Interrupted, racing thoughts, very active dreams.',
    'C': 'Very heavy, difficult to wake up, groggy for hours.'
  },
  {
    'category': 'Dietary Preference',
    'question': 'What foods do you naturally crave?',
    'A': 'Fresh, light, warm, naturally sweet (fruits, grains).',
    'B': 'Very spicy, salty, sour, or highly stimulating foods.',
    'C': 'Heavy, processed, fried, or cold foods.'
  },
  {
    'category': 'Emotional Tendency',
    'question': 'What is your default emotional state when challenged?',
    'A': 'Compassionate, forgiving, and understanding.',
    'B': 'Competitive, aggressive, or easily frustrated.',
    'C': 'Apathetic, resentful, or feeling like a victim.'
  },
  {
    'category': 'Work Approach',
    'question': 'How do you handle your daily tasks?',
    'A': 'Focused, methodical, completing one thing at a time.',
    'B': 'Multitasking, rushed, constantly moving to the next thing.',
    'C': 'Procrastinating, slow, frequently leaving things unfinished.'
  },
  {
    'category': 'Speech Pattern',
    'question': 'How do others describe your way of speaking?',
    'A': 'Clear, calm, truthful, and concise.',
    'B': 'Fast, loud, persuasive, or argumentative.',
    'C': 'Slow, repetitive, unclear, or complaining.'
  },
  {
    'category': 'Learning Style',
    'question': 'How do you react to new information or feedback?',
    'A': 'Open-minded, reflective, and willing to learn.',
    'B': 'Skeptical, immediately debating, or trying to prove them wrong.',
    'C': 'Dismissive, ignoring it, or unable to process it.'
  },
];

const _optionColors = {
  'A': AppColors.sattva,
  'B': AppColors.rajas,
  'C': AppColors.tamas
};
const _optionLabels = {'A': 'Sattva', 'B': 'Rajas', 'C': 'Tamas'};

class VpiScreen extends StatefulWidget {
  const VpiScreen({super.key});
  @override
  State<VpiScreen> createState() => _VpiScreenState();
}

class _VpiScreenState extends State<VpiScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  final List<String?> _answers = List.filled(8, null);
  bool _submitting = false;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.05, 0))
        .animate(_slideCtrl);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _select(String answer) {
    HapticFeedback.lightImpact();
    setState(() => _answers[_current] = answer);
  }

  void _next() async {
    if (_answers[_current] == null) return;
    if (_current < 7) {
      await _slideCtrl.forward();
      setState(() => _current++);
      _slideCtrl.reset();
    } else {
      _submit();
    }
  }

  void _back() {
    if (_current == 0) {
      Navigator.of(context).pop();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _current--);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ApiService().submitVpi(_answers.cast<String>());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guna_baseline', result.baseline);
      await prefs.setInt('sattvic_count', result.sattvicCount);
      await prefs.setInt('rajasic_count', result.rajasicCount);
      await prefs.setInt('tamas_count', result.tamasicCount);
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => RecordScreen(gunaBaseline: result.baseline)),
        );
      }
    } catch (e) {
      final answers = _answers.cast<String>();
      final s = answers.where((a) => a == 'A').length;
      final r = answers.where((a) => a == 'B').length;
      final t = answers.where((a) => a == 'C').length;
      String baseline = s >= r && s >= t
          ? 'Sattvic'
          : r >= t
              ? 'Rajasic'
              : 'Tamasic';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guna_baseline', baseline);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => RecordScreen(gunaBaseline: baseline)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    final progress = (_current + 1) / 8;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0820), Color(0xFF160D35), Color(0xFF0D0820)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                IconButton(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.foreground)),
                Expanded(
                    child: Text('${_current + 1} / 8',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 14,
                            fontWeight: FontWeight.w500))),
                const SizedBox(width: 48),
              ]),
            ),
            LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF2D2050),
                color: AppColors.primary,
                minHeight: 3),
            Expanded(
                child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((q['category'] as String).toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Text(q['question'] as String,
                          style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.4)),
                      const SizedBox(height: 28),
                      for (final key in ['A', 'B', 'C']) ...[
                        _OptionCard(
                          optKey: key,
                          text: q[key] as String,
                          label: _optionLabels[key]!,
                          color: _optionColors[key]!,
                          selected: _answers[_current] == key,
                          onTap: () => _select(key),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ]),
              ),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_answers[_current] != null && !_submitting)
                        ? _next
                        : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryForeground))
                        : Icon(_current == 7
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded),
                    label: Text(_current == 7
                        ? 'Complete Assessment'
                        : 'Next Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      disabledBackgroundColor: AppColors.muted,
                      disabledForegroundColor: AppColors.mutedForeground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  )),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String optKey, text, label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _OptionCard(
      {required this.optKey,
      required this.text,
      required this.label,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: selected ? color : AppColors.muted,
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(optKey,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.mutedForeground,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        color: selected ? color : AppColors.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(text,
                    style: TextStyle(
                        color: selected
                            ? AppColors.foreground
                            : AppColors.mutedForeground,
                        fontSize: 14,
                        height: 1.4)),
              ])),
          if (selected)
            Icon(Icons.check_circle_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}
