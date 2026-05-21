import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../models/analysis_result.dart';

class ResultsScreen extends StatefulWidget {
  final AnalysisResult result;
  const ResultsScreen({super.key, required this.result});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    HapticFeedback.mediumImpact();
    _saveToHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('history') ?? [];
    raw.insert(0, jsonEncode(widget.result.toJson()));
    if (raw.length > 30) raw.removeLast();
    await prefs.setStringList('history', raw);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final color = AppColors.gunaColor(r.gunaState);
    final bgColor = AppColors.gunaBg(r.gunaState);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor, AppColors.background, AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                  position: _slide,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                          child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Row(children: [
                          IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: AppColors.foreground)),
                          const Expanded(
                              child: Text('Your Reading',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600))),
                          IconButton(
                              onPressed: () => Navigator.of(context)
                                  .popUntil((r) => r.isFirst),
                              icon: const Icon(Icons.home_rounded,
                                  color: AppColors.mutedForeground)),
                        ]),
                      )),
                      SliverToBoxAdapter(
                          child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Column(children: [
                          Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withOpacity(0.12),
                                  border: Border.all(
                                      color: color.withOpacity(0.4),
                                      width: 1.5)),
                              child: Icon(_gunaIcon(r.gunaState),
                                  color: color, size: 40)),
                          const SizedBox(height: 12),
                          Text(_pranaPranaLabel(r.gunaState).toUpperCase(),
                              style: TextStyle(
                                  color: AppColors.gunaColor(r.gunaState)
                                      .withOpacity(0.7),
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(r.gunaState,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700)),
                          const Text('Current State',
                              style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 14)),
                          const SizedBox(height: 24),
                          _Section(
                              title: 'Triguna Index',
                              child: Column(children: [
                                _ScoreBar(
                                    'Sattva', r.sattvicScore, AppColors.sattva),
                                const SizedBox(height: 10),
                                _ScoreBar(
                                    'Rajas', r.rajasicScore, AppColors.rajas),
                                const SizedBox(height: 10),
                                _ScoreBar(
                                    'Tamas', r.tamasicScore, AppColors.tamas),
                              ])),
                          const SizedBox(height: 16),
                          _Section(
                              title: 'Dosha Profile',
                              child: Column(children: [
                                _ScoreBar('Vata', r.vataScore, AppColors.vata),
                                const SizedBox(height: 10),
                                _ScoreBar(
                                    'Pitta', r.pittaScore, AppColors.pitta),
                                const SizedBox(height: 10),
                                _ScoreBar(
                                    'Kapha', r.kaphaScore, AppColors.kapha),
                              ])),
                          const SizedBox(height: 16),
                          _Section(
                              title: 'Bio-Acoustic Markers',
                              child: Row(children: [
                                Expanded(
                                    child: _MetricChip(
                                        icon: Icons.bar_chart_rounded,
                                        label: 'Pitch (Hz)',
                                        value: '${r.pitch}',
                                        color: AppColors.sattva)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _MetricChip(
                                        icon:
                                            Icons.radio_button_checked_rounded,
                                        label: 'Energy',
                                        value: '${r.energy}%',
                                        color: AppColors.rajas)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _MetricChip(
                                        icon: Icons.mic_rounded,
                                        label: 'Clarity',
                                        value: '${r.clarity}%',
                                        color: AppColors.tamas)),
                              ])),
                          const SizedBox(height: 16),
                          if (r.transcript != null && r.transcript!.isNotEmpty)
                            _Section(
                                title: 'Transcript',
                                child: Text(r.transcript!,
                                    style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 13,
                                        height: 1.5))),
                          if (r.transcript != null && r.transcript!.isNotEmpty)
                            const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [
                                    Icon(Icons.menu_book_rounded,
                                        size: 18, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text('PRESCRIBED INTERVENTION',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w600)),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(r.technique,
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text(r.prescription,
                                      style: const TextStyle(
                                          color: AppColors.foreground,
                                          fontSize: 14,
                                          height: 1.55)),
                                ]),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => HapticFeedback.mediumImpact(),
                                icon: Icon(_actionIcon(r.gunaState)),
                                label: Text(_actionLabel(r.gunaState)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                              )),
                          const SizedBox(height: 12),
                          SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.refresh_rounded,
                                    color: AppColors.mutedForeground),
                                label: const Text('Record Again',
                                    style: TextStyle(
                                        color: AppColors.mutedForeground)),
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: AppColors.border),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                              )),
                          const SizedBox(height: 32),
                        ]),
                      )),
                    ],
                  ))),
        ),
      ),
    );
  }

  String _pranaPranaLabel(String g) => g == 'Sattvic'
      ? 'Balanced Prana'
      : g == 'Rajasic'
          ? 'High Agitation'
          : 'Low Prana';
  IconData _gunaIcon(String g) => g == 'Sattvic'
      ? Icons.wb_sunny_rounded
      : g == 'Rajasic'
          ? Icons.bolt_rounded
          : Icons.nights_stay_rounded;
  String _actionLabel(String g) => g == 'Sattvic'
      ? 'Begin Dhyana Session'
      : g == 'Rajasic'
          ? 'Start Chanting Guide'
          : 'Start Breathing Timer';
  IconData _actionIcon(String g) => g == 'Sattvic'
      ? Icons.self_improvement_rounded
      : g == 'Rajasic'
          ? Icons.volume_up_rounded
          : Icons.timer_rounded;
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _ScoreBar extends StatefulWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreBar(this.label, this.score, this.color);
  @override
  State<_ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<_ScoreBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 300), _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
            width: 50,
            child: Text(widget.label,
                style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500))),
        Expanded(
            child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => LinearProgressIndicator(
              value: _anim.value,
              backgroundColor: AppColors.muted,
              color: widget.color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3)),
        )),
        const SizedBox(width: 8),
        SizedBox(
            width: 36,
            child: Text('${widget.score}%',
                style: TextStyle(
                    color: widget.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.right)),
      ]);
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _MetricChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.mutedForeground, fontSize: 11)),
        ]),
      );
}
