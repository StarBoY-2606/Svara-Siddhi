import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import 'vpi_screen.dart';
import 'record_screen.dart';
import 'model_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? _gunaBaseline;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadBaseline();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _gunaBaseline = prefs.getString('guna_baseline'));
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_suggest_rounded,
                          color: AppColors.primary, size: 28),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ModelSettingsScreen()),
                      ),
                      tooltip: 'ML Model Settings',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Text(
                    'ॐ',
                    style: TextStyle(
                      fontSize: 80,
                      color: AppColors.primary,
                      shadows: [
                        Shadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 24)
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Svara-Siddhi',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        )),
                const SizedBox(height: 8),
                Text(
                  'Voice-Based Bio-Acoustic\nWellness Tracker',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.mutedForeground, height: 1.5),
                ),
                const SizedBox(height: 32),
                if (_gunaBaseline != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.gunaColor(_gunaBaseline!)
                              .withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('YOUR BASELINE GUNA',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedForeground,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w500)),
                            SizedBox(height: 4),
                          ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gunaColor(_gunaBaseline!)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_gunaBaseline!,
                            style: TextStyle(
                                color: AppColors.gunaColor(_gunaBaseline!),
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Complete Your VPI Assessment',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text(
                                'Answer 8 questions to calibrate your Guna baseline before voice analysis.',
                                style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 13,
                                    height: 1.4)),
                          ])),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('The Three Gunas',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.foreground)),
                        const SizedBox(height: 14),
                        _gunaRow('Sattvic', 'Clarity, balance, and inner peace',
                            AppColors.sattva),
                        const SizedBox(height: 10),
                        _gunaRow(
                            'Rajasic',
                            'Activity, passion, and restlessness',
                            AppColors.rajas),
                        const SizedBox(height: 10),
                        _gunaRow('Tamasic', 'Inertia, heaviness, and lethargy',
                            AppColors.tamas),
                      ]),
                ),
                const SizedBox(height: 32),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const VpiScreen()));
                        _loadBaseline();
                      },
                      icon: const Icon(Icons.list_alt_rounded),
                      label: Text(_gunaBaseline != null
                          ? 'Retake VPI Assessment'
                          : 'Begin VPI Assessment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    )),
                if (_gunaBaseline != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => RecordScreen(
                                    gunaBaseline: _gunaBaseline!))),
                        icon: const Icon(Icons.mic_rounded,
                            color: AppColors.primary),
                        label: const Text('Analyze Voice',
                            style: TextStyle(color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      )),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      setState(() => _gunaBaseline = null);
                    },
                    child: const Text('Reset All Data',
                        style: TextStyle(
                            color: AppColors.mutedForeground, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Rooted in Ayurveda & Yogic Science',
                    style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gunaRow(String name, String desc, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 3,
          height: 36,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(desc,
            style: const TextStyle(
                color: AppColors.mutedForeground, fontSize: 12, height: 1.4)),
      ]),
    ]);
  }
}
