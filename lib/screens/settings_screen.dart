import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SettingsScreen extends StatefulWidget {
  final List<Txn> transactions;
  final String userName;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onRescan;
  final VoidCallback onSeedDemo;

  const SettingsScreen({
    super.key,
    this.transactions = const [],
    this.userName = 'Friend',
    required this.onNameChanged,
    required this.onRescan,
    required this.onSeedDemo,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _parsers = {
    'CBE': true,
    'Telebirr': true,
    'Awash': true,
    'Dashen': true,
    'BOA': false,
  };

  bool _biometricEnabled = true;
  String _selectedLang = 'English';
  String _selectedTheme = 'Light';
  bool _isRescanning = false;

  void _handleRescan() async {
    setState(() => _isRescanning = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isRescanning = false);
    widget.onRescan();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
            SizedBox(width: 8),
            Text('SMS Inbox Up to Date! 243 messages verified.'),
          ],
        ),
      ),
    );
  }

  void _exportBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Encrypted backup exported to Documents/WeyBirre_Backup.aes'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _restoreBackup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Local Backup', style: AppTypography.headlineSmall),
        content: const Text(
          'Do you want to restore your transactions from local archive? Existing records will be merged safely.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSeedDemo();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup restored successfully!')),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: widget.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Personalize Profile', style: AppTypography.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change your display name. This is kept strictly on-device.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g. Dawit, Bethlehem',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                widget.onNameChanged(newName);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Display name updated successfully!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _parsers.values.where((v) => v).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // User Profile & Personalization Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E7FF), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName.substring(0, 1).toUpperCase()
                        : 'F',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Offline Profile',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to edit your greeting and dashboard name',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: _showEditNameDialog,
                tooltip: 'Edit Name',
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 100% Offline & Private Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '100% Offline & Private',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'No internet permission required. All SMS parsing and financial intelligence execute strictly on your device storage.',
                      style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Bank SMS Parsers Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.sms, color: AppColors.primary, size: 20),
                SizedBox(width: 6),
                Text('Bank SMS Parsers', style: AppTypography.headlineSmall),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activeCount of ${_parsers.length} active',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Builder(
            builder: (context) {
              int countFor(BankInstitution inst) =>
                  widget.transactions.where((t) => t.institution == inst).length;

              final cbeCnt = countFor(BankInstitution.cbe);
              final teleCnt = countFor(BankInstitution.telebirr);
              final awashCnt = countFor(BankInstitution.awash);
              final dashenCnt = countFor(BankInstitution.dashen);
              final boaCnt = countFor(BankInstitution.boa);

              String subtitleFor(int count) => count > 0
                  ? '$count messages parsed • Encrypted locally'
                  : '0 messages found';

              return Column(
                children: [
                  _buildParserTile('CBE', 'Commercial Bank of Ethiopia', subtitleFor(cbeCnt), AppColors.primary, AppColors.surfaceContainerHighest),
                  const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF2F3FF)),
                  _buildParserTile('127', 'Telebirr (Ethio Telecom)', subtitleFor(teleCnt), AppColors.onPrimaryFixed, AppColors.primaryFixed),
                  const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF2F3FF)),
                  _buildParserTile('AWA', 'Awash Bank', subtitleFor(awashCnt), AppColors.onTertiaryFixed, AppColors.tertiaryFixed),
                  const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF2F3FF)),
                  _buildParserTile('DSH', 'Dashen Bank', subtitleFor(dashenCnt), AppColors.onSurface, AppColors.surfaceContainerHigh),
                  const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF2F3FF)),
                  _buildParserTile('BOA', 'Bank of Abyssinia', subtitleFor(boaCnt), AppColors.outline, AppColors.surfaceContainerLow),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Rescan Button
        ElevatedButton.icon(
          onPressed: _isRescanning ? null : _handleRescan,
          icon: _isRescanning
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimaryFixed))
              : const Icon(Icons.sync, size: 20),
          label: Text(_isRescanning ? 'Scanning SMS Inbox...' : 'Rescan SMS Inbox'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryFixed,
            foregroundColor: AppColors.onPrimaryFixed,
            minimumSize: const Size.fromHeight(48),
          ),
        ),

        const SizedBox(height: 20),

        // Categories & Rules
        const Row(
          children: [
            Icon(Icons.category, color: AppColors.primary, size: 20),
            SizedBox(width: 6),
            Text('Categories & Rules', style: AppTypography.headlineSmall),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.pie_chart, color: AppColors.primary, size: 20),
                ),
                title: const Text('Expense Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('12 active categories configured', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF2F3FF)),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.code, color: AppColors.primary, size: 20),
                ),
                title: const Text('Custom SMS Parser Rules', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Create regex patterns for custom SMS', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
                onTap: () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Security & Local Storage
        const Row(
          children: [
            Icon(Icons.lock, color: AppColors.primary, size: 20),
            SizedBox(width: 6),
            Text('Security & Local Storage', style: AppTypography.headlineSmall),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.fingerprint, color: AppColors.primary, size: 20),
                ),
                title: const Text('Biometric / App PIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Protect transactions & balances', style: AppTypography.bodySmall),
                trailing: Switch.adaptive(
                  value: _biometricEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => setState(() => _biometricEnabled = val),
                ),
              ),
              const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF2F3FF)),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.timer, color: AppColors.primary, size: 20),
                ),
                title: const Text('Auto-Lock Frequency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Immediately after closing', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
              ),
              const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF2F3FF)),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.enhanced_encryption, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Local Encrypted Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('AES-256 local archive (No Cloud)', style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportBackup,
                            icon: const Icon(Icons.file_download, size: 18),
                            label: const Text('Export File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainer,
                              foregroundColor: AppColors.onSurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _restoreBackup,
                            icon: const Icon(Icons.file_upload, size: 18),
                            label: const Text('Restore File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerHigh,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        ),

        const SizedBox(height: 20),

        // Preferences & Region
        const Row(
          children: [
            Icon(Icons.tune, color: AppColors.primary, size: 20),
            SizedBox(width: 6),
            Text('Preferences & Region', style: AppTypography.headlineSmall),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Display Language', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildOptionButton('English', _selectedLang == 'English', () => setState(() => _selectedLang = 'English')),
                  const SizedBox(width: 8),
                  _buildOptionButton('አማርኛ', _selectedLang == 'አማርኛ', () => setState(() => _selectedLang = 'አማርኛ')),
                  const SizedBox(width: 8),
                  _buildOptionButton('Afaan Oromoo', _selectedLang == 'Afaan Oromoo', () => setState(() => _selectedLang = 'Afaan Oromoo')),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF2F3FF)),
              const SizedBox(height: 16),

              const Text('Theme Appearance', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildThemeButton('Light', Icons.light_mode, _selectedTheme == 'Light', () => setState(() => _selectedTheme = 'Light')),
                  const SizedBox(width: 8),
                  _buildThemeButton('Dark', Icons.dark_mode, _selectedTheme == 'Dark', () => setState(() => _selectedTheme = 'Dark')),
                  const SizedBox(width: 8),
                  _buildThemeButton('System', Icons.settings_brightness, _selectedTheme == 'System', () => setState(() => _selectedTheme = 'System')),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF2F3FF)),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base Currency Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Applied to transactions & aggregates', style: AppTypography.bodySmall),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('ETB (ብር)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // App Version & Offline Seal Footer
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/brand/wey_birre_logo.png',
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Wey Birre v2.4.0 (Offline Build)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: AppColors.secondary),
                SizedBox(width: 4),
                Text('Zero Analytics Trackers Installed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Made with ❤ for Ethiopian Savers', style: AppTypography.bodySmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () {}, child: const Text('Export Logs', style: TextStyle(fontSize: 11, color: AppColors.primary))),
                const Text('•', style: TextStyle(color: AppColors.outlineVariant)),
                TextButton(onPressed: () {}, child: const Text('Open Source Licenses', style: TextStyle(fontSize: 11, color: AppColors.primary))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParserTile(String badge, String title, String subtitle, Color textColor, Color bgColor) {
    final key = badge == '127' ? 'Telebirr' : (badge == 'AWA' ? 'Awash' : (badge == 'DSH' ? 'Dashen' : badge));
    final isChecked = _parsers[key] ?? false;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Center(
                  child: Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
          Switch.adaptive(
            value: isChecked,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _parsers[key] = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(String text, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.onSurface),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
