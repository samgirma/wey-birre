import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../db.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Map<String, bool> _selectedBanks = {
    'CBE': true,
    'Telebirr': true,
    'Awash': true,
    'Dashen': true,
  };

  bool _isRequesting = false;

  int get _selectedCount => _selectedBanks.values.where((v) => v).length;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleGrant() async {
    setState(() => _isRequesting = true);
    try {
      final name = _nameController.text.trim();
      await Db.setUserName(name.isNotEmpty ? name : 'Friend');

      final status = await Permission.sms.request();
      final activeSenders = _selectedBanks.entries.where((e) => e.value).map((e) => e.key).toSet();
      await Db.setSenders(activeSenders);
      await Db.setSetting('onboarding_completed', 'true');

      // Create a welcome notification
      await Db.addNotification(
        title: 'Welcome to Wey Birre!',
        body: 'Your 100% offline financial companion is ready. Synced banks: ${activeSenders.join(', ')}.',
        type: 'system',
      );

      if (!mounted) return;
      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission granted. Scanning inbox...'),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission not granted. You can still use manual entry or demo mode.'),
          ),
        );
      }
      widget.onComplete();
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _handleDemoMode() async {
    setState(() => _isRequesting = true);
    final name = _nameController.text.trim();
    await Db.setUserName(name.isNotEmpty ? name : 'Friend');
    await Db.seedDemoData();
    await Db.setSetting('onboarding_completed', 'true');
    await Db.addNotification(
      title: 'Demo Environment Loaded',
      body: 'Addis Ababa mock transactions and vaults initialized. Feel free to explore and add transactions!',
      type: 'system',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Addis Ababa demo data loaded! Explore the dashboard.'),
          backgroundColor: AppColors.primary,
        ),
      );
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Top Stepper Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
                  onPressed: () {},
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.outlineVariant, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Container(width: 24, height: 6, decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 4),
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.outlineVariant, shape: BoxShape.circle)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('STEP 2 / 3', style: AppTypography.labelSmall),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hero Graphic Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Official Brand Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.asset(
                      'assets/brand/wey_birre_logo.png',
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Visual Vector Illustration
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left incoming SMS cards
                        Positioned(
                          left: 14,
                          top: 20,
                          child: _buildMiniCard('Telebirr', '+2,450 ETB', AppColors.telebirrBg, AppColors.telebirrText),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 20,
                          child: _buildMiniCard('CBE Direct', '-850 ETB', AppColors.cbeBg, AppColors.cbeText),
                        ),

                        // Center Phone Parser Engine
                        Container(
                          width: 64,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 52,
                              height: 98,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bolt, color: AppColors.primary, size: 24),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ETB 45,920',
                                      style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Right Coin & Badge
                        Positioned(
                          right: 18,
                          top: 24,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.tertiaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'ብር',
                                style: TextStyle(
                                  color: AppColors.onTertiaryFixed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
                                SizedBox(width: 4),
                                Text(
                                  '3 Banks Synced',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 100% On-Device Parser Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: AppColors.secondary),
                        SizedBox(width: 6),
                        Text('100% On-Device Parser', style: AppTypography.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Title & Subtitle
            const Text(
              'Track Your Birr Automatically',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Wey Birre parses incoming bank SMS alerts into spending categories, balances, and savings metrics—zero manual entry needed.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),

            const SizedBox(height: 20),

            // Value Propositions
            _buildValueProp(
              Icons.shield_outlined,
              '100% Offline & Private',
              'Your financial figures never leave your device. No cloud storage, no tracker IDs, no account required.',
              AppColors.primary,
            ),
            const SizedBox(height: 10),
            _buildValueProp(
              Icons.account_balance,
              'Works with All Ethiopian Banks',
              'Pre-trained on transaction templates from CBE, Telebirr, Awash, Dashen, and Bank of Abyssinia.',
              AppColors.secondary,
            ),
            const SizedBox(height: 10),
            _buildValueProp(
              Icons.wifi_off,
              'Zero Internet Permission',
              'The app manifest excludes android.permission.INTERNET entirely for verifiable mathematical security.',
              AppColors.tertiary,
            ),

            const SizedBox(height: 20),

            // Personalization Card: Name Entry
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E7FF), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('What should we call you?', style: AppTypography.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Used only on your phone to greet you and personalize your dashboard.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Enter your name (e.g. Dawit, Bethlehem)',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.outline),
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Permission & Bank Scope
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sms, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('SMS Read Scope', style: AppTypography.headlineSmall),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Safe Scope', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Android will ask to allow SMS reading. Wey Birre strictly isolates messages sent by verified financial routing headers. Your family chats and personal SMS are ignored.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select accounts to sync automatically', style: AppTypography.labelSmall),
                      Text('$_selectedCount of ${_selectedBanks.length} active', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bank Pill Checkboxes
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: _selectedBanks.keys.map((bankName) {
                      final isChecked = _selectedBanks[bankName] ?? false;
                      final inst = BankInstitution.fromSender(bankName);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBanks[bankName] = !isChecked;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isChecked ? AppColors.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isChecked ? AppColors.primary : AppColors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isChecked
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(width: 6, height: 6, decoration: BoxDecoration(color: inst.dotColor, shape: BoxShape.circle)),
                                        const SizedBox(width: 4),
                                        Text(bankName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Text(inst.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            ElevatedButton.icon(
              onPressed: _isRequesting ? null : _handleGrant,
              icon: const Icon(Icons.mark_email_read, size: 20),
              label: Text(_isRequesting ? 'Requesting OS Handshake...' : 'Grant SMS Permission & Scan'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _isRequesting ? null : _handleDemoMode,
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Explore with Demo Data'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.surfaceContainer,
                foregroundColor: AppColors.onSurface,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 14),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, size: 14, color: AppColors.outline),
                SizedBox(width: 6),
                Text(
                  'Complies with Ethiopian Personal Data Protection Guidelines',
                  style: TextStyle(fontSize: 10.5, color: AppColors.outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard(String title, String amount, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: text, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
              Text(amount, style: TextStyle(fontSize: 7.5, color: text, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueProp(IconData icon, String title, String desc, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineSmall),
                const SizedBox(height: 2),
                Text(desc, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
