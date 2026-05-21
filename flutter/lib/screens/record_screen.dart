import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../constants/app_theme.dart';
import '../services/api_service.dart';
import 'results_screen.dart';

class RecordScreen extends StatefulWidget {
  final String gunaBaseline;
  const RecordScreen({super.key, required this.gunaBaseline});
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

enum _RecordState { idle, recording, recorded, analyzing }

class _RecordScreenState extends State<RecordScreen>
    with TickerProviderStateMixin {
  final _recorder = AudioRecorder();
  _RecordState _state = _RecordState.idle;
  int _elapsed = 0;
  Timer? _timer;
  String? _recordedPath;
  String? _error;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _waveCtrl;

  final List<AnimationController> _waveCtrls = [];
  final List<Animation<double>> _waveAnims = [];
  static const int _numBars = 22;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.14)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    for (int i = 0; i < _numBars; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 200 + (i * 30) % 300),
      );
      final anim = Tween<double>(begin: 0.1, end: 0.9)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
      _waveCtrls.add(ctrl);
      _waveAnims.add(anim);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    for (final c in _waveCtrls) {
      c.dispose();
    }
    _recorder.dispose();
    super.dispose();
  }

  void _startWaveAnimation() {
    for (int i = 0; i < _numBars; i++) {
      Future.delayed(Duration(milliseconds: i * 40), () {
        if (mounted && _state == _RecordState.recording) {
          _waveCtrls[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopWaveAnimation() {
    for (final c in _waveCtrls) {
      c.stop();
    }
    for (int i = 0; i < _waveCtrls.length; i++) {
      _waveCtrls[i].animateTo(0.1, duration: const Duration(milliseconds: 300));
    }
  }

  Future<bool> _checkPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('Record permission check failed: $e');
      return false;
    }
  }

  Future<Directory> _resolveTemporaryDirectory() async {
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  Future<void> _startRecording() async {
    setState(() => _error = null);
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      setState(() => _error =
          'Microphone permission denied. Please enable it in Settings.');
      return;
    }
    try {
      try {
        final supported = await _recorder.isEncoderSupported(AudioEncoder.wav);
        if (!supported) {
          setState(() => _error =
              'WAV recording is not supported on this platform. Please run on a supported device.');
          return;
        }
      } catch (e) {
        debugPrint('Encoder support check failed (ignoring): $e');
      }

      final dir = await _resolveTemporaryDirectory();
      final path =
          '${dir.path}/svara_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      try {
        await _recorder.start(
            const RecordConfig(
                encoder: AudioEncoder.wav, sampleRate: 22050, numChannels: 1),
            path: path);
      } on UnsupportedError catch (e) {
        debugPrint('UnsupportedError while starting recorder: $e');
        setState(() => _error =
            'Recording is not supported on this platform or plugin version. Run the app on Android/iOS device.');
        return;
      } on PlatformException catch (e) {
        debugPrint('PlatformException while starting recorder: $e');
        setState(() => _error =
            'Recording failed due to platform error: ${e.message ?? e.code}');
        return;
      }
      setState(() {
        _state = _RecordState.recording;
        _elapsed = 0;
      });
      HapticFeedback.heavyImpact();
      _startWaveAnimation();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _elapsed++);
        if (_elapsed >= 30) _stopRecording();
      });
    } catch (e) {
      debugPrint('Start recording error: $e');
      final msg = e is UnsupportedError || e.toString().contains('_Namespace')
          ? 'Could not start recording: unsupported operation on this platform. Run on a physical Android or iOS device.'
          : 'Could not start recording: $e';
      setState(() => _error = msg);
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _stopWaveAnimation();
    try {
      final path = await _recorder.stop();
      HapticFeedback.mediumImpact();
      setState(() {
        _state = _RecordState.recorded;
        _recordedPath = path;
      });
    } catch (e) {
      setState(() {
        _state = _RecordState.idle;
        _error = 'Recording error: $e';
      });
    }
  }

  Future<void> _analyze() async {
    if (_recordedPath == null) return;
    setState(() {
      _state = _RecordState.analyzing;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final result = await ApiService().analyzeVoice(
        audioFile: File(_recordedPath!),
        gunaBaseline: widget.gunaBaseline,
      );
      if (mounted) {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ResultsScreen(result: result)));
        setState(() => _state = _RecordState.recorded);
      }
    } catch (e) {
      setState(() {
        _state = _RecordState.recorded;
        _error = 'Analysis failed: $e\n\nEnsure the FastAPI server is running.';
      });
    }
  }

  String _formatTime(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

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
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.foreground)),
                const Expanded(
                    child: Text('Voice Analysis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 17,
                            fontWeight: FontWeight.w600))),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(
                    _state == _RecordState.idle
                        ? 'Speak naturally for 15–30 seconds.\nShare what is on your mind.'
                        : _state == _RecordState.recording
                            ? 'Recording your Prana signature...'
                            : _state == _RecordState.recorded
                                ? 'Recording complete. Ready to analyze.'
                                : 'Analyzing your bio-acoustic patterns...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 15,
                        height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                      height: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(
                            _numBars,
                            (i) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: AnimatedBuilder(
                                    animation: _waveAnims[i],
                                    builder: (_, __) => Container(
                                      width: 4,
                                      height: 60 *
                                          (_state == _RecordState.recording
                                              ? _waveAnims[i].value
                                              : 0.12),
                                      decoration: BoxDecoration(
                                        color: _state == _RecordState.recording
                                            ? AppColors.primary
                                            : AppColors.mutedForeground
                                                .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                )),
                      )),
                  const SizedBox(height: 24),
                  Text(
                    _formatTime(_state == _RecordState.idle ? 0 : _elapsed),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2),
                  ),
                  if (_state != _RecordState.analyzing)
                    const Text('Max 30s',
                        style: TextStyle(
                            color: AppColors.mutedForeground, fontSize: 13)),
                  if (_state == _RecordState.analyzing) ...[
                    const SizedBox(height: 8),
                    const Text('Extracting MFCCs, Pitch & Energy...',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const Text('Computing Triguna indices via Random Forest',
                        style: TextStyle(
                            color: AppColors.mutedForeground, fontSize: 13)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ])),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: Column(children: [
                if (_state == _RecordState.idle)
                  ScaleTransition(
                      scale: _pulseAnim,
                      child: _RecordButton(
                          icon: Icons.mic_rounded,
                          color: AppColors.primary,
                          onTap: _startRecording)),
                if (_state == _RecordState.recording)
                  _RecordButton(
                      icon: Icons.stop_rounded,
                      color: AppColors.rajas,
                      onTap: _stopRecording),
                if (_state == _RecordState.analyzing)
                  Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 2)),
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2.5))),
                if (_state == _RecordState.idle)
                  const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Tap to begin recording',
                          style: TextStyle(
                              color: AppColors.mutedForeground, fontSize: 14))),
                if (_state == _RecordState.recorded) ...[
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _analyze,
                        icon: const Icon(Icons.bar_chart_rounded),
                        label: const Text('Analyze Voice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.primaryForeground,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      )),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _state = _RecordState.idle;
                      _elapsed = 0;
                      _recordedPath = null;
                    }),
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.mutedForeground, size: 18),
                    label: const Text('Re-record',
                        style: TextStyle(color: AppColors.mutedForeground)),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RecordButton(
      {required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4)
                ]),
            child: Icon(icon, color: Colors.white, size: 38)),
      );
}
