import 'package:birr_tracker/models/models.dart';
import 'package:birr_tracker/parser.dart';
import 'package:birr_tracker/theme/app_colors.dart';
import 'package:birr_tracker/widgets/app_header.dart';
import 'package:birr_tracker/widgets/meskel_watermark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ethiopian SMS Parser Tests', () {
    test('Telebirr payment parsing', () {
      const sms =
          'Dear Customer, You have paid 1,850.50 ETB to SHOA SUPERMARKET on 12/10/2024 18:20:14. Trans ID: 8J92KL910. Your current balance is 24,650.00 ETB. Telebirr.';
      final parsed = parseSms(sms);

      expect(parsed, isNotNull);
      expect(parsed!.income, isFalse);
      expect(parsed.amount, equals(1850.50));
      expect(parsed.balance, equals(24650.00));
      expect(parsed.category, equals('Groceries & Food'));
      expect(parsed.merchant.toLowerCase(), contains('shoa supermarket'));
      expect(parsed.txRef, equals('#8J92KL910'));
    });

    test('CBE Salary credit parsing', () {
      const sms =
          'Your account 10009402 has been credited with ETB 35,000.00 on 29/10/2026. Ref: FT992123. Current balance is ETB 82,400.00. Commercial Bank of Ethiopia.';
      final parsed = parseSms(sms);

      expect(parsed, isNotNull);
      expect(parsed!.income, isTrue);
      expect(parsed.amount, equals(35000.00));
      expect(parsed.balance, equals(82400.00));
      expect(parsed.category, equals('Salary & Income'));
    });

    test('Ignore OTP / Verification messages', () {
      const otpSms = 'Your telebirr verification code is 492102. Never share this code with anyone.';
      final parsed = parseSms(otpSms);
      expect(parsed, isNull);
    });
  });

  group('Models & Enums Tests', () {
    test('BankInstitution detection', () {
      expect(BankInstitution.fromSender('CBE'), equals(BankInstitution.cbe));
      expect(BankInstitution.fromSender('Telebirr'), equals(BankInstitution.telebirr));
      expect(BankInstitution.fromSender('127'), equals(BankInstitution.telebirr));
      expect(BankInstitution.fromSender('AwashBank'), equals(BankInstitution.awash));
      expect(BankInstitution.fromSender('Dashen Bank'), equals(BankInstitution.dashen));
    });

    test('ExpenseCategory lookup', () {
      final groceries = ExpenseCategory.find('Groceries & Food');
      expect(groceries.emoji, equals('🛒'));
      expect(groceries.color, equals(AppColors.primary));
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('AppHeader renders brand logo and notification button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader(),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Wey Birre'), findsNothing);
      expect(find.text('Offline & Safe'), findsNothing);
    });

    testWidgets('AppHeader renders unread badge when unreadNotificationsCount > 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader(unreadNotificationsCount: 3),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      // Finding the Stack with badge container
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('MeskelWatermark renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeskelWatermark(size: 100),
          ),
        ),
      );

      expect(find.byType(MeskelWatermark), findsOneWidget);
    });
  });

  group('Notifications Model Tests', () {
    test('AppNotification toMap and fromMap serialization', () {
      final now = DateTime.now();
      final notif = AppNotification(
        id: 1,
        title: 'New Bank Alert',
        body: 'Paid 350.00 ETB to Shoa',
        timestamp: now,
        isRead: false,
        type: 'sms_debit',
        meta: 'CBE|ref123',
      );

      final map = notif.toMap();
      expect(map['title'], equals('New Bank Alert'));
      expect(map['is_read'], equals(0));
      expect(map['type'], equals('sms_debit'));

      final reconstructed = AppNotification.fromMap(map);
      expect(reconstructed.id, equals(1));
      expect(reconstructed.title, equals('New Bank Alert'));
      expect(reconstructed.isRead, isFalse);
      expect(reconstructed.type, equals('sms_debit'));
    });
  });
}
