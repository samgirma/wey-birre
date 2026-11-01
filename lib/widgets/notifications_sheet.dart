import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Modal Bottom Sheet displaying imported SMS alerts, sync history logs,
/// and live monitor stats for Ethiopian bank message ingestion.
class NotificationsSheet extends StatefulWidget {
  final List<Txn> transactions;
  final VoidCallback onClearNotifications;

  const NotificationsSheet({
    super.key,
    required this.transactions,
    required this.onClearNotifications,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Txn> transactions,
    required VoidCallback onClearNotifications,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationsSheet(
        transactions: transactions,
        onClearNotifications: onClearNotifications,
      ),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final list = await Db.getNotifications(limit: 60);
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    await Db.clearNotifications();
    widget.onClearNotifications();
    if (mounted) {
      setState(() => _notifications = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notification logs cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bank stats
    final cbeCount =
        widget.transactions.where((t) => t.institution == BankInstitution.cbe).length;
    final telebirrCount =
        widget.transactions.where((t) => t.institution == BankInstitution.telebirr).length;
    final awashCount =
        widget.transactions.where((t) => t.institution == BankInstitution.awash).length;
    final dashenCount =
        widget.transactions.where((t) => t.institution == BankInstitution.dashen).length;
    final boaCount =
        widget.transactions.where((t) => t.institution == BankInstitution.boa).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mark_email_read,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SMS & Sync Monitor',
                            style: AppTypography.headlineSmall),
                        Text('Real-time Ethiopian banking alert monitor',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
                if (_notifications.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.onSurfaceVariant,
              labelStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications, size: 16),
                      const SizedBox(width: 6),
                      Text('Alerts (${_notifications.length})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.query_stats, size: 16),
                      SizedBox(width: 6),
                      Text('Bank Monitor'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Alerts List
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                        ? _buildEmptyAlerts()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final notif = _notifications[index];
                              return _buildNotificationCard(notif);
                            },
                          ),

                // Tab 2: Bank Sync Ingestion Monitor
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // System Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined,
                                color: AppColors.secondary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('100% On-Device Ingestion',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 6),
                                    Icon(Icons.check_circle,
                                        size: 14, color: AppColors.secondary),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Background SMS listener scans only designated banking headers. No internet packets are generated.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text('Parsed Messages by Bank Institution',
                        style: AppTypography.labelSmall),
                    const SizedBox(height: 8),

                    _buildBankMetricTile(
                      BankInstitution.cbe.displayName,
                      'CBE SMS & Alerts',
                      cbeCount,
                      AppColors.primary,
                      AppColors.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    _buildBankMetricTile(
                      BankInstitution.telebirr.displayName,
                      'Telebirr (Ethio Telecom 127)',
                      telebirrCount,
                      AppColors.onPrimaryFixed,
                      AppColors.primaryFixed,
                    ),
                    const SizedBox(height: 8),
                    _buildBankMetricTile(
                      BankInstitution.awash.displayName,
                      'Awash Bank Alerts',
                      awashCount,
                      AppColors.onTertiaryFixed,
                      AppColors.tertiaryFixed,
                    ),
                    const SizedBox(height: 8),
                    _buildBankMetricTile(
                      BankInstitution.dashen.displayName,
                      'Dashen Bank Alerts',
                      dashenCount,
                      AppColors.onSurface,
                      AppColors.surfaceContainerHigh,
                    ),
                    const SizedBox(height: 8),
                    _buildBankMetricTile(
                      BankInstitution.boa.displayName,
                      'Bank of Abyssinia',
                      boaCount,
                      AppColors.outline,
                      AppColors.surfaceContainerLow,
                    ),

                    const SizedBox(height: 16),

                    // Overall Summary Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('${widget.transactions.length}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                              const SizedBox(height: 2),
                              const Text('Total Parsed',
                                  style: AppTypography.labelSmall),
                            ],
                          ),
                          Container(
                              height: 30,
                              width: 1,
                              color: AppColors.outlineVariant),
                          Column(
                            children: [
                              Text('${_notifications.length}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary)),
                              const SizedBox(height: 2),
                              const Text('Sync Logs',
                                  style: AppTypography.labelSmall),
                            ],
                          ),
                          Container(
                              height: 30,
                              width: 1,
                              color: AppColors.outlineVariant),
                          const Column(
                            children: [
                              Text('100%',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.tertiary)),
                              SizedBox(height: 2),
                              Text('Offline Safe',
                                  style: AppTypography.labelSmall),
                            ],
                          ),
                        ],
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

  Widget _buildEmptyAlerts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 32, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const Text('No Imported SMS Alerts Yet',
              style: AppTypography.headlineSmall),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'When new bank SMS messages arrive, Wey Birre parses them automatically and lists alert details here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    if (notif.type == 'sms_credit') {
      icon = Icons.arrow_downward;
      iconColor = AppColors.secondary;
      iconBg = AppColors.secondaryContainer;
    } else if (notif.type == 'sms_debit') {
      icon = Icons.arrow_upward;
      iconColor = AppColors.tertiary;
      iconBg = AppColors.tertiaryFixed;
    } else if (notif.type == 'sync_summary') {
      icon = Icons.sync;
      iconColor = AppColors.primary;
      iconBg = AppColors.primaryFixed;
    } else {
      icon = Icons.info_outline;
      iconColor = AppColors.primary;
      iconBg = AppColors.surfaceContainerHigh;
    }

    final dateStr = DateFormat('MMM dd, hh:mm a').format(notif.timestamp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.isRead
              ? const Color(0xFFE2E7FF)
              : AppColors.primary.withOpacity(0.4),
          width: notif.isRead ? 1 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankMetricTile(
    String title,
    String subtitle,
    int count,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    title.length > 3 ? title.substring(0, 3) : title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count msgs',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
