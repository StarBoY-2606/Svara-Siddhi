import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_theme.dart';
import 'screens/entry_screen.dart';
import 'screens/home_screen.dart';
import 'screens/practices_screen.dart';
import 'screens/history_screen.dart';
import 'screens/record_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SvaraSiddhiApp());
}

class SvaraSiddhiApp extends StatelessWidget {
  const SvaraSiddhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Svara-Siddhi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const EntryScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    _AnalyzeTab(),
    PracticesScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF120D28),
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) {
            HapticFeedback.lightImpact();
            setState(() => _tab = i);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedForeground,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.mic_rounded), label: 'Analyze'),
            BottomNavigationBarItem(
                icon: Icon(Icons.air_rounded), label: 'Practices'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded), label: 'History'),
          ],
        ),
      ),
    );
  }
}

class _AnalyzeTab extends StatefulWidget {
  const _AnalyzeTab();
  @override
  State<_AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<_AnalyzeTab> {
  String? _baseline;

  @override
  void initState() {
    super.initState();
    _loadBaseline();
  }

  Future<void> _loadBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _baseline = prefs.getString('guna_baseline'));
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
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),
              const Text('Analyze',
                  style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              const Text('Map your voice to the Triguna indices',
                  style: TextStyle(
                      color: AppColors.mutedForeground, fontSize: 14)),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  if (_baseline != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecordScreen(gunaBaseline: _baseline!),
                        )).then((_) => _loadBaseline());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Complete the VPI Assessment first (Home tab).'),
                      backgroundColor: AppColors.card,
                    ));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.4)),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        Colors.transparent
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.12),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.4),
                            width: 1.5),
                      ),
                      child: const Icon(Icons.mic_rounded,
                          color: AppColors.primary, size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('Voice Analysis',
                        style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      _baseline != null
                          ? 'Record 15–30 seconds and receive your real-time Guna reading.'
                          : 'Complete the VPI Assessment first, then analyze your voice.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                          height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.mic_rounded,
                            color: AppColors.primaryForeground, size: 18),
                        SizedBox(width: 8),
                        Text('Start Recording',
                            style: TextStyle(
                                color: AppColors.primaryForeground,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ]),
                    ),
                  ]),
                ),
              ),
              if (_baseline != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.sattva, size: 18),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VPI Baseline Active',
                              style: TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text(_baseline!,
                              style: TextStyle(
                                  color: AppColors.gunaColor(_baseline!),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ]),
                  ]),
                ),
              ],
              if (_baseline == null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                  child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('VPI Baseline Required',
                                  style: TextStyle(
                                      color: AppColors.foreground,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text(
                                  'The 8-question Vedic Personality Index calibrates the Random Forest model for your unique constitution.',
                                  style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 13,
                                      height: 1.4)),
                            ])),
                      ]),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
