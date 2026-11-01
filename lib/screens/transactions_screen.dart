import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/transaction_detail_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  final List<Txn> transactions;
  final Function(Txn) onUpdateTxn;
  final Function(String) onDeleteTxn;

  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.onUpdateTxn,
    required this.onDeleteTxn,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  final NumberFormat _f = NumberFormat('#,##0.00');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Txn> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();

    return widget.transactions.where((t) {
      // 1. Text Search match
      if (query.isNotEmpty) {
        final m = t.merchant.toLowerCase().contains(query);
        final b = t.body.toLowerCase().contains(query);
        final n = (t.note ?? '').toLowerCase().contains(query);
        final s = t.sender.toLowerCase().contains(query);
        final a = t.amount.toString().contains(query);
        if (!m && !b && !n && !s && !a) return false;
      }

      // 2. Filter Chip match
      switch (_selectedFilter) {
        case 'deposits':
          return t.income;
        case 'withdrawals':
          return !t.income;
        case 'cbe':
          return t.institution == BankInstitution.cbe;
        case 'telebirr':
          return t.institution == BankInstitution.telebirr;
        case 'awash':
          return t.institution == BankInstitution.awash;
        case 'dashen':
          return t.institution == BankInstitution.dashen;
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<Txn>> _groupByDate(List<Txn> txns) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final map = <String, List<Txn>>{};

    for (final t in txns) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      String key;
      if (tDate == today) {
        key = 'Today';
      } else if (tDate == yesterday) {
        key = 'Yesterday';
      } else {
        key = DateFormat('d MMM yyyy').format(tDate);
      }

      (map[key] ??= []).add(t);
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTransactions;
    final totalIn = list.where((t) => t.income).fold(0.0, (a, b) => a + b.amount);
    final totalOut = list.where((t) => !t.income).fold(0.0, (a, b) => a + b.amount);
    final net = totalIn - totalOut;
    final grouped = _groupByDate(list);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // Search Input Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E7FF)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: AppColors.outline, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search merchant, note, amount...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.outline),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal Filter Chips Carousel
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterPill('all', 'All'),
              const SizedBox(width: 8),
              _buildFilterPill('deposits', 'Deposits (+)', dotColor: AppColors.secondary),
              const SizedBox(width: 8),
              _buildFilterPill('withdrawals', 'Withdrawals (-)', dotColor: AppColors.error),
              const SizedBox(width: 8),
              _buildFilterPill('cbe', 'CBE', dotColor: AppColors.cbeDot),
              const SizedBox(width: 8),
              _buildFilterPill('telebirr', 'Telebirr', dotColor: AppColors.telebirrDot),
              const SizedBox(width: 8),
              _buildFilterPill('awash', 'Awash', dotColor: AppColors.awashDot),
              const SizedBox(width: 8),
              _buildFilterPill('dashen', 'Dashen', dotColor: AppColors.dashenDot),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Summary Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('${list.length} transactions', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                ],
              ),
              Row(
                children: [
                  const Text('Net: ', style: AppTypography.bodySmall),
                  Text(
                    '${net >= 0 ? '+' : '-'}${_f.format(net.abs())} ETB',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: net >= 0 ? AppColors.secondary : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Grouped Feed
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No transactions match your search/filter.'),
            ),
          )
        else
          ...grouped.entries.map((entry) {
            final groupTitle = entry.key;
            final txnsInGroup = entry.value;
            final groupNet = txnsInGroup.fold(0.0, (acc, t) => acc + (t.income ? t.amount : -t.amount));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(groupTitle, style: AppTypography.headlineSmall),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${txnsInGroup.length} entries',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${groupNet >= 0 ? '+' : '-'}${_f.format(groupNet.abs())} ETB',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: groupNet >= 0 ? AppColors.secondary : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card with transactions in this group
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txnsInGroup.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF2F3FF)),
                    itemBuilder: (context, i) {
                      final t = txnsInGroup[i];
                      final cat = ExpenseCategory.find(t.category);
                      final timeStr = DateFormat('h:mm a').format(t.date);

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
                            color: t.income ? AppColors.secondaryFixed.withOpacity(0.5) : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cat.icon,
                            size: 20,
                            color: t.income ? AppColors.secondary : AppColors.primary,
                          ),
                        ),
                        title: Text(
                          t.merchant,
                          style: AppTypography.headlineSmall.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text(timeStr, style: AppTypography.bodySmall),
                            const SizedBox(width: 4),
                            const Text('•', style: TextStyle(fontSize: 10, color: AppColors.outline)),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: t.institution.bgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.institution.shortCode,
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: t.institution.textColor),
                              ),
                            ),
                            if (t.txRef != null) ...[
                              const SizedBox(width: 4),
                              const Text('•', style: TextStyle(fontSize: 10, color: AppColors.outline)),
                              const SizedBox(width: 4),
                              Text(t.txRef!, style: const TextStyle(fontSize: 10, color: AppColors.outlineVariant, fontFamily: 'monospace')),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${t.income ? '+' : '-'}${_f.format(t.amount)} ETB',
                              style: AppTypography.currencyBody.copyWith(
                                color: t.income ? AppColors.secondary : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  t.income ? Icons.arrow_downward : Icons.arrow_upward,
                                  size: 11,
                                  color: t.income ? AppColors.secondary : AppColors.outline,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  t.income ? 'Received' : 'Paid',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: t.income ? AppColors.secondary : AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),

        const SizedBox(height: 16),

        // Local Storage Guarantee Note
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'All ${list.length} transactions stored safely on this device',
                style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String filterKey, String label, {Color? dotColor}) {
    final isSelected = _selectedFilter == filterKey;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
