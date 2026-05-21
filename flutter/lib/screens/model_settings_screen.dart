import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/api_service.dart';

class ModelSettingsScreen extends StatefulWidget {
  const ModelSettingsScreen({super.key});

  @override
  State<ModelSettingsScreen> createState() => _ModelSettingsScreenState();
}

class _ModelSettingsScreenState extends State<ModelSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _statusData = {};
  Timer? _statusTimer;
  int _selectedActors = 6; // Default to fast mode (6 actors)

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_statusData['training_active'] == true) {
        _fetchStatus(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final status = await _apiService.getModelStatus();
      if (mounted) {
        setState(() {
          _statusData = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to connect to ML server: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startRetraining() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await _apiService.retrainModel(maxActors: _selectedActors);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ??
                'Training job started in the background.'),
            backgroundColor: AppColors.sattva,
          ),
        );
      }
      await _fetchStatus(silent: true);
    } catch (e) {
      setState(() {
        _error = 'Failed to initiate retraining: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _statusData['training_active'] ?? false;
    final double progress = (_statusData['progress'] ?? 0.0) / 100.0;
    final String message = _statusData['message'] ?? 'Model is idle';
    final String statusStr = _statusData['status'] ?? 'idle';

    final metadata = _statusData['metadata'] ?? {};
    final String modelType = metadata['model_type'] ?? 'synthetic';
    final double accuracy = metadata['accuracy'] ?? 0.98;
    final int samples = metadata['samples'] ?? 1800;
    final int actors = metadata['actors_trained'] ?? 0;
    final String timestamp = metadata['timestamp'] ?? 'N/A';
    final String description =
        metadata['description'] ?? 'Using synthetic bio-acoustic patterns.';

    final List<dynamic> importances = metadata['feature_importances'] ?? [];
    final Map<String, dynamic> metrics = metadata['metrics'] ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bio-Acoustic ML Engine',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.foreground)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0820), Color(0xFF160D35), Color(0xFF0D0820)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => _fetchStatus(),
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: _isLoading && _statusData.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) _buildErrorCard(),
                      _buildModelStatusHeader(
                          modelType, active, statusStr, timestamp),
                      const SizedBox(height: 20),
                      if (active)
                        _buildActiveTrainingProgress(
                            progress, message, statusStr)
                      else
                        _buildRetrainingCard(modelType),
                      const SizedBox(height: 24),
                      _buildMetricsGrid(accuracy, samples, actors, modelType),
                      const SizedBox(height: 24),
                      if (importances.isNotEmpty) ...[
                        _buildFeatureImportances(importances),
                        const SizedBox(height: 24),
                      ],
                      if (metrics.isNotEmpty) ...[
                        _buildMetricsBreakdown(metrics),
                        const SizedBox(height: 24),
                      ],
                      _buildFooterDescription(description),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1018),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelStatusHeader(
      String modelType, bool active, String statusStr, String timestamp) {
    final isRavdess = modelType == 'ravdess';
    final Color modelColor = isRavdess ? AppColors.sattva : AppColors.rajas;
    final String label =
        isRavdess ? 'RAVDESS SCIENTIFIC CLASSIFIER' : 'SYNTHETIC RANDOM FOREST';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                active ? AppColors.primary.withOpacity(0.5) : AppColors.border),
        boxShadow: [
          if (isRavdess)
            BoxShadow(
              color: AppColors.sattva.withOpacity(0.05),
              blurRadius: 16,
              spreadRadius: 2,
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: modelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                      color: modelColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? Colors.amber
                          : (isRavdess ? AppColors.sattva : Colors.cyan),
                      boxShadow: [
                        BoxShadow(
                          color: (active
                                  ? Colors.amber
                                  : (isRavdess
                                      ? AppColors.sattva
                                      : Colors.cyan))
                              .withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    active ? 'Retraining...' : 'Ready',
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.amber : AppColors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isRavdess ? 'RAVDESS Speech Engine' : 'Svara-Siddhi Base Model',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground),
          ),
          const SizedBox(height: 6),
          Text(
            isRavdess
                ? 'Trained on professional vocal audio logs.'
                : 'Utilizing standard synthesized yogic bio-markers.',
            style:
                const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
          const Divider(height: 24, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calibration Date:',
                style:
                    TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
              Text(
                timestamp,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTrainingProgress(
      double progress, String message, String statusStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Processing Dataset Pipeline: ${statusStr.toUpperCase()}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetrainingCard(String modelType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_rounded,
                  color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text(
                'Upgrade Model with RAVDESS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.foreground),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Calibrate the engine using the Ryerson Audio-Visual Database of Emotional Speech and Song. The server will download the dataset (248MB) and process high-fidelity emotional bio-markers to train a high-accuracy Guna classification model.',
            style: TextStyle(
                fontSize: 12, color: AppColors.mutedForeground, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Training Depth (Actor set limits):',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildActorRadioOption(6, '6 Actors', 'Fast (1 min)'),
              const SizedBox(width: 8),
              _buildActorRadioOption(12, '12 Actors', 'Medium (2 mins)'),
              const SizedBox(width: 8),
              _buildActorRadioOption(24, '24 Actors', 'Full Set (5 mins)'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startRetraining,
              icon: const Icon(Icons.rocket_launch_rounded),
              label: Text(modelType == 'ravdess'
                  ? 'Re-Calibrate RAVDESS Model'
                  : 'Train RAVDESS Classifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActorRadioOption(int count, String label, String sub) {
    final isSelected = _selectedActors == count;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedActors = count;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
      double accuracy, int samples, int actors, String modelType) {
    final hasActors = modelType == 'ravdess' && actors > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scientific Metrics',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            _buildMetricGridCard(
                'MODEL ACCURACY',
                '${(accuracy * 100).toStringAsFixed(1)}%',
                Icons.check_circle_outline_rounded,
                AppColors.sattva),
            _buildMetricGridCard('DATASET SIZE', '$samples samples',
                Icons.folder_open_rounded, Colors.cyan),
            _buildMetricGridCard('BIO-MARKERS', '17 Indicators',
                Icons.analytics_outlined, Colors.purpleAccent),
            _buildMetricGridCard(
              'TRAINED ON',
              hasActors ? '$actors Actors' : 'Synthetic Data',
              Icons.people_alt_outlined,
              hasActors ? AppColors.primary : AppColors.mutedForeground,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricGridCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureImportances(List<dynamic> importances) {
    double maxVal = 0.01;
    for (var item in importances) {
      final double val = item['importance'] ?? 0.0;
      if (val > maxVal) maxVal = val;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Text(
                'Top Bio-Acoustic Voice Markers',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.foreground),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Calculated based on Guna correlations from the RAVDESS training set:',
            style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: importances.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = importances[index];
              final String name = item['feature'] ?? 'Marker';
              final double value = item['importance'] ?? 0.0;
              final double percentOfMax = value / maxVal;

              String displayName = name;
              if (name == 'Pitch (F0)') {
                displayName = 'Vocal Pitch (F0)';
              } else if (name == 'RMS Energy')
                displayName = 'Vocal Intensity (RMS)';
              else if (name == 'Spectral Centroid')
                displayName = 'Acoustic Brightness';
              else if (name == 'ZCR')
                displayName = 'Speech Clarity (ZCR)';
              else if (name.startsWith('MFCC_'))
                displayName = 'Timbre Texture (${name.replaceAll('_', ' ')})';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.foreground)),
                      Text('${(value * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentOfMax,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.5),
                              AppColors.primary
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBreakdown(Map<String, dynamic> metrics) {
    final List<String> gunas = ['Sattvic', 'Rajasic', 'Tamasic'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Text(
                'Guna Classifier Performance',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.foreground),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gunas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final String guna = gunas[index];
              final gunaData = metrics[guna] ??
                  {'precision': 1.0, 'recall': 1.0, 'f1-score': 1.0};
              final Color color = AppColors.gunaColor(guna);

              final double f1 = gunaData['f1-score'] ?? 1.0;
              final double precision = gunaData['precision'] ?? 1.0;
              final double recall = gunaData['recall'] ?? 1.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(guna,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      const Spacer(),
                      Text('F1: ${(f1 * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.foreground)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMetricBar('Precision', precision),
                      const SizedBox(width: 16),
                      _buildMetricBar('Recall', recall),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, double val) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.mutedForeground)),
              Text('${(val * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mutedForeground)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: val,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.mutedForeground.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterDescription(String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        desc,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
            height: 1.5,
            fontStyle: FontStyle.italic),
      ),
    );
  }
}
