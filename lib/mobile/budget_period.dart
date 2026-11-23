part of '../home.dart';

enum _BudgetPeriod {
  daily('Day', 'Daily', 'day'),
  weekly('Week', 'Weekly', 'week'),
  monthly('Month', 'Monthly', 'month');

  const _BudgetPeriod(this.tab, this.label, this.unit);
  final String tab;
  final String label;
  final String unit;

  DateTime start(DateTime date) => switch (this) {
    daily => DateUtils.dateOnly(date),
    weekly => DateTime(date.year, date.month, date.day - date.weekday + 1),
    monthly => DateTime(date.year, date.month),
  };

  DateTime move(DateTime date, int periods) {
    final first = start(date);
    return switch (this) {
      daily => DateTime(first.year, first.month, first.day + periods),
      weekly => DateTime(first.year, first.month, first.day + periods * 7),
      monthly => DateTime(first.year, first.month + periods),
    };
  }

  DateTimeRange range(DateTime date) {
    final next = move(date, 1);
    return DateTimeRange(
      start: start(date),
      end: DateTime(next.year, next.month, next.day - 1),
    );
  }

  String key(DateTime date, bool repeats) =>
      repeats
          ? name
          : '$name:${start(date).toIso8601String().split('T').first}';

  String dateLabel(DateTime date) {
    final window = range(date);
    return switch (this) {
      daily => DateFormat('EEE, MMM d, y').format(window.start),
      weekly =>
        '${DateFormat.MMMd().format(window.start)} – ${DateFormat.yMMMd().format(window.end)}',
      monthly => DateFormat.yMMMM().format(window.start),
    };
  }
}

extension _BudgetLedger on _Ledger {
  Map<String, int> _budgetBucket(
    _BudgetPeriod period,
    DateTime date,
    bool repeats,
  ) =>
      period == _BudgetPeriod.monthly && repeats
          ? budgets
          : periodBudgets[period.key(date, repeats)] ?? const {};

  Map<String, int> budgetLimits(_BudgetPeriod period, DateTime date) => {
    ..._budgetBucket(period, date, true),
    ..._budgetBucket(period, date, false),
  };

  _Ledger updateBudget(
    _BudgetPeriod period,
    DateTime date,
    bool repeats,
    String category,
    int? amount,
  ) {
    final next = {..._budgetBucket(period, date, repeats)};
    if (amount == null) {
      next.remove(category);
    } else {
      next[category] = amount;
    }
    if (period == _BudgetPeriod.monthly && repeats) {
      return copyWith(budgets: next);
    }
    final key = period.key(date, repeats);
    final buckets = {...periodBudgets};
    if (next.isEmpty) {
      buckets.remove(key);
    } else {
      buckets[key] = next;
    }
    return copyWith(periodBudgets: buckets);
  }

  _CashFlow budgetSpending(
    _BudgetPeriod period,
    DateTime date,
    DateTime today,
  ) {
    final range = period.range(date);
    return _CashFlow(
      transactions.where((entry) {
        final day = DateUtils.dateOnly(entry.date);
        return !day.isBefore(range.start) &&
            !day.isAfter(range.end) &&
            !day.isAfter(today);
      }),
    );
  }
}

int _allocatedBudget(Map<String, int> limits) => limits.entries.fold(
  0,
  (total, limit) => total + (limit.key == _allExpenses ? 0 : limit.value),
);

int? _totalBudget(Map<String, int> limits) =>
    limits.isEmpty ? null : limits[_allExpenses] ?? _allocatedBudget(limits);

const _mealCategories = <(String, String, Color, IconData)>[
  (
    'meal_breakfast',
    'Breakfast',
    Color(0xFF8B541A),
    Icons.free_breakfast_rounded,
  ),
  ('meal_lunch', 'Lunch', Color(0xFF287656), Icons.lunch_dining_rounded),
  ('meal_dinner', 'Dinner', Color(0xFF65519A), Icons.dinner_dining_rounded),
  ('meal_snacks', 'Snacks', Color(0xFFA24B67), Icons.bakery_dining_rounded),
];
