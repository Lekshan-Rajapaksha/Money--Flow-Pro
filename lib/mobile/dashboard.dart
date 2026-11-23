part of '../home.dart';

class _Page extends StatelessWidget {
  const _Page({
    required this.children,
    required this.storageKey,
    this.pinnedHeader,
  });

  final List<Widget> children;
  final String storageKey;
  final Widget? pinnedHeader;

  @override
  Widget build(BuildContext context) {
    Widget constrain(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: PageStorageKey(storageKey),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (pinnedHeader case final header?)
            PinnedHeaderSliver(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: constrain(header),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              pinnedHeader == null ? 16 : 0,
              20,
              100,
            ),
            sliver: SliverList.list(
              children: [for (final child in children) constrain(child)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle case final text?) ...[
                Text(
                  text,
                  style: TextStyle(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 33,
                  height: 1.07,
                  letterSpacing: -1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing case final widget?) widget,
      ],
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: context.colors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: context.colors.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class _TintedCard extends StatelessWidget {
  const _TintedCard({
    required this.decoration,
    required this.ringColor,
    required this.padding,
    required this.child,
  });

  final BoxDecoration decoration;
  final Color ringColor;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: decoration,
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(
      painter: _CardRings(ringColor),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class _CardRings extends CustomPainter {
  const _CardRings(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final brush =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    final center = Offset(size.width - 22, 18);
    for (final radius in [38.0, 62.0, 86.0]) {
      canvas.drawCircle(center, radius, brush);
    }
  }

  @override
  bool shouldRepaint(_CardRings oldDelegate) => oldDelegate.color != color;
}

class _Section extends StatelessWidget {
  const _Section(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
          ),
        ),
        if (action case final widget?) widget,
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.icon, this.title, this.message);

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => _Surface(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _IconChip(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        message,
        style: TextStyle(color: context.colors.onSurfaceVariant),
      ),
    ),
  );
}

class _IconChip extends StatelessWidget {
  const _IconChip(this.icon, {this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = context.readable(color ?? context.colors.primary);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: tint, size: 21),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.state});

  final _MainPageState state;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final balances = state._ledger.balances(today);
    final total = balances.values.fold(0, (sum, amount) => sum + amount);
    final current = state._ledger.transactions.where(
      (entry) =>
          _inMonth(entry.date, today) &&
          !DateUtils.dateOnly(entry.date).isAfter(today),
    );
    final flow = _CashFlow(current);
    final recent = state._sortedTransactions.take(4).toList();
    final upcoming = state._sortedSchedule.take(3).toList();
    final nickname = state._nickname;
    final previousDailyLimit = state._dailyLimit;
    final planLimits = {
      for (final period in _BudgetPeriod.values)
        period: _totalBudget(state._ledger.budgetLimits(period, today)),
    };
    final usesLegacyDailyLimit =
        planLimits[_BudgetPeriod.daily] == null &&
        previousDailyLimit != null &&
        previousDailyLimit.isFinite &&
        _minor(previousDailyLimit) > 0;
    if (usesLegacyDailyLimit) {
      planLimits[_BudgetPeriod.daily] = _minor(previousDailyLimit);
    }
    return _Page(
      storageKey: 'overview',
      children: [
        _Heading(
          nickname == 'Nickname' ? 'Your overview' : 'Hi, $nickname',
          subtitle: DateFormat('EEEE, MMM d').format(today),
          trailing: IconButton.filledTonal(
            tooltip: 'Settings',
            onPressed: () => state._openTools(_Tools.settings),
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
        _TintedCard(
          padding: const EdgeInsets.all(20),
          ringColor: const Color(0x44D9F678),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFF143D31), Color(0xFF245C47)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: Color(0xFFD9F678),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tracked balance',
                      style: TextStyle(
                        color: Color(0xFFECF7DB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                state._money(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 41,
                  height: 1.05,
                  letterSpacing: -1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 21),
              const Divider(color: Color(0xFF52826A), height: 1),
              const SizedBox(height: 14),
              const Text(
                'This month',
                style: TextStyle(color: Color(0xFFECF7DB)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  _FlowValue(
                    'Income',
                    state._money(flow.income),
                    Icons.south_west_rounded,
                    const Color(0xFFD9F678),
                  ),
                  _FlowValue(
                    'Spending',
                    state._money(flow.spent),
                    Icons.north_east_rounded,
                    const Color(0xFFFFD7C4),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (planLimits.values.any((limit) => limit != null)) ...[
          _Section('Spending plans'),
          _Surface(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (final entry in planLimits.entries)
                  if (entry.value case final limit?)
                    _OverviewBudgetTile(
                      state: state,
                      period: entry.key,
                      limit: limit,
                      today: today,
                      legacy:
                          usesLegacyDailyLimit &&
                          entry.key == _BudgetPeriod.daily,
                    ),
              ],
            ),
          ),
        ],
        _Section(
          'Accounts',
          action: TextButton.icon(
            onPressed: () => state._editAccount(),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        _Surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final account in state._ledger.accounts)
                ListTile(
                  leading: _IconChip(account.kind.icon),
                  title: Text(
                    account.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(account.kind.label),
                  trailing: Text(
                    state._money(balances[account.id]!),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => state._editAccount(account),
                ),
            ],
          ),
        ),
        if (upcoming.isNotEmpty) ...[
          _Section(
            'Upcoming',
            action: TextButton(
              onPressed: () => state._openPlan(_PlanSection.schedule),
              child: const Text('View schedule'),
            ),
          ),
          _Surface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final entry in upcoming)
                  _ScheduleTile(state: state, entry: entry),
              ],
            ),
          ),
        ],
        _Section(
          'Recent activity',
          action: TextButton(
            onPressed: () => state._navigate(_Destination.activity),
            child: const Text('View all'),
          ),
        ),
        if (recent.isEmpty)
          const _Empty(
            Icons.receipt_long_outlined,
            'No activity yet',
            'Add an income or expense to start tracking.',
          )
        else
          _Surface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final entry in recent)
                  _EntryTile(state: state, entry: entry),
              ],
            ),
          ),
      ],
    );
  }
}

class _OverviewBudgetTile extends StatelessWidget {
  const _OverviewBudgetTile({
    required this.state,
    required this.period,
    required this.limit,
    required this.today,
    required this.legacy,
  });

  final _MainPageState state;
  final _BudgetPeriod period;
  final int limit;
  final DateTime today;
  final bool legacy;

  @override
  Widget build(BuildContext context) {
    final spent = state._ledger.budgetSpending(period, today, today).spent;
    final left = limit - spent;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const _IconChip(Icons.track_changes_rounded),
      title: Text(
        legacy ? 'Daily spending limit' : '${period.label} plan',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${state._money(left.abs())} ${left < 0 ? 'over' : 'left'}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap:
          legacy
              ? () => state._openTools(_Tools.settings)
              : () => state._openBudgets(period),
    );
  }
}

class _FlowValue extends StatelessWidget {
  const _FlowValue(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 7),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    ],
  );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.state,
    required this.entry,
    this.showDate = true,
  });

  final _MainPageState state;
  final Transaction entry;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final category = state._category(entry.categoryId);
    final transfer = entry.isTransfer;
    final note = entry.description?.trim();
    final account = state._accountName(entry.accountId);
    final description =
        transfer
            ? '$account → ${state._accountName(entry.destinationId!)}'
            : account;
    final color =
        transfer
            ? context.colors.primary
            : entry.isExpense
            ? context.colors.onSurface
            : context.positive;
    return ListTile(
      leading: _IconChip(
        transfer
            ? Icons.swap_horiz_rounded
            : category?.icon ?? Icons.receipt_outlined,
        color:
            transfer
                ? context.colors.primary
                : category?.color ?? context.colors.primary,
      ),
      title: Text(
        (note?.isNotEmpty ?? false)
            ? note!
            : transfer
            ? 'Transfer'
            : category?.name ?? 'Uncategorized',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        showDate
            ? '$description · ${DateFormat.MMMd().format(entry.date)}'
            : description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${transfer
            ? ''
            : entry.isExpense
            ? '−'
            : '+'}${state._money(_minor(entry.amount))}',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      onTap: () => state._openEntry(entry),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.state});

  final _MainPageState state;

  @override
  Widget build(BuildContext context) {
    final query = state._query.trim().toLowerCase();
    final entries = state._sortedTransactions.where((entry) {
      if (state._kindFilter case final type? when entry._kind != type) {
        return false;
      }
      if (state._accountFilter case final id?
          when entry.accountId != id && entry.destinationId != id) {
        return false;
      }
      if (state._categoryFilter case final id? when entry.categoryId != id) {
        return false;
      }
      if (state._activityRange case final range?) {
        final date = DateUtils.dateOnly(entry.date);
        if (date.isBefore(range.start) || date.isAfter(range.end)) return false;
      }
      return [
        entry.description,
        state._category(entry.categoryId)?.name,
        state._accountName(entry.accountId),
        if (entry.destinationId != null)
          state._accountName(entry.destinationId!),
        entry._kind.name,
        _moneyText(_minor(entry.amount)),
      ].whereType<String>().any((text) => text.toLowerCase().contains(query));
    });
    final groups = <DateTime, List<Transaction>>{};
    for (final entry in entries) {
      groups.putIfAbsent(DateUtils.dateOnly(entry.date), () => []).add(entry);
    }
    return _Page(
      storageKey: 'activity',
      children: [
        _Heading(
          'Activity',
          trailing: IconButton.filledTonal(
            tooltip: 'Export transactions',
            onPressed: state._exportCsv,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ),
        TextField(
          controller: state._search,
          onChanged: state._searchActivity,
          decoration: InputDecoration(
            labelText: 'Search transactions',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon:
                query.isEmpty
                    ? null
                    : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: state._clearSearch,
                    ),
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          children: [
            for (final (type, label) in <(_EntryKind?, String)>[
              (null, 'All'),
              (_EntryKind.expense, 'Expenses'),
              (_EntryKind.income, 'Income'),
              (_EntryKind.transfer, 'Transfers'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: state._kindFilter == type,
                onSelected: (_) => state._filterKind(type),
              ),
            ActionChip(
              avatar: const Icon(Icons.filter_list_rounded, size: 16),
              label: Text(state._hasActivityFilters ? 'Filters on' : 'Filters'),
              onPressed: state._filterActivity,
            ),
          ],
        ),
        if (groups.isEmpty) ...[
          const SizedBox(height: 14),
          const _Empty(
            Icons.search_rounded,
            'No matching activity',
            'Try changing your filters or add a transaction.',
          ),
        ],
        for (final group in groups.entries) ...[
          _Section(DateFormat('EEE, MMM d, y').format(group.key)),
          _Surface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final entry in group.value)
                  _EntryTile(state: state, entry: entry, showDate: false),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Insights extends StatelessWidget {
  const _Insights({required this.state});

  final _MainPageState state;

  @override
  Widget build(BuildContext context) {
    final month = state._reportMonth;
    final entries = state._ledger.transactions.where(
      (entry) => _inMonth(entry.date, month),
    );
    final flow = _CashFlow(entries);
    final categories =
        flow.expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final months = List.generate(
      6,
      (index) => DateTime(month.year, month.month - 5 + index),
    );
    final trends =
        months
            .map(
              (date) => _CashFlow(
                state._ledger.transactions.where(
                  (entry) => _inMonth(entry.date, date),
                ),
              ),
            )
            .toList();
    final peak = trends.fold(
      1,
      (top, point) => max(top, max(point.income, point.spent)),
    );
    return _Page(
      storageKey: 'insights',
      children: [
        _Heading(
          'Insights',
          trailing: TextButton(
            onPressed: () => state._openTools(_Tools.reports),
            child: const Text('Detailed reports'),
          ),
        ),
        _Surface(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => state._moveReport(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed:
                    _inMonth(month, DateTime.now())
                        ? null
                        : () => state._moveReport(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        _Section('Cash flow'),
        _Surface(
          child: Column(
            children: [
              _Metric('Income', state._money(flow.income), context.positive),
              _Metric(
                'Spending',
                state._money(flow.spent),
                context.colors.error,
              ),
              const Divider(),
              _Metric(
                'Net cash flow',
                state._money(flow.net),
                flow.net < 0 ? context.colors.error : context.positive,
              ),
            ],
          ),
        ),
        _Section('Six-month trend'),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                children: [
                  Text(
                    '● Income',
                    style: TextStyle(
                      color: context.positive,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '● Spending',
                    style: TextStyle(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < months.length; index++)
                    Expanded(
                      child: Semantics(
                        label:
                            '${DateFormat.yMMMM().format(months[index])}, income ${state._money(trends[index].income)}, spending ${state._money(trends[index].spent)}',
                        child: Column(
                          children: [
                            SizedBox(
                              height: 88,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _Bar(
                                    trends[index].income / peak,
                                    context.positive,
                                  ),
                                  const SizedBox(width: 3),
                                  _Bar(
                                    trends[index].spent / peak,
                                    context.colors.primary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat.MMM().format(months[index]),
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _Section('Spending by category'),
        if (categories.isEmpty)
          const _Empty(
            Icons.donut_large_rounded,
            'No spending this month',
            'Your category totals will appear here.',
          )
        else
          _Surface(
            child: Column(
              children: [
                for (final category in categories)
                  InkWell(
                    onTap:
                        () => state._showCategoryActivity(category.key, month),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Meter(
                              label:
                                  state._category(category.key)?.name ??
                                  'Uncategorized',
                              detail: state._money(category.value),
                              amount: category.value,
                              target: flow.spent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.ratio, this.color);
  final double ratio;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: max(2, 88 * ratio),
    decoration: BoxDecoration(
      color: ratio == 0 ? context.colors.outlineVariant : color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
    ),
  );
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.detail,
    required this.amount,
    required this.target,
    this.spendingLimit = false,
  });
  final String label;
  final String detail;
  final int amount;
  final int target;
  final bool spendingLimit;
  @override
  Widget build(BuildContext context) {
    final ratio = target > 0 ? (amount / target).clamp(0.0, 1.0) : 0.0;
    final color =
        spendingLimit && amount > target
            ? context.colors.error
            : context.colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Metric(label, detail, color),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: context.colors.outlineVariant,
            color: color,
            semanticsLabel: label,
          ),
        ),
      ],
    );
  }
}
