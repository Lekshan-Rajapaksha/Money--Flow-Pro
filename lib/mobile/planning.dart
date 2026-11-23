part of '../home.dart';

enum _Destination { overview, activity, plan, insights, tools }

enum _PlanSection { budgets, goals, schedule }

enum _Tools { menu, wallet, loans, settings, reports }

class _Planning extends StatelessWidget {
  const _Planning({required this.state});
  final _MainPageState state;

  @override
  Widget build(BuildContext context) => _Page(
    storageKey: 'plan-${state._planSection.name}',
    pinnedHeader: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Spending plan'),
        SegmentedButton<_PlanSection>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _PlanSection.budgets, label: Text('Budgets')),
            ButtonSegment(value: _PlanSection.goals, label: Text('Goals')),
            ButtonSegment(
              value: _PlanSection.schedule,
              label: Text('Schedule'),
            ),
          ],
          selected: {state._planSection},
          onSelectionChanged: (selection) => state._openPlan(selection.single),
        ),
      ],
    ),
    children: [
      ...switch (state._planSection) {
        _PlanSection.budgets => _budgetPlan(context, state),
        _PlanSection.goals => _goals(context),
        _PlanSection.schedule => _schedule(),
      },
    ],
  );

  List<Widget> _goals(BuildContext context) => [
    _Section(
      'Savings goals',
      action: TextButton.icon(
        onPressed: () => state._editGoal(),
        icon: const Icon(Icons.add),
        label: const Text('Goal'),
      ),
    ),
    if (state._ledger.goals.isEmpty)
      const _Empty(
        Icons.flag_outlined,
        'Save toward something',
        'Set a target and track how much you’ve set aside.',
      ),
    for (final goal in state._ledger.goals) ...[
      _Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Meter(
                    label: goal.name,
                    detail:
                        '${state._money(goal.saved)} / ${state._money(goal.target)}',
                    amount: goal.saved,
                    target: goal.target,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit ${goal.name}',
                  onPressed: () => state._editGoal(goal),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            if (goal.due case final date?)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Target date ${DateFormat.yMMMd().format(date)}',
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
              ),
            if (goal.saved >= goal.target)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Goal reached',
                  style: TextStyle(
                    color: context.positive,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ],
  ];

  List<Widget> _schedule() => [
    _Section(
      'Bills and income',
      action: TextButton.icon(
        onPressed: () => state._openSchedule(),
        icon: const Icon(Icons.add),
        label: const Text('New schedule'),
      ),
    ),
    if (state._ledger.schedule.isEmpty)
      const _Empty(
        Icons.event_repeat_rounded,
        'Plan upcoming payments',
        'Schedule bills or paydays and record them when they happen.',
      )
    else
      _Surface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final entry in state._sortedSchedule)
              _ScheduleTile(state: state, entry: entry),
          ],
        ),
      ),
  ];
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.state, required this.entry});
  final _MainPageState state;
  final _ScheduledEntry entry;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final overdue = entry.due.isBefore(today);
    final due = !entry.due.isAfter(today);
    final name = entry.template.description;
    return ListTile(
      leading: _IconChip(
        Icons.event_repeat_outlined,
        color: overdue ? context.colors.error : context.colors.primary,
      ),
      title: Text(
        name ??
            state._category(entry.template.categoryId)?.name ??
            'Scheduled transaction',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${overdue ? 'Overdue · ' : ''}${DateFormat.MMMd().format(entry.due)} · ${entry.frequency.label}',
      ),
      trailing: Text(
        state._money(_minor(entry.template.amount)),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      onTap: () => state._scheduleActions(entry, due),
    );
  }
}

class _ToolsMenu extends StatelessWidget {
  const _ToolsMenu({required this.state});
  final _MainPageState state;

  @override
  Widget build(BuildContext context) => _Page(
    storageKey: 'tools',
    children: [
      const _Heading('More'),
      _Surface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (icon, name, detail, destination) in [
              (
                Icons.savings_outlined,
                'Savings & deposits',
                'Manage savings and fixed deposits',
                _Tools.wallet,
              ),
              (
                Icons.request_quote_outlined,
                'Loans',
                'Track money lent, borrowed, and repaid',
                _Tools.loans,
              ),
              (
                Icons.tune_rounded,
                'Settings',
                'Currency, categories, daily limit, and profile',
                _Tools.settings,
              ),
            ])
              ListTile(
                leading: _IconChip(icon),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(detail),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => state._openTools(destination),
              ),
            ListTile(
              leading: const _IconChip(Icons.file_open_outlined),
              title: const Text(
                'Import transactions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Preview a CSV file before adding it'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _importTransactions(state),
            ),
            ListTile(
              leading: const _IconChip(Icons.ios_share_rounded),
              title: const Text(
                'Export transactions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Save or share a CSV file'),
              trailing: const Icon(Icons.chevron_right),
              onTap: state._exportCsv,
            ),
          ],
        ),
      ),
    ],
  );
}
