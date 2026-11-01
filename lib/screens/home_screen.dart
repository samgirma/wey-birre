import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/charts.dart';
import '../widgets/meskel_watermark.dart';
import '../widgets/transaction_detail_sheet.dart';

class HomeScreen extends StatefulWidget {
  final List<Txn> transactions;
  final VoidCallback onSyncSms;
  final bool isSyncing;
  final String userName;
  final VoidCallback onSeeAllTransactions;
  final Function(Txn) onUpdateTxn;
  final Function(String) onDeleteTxn;

  const HomeScreen({
    super.key,
    required this.transactions,
    required this.onSyncSms,
    required this.isSyncing,
    this.userName = 'Friend',
    required this.onSeeAllTransactions,
    required this.onUpdateTxn,
    required this.onDeleteTxn,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceHidden = false;
  late DateTime _selectedMonth;
  final NumberFormat _f = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT MONTH & YEAR',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    // Filter transactions by selected month
    final monthlyTxns = widget.transactions
        .where((t) => t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month)
        .toList();

    final inflowVal = monthlyTxns
        .where((t) => t.income && !t.isExcludedFromReports)
        .fold(0.0, (acc, t) => acc + t.amount);

    final outflowVal = monthlyTxns
        .where((t) => !t.income && !t.isExcludedFromReports)
        .fold(0.0, (acc, t) => acc + t.amount);

    final monthNet = inflowVal - outflowVal;

    // Lifetime balance from latest bank balances or overall transactions sum
    final accounts = Db.getAccountsSummary(widget.transactions);
    final totalAccountsBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);
    final netBalance = totalAccountsBalance > 0
        ? totalAccountsBalance
        : widget.transactions.fold(0.0, (sum, t) => sum + (t.income ? t.amount : -t.amount));

    final recent = widget.transactions.take(5).toList();

    // 7-day velocity for Mon-Sun of current/selected month
    final startOfVelocity = isCurrentMonth
        ? DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday - 1)))
        : DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final velocityInflows = List<double>.filled(7, 0.0);
    final velocityOutflows = List<double>.filled(7, 0.0);

    for (final t in monthlyTxns) {
      final diff = t.date.difference(startOfVelocity).inDays;
      if (diff >= 0 && diff < 7) {
        if (t.income) {
          velocityInflows[diff] += t.amount;
        } else {
          velocityOutflows[diff] += t.amount;
        }
      }
    }

    // Check if there is any real activity in velocity
    final maxVelocity = [...velocityInflows, ...velocityOutflows].fold(0.0, (m, v) => v > m ? v : m);
    // Normalized 0-70 scale for the painter if values are large
    final scale = maxVelocity > 70 ? (70.0 / maxVelocity) : 1.0;
    final scaledInflows = velocityInflows.map((v) => v * scale).toList();
    final scaledOutflows = velocityOutflows.map((v) => v * scale).toList();

    final monthTitle = DateFormat('MMMM yyyy').format(_selectedMonth);
    final monthShort = DateFormat('MMM').format(_selectedMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // Greeting & Quick Status Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Selam, ${widget.userName}', style: AppTypography.headlineLarge),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    InkWell(
                      onTap: _pickMonth,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              monthTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppColors.outlineVariant)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Auto-read SMS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
            ),

            // Parse SMS Action Button
            ElevatedButton.icon(
              onPressed: widget.isSyncing ? null : widget.onSyncSms,
              icon: widget.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.isSyncing ? 'Scanning...' : 'Parse SMS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Text('100% Offline', style: TextStyle(fontSize: 8.5, color: AppColors.onPrimaryContainer)),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Hero Total Balance Card (Teal Surface with Meskel Motif & Per-Bank Breakdown)
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryContainer,
                AppColors.primary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Meskel Watermark in bottom right
              const Positioned(
                right: -24,
                bottom: -32,
                child: MeskelWatermark(size: 190, opacity: 0.08),
              ),

              // Encrypted Local DB Badge
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: AppColors.secondaryFixed),
                      SizedBox(width: 4),
                      Text(
                        'Encrypted Local DB',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Balance & Details Content
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 54),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'NET LIQUID WORTH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: AppColors.onPrimaryContainer.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                          child: Icon(
                            _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.onPrimaryContainer,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _isBalanceHidden ? '••••••••' : _f.format(netBalance),
                          style: AppTypography.displayLarge.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ETB',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryFixed,
                          ),
                        ),
                      ],
                    ),

                    // Dynamic Per-Bank / Per-Wallet Breakdown Pills
                    if (accounts.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: accounts.map((acc) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: acc.institution.dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    acc.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isBalanceHidden ? '••••' : '${_f.format(acc.balance)} ETB',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Trend Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  color: Colors.black.withOpacity(0.12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (monthNet >= 0 ? AppColors.secondaryFixed : AppColors.errorContainer).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              monthNet >= 0 ? Icons.trending_up : Icons.trending_down,
                              size: 14,
                              color: monthNet >= 0 ? AppColors.secondaryFixed : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${monthNet >= 0 ? '+' : ''}${_f.format(monthNet)} ETB ($monthShort)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: monthNet >= 0 ? AppColors.secondaryFixed : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.account_balance, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            accounts.isNotEmpty
                                ? '${accounts.length} active institution${accounts.length == 1 ? '' : 's'}'
                                : (monthlyTxns.isNotEmpty ? '${monthlyTxns.length} records' : 'No activity'),
                            style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Inflow & Outflow Summary Tiles
        Row(
          children: [
            // Deposits Inflow Tile
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_downward, color: AppColors.secondary, size: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${monthlyTxns.where((t) => t.income).length} in',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Inflow ($monthShort)', style: AppTypography.labelSmall),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(_f.format(inflowVal), style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Text('ETB', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Withdrawals Outflow Tile
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_upward, color: AppColors.error, size: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${monthlyTxns.where((t) => !t.income).length} out',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Spent ($monthShort)', style: AppTypography.labelSmall),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(_f.format(outflowVal), style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Text('ETB', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 7-Day Spending Breakdown (Weekly Velocity)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
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
                      Text('Weekly Velocity', style: AppTypography.headlineSmall),
                      Text('Daily cash flows (Mon - Sun)', style: AppTypography.bodySmall),
                    ],
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Spent', style: TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Added', style: TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              WeeklyVelocityChart(
                inflows: scaledInflows,
                outflows: scaledOutflows,
                peakLabel: maxVelocity > 0 ? '${maxVelocity.toStringAsFixed(0)} ETB Peak' : '0 ETB',
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Connected Vaults & Accounts Carousel
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Vaults & Accounts', style: AppTypography.headlineSmall),
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${accounts.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: widget.onSeeAllTransactions,
              child: const Text('Manage', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final acc = accounts[i];
              return Container(
                width: 230,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: acc.institution.bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(acc.institution.iconData, size: 18, color: acc.institution.textColor),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(acc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(acc.subtext, style: const TextStyle(fontSize: 9.5, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${acc.messageCount} SMS', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.onSecondaryFixed)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_f.format(acc.balance), style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Text('ETB', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(acc.note, style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
                            Text(
                              acc.trendLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: acc.isTrendPositive ? AppColors.secondary : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 22),

        // Recent Transactions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Transactions', style: AppTypography.headlineSmall),
                Text('Parsed straight from offline bank alerts', style: AppTypography.bodySmall),
              ],
            ),
            TextButton.icon(
              onPressed: widget.onSeeAllTransactions,
              label: const Text('See all', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Recent Transactions List Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: recent.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text('No transactions recorded yet. Tap "Parse SMS" or "Add Cash".'),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF2F3FF)),
                  itemBuilder: (context, i) {
                    final t = recent[i];
                    final cat = ExpenseCategory.find(t.category);
                    final df = DateFormat('d MMM, HH:mm');

                    return ListTile(
                      onTap: () {
                        TransactionDetailSheet.show(
                          context,
                          txn: t,
                          onUpdate: widget.onUpdateTxn,
                          onDelete: () => widget.onDeleteTxn(t.key),
                        );
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.income ? AppColors.secondaryContainer.withOpacity(0.3) : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          cat.icon,
                          size: 20,
                          color: t.income ? AppColors.secondary : AppColors.onSurfaceVariant,
                        ),
                      ),
                      title: Text(t.merchant, style: AppTypography.headlineSmall.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: t.institution.bgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(t.institution.shortCode, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: t.institution.textColor)),
                          ),
                          const SizedBox(width: 6),
                          Text(df.format(t.date), style: AppTypography.bodySmall),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${t.income ? '+' : '-'}${_f.format(t.amount)}',
                            style: AppTypography.currencyBody.copyWith(
                              color: t.income ? AppColors.secondary : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('ETB', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 18),

        // Offline Guarantee Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user, color: AppColors.secondary, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zero Cloud Exposure', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(
                      'Financial SMS texts stay on your device storage forever.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
