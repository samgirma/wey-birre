import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TransactionDetailSheet extends StatefulWidget {
  final Txn txn;
  final ValueChanged<Txn>? onUpdate;
  final VoidCallback? onDelete;

  const TransactionDetailSheet({
    super.key,
    required this.txn,
    this.onUpdate,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required Txn txn,
    ValueChanged<Txn>? onUpdate,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionDetailSheet(
        txn: txn,
        onUpdate: onUpdate,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  late Txn _current;
  late TextEditingController _noteController;
  bool _smsCollapsed = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _current = widget.txn;
    _noteController = TextEditingController(text: _current.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _copySms() {
    Clipboard.setData(ClipboardData(text: _current.body));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _chooseCategory() async {
    final chosen = await showDialog<ExpenseCategory>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Category', style: AppTypography.headlineSmall),
        children: ExpenseCategory.defaults.map((cat) {
          final isSelected = cat.name == _current.category;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, cat),
            child: Row(
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(cat.name, style: isSelected ? AppTypography.headlineSmall : AppTypography.bodyMedium),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: AppColors.primary, size: 20),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (chosen != null) {
      final updated = _current.copyWith(category: chosen.name);
      setState(() => _current = updated);
      widget.onUpdate?.call(updated);
    }
  }

  void _toggleExclude() {
    final updated = _current.copyWith(isExcludedFromReports: !_current.isExcludedFromReports);
    setState(() => _current = updated);
    widget.onUpdate?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,##0.00');
    final df = DateFormat('EEEE, d MMM yyyy • HH:mm');
    final timeStr = DateFormat('HH:mm:ss').format(_current.date);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Transaction Details', style: AppTypography.headlineSmall),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Body
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),

                // Hero Amount Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_current.income ? '+' : '-'}${f.format(_current.amount)} ETB',
                        style: AppTypography.displayMedium.copyWith(
                          color: _current.income ? AppColors.deposit : AppColors.withdrawal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mark_chat_read, size: 14, color: AppColors.secondary),
                            SizedBox(width: 5),
                            Text(
                              'Verified from SMS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSecondaryFixed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _current.merchant,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Meta Details Grid
                Row(
                  children: [
                    // Account
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
                            const Text('Account', style: AppTypography.labelSmall),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _current.institution.dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _current.institution.shortCode,
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _current.txRef ?? '..Verified',
                              style: const TextStyle(fontSize: 11, color: AppColors.outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Balance After
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
                            const Text('Balance After', style: AppTypography.labelSmall),
                            const SizedBox(height: 4),
                            Text(
                              _current.balance != null ? '${f.format(_current.balance)} ETB' : 'Recorded',
                              style: AppTypography.currencyBody.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Verified Safe',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Time Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18, color: AppColors.outline),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Transaction Time', style: AppTypography.labelSmall),
                              Text(df.format(_current.date), style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.outlineVariant, fontFamily: 'monospace')),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Category Selector
                const Text('Category Classification', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _chooseCategory,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E7FF)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(ExpenseCategory.find(_current.category).emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(_current.category, style: AppTypography.headlineSmall),
                          ],
                        ),
                        const Row(
                          children: [
                            Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                            Icon(Icons.expand_more, color: AppColors.primary, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Personal Note Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Personal Note', style: AppTypography.labelSmall),
                    Text('Local note', style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.edit_note, color: AppColors.outline, size: 20),
                    hintText: 'Add an offline private note...',
                  ),
                  onChanged: (val) {
                    final updated = _current.copyWith(note: val);
                    setState(() => _current = updated);
                    widget.onUpdate?.call(updated);
                  },
                ),

                const SizedBox(height: 16),

                // Raw SMS Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _smsCollapsed = !_smsCollapsed),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sms, size: 18, color: _current.institution.dotColor),
                                  const SizedBox(width: 8),
                                  const Text('Original Bank SMS', style: AppTypography.headlineSmall),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _current.institution.bgColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _current.institution.shortCode,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _current.institution.textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(_smsCollapsed ? Icons.expand_more : Icons.expand_less, color: AppColors.outline),
                            ],
                          ),
                        ),
                      ),
                      if (!_smsCollapsed) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SelectableText(
                              _current.body,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                height: 1.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lock, size: 12, color: AppColors.outline),
                                  SizedBox(width: 4),
                                  Text(
                                    'Parsed locally on-device',
                                    style: TextStyle(fontSize: 11, color: AppColors.outline),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _copySms,
                                icon: Icon(_copied ? Icons.check : Icons.content_copy, size: 14),
                                label: Text(_copied ? 'Copied!' : 'Copy Raw SMS'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: _chooseCategory,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Category'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleExclude,
                        icon: Icon(
                          _current.isExcludedFromReports ? Icons.visibility : Icons.visibility_off,
                          size: 16,
                        ),
                        label: Text(_current.isExcludedFromReports ? 'Include in Reports' : 'Exclude in Reports'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: _current.isExcludedFromReports ? AppColors.tertiary : AppColors.onSurfaceVariant,
                          backgroundColor: _current.isExcludedFromReports ? AppColors.tertiaryFixed : AppColors.surfaceContainerHigh,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDelete?.call();
                        },
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete Entry'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: AppColors.error,
                          backgroundColor: AppColors.errorContainer.withOpacity(0.4),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
