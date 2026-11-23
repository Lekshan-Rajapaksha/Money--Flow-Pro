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

  Map<String, int> budgetLimits(_BudgetPeriod period, DateTime date) {
    final limits = {
      ..._budgetBucket(period, date, true),
      ..._budgetBucket(period, date, false),
    };
    if (period == _BudgetPeriod.daily) return limits;
    final dailyTotals = <String, int>{};
    for (final day in _budgetDays(period.range(date))) {
      for (final limit in budgetLimits(_BudgetPeriod.daily, day).entries) {
        dailyTotals.update(
          limit.key,
          (total) => total + limit.value,
          ifAbsent: () => limit.value,
        );
      }
    }
    return {...dailyTotals, ...limits};
  }

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

  Map<DateTime, _CashFlow> budgetSpendingByDay(
    DateTimeRange range,
    DateTime today,
  ) {
    final days = {for (final day in _budgetDays(range)) day: _CashFlow([])};
    for (final entry in transactions) {
      if (entry._kind != _EntryKind.expense) continue;
      final purchase = DateUtils.dateOnly(entry.date);
      if (purchase.isAfter(today)) continue;
      final start = entry._planStart;
      if (start.isAfter(range.end)) continue;
      final lastDay = _shiftBudgetDay(start, entry.coverageDays - 1);
      if (lastDay.isBefore(range.start)) continue;
      final amount = _minor(entry.amount);
      for (var index = 0; index < entry.coverageDays; index++) {
        final flow = days[_shiftBudgetDay(start, index)];
        if (flow == null) continue;
        flow.addExpense(
          entry.categoryId,
          _budgetShare(amount, entry.coverageDays, index),
        );
      }
    }
    return days;
  }
}

DateTime _shiftBudgetDay(DateTime day, int offset) =>
    DateTime(day.year, day.month, day.day + offset);

Iterable<DateTime> _budgetDays(DateTimeRange range) sync* {
  for (
    var day = range.start;
    !day.isAfter(range.end);
    day = _shiftBudgetDay(day, 1)
  ) {
    yield day;
  }
}

int _budgetShare(int amount, int days, int index) =>
    amount ~/ days + (index < amount % days ? 1 : 0);

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
