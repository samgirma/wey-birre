import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  static Future<Txn?> show(BuildContext context) {
    return showModalBottomSheet<Txn>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddTransactionDialog(),
    );
  }

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  bool _isIncome = false;
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'Groceries & Food';
  BankInstitution _selectedInstitution = BankInstitution.cash;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final merchant = _merchantController.text.trim().isEmpty
        ? (_isIncome ? 'Cash Income' : 'Cash Expense')
        : _merchantController.text.trim();

    final now = DateTime.now();
    final txn = Txn(
      key: 'manual_${now.millisecondsSinceEpoch}',
      sender: _selectedInstitution.shortCode,
      merchant: merchant,
      income: _isIncome,
      amount: amount,
      date: now,
      body: 'Manual cash entry: $merchant - $amount ETB',
      category: _isIncome ? 'Salary & Income' : _selectedCategory,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    Navigator.pop(context, txn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Cash Transaction', style: AppTypography.headlineSmall),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Inflow / Outflow Toggle
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Spent / Expense (-)')),
                    selected: !_isIncome,
                    selectedColor: AppColors.errorContainer,
                    labelStyle: TextStyle(
                      color: !_isIncome ? AppColors.error : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _isIncome = false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Received / Inflow (+)')),
                    selected: _isIncome,
                    selectedColor: AppColors.secondaryContainer,
                    labelStyle: TextStyle(
                      color: _isIncome ? AppColors.secondary : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _isIncome = true);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Amount Field
            const Text('Amount (ETB)', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppTypography.currencyDisplay.copyWith(color: AppColors.onSurface),
              decoration: const InputDecoration(
                hintText: '0.00',
                suffixText: 'ETB',
                suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),

            // Merchant / Description
            const Text('Merchant / Description', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                hintText: 'e.g. Kaldis Coffee, Bole Taxi, Bambis...',
                prefixIcon: Icon(Icons.storefront, color: AppColors.outline),
              ),
            ),
            const SizedBox(height: 14),

            // Account selection
            const Text('Account / Vehicle', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: BankInstitution.values.map((inst) {
                final isSelected = _selectedInstitution == inst;
                return ChoiceChip(
                  avatar: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: inst.dotColor, shape: BoxShape.circle),
                  ),
                  label: Text(inst.shortCode),
                  selected: isSelected,
                  selectedColor: inst.bgColor,
                  labelStyle: TextStyle(
                    color: isSelected ? inst.textColor : AppColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedInstitution = inst);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Category selector (if expense)
            if (!_isIncome) ...[
              const Text('Category', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category, color: AppColors.outline),
                ),
                items: ExpenseCategory.defaults
                    .where((c) => c.name != 'Salary & Income')
                    .map((cat) => DropdownMenuItem(
                          value: cat.name,
                          child: Text('${cat.emoji} ${cat.name}'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),
            ],

            // Note Field
            const Text('Offline Note (Optional)', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Optional personal note...',
                prefixIcon: Icon(Icons.edit_note, color: AppColors.outline),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
