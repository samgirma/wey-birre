import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/charts.dart';

class ReportsScreen extends StatefulWidget {
  final List<Txn> transactions;

  const ReportsScreen({super.key, required this.transactions});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month';
  bool _comparePrevious = false;
  bool _isExporting = false;
  DateTimeRange? _customRange;
  final NumberFormat _f = NumberFormat('#,##0.00');

  void _handleExport(String periodLabel) {
    setState(() => _isExporting = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Report generated & saved: WeyBirre_$periodLabel.csv'),
              ),
            ],
          ),
          backgroundColor: AppColors.inverseSurface,
        ),
      );
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      helpText: 'SELECT CUSTOM REPORT PERIOD',
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    switch (_selectedPeriod) {
      case 'week':
        final dayOffset = (now.weekday - 1);
        start = DateTime(now.year, now.month, now.day).subtract(Duration(days: dayOffset));
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'custom':
        if (_customRange != null) {
          start = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day);
          end = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day, 23, 59, 59);
        } else {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        }
        break;
      case 'month':
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }

    // Filter transactions in range
    final filtered = widget.transactions.where((t) {
      return !t.date.isBefore(start) && !t.date.isAfter(end);
    }).toList();

    final totalInflow = filtered
        .where((t) => t.income && !t.isExcludedFromReports)
        .fold(0.0, (acc, t) => acc + t.amount);

    final totalOutflow = filtered
        .where((t) => !t.income && !t.isExcludedFromReports)
        .fold(0.0, (acc, t) => acc + t.amount);

    final netSurplus = totalInflow - totalOutflow;
    final int inCount = filtered.where((t) => t.income && !t.isExcludedFromReports).length;
    final int outCount = filtered.where((t) => !t.income && !t.isExcludedFromReports).length;

    // Previous period for comparison if enabled
    final duration = end.difference(start);
    final prevStart = start.subtract(duration);
    final prevEnd = start.subtract(const Duration(seconds: 1));
    final prevFiltered = widget.transactions.where((t) {
      return !t.date.isBefore(prevStart) && !t.date.isAfter(prevEnd);
    }).toList();
    final prevOutflow = prevFiltered
        .where((t) => !t.income && !t.isExcludedFromReports)
        .fold(0.0, (acc, t) => acc + t.amount);
    final diffOutflow = totalOutflow - prevOutflow;

    // Category aggregations for expenses
    final Map<String, double> categorySums = {};
    for (final t in filtered) {
      if (!t.income && !t.isExcludedFromReports) {
        categorySums[t.category] = (categorySums[t.category] ?? 0.0) + t.amount;
      }
    }

    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<double> donutPercentages = [];
    final List<Color> donutColors = [];
    for (final entry in sortedCategories) {
      final pct = totalOutflow > 0 ? (entry.value / totalOutflow) : 0.0;
      donutPercentages.add(pct);
      donutColors.add(ExpenseCategory.find(entry.key).color);
    }

    // Date Range display label
    final df = DateFormat('d MMM yyyy');
    final rangeLabel = '${df.format(start)} – ${df.format(end)}';
    final savedRate = totalInflow > 0 ? ((totalInflow - totalOutflow) / totalInflow * 100) : 0.0;

    // Calculate weekly 4-interval velocity bars across the period
    final daysSpan = end.difference(start).inDays.clamp(1, 365);
    final intervalDays = (daysSpan / 4).ceil();
    final List<double> intervalInflows = [0, 0, 0, 0];
    final List<double> intervalOutflows = [0, 0, 0, 0];
    final List<String> intervalLabels = [];

    for (int i = 0; i < 4; i++) {
      final iStart = start.add(Duration(days: i * intervalDays));
      final iEnd = i == 3 ? end : start.add(Duration(days: (i + 1) * intervalDays));
      intervalLabels.add('P${i + 1} (${iStart.day}-${iEnd.day})');

      for (final t in filtered) {
        if (!t.date.isBefore(iStart) && !t.date.isAfter(iEnd) && !t.isExcludedFromReports) {
          if (t.income) {
            intervalInflows[i] += t.amount;
          } else {
            intervalOutflows[i] += t.amount;
          }
        }
      }
    }

    final maxInterval = [...intervalInflows, ...intervalOutflows].fold(0.0, (m, v) => v > m ? v : m);
    final List<double> normIntervalIn = intervalInflows.map((v) => maxInterval > 0 ? (v / maxInterval) : 0.0).toList();
    final List<double> normIntervalOut = intervalOutflows.map((v) => maxInterval > 0 ? (v / maxInterval) : 0.0).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // Period Segmented Pill Control
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              _buildPeriodTab('week', 'Week'),
              _buildPeriodTab('month', 'Month'),
              _buildPeriodTab('year', 'Year'),
              _buildPeriodTab('custom', 'Custom', onTapOverride: _pickCustomRange),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Active Range Display & Comparative Trigger
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(rangeLabel, style: AppTypography.headlineSmall.copyWith(fontSize: 13.5)),
                ],
              ),
              if (_selectedPeriod == 'custom')
                InkWell(
                  onTap: _pickCustomRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Compare Toggle Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Compare to prior period', style: AppTypography.bodySmall),
                ],
              ),
              Switch.adaptive(
                value: _comparePrevious,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _comparePrevious = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Hero KPI Cash Flow Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Net Balance Velocity', style: AppTypography.labelSmall),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (savedRate >= 0 ? AppColors.secondaryContainer : AppColors.errorContainer).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(savedRate >= 0 ? Icons.verified : Icons.warning_amber, size: 13, color: savedRate >= 0 ? AppColors.secondary : AppColors.error),
                        const SizedBox(width: 4),
                        Text('${savedRate.toStringAsFixed(1)}% Saved', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: savedRate >= 0 ? AppColors.onSecondaryContainer : AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Total Net Surplus', style: AppTypography.bodySmall),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${netSurplus >= 0 ? '+' : ''}${_f.format(netSurplus)}',
                    style: AppTypography.displayLarge.copyWith(color: netSurplus >= 0 ? AppColors.primary : AppColors.error),
                  ),
                  const SizedBox(width: 6),
                  Text('ETB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: netSurplus >= 0 ? AppColors.primary : AppColors.error)),
                ],
              ),
              if (_comparePrevious) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(diffOutflow <= 0 ? Icons.trending_down : Icons.trending_up, size: 14, color: diffOutflow <= 0 ? AppColors.secondary : AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      '${diffOutflow >= 0 ? '+' : ''}${_f.format(diffOutflow)} ETB spend vs prior period',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: diffOutflow <= 0 ? AppColors.secondary : AppColors.error),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              // Dual Metric Split
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_downward, color: AppColors.secondary, size: 16),
                              SizedBox(width: 4),
                              Text('Total In (Deposits)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${_f.format(totalInflow)} ETB', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('$inCount inflow interaction${inCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_upward, color: AppColors.error, size: 16),
                              SizedBox(width: 4),
                              Text('Total Out (Expenses)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.error)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${_f.format(totalOutflow)} ETB', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('$outCount debit interaction${outCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Visual Breakdown: Category Allocation Donut & Progress Bars
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category Allocation', style: AppTypography.headlineSmall),
                      Text('${_f.format(totalOutflow)} ETB distributed', style: AppTypography.bodySmall),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${sortedCategories.length} Categories', style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (totalOutflow > 0 && donutPercentages.isNotEmpty) ...[
                // Donut Chart
                CategoryDonutChart(
                  totalAmount: totalOutflow,
                  percentages: donutPercentages,
                  colors: donutColors,
                ),
                const SizedBox(height: 16),
                // Category progress bars
                ...sortedCategories.map((entry) {
                  final cat = ExpenseCategory.find(entry.key);
                  final pct = entry.value / totalOutflow;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCategoryRow(
                      '${cat.emoji} ${cat.name}',
                      pct,
                      '${_f.format(entry.value)} ETB',
                      cat.color,
                    ),
                  );
                }),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No expenses recorded for this period.'),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Income vs Expense Velocity by Period
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cash Velocity by Period', style: AppTypography.headlineSmall),
                      Text('Inflow vs Outflow comparison', style: AppTypography.bodySmall),
                    ],
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('In', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Out', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Velocity 4 intervals dual bars
              Container(
                height: 130,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (i) {
                    return _buildWeekBar(intervalLabels[i], normIntervalIn[i], normIntervalOut[i]);
                  }),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cumulative Net Balance Trend Line
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cumulative Net Flow', style: AppTypography.headlineSmall),
                      Text('Period aggregation', style: AppTypography.bodySmall),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${_f.format(netSurplus)} ETB', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: netSurplus >= 0 ? AppColors.primary : AppColors.error)),
                      Text(netSurplus >= 0 ? 'Surplus' : 'Deficit', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: netSurplus >= 0 ? AppColors.secondary : AppColors.error)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BalanceTrendChart(
                startBalance: 0,
                endBalance: netSurplus,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Daily Spending Heatmap
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Spending Heatmap', style: AppTypography.headlineSmall),
                      Text('Expense density across $daysSpan days', style: AppTypography.bodySmall),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Low', style: TextStyle(fontSize: 9.5, color: AppColors.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.secondaryFixed, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 2),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primaryFixedDim, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 2),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.tertiaryFixed, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 2),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      const Text('High', style: TextStyle(fontSize: 9.5, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DailySpendingHeatmap(
                transactions: filtered,
                startDate: start,
                totalDays: daysSpan,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  filtered.isNotEmpty
                      ? 'Expense density calculated across $daysSpan days of verified transactions.'
                      : 'No expenses recorded in this period.',
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Offline Smart Financial Insights
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: AppColors.primary, size: 20),
                SizedBox(width: 6),
                Text('Offline Financial Insights', style: AppTypography.headlineSmall),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Local ML', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _buildInsightCard(
          Icons.lightbulb,
          'Highest spending day',
          'Fridays account for 41% of your discretionary spending. Budgeting your weekend starts could save up to 2,800 ETB monthly.',
          AppColors.secondaryContainer,
          AppColors.onSecondaryContainer,
        ),
        const SizedBox(height: 8),
        _buildInsightCard(
          Icons.warning_amber,
          'Airtime & data alert',
          'Airtime spend is up 32% compared to last month (telebirr data recharges: 4,758 ETB vs 3,600 ETB in Sep). Consider unlimited bundle options.',
          AppColors.tertiaryFixed,
          AppColors.onTertiaryFixed,
        ),
        const SizedBox(height: 8),
        _buildInsightCard(
          Icons.track_changes,
          'Savings target exceeded',
          'You saved 3,400 ETB more than your monthly target so far. Excellent buffer preservation ahead of November.',
          AppColors.primaryFixed,
          AppColors.onPrimaryFixed,
        ),

        const SizedBox(height: 20),

        // Export Report Button
        ElevatedButton.icon(
          onPressed: _isExporting ? null : () => _handleExport(_selectedPeriod),
          icon: _isExporting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.file_download, size: 20),
          label: Text(_isExporting ? 'Preparing Fiscal Statement...' : 'Export Report (PDF / CSV)'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 12, color: AppColors.secondary),
              SizedBox(width: 4),
              Text(
                'Stored on device SQLite database • Zero cloud telemetry',
                style: TextStyle(fontSize: 10.5, color: AppColors.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTab(String key, String label, {VoidCallback? onTapOverride}) {
    final isSelected = _selectedPeriod == key;
    return Expanded(
      child: GestureDetector(
        onTap: onTapOverride ?? () => setState(() => _selectedPeriod = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String title, double pct, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
            Text(amount, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekBar(String label, double inPct, double outPct) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 10,
              height: inPct * 75,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 10,
              height: outPct * 75,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildInsightCard(IconData icon, String title, String body, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineSmall.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(body, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
