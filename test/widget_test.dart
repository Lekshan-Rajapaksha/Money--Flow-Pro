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

      await _tap(tester, find.text('Add'));
      await tester.enterText(_field('Account name'), 'Rainy day');
      await _tap(tester, find.text('Save'));
      expect(find.text('Rainy day'), findsOneWidget);

      await _tap(tester, find.byTooltip('Add transaction'));
      await _tap(tester, find.text('Transfer'));
      await tester.enterText(_field('Amount'), '25.00');
      await _tap(tester, find.text('Save'));
      expect(find.text(r'$ 100.00'), findsOneWidget);
      expect(find.text(r'$ 125.00'), findsNWidgets(2));

      await _tap(tester, find.text('Activity'));
      await _tap(tester, find.text('Transfers'));
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Legacy salary'), findsNothing);
    },
  );

  testWidgets('records a recurring bill and persists the next occurrence', (
    tester,
  ) async {
    await _launch(tester);
    await _tap(tester, find.text('Plan'));
    await _tap(tester, find.text('Month'));
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
      await _tap(tester, find.text('Week'));
      await _tap(tester, find.byTooltip('Set overall limit'));
      await _tap(tester, find.text('Every week'));
      await _tap(tester, find.text('Only this week').last);
      await tester.enterText(_field('Weekly limit'), '3000');
      await _tap(tester, find.text('Save'));
      expect(find.text(r'$ 125.00 / $ 3,000.00'), findsOneWidget);
      await _tap(tester, find.byTooltip('Next week'));
      expect(find.text('Weekly spending'), findsOneWidget);
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
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Food'));
    expect(find.text('Filters on'), findsOneWidget);
    expect(find.text('Cafe, "lunch"'), findsOneWidget);
  });
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _launch(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(const MyApp());
    for (var attempt = 0; attempt < 50; attempt++) {
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
