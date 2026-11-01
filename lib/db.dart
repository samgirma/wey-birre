import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/models.dart';

class Db {
  static Database? _d;

  static Future<Database> get _db async {
    if (_d != null) return _d!;
    _d = await openDatabase(
      join(await getDatabasesPath(), 'wey_birre_v2.db'),
      version: 3,
      onCreate: (d, version) async {
        await d.execute('''
          CREATE TABLE txn(
            k TEXT PRIMARY KEY,
            sender TEXT,
            merchant TEXT,
            income INTEGER,
            amount REAL,
            balance REAL,
            date INTEGER,
            body TEXT,
            category TEXT,
            note TEXT,
            isExcluded INTEGER,
            txRef TEXT
          )
        ''');
        await d.execute('CREATE TABLE sender(name TEXT PRIMARY KEY, enabled INTEGER DEFAULT 1)');
        await d.execute('CREATE TABLE settings(k TEXT PRIMARY KEY, v TEXT)');
        await d.execute('''
          CREATE TABLE IF NOT EXISTS notifications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            body TEXT,
            timestamp INTEGER,
            is_read INTEGER DEFAULT 0,
            type TEXT,
            meta TEXT
          )
        ''');
      },
      onUpgrade: (d, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await d.execute('DROP TABLE IF EXISTS txn');
          await d.execute('''
            CREATE TABLE txn(
              k TEXT PRIMARY KEY,
              sender TEXT,
              merchant TEXT,
              income INTEGER,
              amount REAL,
              balance REAL,
              date INTEGER,
              body TEXT,
              category TEXT,
              note TEXT,
              isExcluded INTEGER,
              txRef TEXT
            )
          ''');
          await d.execute('CREATE TABLE IF NOT EXISTS settings(k TEXT PRIMARY KEY, v TEXT)');
        }
        if (oldVersion < 3) {
          await d.execute('''
            CREATE TABLE IF NOT EXISTS notifications(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              body TEXT,
              timestamp INTEGER,
              is_read INTEGER DEFAULT 0,
              type TEXT,
              meta TEXT
            )
          ''');
        }
      },
    );
    return _d!;
  }

  static Future<List<Txn>> all() async {
    final d = await _db;
    final res = await d.query('txn', orderBy: 'date DESC');
    return res.map(Txn.fromMap).toList();
  }

  static Future<int> count() async {
    final d = await _db;
    return Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM txn')) ?? 0;
  }

  static Future<void> insert(Txn t) async {
    final d = await _db;
    await d.insert('txn', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertAll(List<Txn> list) async {
    final d = await _db;
    final batch = d.batch();
    for (final t in list) {
      batch.insert('txn', t.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> update(Txn t) async {
    final d = await _db;
    await d.update(
      'txn',
      t.toMap(),
      where: 'k = ?',
      whereArgs: [t.key],
    );
  }

  static Future<void> delete(String key) async {
    final d = await _db;
    await d.delete('txn', where: 'k = ?', whereArgs: [key]);
  }

  static Future<List<String>> senders() async {
    final d = await _db;
    final res = await d.query('sender');
    return res.map((e) => e['name'] as String).toList();
  }

  static Future<void> setSenders(Set<String> s) async {
    final d = await _db;
    await d.delete('sender');
    for (final n in s) {
      await d.insert('sender', {'name': n, 'enabled': 1});
    }
  }

  static Future<String?> getSetting(String key) async {
    final d = await _db;
    final res = await d.query('settings', where: 'k = ?', whereArgs: [key]);
    if (res.isEmpty) return null;
    return res.first['v'] as String?;
  }

  static Future<void> setSetting(String key, String value) async {
    final d = await _db;
    await d.insert(
      'settings',
      {'k': key, 'v': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String> getUserName() async {
    final name = await getSetting('user_name');
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    return 'Friend';
  }

  static Future<void> setUserName(String name) async {
    await setSetting('user_name', name.trim().isEmpty ? 'Friend' : name.trim());
  }

  // --- Notification & SMS Monitor helpers ---

  static Future<void> addNotification({
    required String title,
    required String body,
    String type = 'system',
    String? meta,
  }) async {
    final d = await _db;
    await d.insert('notifications', {
      'title': title,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'is_read': 0,
      'type': type,
      'meta': meta,
    });
  }

  static Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    final d = await _db;
    final res = await d.query(
      'notifications',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return res.map(AppNotification.fromMap).toList();
  }

  static Future<int> getUnreadNotificationCount() async {
    final d = await _db;
    final res = await d.rawQuery('SELECT COUNT(*) FROM notifications WHERE is_read = 0');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  static Future<void> markAllNotificationsRead() async {
    final d = await _db;
    await d.update('notifications', {'is_read': 1});
  }

  static Future<void> clearNotifications() async {
    final d = await _db;
    await d.delete('notifications');
  }

  static Future<void> clear() async {
    final d = await _db;
    await d.delete('txn');
    await d.delete('notifications');
  }

  /// Seeds realistic Addis Ababa banking data matching the Stitch design mockups.
  static Future<void> seedDemoData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final sampleTxns = [
      // 1. CBE Salary (Today)
      Txn(
        key: 'demo-1',
        sender: 'CBE',
        merchant: 'Salary Deposit (Finchaa Tech)',
        income: true,
        amount: 35000.00,
        balance: 82400.00,
        date: today.add(const Duration(hours: 10, minutes: 45)),
        body: 'Your account 1000****9402 has been credited with ETB 35,000.00 on 29/10/2026. Ref: FT992123. Current balance is ETB 82,400.00. Commercial Bank of Ethiopia.',
        category: 'Salary & Income',
        txRef: '#TX9921',
      ),

      // 2. Kaldis Coffee Bole (Today)
      Txn(
        key: 'demo-2',
        sender: 'Telebirr',
        merchant: 'Kaldis Coffee Bole',
        income: false,
        amount: 180.00,
        balance: 24470.00,
        date: today.add(const Duration(hours: 13, minutes: 15)),
        body: 'Dear Customer, You have paid 180.00 ETB to KALDIS COFFEE BOLE. Trans ID: 9A88712. Current balance: 24,470.00 ETB. telebirr.',
        category: 'Groceries & Food',
        txRef: '#9A88712',
      ),

      // 3. Total Fuel Station Gotera (Today)
      Txn(
        key: 'demo-3',
        sender: 'CBE',
        merchant: 'Total Fuel Station Gotera',
        income: false,
        amount: 1670.50,
        balance: 80729.50,
        date: today.add(const Duration(hours: 15, minutes: 40)),
        body: 'Your account has been debited with ETB 1,670.50 at TOTAL GOTERA FUEL. Current balance: ETB 80,729.50. CBE.',
        category: 'Transport & Fuel',
        txRef: '#CBE5519',
      ),

      // 4. Pharmacy Bambis (Yesterday)
      Txn(
        key: 'demo-4',
        sender: 'Awash',
        merchant: 'Pharmacy Bambis',
        income: false,
        amount: 300.00,
        balance: 30900.00,
        date: yesterday.add(const Duration(hours: 16, minutes: 20)),
        body: 'Dear Customer, your Awash Bank A/C was debited with ETB 300.00 at Bambis Pharmacy. Bal: ETB 30,900.00. Awash Bank.',
        category: 'Other & Miscellaneous',
        txRef: '#AWA4491',
      ),

      // 5. Shoa Supermarket (Yesterday - Featured inspection target)
      Txn(
        key: 'demo-5',
        sender: 'Telebirr',
        merchant: 'Shoa Supermarket (Groceries)',
        income: false,
        amount: 1850.50,
        balance: 24650.00,
        date: yesterday.add(const Duration(hours: 18, minutes: 20)),
        body: 'Dear Customer, You have paid 1,850.50 ETB to SHOA SUPERMARKET on 12/10/2024 18:20:14. Trans ID: 8J92KL910. Your current balance is 24,650.00 ETB. Telebirr.',
        category: 'Groceries & Food',
        note: 'Weekly household supplies for family',
        txRef: '#8J92KL910',
      ),

      // 6. Bole Medhanealem ATM (12 Oct)
      Txn(
        key: 'demo-6',
        sender: 'Awash',
        merchant: 'Bole Medhanealem ATM',
        income: false,
        amount: 4000.00,
        balance: 31200.00,
        date: today.subtract(const Duration(days: 2, hours: 2)),
        body: 'Dear Customer, ATM withdrawal of ETB 4,000.00 at Bole Medhanealem. Avail Bal: ETB 31,200.00. Awash Bank.',
        category: 'Other & Miscellaneous',
        txRef: '#ATM8812',
      ),

      // 7. Dashen Bank Transfer to Almaz T. (12 Oct)
      Txn(
        key: 'demo-7',
        sender: 'Dashen',
        merchant: 'Transfer to Almaz T.',
        income: false,
        amount: 2500.00,
        balance: 10000.00,
        date: today.subtract(const Duration(days: 2, hours: 5)),
        body: 'Transfer of ETB 2,500.00 to Almaz T. via Amole completed successfully. Available Balance: ETB 10,000.00. Dashen Bank.',
        category: 'Family & Transfers',
        txRef: '#DSH9912',
      ),

      // 8. Ethio Telecom 800MB (11 Oct)
      Txn(
        key: 'demo-8',
        sender: 'Telebirr',
        merchant: 'Ethio Telecom 800MB',
        income: false,
        amount: 150.00,
        balance: 26500.50,
        date: today.subtract(const Duration(days: 3, hours: 7)),
        body: 'You have bought Ethio telecom Monthly Data Package 800MB for 150.00 ETB. Current balance: 26,500.50 ETB. Telebirr.',
        category: 'Airtime & Internet',
        txRef: '#ET3321',
      ),

      // 9. Sarbet Meat & Poultry (10 Oct)
      Txn(
        key: 'demo-9',
        sender: 'Telebirr',
        merchant: 'Sarbet Quality Butchery',
        income: false,
        amount: 3200.00,
        balance: 26650.50,
        date: today.subtract(const Duration(days: 4, hours: 4)),
        body: 'You have paid 3,200.00 ETB to SARBET QUALITY BUTCHERY. Trans ID: 8K7710. Current balance: 26,650.50 ETB. Telebirr.',
        category: 'Groceries & Food',
      ),

      // 10. Secondary Inflow - Consulting (8 Oct)
      Txn(
        key: 'demo-10',
        sender: 'CBE',
        merchant: 'Addis Soft Consulting Contract',
        income: true,
        amount: 27400.00,
        balance: 49070.50,
        date: today.subtract(const Duration(days: 6, hours: 6)),
        body: 'Account 1000****9402 credited with ETB 27,400.00 from Addis Soft. Ref: FT2299. Current balance: ETB 49,070.50. CBE.',
        category: 'Salary & Income',
      ),

      // 11. Housing & Utility (5 Oct)
      Txn(
        key: 'demo-11',
        sender: 'CBE',
        merchant: 'CMC Residence Rent & Water',
        income: false,
        amount: 10467.60,
        balance: 21670.50,
        date: today.subtract(const Duration(days: 9)),
        body: 'Transfer of ETB 10,467.60 for CMC Residence Rent executed. CBE.',
        category: 'Housing & Utilities',
      ),

      // 12. Transport / Feres Taxi rides (4 Oct)
      Txn(
        key: 'demo-12',
        sender: 'Telebirr',
        merchant: 'Feres Taxi Trips (Weekly)',
        income: false,
        amount: 2742.30,
        balance: 29850.50,
        date: today.subtract(const Duration(days: 10)),
        body: 'You have paid 2,742.30 ETB to FERES TECHNOLOGIES. Telebirr.',
        category: 'Transport & Fuel',
      ),

      // 13. Telebirr Home Broadband Fibre (2 Oct)
      Txn(
        key: 'demo-13',
        sender: 'Telebirr',
        merchant: 'Ethio Telecom Fibre 50Mbps',
        income: false,
        amount: 4608.00,
        balance: 32592.80,
        date: today.subtract(const Duration(days: 12)),
        body: 'You have paid 4,608.00 ETB for Ethio Telecom Fibre Broadband. Telebirr.',
        category: 'Airtime & Internet',
      ),

      // 14. Family Support Harar (1 Oct)
      Txn(
        key: 'demo-14',
        sender: 'CBE',
        merchant: 'Family Support Transfer',
        income: false,
        amount: 1782.20,
        balance: 32138.10,
        date: today.subtract(const Duration(days: 13)),
        body: 'Direct transfer of ETB 1,782.20 sent. CBE.',
        category: 'Family & Transfers',
      ),
    ];

    await clear();
    await insertAll(sampleTxns);
    await setSenders({'CBE', 'Telebirr', 'Awash', 'Dashen', 'BOA'});
    await setSetting('onboarding_completed', 'true');
    await setSetting('user_name', 'Dawit');
  }

  /// Calculates dynamic accounts and vaults breakdown based on stored data.
  static List<AccountVault> getAccountsSummary(List<Txn> txns) {
    // Map to track latest balance or calculated net sum per institution
    final Map<BankInstitution, double> latestBalances = {};
    final Map<BankInstitution, double> netSums = {};
    final Map<BankInstitution, int> counts = {};

    // Group transactions by date descending to get most recent reported balance
    final sorted = List<Txn>.from(txns)..sort((a, b) => b.date.compareTo(a.date));

    for (final t in sorted) {
      final inst = t.institution;
      counts[inst] = (counts[inst] ?? 0) + 1;
      if (t.balance != null && !latestBalances.containsKey(inst)) {
        latestBalances[inst] = t.balance!;
      }
      final delta = t.income ? t.amount : -t.amount;
      netSums[inst] = (netSums[inst] ?? 0.0) + delta;
    }

    final activeInstitutions = counts.keys.where((k) => k != BankInstitution.cash).toList();
    if (activeInstitutions.isEmpty && counts.containsKey(BankInstitution.cash)) {
      activeInstitutions.add(BankInstitution.cash);
    }

    // If no transactions exist yet, return empty list
    if (activeInstitutions.isEmpty) {
      return [];
    }

    return activeInstitutions.map((inst) {
      final bal = latestBalances[inst] ?? (netSums[inst] != null && netSums[inst]! > 0 ? netSums[inst]! : 0.0);
      final cnt = counts[inst] ?? 0;
      final net = netSums[inst] ?? 0.0;
      final isPositive = net >= 0;

      return AccountVault(
        id: inst.name,
        name: inst.shortCode,
        subtext: inst.displayName,
        balance: bal,
        messageCount: cnt,
        institution: inst,
        note: '$cnt verified transaction${cnt == 1 ? '' : 's'}',
        trendLabel: isPositive ? '+$cnt active' : '-$cnt debits',
        isTrendPositive: isPositive,
      );
    }).toList();
  }
}
