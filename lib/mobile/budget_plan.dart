part of '../home.dart';

const _lime = Color(0xFFDDF58E);
const _limeTrack = Color(0xFFB0CB71);

List<Widget> _budgetPlan(BuildContext context, _MainPageState state) {
  final period = state._budgetPeriod;
  final date = state._budgetDate;
  final today = DateUtils.dateOnly(DateTime.now());
  final window = period.range(date);
  final limits = state._ledger.budgetLimits(period, date);
  final oneTime = state._ledger._budgetBucket(period, date, false);
  final flow = state._ledger.budgetSpending(period, date, today);
  final canLog = !window.start.isAfter(today);
  final logDate = today.isAfter(window.end) ? window.start : today;
  final categoryLimits =
      limits.entries.where((item) => item.key != _allExpenses).toList()..sort(
        (a, b) => state._budgetName(a.key).compareTo(state._budgetName(b.key)),
      );
  final meals = <(String, String, IconData)>[];
  for (final (id, name, _, icon) in _mealCategories) {
    final category =
        state._categories
            .where(
              (item) =>
                  item.isExpense &&
                  item.name.toLowerCase() == name.toLowerCase(),
            )
            .firstOrNull;
    if (category == null && state._category(id) != null) continue;
    final key = category?.id ?? id;
    if (!limits.containsKey(key)) meals.add((key, name, icon));
  }

  return [
    const SizedBox(height: 16),
    SegmentedButton<_BudgetPeriod>(
      showSelectedIcon: false,
      segments: [
        for (final option in _BudgetPeriod.values)
          ButtonSegment(value: option, label: Text(option.tab)),
      ],
      selected: {period},
      onSelectionChanged:
          (selection) => state._selectBudgetPeriod(selection.single),
    ),
    const SizedBox(height: 12),
    _Surface(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous ${period.unit}',
            onPressed: () => state._moveBudgetDate(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              period.dateLabel(date),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Next ${period.unit}',
            onPressed: () => state._moveBudgetDate(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    ),
    if (period.start(date) != period.start(today))
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => state._moveBudgetDate(0),
          child: Text('Back to this ${period.unit}'),
        ),
      )
    else
      const SizedBox(height: 12),
    _BudgetSummary(
      state: state,
      limits: limits,
      spent: flow.spent,
      window: window,
    ),
    _Section(
      'Category limits',
      action: TextButton.icon(
        onPressed: state._editBudget,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add limit'),
      ),
    ),
    if (categoryLimits.isEmpty)
      const _Empty(
        Icons.track_changes_rounded,
        'Give your spending a limit',
        'Start with a meal below or choose another category.',
      ),
    for (final limit in categoryLimits) ...[
      _BudgetCategoryTile(
        state: state,
        id: limit.key,
        amount: limit.value,
        spent: flow.expenseByCategory[limit.key] ?? 0,
        window: window,
        logDate: canLog ? logDate : null,
        repeats: !oneTime.containsKey(limit.key),
      ),
      const SizedBox(height: 8),
    ],
    if (meals.isNotEmpty) ...[
      _Section('Quick meal limits'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (id, name, icon) in meals)
            ActionChip(
              avatar: Icon(icon, size: 17, color: context.colors.primary),
              label: Text(name),
              onPressed: () => state._editBudget(suggested: id),
            ),
        ],
      ),
    ],
  ];
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({
    required this.state,
    required this.limits,
    required this.spent,
    required this.window,
  });

  final _MainPageState state;
  final Map<String, int> limits;
  final int spent;
  final DateTimeRange window;

  @override
  Widget build(BuildContext context) {
    final total = _totalBudget(limits);
    final dark = context.colors.brightness == Brightness.dark;
    final foreground = context.colors.onSecondaryContainer;
    final track = dark ? context.colors.outlineVariant : _limeTrack;
    final cap = limits[_allExpenses];
    final allocated = _allocatedBudget(limits);
    final remaining = total == null ? null : total - spent;
    return _TintedCard(
      padding: const EdgeInsets.all(18),
      ringColor: const Color(0x3017604A),
      decoration: BoxDecoration(
        color: dark ? context.colors.secondaryContainer : _lime,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining == null
                      ? '${state._budgetPeriod.label} spending'
                      : remaining < 0
                      ? 'Over budget'
                      : 'Left to spend',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    cap == null ? 'Set overall limit' : 'Edit overall limit',
                onPressed:
                    () => state._editBudget(
                      category: cap == null ? null : _allExpenses,
                    ),
                icon: Icon(
                  cap == null ? Icons.add_rounded : Icons.tune_rounded,
                  color: foreground,
                ),
              ),
            ],
          ),
          Text(
            state._money(remaining?.abs() ?? spent),
            style: TextStyle(
              color: foreground,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -1.2,
            ),
          ),
          if (total != null) ...[
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (spent / total).clamp(0, 1),
                backgroundColor: track,
                color: remaining! < 0 ? context.colors.error : foreground,
                minHeight: 8,
                semanticsLabel: 'Budget spent',
              ),
            ),
            const SizedBox(height: 9),
            _Metric(
              cap == null ? 'Category total' : 'All expenses',
              '${state._money(spent)} / ${state._money(total)}',
              foreground,
            ),
            if (cap != null && allocated > cap)
              Text(
                'Category limits exceed the cap by ${state._money(allocated - cap)}.',
                style: TextStyle(
                  color: context.colors.error,
                  fontWeight: FontWeight.w700,
                ),
              )
            else if (cap != null && allocated > 0 && allocated < cap)
              Text(
                '${state._money(cap - allocated)} of the cap is unallocated.',
              ),
          ],
          if (spent > 0)
            TextButton.icon(
              onPressed:
                  () => state._openActivity(
                    kind: _EntryKind.expense,
                    range: window,
                  ),
              icon: const Icon(Icons.arrow_outward_rounded, size: 16),
              label: const Text('View spending'),
            ),
        ],
      ),
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  const _BudgetCategoryTile({
    required this.state,
    required this.id,
    required this.amount,
    required this.spent,
    required this.window,
    required this.logDate,
    required this.repeats,
  });

  final _MainPageState state;
  final String id;
  final int amount;
  final int spent;
  final DateTimeRange window;
  final DateTime? logDate;
  final bool repeats;

  @override
  Widget build(BuildContext context) {
    final category = state._category(id);
    final name = state._budgetName(id);
    final left = amount - spent;
    return _Surface(
      child: Column(
        children: [
          Row(
            children: [
              _IconChip(
                category?.icon ?? Icons.category_outlined,
                color: category?.color ?? context.colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap:
                      () => state._openActivity(
                        category: id,
                        kind: _EntryKind.expense,
                        range: window,
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        repeats
                            ? 'Repeats every ${state._budgetPeriod.unit}'
                            : 'Only this ${state._budgetPeriod.unit}',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (logDate != null)
                IconButton(
                  tooltip: 'Log $name expense',
                  onPressed:
                      () => state._editEntry(category: id, date: logDate),
                  icon: const Icon(Icons.add_rounded),
                ),
              IconButton(
                tooltip: 'Edit $name limit',
                onPressed: () => state._editBudget(category: id),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _Meter(
            label: '${state._money(left.abs())} ${left < 0 ? 'over' : 'left'}',
            detail: '${state._money(spent)} / ${state._money(amount)}',
            amount: spent,
            target: amount,
            spendingLimit: true,
          ),
        ],
      ),
    );
  }
}
