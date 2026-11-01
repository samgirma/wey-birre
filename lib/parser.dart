class Parsed {
  final bool income;
  final double amount;
  final double? balance;
  final String merchant;
  final String category;
  final String? txRef;

  Parsed({
    required this.income,
    required this.amount,
    this.balance,
    required this.merchant,
    required this.category,
    this.txRef,
  });
}

const _inWords = [
  'credited',
  'deposited',
  'deposit',
  'received',
  'credit',
  'inward',
  'salary',
  'cash in',
];

const _outWords = [
  'debited',
  'withdrawn',
  'withdrawal',
  'transferred',
  'paid',
  'purchase',
  'sent',
  'debit',
  'transfer to',
  'cash out',
  'bought',
];

double _num(String s) => double.parse(s.replaceAll(',', ''));

String _extractMerchant(String text, bool income) {
  final t = text.replaceAll('\n', ' ');

  // Pattern: "paid ... to <MERCHANT> on/at/."
  final paidTo = RegExp(r'paid\s+[\d,.]+\s*(?:etb|birr)?\s+to\s+([^,.\n0-9]+?)(?:\s+(?:on|at|with|\.)|$)', caseSensitive: false);
  final m1 = paidTo.firstMatch(t);
  if (m1 != null && m1.group(1) != null) {
    return _cleanMerchant(m1.group(1)!);
  }

  // Pattern: "for <MERCHANT>" or "at <MERCHANT>"
  final forAt = RegExp(r'(?:for|at)\s+([A-Za-z0-9\s&]+?)(?:\s+(?:on|via|with|\.)|$)', caseSensitive: false);
  final m2 = forAt.firstMatch(t);
  if (m2 != null && m2.group(1) != null) {
    final cand = m2.group(1)!.trim();
    if (cand.length > 2 && !cand.toLowerCase().startsWith('etb')) {
      return _cleanMerchant(cand);
    }
  }

  // Pattern: "transfer to <NAME>"
  final transferTo = RegExp(r'transfer\s+to\s+([A-Za-z\s]+?)(?:\s+(?:completed|is|\.)|$)', caseSensitive: false);
  final m3 = transferTo.firstMatch(t);
  if (m3 != null && m3.group(1) != null) {
    return 'Transfer to ${_cleanMerchant(m3.group(1)!)}';
  }

  // Pattern: "from <NAME>"
  final fromMatch = RegExp(r'from\s+([A-Za-z0-9\s]+?)(?:\s+(?:on|via|\.)|$)', caseSensitive: false);
  final m4 = fromMatch.firstMatch(t);
  if (m4 != null && m4.group(1) != null) {
    return 'From ${_cleanMerchant(m4.group(1)!)}';
  }

  return income ? 'Income / Deposit' : 'Payment / Purchase';
}

String _cleanMerchant(String s) {
  var clean = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.length > 32) clean = clean.substring(0, 32).trim();
  // Capitalize nicely if all uppercase
  if (clean == clean.toUpperCase() && clean.length > 3) {
    clean = clean.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  return clean;
}

String _inferCategory(String merchant, String body, bool income) {
  if (income) return 'Salary & Income';

  final combined = '$merchant $body'.toLowerCase();

  if (combined.contains('supermarket') ||
      combined.contains('grocer') ||
      combined.contains('mart') ||
      combined.contains('cafe') ||
      combined.contains('coffee') ||
      combined.contains('shoa') ||
      combined.contains('kaldis') ||
      combined.contains('restaurant') ||
      combined.contains('burger') ||
      combined.contains('food')) {
    return 'Groceries & Food';
  }

  if (combined.contains('fuel') ||
      combined.contains('total') ||
      combined.contains('oil') ||
      combined.contains('gas') ||
      combined.contains('taxi') ||
      combined.contains('ride') ||
      combined.contains('feres') ||
      combined.contains('transport')) {
    return 'Transport & Fuel';
  }

  if (combined.contains('airtime') ||
      combined.contains('telecom') ||
      combined.contains('ethio telecom') ||
      combined.contains('recharge') ||
      combined.contains('800mb') ||
      combined.contains('data') ||
      combined.contains('internet') ||
      combined.contains('package')) {
    return 'Airtime & Internet';
  }

  if (combined.contains('transfer') ||
      combined.contains('sent to') ||
      combined.contains('family') ||
      combined.contains('friend') ||
      combined.contains('almaz')) {
    return 'Family & Transfers';
  }

  if (combined.contains('rent') ||
      combined.contains('electric') ||
      combined.contains('water') ||
      combined.contains('utility') ||
      combined.contains('house') ||
      combined.contains('housing')) {
    return 'Housing & Utilities';
  }

  return 'Other & Miscellaneous';
}

String? _extractTxRef(String body) {
  final refRe = RegExp(r'(?:trans(?:action)?\s*id|txn|ref|tx|ft)[\s:#]+([A-Za-z0-9]+)', caseSensitive: false);
  final m = refRe.firstMatch(body);
  if (m != null) return '#${m.group(1)}';
  return null;
}

/// Returns null when the SMS is not a money-movement message (OTP, ads, promo).
Parsed? parseSms(String body) {
  final t = body.replaceAll('\n', ' ');
  final l = t.toLowerCase();

  // Exclude non-transaction messages like verification codes or generic promos
  if (l.contains('verification code') ||
      l.contains('otp') ||
      l.contains('security code') ||
      (l.contains('password') && !l.contains('paid'))) {
    return null;
  }

  int first(List<String> words) {
    var best = -1;
    for (final w in words) {
      final i = l.indexOf(w);
      if (i >= 0 && (best < 0 || i < best)) best = i;
    }
    return best;
  }

  final i = first(_inWords), o = first(_outWords);
  if (i < 0 && o < 0) return null;
  final income = o < 0 || (i >= 0 && i < o);

  final amountRe = RegExp(
      r'(?:etb|birr|br)\.?\s*([\d,]+(?:\.\d+)?)|([\d,]+(?:\.\d+)?)\s*(?:etb|birr)',
      caseSensitive: false);
  final m = amountRe.firstMatch(t);
  if (m == null) return null;
  final amountStr = m.group(1) ?? m.group(2);
  if (amountStr == null) return null;
  final amount = _num(amountStr);
  if (amount <= 0) return null;

  final balRe = RegExp(r'(?:balance|bal|current bal)[\s:is]+(?:etb|birr)?\s*([\d,]+(?:\.\d+)?)',
      caseSensitive: false);
  final b = balRe.firstMatch(t);
  final balance = b != null ? _num(b.group(1)!) : null;

  final merchant = _extractMerchant(t, income);
  final category = _inferCategory(merchant, t, income);
  final txRef = _extractTxRef(t);

  return Parsed(
    income: income,
    amount: amount,
    balance: balance,
    merchant: merchant,
    category: category,
    txRef: txRef,
  );
}
