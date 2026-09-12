import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/wifi_network.dart';

class ChannelGraph extends StatelessWidget {
  final List<WifiNetwork> networks;
  final String activeBand;

  const ChannelGraph({
    super.key,
    required this.networks,
    required this.activeBand,
  });

  @override
  Widget build(BuildContext context) {
    final is5GHz = activeBand == "5 GHz";

    final filtered = networks.where((n) {
      if (activeBand == "Both") return true;
      return n.band == activeBand;
    }).toList();

    final minX = is5GHz ? 32.0 : 0.0;
    final maxX = is5GHz ? 168.0 : 14.0;
    final interval = is5GHz ? 16.0 : 2.0;

    return Container(
      height: 230,
      padding: const EdgeInsets.fromLTRB(10, 16, 16, 10),
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
              const Text(
                'RF SPECTRUM DISTRIBUTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '${filtered.length} BSSIDs Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.emeraldBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: -100,
                maxY: -30,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  verticalInterval: interval,
                  getDrawingHorizontalLine: (val) =>
                      const FlLine(color: AppColors.borderHairline, strokeWidth: 0.6),
                  getDrawingVerticalLine: (val) =>
                      const FlLine(color: AppColors.borderHairline, strokeWidth: 0.6),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      getTitlesWidget: (val, meta) {
                        if (val <= minX || val >= maxX) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Ch ${val.toInt()}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: filtered.map((net) => _createCurve(net, minX, maxX)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _createCurve(WifiNetwork net, double minX, double maxX) {
    final ch = net.channel.toDouble();
    final peak = net.rssi.toDouble();
    final isConnected = net.isConnected;
    final color = isConnected
        ? AppColors.emerald
        : (peak > -65 ? AppColors.emeraldBright : (peak > -75 ? AppColors.amber : AppColors.rose));

    final spread = net.band == "5 GHz" ? 4.0 : 2.0;

    return LineChartBarData(
      spots: [
        FlSpot((ch - spread).clamp(minX, maxX), -100),
        FlSpot(ch.clamp(minX, maxX), peak.clamp(-100, -30)),
        FlSpot((ch + spread).clamp(minX, maxX), -100),
      ],
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: isConnected ? 2.8 : 1.6,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: isConnected ? 0.28 : 0.09),
      ),
    );
  }
}
