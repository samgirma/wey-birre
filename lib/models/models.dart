import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Supported Ethiopian Financial Institutions / Rails
enum BankInstitution {
  cbe,
  telebirr,
  awash,
  dashen,
  boa,
  cash;

  String get displayName {
    switch (this) {
      case BankInstitution.cbe:
        return 'Commercial Bank of Ethiopia';
      case BankInstitution.telebirr:
        return 'Telebirr (Ethio Telecom)';
      case BankInstitution.awash:
        return 'Awash Bank';
      case BankInstitution.dashen:
        return 'Dashen Bank';
      case BankInstitution.boa:
        return 'Bank of Abyssinia';
      case BankInstitution.cash:
        return 'Cash & Physical Ledger';
    }
  }

  String get shortCode {
    switch (this) {
      case BankInstitution.cbe:
        return 'CBE';
      case BankInstitution.telebirr:
        return 'Telebirr';
      case BankInstitution.awash:
        return 'Awash';
      case BankInstitution.dashen:
        return 'Dashen';
      case BankInstitution.boa:
        return 'BOA';
      case BankInstitution.cash:
        return 'Cash';
    }
  }

  Color get textColor {
    switch (this) {
      case BankInstitution.cbe:
        return AppColors.cbeText;
      case BankInstitution.telebirr:
        return AppColors.telebirrText;
      case BankInstitution.awash:
        return AppColors.awashText;
      case BankInstitution.dashen:
        return AppColors.dashenText;
      case BankInstitution.boa:
        return AppColors.boaText;
      case BankInstitution.cash:
        return AppColors.cashText;
    }
  }

  Color get bgColor {
    switch (this) {
      case BankInstitution.cbe:
        return AppColors.cbeBg;
      case BankInstitution.telebirr:
        return AppColors.telebirrBg;
      case BankInstitution.awash:
        return AppColors.awashBg;
      case BankInstitution.dashen:
        return AppColors.dashenBg;
      case BankInstitution.boa:
        return AppColors.boaBg;
      case BankInstitution.cash:
        return AppColors.cashBg;
    }
  }

  Color get dotColor {
    switch (this) {
      case BankInstitution.cbe:
        return AppColors.cbeDot;
      case BankInstitution.telebirr:
        return AppColors.telebirrDot;
      case BankInstitution.awash:
        return AppColors.awashDot;
      case BankInstitution.dashen:
        return AppColors.dashenDot;
      case BankInstitution.boa:
        return AppColors.boaDot;
      case BankInstitution.cash:
        return AppColors.cashDot;
    }
  }

  IconData get iconData {
    switch (this) {
      case BankInstitution.cbe:
        return Icons.account_balance;
      case BankInstitution.telebirr:
        return Icons.smartphone;
      case BankInstitution.awash:
        return Icons.assured_workload;
      case BankInstitution.dashen:
        return Icons.account_balance_wallet;
      case BankInstitution.boa:
        return Icons.account_balance;
      case BankInstitution.cash:
        return Icons.payments;
    }
  }

  static BankInstitution fromSender(String sender) {
    final s = sender.toLowerCase();
    if (s.contains('telebirr') || s.contains('127') || s.contains('ethio telecom')) {
      return BankInstitution.telebirr;
    }
    if (s.contains('cbe') || s.contains('commercial') || s.contains('ethiopia')) {
      return BankInstitution.cbe;
    }
    if (s.contains('awash') || s.contains('awa')) {
      return BankInstitution.awash;
    }
    if (s.contains('dashen') || s.contains('amole') || s.contains('dsh')) {
      return BankInstitution.dashen;
    }
    if (s.contains('abyssinia') || s.contains('boa')) {
      return BankInstitution.boa;
    }
    return BankInstitution.cash;
  }
}

/// Transaction Model representing bank SMS or manual ledger entries.
class Txn {
  final String key;
  final String sender;
  final String merchant;
  final bool income;
  final double amount;
  final double? balance;
  final DateTime date;
  final String body;
  final String category;
  final String? note;
  final bool isExcludedFromReports;
  final String? txRef;

  Txn({
    required this.key,
    required this.sender,
    required this.merchant,
    required this.income,
    required this.amount,
    this.balance,
    required this.date,
    required this.body,
    required this.category,
    this.note,
    this.isExcludedFromReports = false,
    this.txRef,
  });

  BankInstitution get institution => BankInstitution.fromSender(sender);

  Txn copyWith({
    String? key,
    String? sender,
    String? merchant,
    bool? income,
    double? amount,
    double? balance,
    DateTime? date,
    String? body,
    String? category,
    String? note,
    bool? isExcludedFromReports,
    String? txRef,
  }) {
    return Txn(
      key: key ?? this.key,
      sender: sender ?? this.sender,
      merchant: merchant ?? this.merchant,
      income: income ?? this.income,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      date: date ?? this.date,
      body: body ?? this.body,
      category: category ?? this.category,
      note: note ?? this.note,
      isExcludedFromReports: isExcludedFromReports ?? this.isExcludedFromReports,
      txRef: txRef ?? this.txRef,
    );
  }

  Map<String, Object?> toMap() => {
        'k': key,
        'sender': sender,
        'merchant': merchant,
        'income': income ? 1 : 0,
        'amount': amount,
        'balance': balance,
        'date': date.millisecondsSinceEpoch,
        'body': body,
        'category': category,
        'note': note,
        'isExcluded': isExcludedFromReports ? 1 : 0,
        'txRef': txRef,
      };

  static Txn fromMap(Map<String, Object?> m) => Txn(
        key: m['k'] as String,
        sender: (m['sender'] as String?) ?? 'Unknown',
        merchant: (m['merchant'] as String?) ?? (m['sender'] as String? ?? 'Transaction'),
        income: m['income'] == 1,
        amount: (m['amount'] as num).toDouble(),
        balance: (m['balance'] as num?)?.toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        body: (m['body'] as String?) ?? '',
        category: (m['category'] as String?) ?? 'Other',
        note: m['note'] as String?,
        isExcludedFromReports: m['isExcluded'] == 1,
        txRef: m['txRef'] as String?,
      );
}

/// Category Model with color and emoji/icon representation.
class ExpenseCategory {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.color,
  });

  static const List<ExpenseCategory> defaults = [
    ExpenseCategory(
      id: 'groceries',
      name: 'Groceries & Food',
      emoji: '🛒',
      icon: Icons.shopping_cart,
      color: AppColors.primary,
    ),
    ExpenseCategory(
      id: 'housing',
      name: 'Housing & Utilities',
      emoji: '🏠',
      icon: Icons.home,
      color: AppColors.secondary,
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transport & Fuel',
      emoji: '⛽',
      icon: Icons.local_gas_station,
      color: AppColors.tertiaryFixedDim,
    ),
    ExpenseCategory(
      id: 'airtime',
      name: 'Airtime & Internet',
      emoji: '📱',
      icon: Icons.phone_android,
      color: AppColors.primaryContainer,
    ),
    ExpenseCategory(
      id: 'family',
      name: 'Family & Transfers',
      emoji: '🤝',
      icon: Icons.send,
      color: AppColors.primaryFixedDim,
    ),
    ExpenseCategory(
      id: 'salary',
      name: 'Salary & Income',
      emoji: '💰',
      icon: Icons.payments,
      color: AppColors.deposit,
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Other & Miscellaneous',
      emoji: '📦',
      icon: Icons.category,
      color: AppColors.surfaceContainerHighest,
    ),
  ];

  static ExpenseCategory find(String name) {
    return defaults.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase() || c.id == name.toLowerCase(),
      orElse: () => defaults.last,
    );
  }
}

/// Account / Vault representation for Ethiopian banks & wallets.
class AccountVault {
  final String id;
  final String name;
  final String subtext;
  final double balance;
  final int messageCount;
  final BankInstitution institution;
  final String note;
  final String trendLabel;
  final bool isTrendPositive;

  const AccountVault({
    required this.id,
    required this.name,
    required this.subtext,
    required this.balance,
    required this.messageCount,
    required this.institution,
    required this.note,
    required this.trendLabel,
    this.isTrendPositive = true,
  });
}

/// Notification representation for tracked SMS alerts and sync events.
class AppNotification {
  final int? id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'sms_credit', 'sms_debit', 'sync_summary', 'system'
  final String? meta;

  const AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type = 'system',
    this.meta,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_read': isRead ? 1 : 0,
      'type': type,
      'meta': meta,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int? ?? 0),
      isRead: (map['is_read'] as int? ?? 0) == 1,
      type: map['type'] as String? ?? 'system',
      meta: map['meta'] as String?,
    );
  }
}
