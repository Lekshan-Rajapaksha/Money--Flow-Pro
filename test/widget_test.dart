import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyflow1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const dataChannel = MethodChannel('com.lekshan.moneyflow/export');
  late Directory documents;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('money-flow-test-');
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (call) async => documents.path);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dataChannel, null);
    documents.deleteSync(recursive: true);
  });

  testWidgets(
    'migrates a legacy transaction and keeps transfers out of cash flow',
    (tester) async {
      File('${documents.path}/transactions.json').writeAsStringSync(
        jsonEncode([
          {
            'id': 'legacy-salary',
            'description': 'Legacy salary',
            'amount': 125,
            'isExpense': false,
            'categoryId': 'salary',
            'date': DateTime.now().toIso8601String(),
          },
        ]),
      );
      await _launch(tester);
      expect(find.text('Legacy salary'), findsOneWidget);
      expect(find.text(r'$ 125.00'), findsWidgets);

      await _tap(tester, find.byTooltip('Settings'));
      await _tap(tester, find.text('Accounts'));
      await _tap(tester, find.byTooltip('Add account'));
      await tester.enterText(_field('Account name'), 'Rainy day');
      await _tap(tester, find.text('Save'));
      expect(find.text('Rainy day'), findsOneWidget);
      await _tap(tester, find.text('Overview'));

      await _tap(tester, find.byTooltip('Add transaction'));
      await _tap(tester, find.text('Transfer'));
      await tester.enterText(_field('Amount'), '25.00');
      await _tap(tester, find.text('Save'));
      expect(find.text(r'$ 100.00'), findsOneWidget);
      expect(find.text(r'$ 125.00'), findsOneWidget);

      await _tap(tester, find.text('Activity'));
      await _tap(tester, find.text('Transfers'));
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Legacy salary'), findsNothing);
    },
  );

  testWidgets('switches accounts in Settings and scopes Insights by date', (
    tester,
  ) async {
    final today = DateTime.now().toIso8601String();
    SharedPreferences.setMockInitialValues({'dailyLimit': 75.0});
    File('${documents.path}/ledger.json').writeAsStringSync(
      jsonEncode({
        'version': 1,
        'accounts': [
          {'id': 'main', 'name': 'Main account', 'kind': 'cash', 'opening': 0},
          {
            'id': 'bank',
            'name': 'Bank account',
            'kind': 'bank',
            'opening': 50000,
          },
        ],
        'transactions': [
          for (final (id, category, amount) in [
            ('main', 'food', 40),
            ('bank', 'shopping', 25),
          ])
            {
              'id': 'expense-$id',
              'description': '$id purchase',
              'amount': amount,
              'isExpense': true,
              'categoryId': category,
              'date': today,
              'accountId': id,
            },
        ],
        'budgets': {},
        'goals': [],
        'schedule': [],
      }),
    );
    await _launch(tester);
    expect(find.text('Spending plans'), findsNothing);
    expect(find.text('main purchase'), findsOneWidget);
    expect(find.text('bank purchase'), findsNothing);

    await _tap(tester, find.byTooltip('Settings'));
    await _tap(tester, find.text('Accounts'));
    await _tap(tester, find.text('Bank account'));
    await _tap(tester, find.text('Overview'));
    expect(find.text('Bank account'), findsOneWidget);
    expect(find.text(r'$ 475.00'), findsOneWidget);
    expect(find.text('bank purchase'), findsOneWidget);
    await _tap(tester, find.byTooltip('Hide overview amounts'));
    expect(find.text(r'$ 475.00'), findsNothing);

    await _tap(tester, find.text('Plan'));
    expect(find.text(r'$ 65.00 / $ 75.00'), findsOneWidget);
    await _tap(tester, find.text('Insights'));
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text(r'$ 25.00'), findsWidgets);
    await tester.tap(find.text('All accounts'));
    await tester.pumpAndSettle();
    expect(find.text(r'$ 65.00'), findsWidgets);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text(r'$ 65.00'), findsWidgets);
    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('Back to today'), findsOneWidget);
    expect(find.text(r'$ 65.00'), findsNothing);

    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();
    expect(find.text(r'$ 65.00'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await _launch(tester);
    expect(find.text('Bank account'), findsOneWidget);
    expect(find.byTooltip('Show overview amounts'), findsOneWidget);
  });

  testWidgets(
    'opens with the branded splash and saves loan payments and top-ups',
    (tester) async {
      File('${documents.path}/loans.json').writeAsStringSync(
        jsonEncode([
          {
            'id': 'loan-one',
            'type': 'given',
            'personName': 'Amaya',
            'amount': 100,
            'date': DateTime.now().toIso8601String(),
          },
        ]),
      );

      SharedPreferences.setMockInitialValues({'savingsPot': 40.0});
      File('${documents.path}/fixed_deposits.json').writeAsStringSync(
        jsonEncode([
          {
            'amount': 200.0,
            'maturityDate': DateTime(2090, 1, 2).toIso8601String(),
          },
        ]),
      );
      await _launch(tester, verifySplash: true);
      final cards = find.byKey(const PageStorageKey('overview-cards'));
      await tester.drag(cards, const Offset(-550, 0));
      await tester.pumpAndSettle();
      expect(find.text('Owed to you'), findsOneWidget);
      expect(find.text('Loan summary'), findsOneWidget);
      expect(find.text('Amaya'), findsOneWidget);
      expect(find.text('Recent activity'), findsNothing);
      await tester.drag(cards, const Offset(-550, 0));
      await tester.pumpAndSettle();
      expect(find.text('Savings & deposits'), findsOneWidget);
      expect(find.text(r'$ 240.00'), findsOneWidget);
      expect(find.text('Savings summary'), findsOneWidget);
      expect(find.text('Savings pot balance'), findsOneWidget);
      expect(find.text('Loan summary'), findsNothing);

      Future<void> openLoans() async {
        await _tap(tester, find.text('More'));
        await _tap(tester, find.text('Loans'));
      }

      await openLoans();
      expect(find.text(r'$ 100.00 remaining'), findsOneWidget);
      await _tap(tester, find.text('Record payment'));
      await tester.enterText(_field('Payment amount'), '101');
      await _tap(tester, find.text('Save'));
      expect(find.text(r'Enter $ 100.00 or less.'), findsOneWidget);
      await tester.enterText(_field('Payment amount'), '25.50');
      await _tap(tester, find.text('Save'));
      expect(find.text(r'$ 74.50 remaining'), findsOneWidget);
      expect(find.text(r'$74.50'), findsOneWidget);

      await _tap(tester, find.text('Add to loan'));
      await tester.enterText(_field('Additional amount'), '50');
      await _tap(tester, find.text('Save'));
      expect(find.text(r'$ 124.50 remaining'), findsOneWidget);
      expect(find.text(r'$ 25.50 / $ 150.00 paid'), findsOneWidget);

      final saved = await tester.runAsync(() async {
        final file = File('${documents.path}/loans.json');
        for (var attempt = 0; attempt < 50; attempt++) {
          await tester.pump();
          final loan =
              (jsonDecode(await file.readAsString()) as List).single as Map;
          if (loan['amount'] == 150 && loan['paidAmount'] == 25.5) return true;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        return false;
      });
      expect(saved, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await _launch(tester);
      await openLoans();
      expect(find.text(r'$ 124.50 remaining'), findsOneWidget);
      await _tap(tester, find.text('Record payment'));
      await tester.enterText(_field('Payment amount'), '124.50');
      await _tap(tester, find.text('Save'));
      expect(find.text('Amaya'), findsNothing);
      await _tap(tester, find.text('Paid'));
      expect(find.text(r'$ 0.00 remaining'), findsOneWidget);
    },
  );

  testWidgets('records a recurring bill and persists the next occurrence', (
    tester,
  ) async {
    await _launch(tester);
    await _tap(tester, find.text('Plan'));
    await _tap(tester, find.byTooltip('Budget period'));
    await tester.tap(_budgetPeriodItem('Month'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Add limit'));
    await tester.enterText(_field('Monthly limit'), '100');
    await _tap(tester, find.text('Save'));
    expect(find.text('All expenses'), findsOneWidget);

    await _tap(tester, find.text('Schedule'));
    await _tap(tester, find.text('New schedule'));
    await tester.enterText(_field('Amount'), '20');
    await tester.enterText(_field('Name or note'), 'Internet');
    await _tap(tester, find.text('Save'));
    await _tap(tester, find.text('Internet'));
    await _tap(tester, find.text('Record transaction'));

    await _tap(tester, find.text('Budgets'));
    expect(find.text(r'$ 20.00 / $ 100.00'), findsOneWidget);
    final saved = await tester.runAsync(() async {
      final file = File('${documents.path}/ledger.json');
      for (var attempt = 0; attempt < 50; attempt++) {
        if (await file.exists()) {
          final stored = jsonDecode(await file.readAsString()) as Map;
          if ((stored['transactions'] as List).isNotEmpty) return stored;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
      return null;
    });
    expect(saved, isNotNull);
    expect((saved!['schedule'] as List).single['occurrence'], 1);
    expect((saved['transactions'] as List).single['description'], 'Internet');
    await tester.pumpWidget(const SizedBox.shrink());
    await _launch(tester);
    await _tap(tester, find.text('Activity'));
    expect(find.text('Internet'), findsOneWidget);
    await _tap(tester, find.text('Plan'));
    await _tap(tester, find.text('Schedule'));
    expect(find.text('Internet'), findsOneWidget);
  });

  testWidgets(
    'plans meals, logs categorized spending, and sets a one-week cap',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _launch(tester);
      await _tap(tester, find.text('Plan'));
      final plan = find.byType(CustomScrollView);
      await tester.scrollUntilVisible(find.text('Breakfast'), 200);
      await _tap(tester, find.text('Breakfast'));
      await tester.enterText(_field('Daily limit'), '500');
      await _tap(tester, find.text('Save'));
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 50; attempt++) {
          if (find.byTooltip('Log Breakfast expense').evaluate().isNotEmpty) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
      });
      await tester.scrollUntilVisible(find.text('Dinner'), 200);
      await _tap(tester, find.text('Dinner'));
      await tester.enterText(_field('Daily limit'), '400');
      await _tap(tester, find.text('Save'));
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 50; attempt++) {
          if (find.byTooltip('Log Dinner expense').evaluate().isNotEmpty) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
      });
      await tester.scrollUntilVisible(find.text(r'$ 900.00'), -200);
      expect(find.text(r'$ 0.00 / $ 900.00'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byTooltip('Log Breakfast expense'),
        200,
      );
      await _tap(tester, find.byTooltip('Log Breakfast expense'));
      await tester.enterText(_field('Amount'), '125');
      await _tap(tester, find.text('Save'));
      expect(find.text(r'$ 125.00 / $ 500.00'), findsOneWidget);

      await tester.drag(plan, const Offset(0, 850));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Budget period'));
      await tester.tap(_budgetPeriodItem('Week'));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Set overall limit'));
      await _tap(tester, find.text('Every week'));
      await _tap(tester, find.text('Only this week').last);
      await tester.enterText(_field('Weekly limit'), '3000');
      await _tap(tester, find.text('Save'));
      expect(find.text(r'$ 125.00 / $ 3,000.00'), findsOneWidget);
      await _tap(tester, find.byTooltip('Next week'));
      expect(find.text(r'$ 0.00 / $ 6,300.00'), findsOneWidget);
      await _tap(tester, find.text('Back to this week'));
      expect(find.text(r'$ 125.00 / $ 3,000.00'), findsOneWidget);

      final persisted = await tester.runAsync(() async {
        final file = File('${documents.path}/ledger.json');
        for (var attempt = 0; attempt < 50; attempt++) {
          if (await file.exists()) {
            final stored = jsonDecode(await file.readAsString()) as Map;
            final budgets = stored['periodBudgets'] as Map?;
            if (budgets != null && budgets.length == 2) return budgets;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        return null;
      });
      expect(persisted?['daily'], {
        'meal_breakfast': 50000,
        'meal_dinner': 40000,
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await _launch(tester);
      await _tap(tester, find.text('Plan'));
      expect(find.text(r'$ 125.00 / $ 900.00'), findsOneWidget);
    },
  );

  testWidgets('rolls up daily limits and spreads one bulk expense', (
    tester,
  ) async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - now.weekday - 6);
    File('${documents.path}/ledger.json').writeAsStringSync(
      jsonEncode({
        'version': 1,
        'accounts': [
          {'id': 'main', 'name': 'Main account', 'kind': 'cash', 'opening': 0},
        ],
        'transactions': [
          {
            'id': 'weekly-bread',
            'description': 'Bread for the week',
            'amount': 700,
            'isExpense': true,
            'categoryId': 'food',
            'date':
                DateTime(
                  monday.year,
                  monday.month,
                  monday.day - 1,
                ).toIso8601String(),
            'coverageDays': 7,
            'coverageStart': monday.toIso8601String(),
          },
        ],
        'budgets': {},
        'periodBudgets': {
          'daily': {'food': 30000},
        },
        'goals': [],
        'schedule': [],
      }),
    );

    await _launch(tester);
    expect(find.text(r'-$ 700.00'), findsWidgets);
    await _tap(tester, find.text('Plan'));
    await _tap(tester, find.byTooltip('Budget period'));
    await tester.tap(_budgetPeriodItem('Week'));
    await tester.pumpAndSettle();
    await _tap(tester, find.byTooltip('Previous week'));
    expect(find.text(r'$ 700.00 / $ 2,100.00'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Daily breakdown'), 200);
    await _tap(tester, find.text('Daily breakdown'));
    await tester.scrollUntilVisible(
      find.text(r'$ 100.00 / $ 300.00').last,
      200,
    );
    expect(find.text(r'$ 200.00 left'), findsWidgets);
  });

  testWidgets('appearance follows the device and persists across the app', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    void expectMode(String label, Brightness brightness) {
      final view = tester.element(find.text(label).first);
      final theme = Theme.of(view);
      expect(theme.brightness, brightness);
      final luminance = theme.colorScheme.surface.computeLuminance();
      expect(
        luminance,
        brightness == Brightness.dark ? lessThan(.15) : greaterThan(.85),
      );
    }

    await _launch(tester);
    expectMode('Your overview', Brightness.dark);
    await _tap(tester, find.text('More'));
    await _tap(tester, find.text('Settings'));
    await _tap(tester, find.text('Appearance'));
    await _tap(tester, find.text('Light'));
    expectMode('Appearance', Brightness.light);
    await _tap(tester, find.text('Appearance'));
    await _tap(tester, find.text('Dark'));
    expectMode('Appearance', Brightness.dark);

    await _tap(tester, find.text('Category Manager'));
    expectMode('Manage Categories', Brightness.dark);
    await _tap(tester, find.text('New Category'));
    expectMode('Category Name', Brightness.dark);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await _tap(tester, find.text('Plan'));
    expectMode('Spending plan', Brightness.dark);
    await _tap(tester, find.text('Goals'));
    expectMode('Savings goals', Brightness.dark);
    await _tap(tester, find.text('Schedule'));
    expectMode('Bills and income', Brightness.dark);
    await _tap(tester, find.text('Activity'));
    expectMode('Search transactions', Brightness.dark);
    await _tap(tester, find.byTooltip('Add transaction'));
    expectMode('Add transaction', Brightness.dark);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Insights'));
    await _tap(tester, find.text('Detailed reports'));
    expectMode('Statistics', Brightness.dark);
    await _tap(tester, find.text('More'));
    await _tap(tester, find.text('Loans'));
    expectMode('Loan Manager', Brightness.dark);
    await _tap(tester, find.text('More'));
    await _tap(tester, find.text('Savings & deposits'));
    expectMode('TOTAL BALANCE', Brightness.dark);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await _launch(tester);
    expectMode('Your overview', Brightness.dark);
    await _tap(tester, find.byTooltip('Settings'));
    await _tap(tester, find.text('Appearance'));
    await _tap(tester, find.text('System'));
    expectMode('Appearance', Brightness.light);
  });

  testWidgets('previews CSV history and skips entries on repeat import', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final today = DateTime.now().toIso8601String().split('T').first;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dataChannel, (call) async {
          expect(call.method, 'pickCsv');
          return Uint8List.fromList(
            utf8.encode(
              '\uFEFFDate,Type,Amount,Currency,Category,Note\r\n'
              '$today,expense,17.25,USD,Food,"Cafe, ""lunch"""\r\n',
            ),
          );
        });
    await _launch(tester);
    await _tap(tester, find.text('More'));
    await _tap(tester, find.text('Import transactions'));
    expect(
      find.text('1 new transactions\n0 existing transactions skipped'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Import'));
    expect(find.text('Cafe, "lunch"'), findsOneWidget);

    await _tap(tester, find.text('More'));
    await _tap(tester, find.text('Import transactions'));
    expect(
      find.text('0 new transactions\n1 existing transactions skipped'),
      findsOneWidget,
    );
    expect(find.text('Import'), findsNothing);
    await _tap(tester, find.text('Close'));
    await _tap(tester, find.text('Insights'));
    await tester.scrollUntilVisible(find.text('Food'), 200);
    await _tap(tester, find.text('Food'));
    expect(find.text('Filters on'), findsOneWidget);
    expect(find.text('Cafe, "lunch"'), findsOneWidget);
  });
}

Finder _budgetPeriodItem(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is CheckedPopupMenuItem &&
      widget.child is Text &&
      (widget.child! as Text).data == label,
);

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _launch(WidgetTester tester, {bool verifySplash = false}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(const MyApp());
    if (verifySplash) expect(find.text('Created by LexN'), findsOneWidget);
    for (var attempt = 0; attempt < 300; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
      if (find.text('Your overview').evaluate().isNotEmpty) return;
    }
  });
  expect(find.text('Your overview'), findsOneWidget);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
