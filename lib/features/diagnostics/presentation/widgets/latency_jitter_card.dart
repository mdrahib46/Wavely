import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/services/ping_service.dart';

class LatencyJitterCard extends StatefulWidget {
  const LatencyJitterCard({super.key});

  @override
  State<LatencyJitterCard> createState() => _LatencyJitterCardState();
}

class _LatencyJitterCardState extends State<LatencyJitterCard> {
  final PingService _service = PingService();
  PingResult? _result;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    if (!mounted) return;
    setState(() => _testing = true);
    final res = await _service.measureLatencyAndJitter();
    if (!mounted) return;
    setState(() {
      _result = res;
      _testing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = _result ??
        const PingResult(
          lanLatencyMs: 3.2,
          wanLatencyMs: 24.5,
          jitterMs: 1.1,
          bufferbloatGrade: "A+",
          diagnosis: "Local link is optimal. Bottleneck is outside the LAN.",
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed, color: AppColors.emeraldBright, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'LATENCY & BUFFERBLOAT ISOLATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _testing ? null : _runTest,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      if (_testing)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.emerald),
                        )
                      else
                        const Icon(Icons.refresh, size: 14, color: AppColors.emeraldBright),
                      const SizedBox(width: 4),
                      Text(
                        _testing ? 'Pinging...' : 'Retest',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.emeraldBright,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 3-Column Split: Local Gateway vs WAN vs Jitter
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Router Hop (LAN)',
                  value: '${res.lanLatencyMs} ms',
                  grade: 'Clean',
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricPill(
                  label: 'Internet (WAN)',
                  value: '${res.wanLatencyMs} ms',
                  grade: 'ISP',
                  color: res.wanLatencyMs > 50 ? AppColors.amber : AppColors.emeraldBright,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricPill(
                  label: 'Jitter StdDev',
                  value: '±${res.jitterMs} ms',
                  grade: res.bufferbloatGrade,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Plain English Diagnosis
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.diagnosis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final String grade;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.grade,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Grade: $grade',
            style: const TextStyle(
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
