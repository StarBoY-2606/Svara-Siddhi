import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../models/analysis_result.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AnalysisResult> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('history') ?? [];
    setState(() {
      _history = raw
          .map((s) =>
              AnalysisResult.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      _loading = false;
    });
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Clear History',
                  style: TextStyle(color: AppColors.foreground)),
              content: const Text(
                  'This will permanently delete all session records.',
                  style: TextStyle(color: AppColors.mutedForeground)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.mutedForeground))),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear All',
                        style: TextStyle(color: Colors.redAccent))),
              ],
            ));
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('history');
      setState(() => _history = []);
    }
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
              end: Alignment.bottomCenter),
        ),
        child: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(children: [
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('History',
                          style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 26,
                              fontWeight: FontWeight.w700)),
                      Text('Your Guna journey over time',
                          style: TextStyle(
                              color: AppColors.mutedForeground, fontSize: 14)),
                    ]),
                const Spacer(),
                if (_history.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.mutedForeground),
                    label: const Text('Clear',
                        style: TextStyle(
                            color: AppColors.mutedForeground, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
              ])),
          if (_loading)
            const Expanded(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_history.isEmpty)
            Expanded(
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.card,
                      border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.history_rounded,
                      color: AppColors.mutedForeground, size: 36)),
              const SizedBox(height: 16),
              const Text('No Sessions Yet',
                  style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                      'Complete a voice analysis to start tracking your Guna journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                          height: 1.5))),
            ])))
          else
            Expanded(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                  _SummaryCard(history: _history),
                  const SizedBox(height: 16),
                  for (int i = 0; i < _history.length; i++) ...[
                    if (i == 0 ||
                        !_sameDay(
                            _history[i].timestamp, _history[i - 1].timestamp))
                      Padding(
                          padding:
                              EdgeInsets.only(bottom: 8, top: i == 0 ? 0 : 12),
                          child: Text(_dateLabel(_history[i].timestamp),
                              style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1))),
                    _HistoryItem(
                        item: _history[i],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ResultsScreen(result: _history[i])))),
                    const SizedBox(height: 8),
                  ],
                ])),
        ])),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return DateFormat('EEEE').format(dt).toUpperCase();
    return DateFormat('MMM d').format(dt).toUpperCase();
  }
}

class _SummaryCard extends StatelessWidget {
  final List<AnalysisResult> history;
  const _SummaryCard({required this.history});
  @override
  Widget build(BuildContext context) {
    final counts = {'Sattvic': 0, 'Rajasic': 0, 'Tamasic': 0};
    for (final r in history) {
      counts[r.gunaState] = (counts[r.gunaState] ?? 0) + 1;
    }
    final dominant =
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final avgS = (history.map((r) => r.sattvicScore).reduce((a, b) => a + b) /
            history.length)
        .round();
    final avgR = (history.map((r) => r.rajasicScore).reduce((a, b) => a + b) /
            history.length)
        .round();
    final avgT = (history.map((r) => r.tamasicScore).reduce((a, b) => a + b) /
            history.length)
        .round();
    final color = AppColors.gunaColor(dominant);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4))),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DOMINANT GUNA',
              style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(dominant,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w700)),
          Text('${history.length} session${history.length != 1 ? 's' : ''}',
              style: const TextStyle(
                  color: AppColors.mutedForeground, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('AVG INDEX',
              style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('S $avgS%',
              style: const TextStyle(
                  color: AppColors.sattva,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          Text('R $avgR%',
              style: const TextStyle(
                  color: AppColors.rajas,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          Text('T $avgT%',
              style: const TextStyle(
                  color: AppColors.tamas,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final AnalysisResult item;
  final VoidCallback onTap;
  const _HistoryItem({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = AppColors.gunaColor(item.gunaState);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                  item.gunaState == 'Sattvic'
                      ? Icons.wb_sunny_rounded
                      : item.gunaState == 'Rajasic'
                          ? Icons.bolt_rounded
                          : Icons.nights_stay_rounded,
                  color: color,
                  size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.gunaState,
                    style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Text(item.technique,
                    style: const TextStyle(
                        color: AppColors.mutedForeground, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Text('S ${item.sattvicScore}%',
                      style: const TextStyle(
                          color: AppColors.sattva,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const Text('  ·  ',
                      style: TextStyle(color: AppColors.border)),
                  Text('R ${item.rajasicScore}%',
                      style: const TextStyle(
                          color: AppColors.rajas,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const Text('  ·  ',
                      style: TextStyle(color: AppColors.border)),
                  Text('T ${item.tamasicScore}%',
                      style: const TextStyle(
                          color: AppColors.tamas,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(DateFormat('h:mm a').format(item.timestamp),
                style: const TextStyle(
                    color: AppColors.mutedForeground, fontSize: 11)),
            const SizedBox(height: 4),
            Text('${item.pitch}Hz',
                style: const TextStyle(
                    color: AppColors.mutedForeground, fontSize: 11)),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.mutedForeground, size: 18),
          ]),
        ]),
      ),
    );
  }
}
