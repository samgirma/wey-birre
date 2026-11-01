import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../db.dart';
import '../models/models.dart';
import '../parser.dart';
import '../theme/app_colors.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/app_header.dart';
import '../widgets/notifications_sheet.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;
  List<Txn> _transactions = [];
  bool _isSyncing = false;
  String _userName = 'Friend';
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final list = await Db.all();
    final name = await Db.getUserName();
    final unread = await Db.getUnreadNotificationCount();
    if (mounted) {
      setState(() {
        _transactions = list;
        _userName = name;
        _unreadNotifications = unread;
      });
    }
  }

  Future<void> _loadTransactions() async {
    final list = await Db.all();
    final unread = await Db.getUnreadNotificationCount();
    if (mounted) {
      setState(() {
        _transactions = list;
        _unreadNotifications = unread;
      });
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _syncSms() async {
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      final req = await Permission.sms.request();
      if (!req.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to read bank alert messages.'),
          ),
        );
        return;
      }
    }

    setState(() => _isSyncing = true);
    try {
      final msgs = await SmsQuery().querySms(kinds: [SmsQueryKind.inbox]);
      var senders = await Db.senders();
      if (senders.isEmpty) {
        senders = ['CBE', 'Telebirr', 'Awash', 'Dashen', 'BOA'];
        await Db.setSenders(senders.toSet());
      }

      final before = await Db.count();
      final newTxns = <Txn>[];

      for (final m in msgs) {
        final body = m.body ?? '';
        final addr = m.address ?? '';
        final p = parseSms(body);
        if (p == null) continue;

        final d = m.date ?? DateTime.now();
        final key = '$addr|${d.millisecondsSinceEpoch}|${body.hashCode}';

        newTxns.add(Txn(
          key: key,
          sender: addr.isNotEmpty ? addr : 'Bank',
          merchant: p.merchant,
          income: p.income,
          amount: p.amount,
          balance: p.balance,
          date: d,
          body: body,
          category: p.category,
          txRef: p.txRef,
        ));
      }

      await Db.insertAll(newTxns);
      final added = (await Db.count()) - before;

      // Add notifications for newly imported items
      if (added > 0) {
        await Db.addNotification(
          title: '$added New Bank Transactions Parsed',
          body: 'Synced latest banking alerts from your inbox. Balances and spending charts updated.',
          type: 'sync_summary',
        );

        // Record individual transaction alerts for up to 3 most recent
        for (final t in newTxns.take(3)) {
          final prefix = t.income ? '+' : '-';
          final action = t.income ? 'Received' : 'Paid';
          final refStr = (t.txRef != null && t.txRef!.isNotEmpty) ? t.txRef! : 'N/A';
          await Db.addNotification(
            title: '$action $prefix${t.amount.toStringAsFixed(2)} ETB (${t.institution.shortCode})',
            body: '${t.merchant} • Ref: $refStr',
            type: t.income ? 'sms_credit' : 'sms_debit',
          );
        }
      }

      await _loadTransactions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  added > 0
                      ? '$added new bank transactions imported & verified!'
                      : 'Inbox is up to date. No new alerts found.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.inverseSurface,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleUpdateTxn(Txn updated) async {
    await Db.update(updated);
    await _loadTransactions();
  }

  Future<void> _handleDeleteTxn(String key) async {
    await Db.delete(key);
    await _loadTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted from local storage.')),
      );
    }
  }

  Future<void> _openAddCash() async {
    final txn = await AddTransactionDialog.show(context);
    if (txn != null) {
      await Db.insert(txn);
      await Db.addNotification(
        title: 'Manual Cash Transaction Added',
        body: '${txn.income ? "Income" : "Expense"}: ${txn.merchant} (${txn.amount.toStringAsFixed(2)} ETB)',
        type: txn.income ? 'sms_credit' : 'sms_debit',
      );
      await _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text('Added: ${txn.merchant} (${txn.amount.toStringAsFixed(2)} ETB)'),
              ],
            ),
          ),
        );
      }
    }
  }

  void _openNotifications() async {
    await NotificationsSheet.show(
      context,
      transactions: _transactions,
      onClearNotifications: () {
        setState(() => _unreadNotifications = 0);
      },
    );
    await Db.markAllNotificationsRead();
    if (mounted) {
      setState(() => _unreadNotifications = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        unreadNotificationsCount: _unreadNotifications,
        onNotificationTap: _openNotifications,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          // Tab 0: Home Dashboard
          HomeScreen(
            transactions: _transactions,
            userName: _userName,
            onSyncSms: _syncSms,
            isSyncing: _isSyncing,
            onSeeAllTransactions: () => _onTabTapped(1),
            onUpdateTxn: _handleUpdateTxn,
            onDeleteTxn: _handleDeleteTxn,
          ),

          // Tab 1: Activity & Transactions
          TransactionsScreen(
            transactions: _transactions,
            onUpdateTxn: _handleUpdateTxn,
            onDeleteTxn: _handleDeleteTxn,
          ),

          // Tab 2: Reports & Analytics
          ReportsScreen(
            transactions: _transactions,
          ),

          // Tab 3: Settings & Privacy
          SettingsScreen(
            transactions: _transactions,
            userName: _userName,
            onNameChanged: (newName) async {
              await Db.setUserName(newName);
              setState(() => _userName = newName);
            },
            onRescan: _syncSms,
            onSeedDemo: () async {
              await Db.seedDemoData();
              await Db.addNotification(
                title: 'Addis Ababa Demo Data Restored',
                body: 'Loaded mock salaries, coffee, supermarkets, and transfers across CBE, Telebirr & Awash.',
                type: 'sync_summary',
              );
              await _loadTransactions();
            },
          ),
        ],
      ),

      // Floating Add Cash Button (on Home and Activity tabs)
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton.extended(
              onPressed: _openAddCash,
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add, size: 22),
              label: const Text(
                'Add Cash',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
              ),
            )
          : null,

      // Expanding Interactive Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 68 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest.withOpacity(0.98),
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E7FF), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.account_balance_wallet, 'Home'),
            _buildNavItem(1, Icons.receipt_long, 'Activity'),
            _buildNavItem(2, Icons.insights, 'Reports'),
            _buildNavItem(3, Icons.settings, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      flex: isSelected ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () => _onTabTapped(index),
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.fastOutSlowIn,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
