import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 7-Day Spending Breakdown with Peak Highlight
class WeeklyVelocityChart extends StatelessWidget {
  final List<double> inflows;
  final List<double> outflows;
  final String? peakLabel;
  final int? peakIndex;

  const WeeklyVelocityChart({
    super.key,
    this.inflows = const [25, 12, 15, 10, 50, 14, 8],
    this.outflows = const [18, 32, 22, 64, 28, 35, 12],
    this.peakLabel,
    this.peakIndex,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Find peak outflow index if not provided
    int calculatedPeak = 3;
    double maxOut = -1;
    for (int idx = 0; idx < outflows.length; idx++) {
      if (outflows[idx] > maxOut) {
        maxOut = outflows[idx];
        calculatedPeak = idx;
      }
    }
    final actualPeakIdx = peakIndex ?? calculatedPeak;
    final String label = peakLabel ?? (maxOut > 0 ? '${maxOut.toStringAsFixed(0)} ETB Peak' : 'Peak Flow');

    return Column(
      children: [
        // Chart Area with Tooltip
        SizedBox(
          height: 140,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Peak indicator tooltip
              if (maxOut > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.inverseSurface,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryFixed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.inverseOnSurface,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Grid lines and Bars
              Positioned(
                top: 26,
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  painter: _WeeklyVelocityPainter(
                    inflows: inflows,
                    outflows: outflows,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Day Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final isPeak = i == actualPeakIdx;
            return Text(
              days[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPeak ? FontWeight.bold : FontWeight.w500,
                color: isPeak ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _WeeklyVelocityPainter extends CustomPainter {
  final List<double> inflows;
  final List<double> outflows;

  _WeeklyVelocityPainter({required this.inflows, required this.outflows});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E7FF)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw horizontal guidelines
    for (double y = 0.2; y <= 0.9; y += 0.35) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        gridPaint,
      );
    }

    const barWidth = 7.0;
    final groupSpacing = size.width / 7;
    const maxVal = 70.0;

    for (int i = 0; i < 7; i++) {
      final centerX = groupSpacing * i + groupSpacing / 2;
      final inH = (inflows[i] / maxVal) * size.height;
      final outH = (outflows[i] / maxVal) * size.height;

      // Inflow bar (Mint / Secondary Container)
      final inPaint = Paint()
        ..color = AppColors.secondaryContainer
        ..style = PaintingStyle.fill;

      final inRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth - 1.5,
          size.height - inH,
          barWidth,
          inH,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(inRect, inPaint);

      // Outflow bar (Highland Teal / Primary)
      final outPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;

      if (i == 3) {
        // Thursday peak glow shadow
        final shadowPaint = Paint()
          ..color = AppColors.primary.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(centerX + 1.5, size.height - outH, barWidth + 1, outH),
            const Radius.circular(3),
          ),
          shadowPaint,
        );
      }

      final outRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + 1.5,
          size.height - outH,
          i == 3 ? barWidth + 1.5 : barWidth,
          outH,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(outRect, outPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyVelocityPainter oldDelegate) => true;
}

/// Category Donut Breakdown Chart with center metrics
class CategoryDonutChart extends StatelessWidget {
  final double totalAmount;
  final List<double> percentages;
  final List<Color> colors;

  const CategoryDonutChart({
    super.key,
    this.totalAmount = 47580.00,
    this.percentages = const [0.38, 0.22, 0.16, 0.10, 0.09, 0.05],
    this.colors = const [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiaryFixedDim,
      AppColors.primaryContainer,
      AppColors.primaryFixedDim,
      AppColors.surfaceContainerHighest,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 170,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(170, 170),
              painter: _DonutChartPainter(
                percentages: percentages,
                colors: colors,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  totalAmount.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]},',
                      ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'ETB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> percentages;
  final List<Color> colors;

  _DonutChartPainter({required this.percentages, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 20.0;

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFFEAEDFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < percentages.length; i++) {
      final sweepAngle = percentages[i] * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.04, // slight segment separation
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

/// Cumulative Net Balance Trend Curve with Area Gradient
class BalanceTrendChart extends StatelessWidget {
  final double startBalance;
  final double endBalance;

  const BalanceTrendChart({
    super.key,
    this.startBalance = 133430,
    this.endBalance = 148250,
  });

  @override
  Widget build(BuildContext context) {
    final diff = endBalance - startBalance;
    final pct = startBalance > 0 ? (diff / startBalance * 100) : 0.0;
    final pctStr = pct >= 0 ? '+${pct.toStringAsFixed(1)}%' : '${pct.toStringAsFixed(1)}%';

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _BalanceTrendPainter(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${startBalance.toStringAsFixed(0)} ETB',
                style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
              Text(
                'End: ${endBalance.toStringAsFixed(0)} ETB ($pctStr)',
                style: AppTypography.labelSmall.copyWith(
                  color: diff >= 0 ? AppColors.secondary : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.25, h * 0.65, w * 0.45, h * 0.45)
      ..quadraticBezierTo(w * 0.65, h * 0.50, w * 0.80, h * 0.25)
      ..quadraticBezierTo(w * 0.90, h * 0.15, w, h * 0.08);

    // Gradient Area Fill
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.24),
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke Line
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Peak Marker Dot
    final peakDotPaint = Paint()..color = AppColors.primary;
    final peakBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(w, h * 0.08), 5.0, peakDotPaint);
    canvas.drawCircle(Offset(w, h * 0.08), 5.0, peakBorderPaint);

    // Start Dot
    canvas.drawCircle(Offset(0, h * 0.82), 4.0, Paint()..color = AppColors.secondary);
    canvas.drawCircle(Offset(0, h * 0.82), 4.0, peakBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _BalanceTrendPainter oldDelegate) => false;
}

/// Calendar Expense Density Heatmap
class DailySpendingHeatmap extends StatelessWidget {
  final List<Txn> transactions;
  final DateTime? startDate;
  final int totalDays;

  const DailySpendingHeatmap({
    super.key,
    this.transactions = const [],
    this.startDate,
    this.totalDays = 31,
  });

  @override
  Widget build(BuildContext context) {
    const daysHeader = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final now = DateTime.now();
    final actualStart = startDate ?? DateTime(now.year, now.month, 1);
    final int leadingEmpty = (actualStart.weekday - 1) % 7; // Monday=1 -> 0 empty

    // Aggregate expense amount per day offset (1-based day)
    final Map<int, double> dayAmounts = {};
    for (final t in transactions) {
      if (!t.income && !t.isExcludedFromReports) {
        final diffDays = t.date.difference(DateTime(actualStart.year, actualStart.month, actualStart.day)).inDays + 1;
        if (diffDays >= 1 && diffDays <= totalDays) {
          dayAmounts[diffDays] = (dayAmounts[diffDays] ?? 0.0) + t.amount;
        }
      }
    }

    // Determine max spending day for heat thresholds
    double maxSpent = 0;
    for (final val in dayAmounts.values) {
      if (val > maxSpent) maxSpent = val;
    }

    final totalSlots = leadingEmpty + totalDays;
    final List<int?> gridSlots = List.generate(totalSlots, (index) {
      if (index < leadingEmpty) return null;
      return index - leadingEmpty + 1; // 1-based day
    });

    Color getHeatColor(int? dayNumber) {
      if (dayNumber == null) return const Color(0x1AEAEDFF);
      final spent = dayAmounts[dayNumber] ?? 0.0;
      if (spent == 0) return AppColors.surfaceContainer;
      if (maxSpent <= 0) return AppColors.surfaceContainer;
      final ratio = spent / maxSpent;
      if (ratio > 0.75) return AppColors.errorContainer;
      if (ratio > 0.45) return AppColors.tertiaryFixed;
      if (ratio > 0.20) return AppColors.primaryFixedDim;
      return AppColors.secondaryFixed;
    }

    return Column(
      children: [
        // Days of week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: daysHeader.map((d) {
            final isFri = d == 'F';
            return SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isFri ? FontWeight.bold : FontWeight.w500,
                    color: isFri ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        // Grid
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: gridSlots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final dayNumber = gridSlots[index];

            return Container(
              decoration: BoxDecoration(
                color: getHeatColor(dayNumber),
                borderRadius: BorderRadius.circular(6),
              ),
              child: dayNumber != null
                  ? Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: (dayAmounts[dayNumber] ?? 0) > 0 && maxSpent > 0 && (dayAmounts[dayNumber]! / maxSpent) > 0.75
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: (dayAmounts[dayNumber] ?? 0) > 0 && maxSpent > 0 && (dayAmounts[dayNumber]! / maxSpent) > 0.75
                              ? AppColors.error
                              : AppColors.onSurface,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}
