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
    final nickname = state._nickname;
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
        _OverviewCards(state: state, today: today),
      ],
    );
  }
}

class _OverviewCards extends StatefulWidget {
  const _OverviewCards({required this.state, required this.today});

  final _MainPageState state;
  final DateTime today;

  @override
  State<_OverviewCards> createState() => _OverviewCardsState();
}

class _OverviewCardsState extends State<_OverviewCards> {
  final _controller = PageController(keepPage: false);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final today = widget.today;
    final account = state._activeAccount;
    final balance = state._ledger.balances(today)[account.id] ?? 0;
    final flow = _CashFlow(
      state._transactions.where(
        (entry) =>
            entry.accountId == account.id &&
            _inMonth(entry.date, today) &&
            !DateUtils.dateOnly(entry.date).isAfter(today),
      ),
    );
    var owedToYou = 0;
    var youOwe = 0;
    final activeLoans =
        state._loans.where((loan) => !loan.isDeleted && !loan.isPaid).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    for (final loan in activeLoans) {
      if (loan.type == LoanType.given) {
        owedToYou += loan._outstanding;
      } else {
        youOwe += loan._outstanding;
      }
    }
    final savings = _minor(state._savingsPot);
    var deposits = 0;
    DateTime? nextMaturity;
    for (final deposit in state._fixedDeposits) {
      deposits += _minor(deposit.amount);
      final maturity = DateUtils.dateOnly(deposit.maturityDate);
      if (!maturity.isBefore(today) &&
          (nextMaturity == null || maturity.isBefore(nextMaturity))) {
        nextMaturity = maturity;
      }
    }

    final hidden = state._hideOverviewAmounts;
    String amount(int value) => hidden ? '••••' : state._money(value);
    const positive = Color(0xFFD9F678);
    const negative = Color(0xFFFFD7C4);
    final cards = [
      _OverviewCard(
        title: account.name,
        icon: account.kind.icon,
        headline: amount(balance),
        caption: 'Cash flow this month',
        details: [
          _FlowValue(
            'Income',
            amount(flow.income),
            Icons.south_west_rounded,
            positive,
          ),
          _FlowValue(
            'Spending',
            amount(flow.spent),
            Icons.north_east_rounded,
            negative,
          ),
        ],
      ),
      _OverviewCard(
        title: 'Loans',
        icon: Icons.handshake_outlined,
        headline: '${activeLoans.length}',
        caption: activeLoans.length == 1 ? 'Active loan' : 'Active loans',
        destination: _Tools.loans,
        details: [
          _FlowValue(
            'Owed to you',
            amount(owedToYou),
            Icons.south_west_rounded,
            positive,
          ),
          _FlowValue(
            'You owe',
            amount(youOwe),
            Icons.north_east_rounded,
            negative,
          ),
        ],
      ),
      _OverviewCard(
        title: 'Savings & deposits',
        icon: Icons.savings_outlined,
        headline: amount(savings + deposits),
        caption:
            nextMaturity == null
                ? 'Total savings and deposits'
                : 'Next maturity ${DateFormat.MMMd().format(nextMaturity)}',
        destination: _Tools.wallet,
        details: [
          _FlowValue(
            'Savings pot',
            amount(savings),
            Icons.savings_outlined,
            positive,
          ),
          _FlowValue(
            'Fixed deposits',
            amount(deposits),
            Icons.account_balance_outlined,
            positive,
          ),
        ],
      ),
    ];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        _TintedCard(
          padding: EdgeInsets.zero,
          ringColor: const Color(0x44D9F678),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFF143D31), Color(0xFF245C47)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SizedBox(
            height:
                240 +
                (MediaQuery.textScalerOf(context).scale(17) - 17).clamp(0, 80) *
                    6,
            child: PageView.builder(
              key: const PageStorageKey('overview-cards'),
              controller: _controller,
              itemCount: cards.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final content = _buildCard(state, cards[index], hidden);
                if (reduceMotion) return content;
                return AnimatedBuilder(
                  animation: _controller,
                  child: content,
                  builder: (context, child) {
                    final page =
                        _controller.hasClients ? _controller.page ?? 0 : 0;
                    final distance = (page - index).abs().clamp(0.0, 1.0);
                    return Opacity(opacity: 1 - 0.45 * distance, child: child);
                  },
                );
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (index, label)
                in ['Balance', 'Loans', 'Savings'].indexed)
              Flexible(
                child: TextButton(
                  onPressed: () {
                    if (reduceMotion) {
                      _controller.jumpToPage(index);
                    } else {
                      _controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor:
                        index == _page
                            ? context.colors.secondaryContainer
                            : null,
                    foregroundColor:
                        index == _page
                            ? context.colors.onSecondaryContainer
                            : null,
                  ),
                  child: Text(label),
                ),
              ),
          ],
        ),
        AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          layoutBuilder:
              (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  for (final child in previous)
                    IgnorePointer(child: ExcludeSemantics(child: child)),
                  if (current != null) current,
                ],
              ),
          child: Column(
            key: ValueKey(_page),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: switch (_page) {
              1 => _loanPreview(state, activeLoans, amount),
              2 => _savingsPreview(state, today, amount),
              _ => _recentActivity(state, hidden),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(_MainPageState state, _OverviewCard card, bool hidden) =>
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(card.icon, size: 18, color: const Color(0xFFD9F678)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFECF7DB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (card.destination case final destination?)
                  IconButton(
                    tooltip: 'Open ${card.title.toLowerCase()}',
                    color: const Color(0xFFECF7DB),
                    onPressed: () => state._openTools(destination),
                    icon: const Icon(Icons.arrow_outward_rounded),
                  ),
                IconButton(
                  tooltip:
                      hidden
                          ? 'Show overview amounts'
                          : 'Hide overview amounts',
                  color: const Color(0xFFECF7DB),
                  onPressed: state._toggleOverviewPrivacy,
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                card.headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            const Spacer(),
            const Divider(color: Color(0xFF52826A)),
            Text(
              card.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFECF7DB)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: card.details.first),
                const SizedBox(width: 12),
                Expanded(child: card.details.last),
              ],
            ),
          ],
        ),
      );

  List<Widget> _recentActivity(_MainPageState state, bool private) {
    final recent = state._sortedTransactions
        .where((entry) => entry.involvesAccount(state._activeAccount.id))
        .take(4);
    return [
      _Section(
        'Recent activity',
        action: TextButton(
          onPressed: () => state._openActivity(),
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
                _EntryTile(state: state, entry: entry, hideAmount: private),
            ],
          ),
        ),
    ];
  }

  List<Widget> _loanPreview(
    _MainPageState state,
    List<Loan> loans,
    String Function(int) amount,
  ) => [
    _Section(
      'Loan summary',
      action: TextButton(
        onPressed: () => state._openTools(_Tools.loans),
        child: const Text('View loans'),
      ),
    ),
    if (loans.isEmpty)
      const _Empty(
        Icons.handshake_outlined,
        'No active loans',
        'Outstanding loans will appear here.',
      )
    else
      _Surface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final loan in loans.take(3))
              ListTile(
                leading: const _IconChip(Icons.handshake_outlined),
                title: Text(loan.personName),
                subtitle: Text(
                  loan.type == LoanType.given ? 'Loan given' : 'Loan taken',
                ),
                trailing: Text(amount(loan._outstanding)),
              ),
          ],
        ),
      ),
  ];

  List<Widget> _savingsPreview(
    _MainPageState state,
    DateTime today,
    String Function(int) amount,
  ) {
    final upcoming =
        state._fixedDeposits
            .where(
              (deposit) =>
                  !DateUtils.dateOnly(deposit.maturityDate).isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.maturityDate.compareTo(b.maturityDate));
    return [
      _Section(
        'Savings summary',
        action: TextButton(
          onPressed: () => state._openTools(_Tools.wallet),
          child: const Text('View savings'),
        ),
      ),
      _Surface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: const _IconChip(Icons.savings_outlined),
              title: const Text('Savings pot balance'),
              trailing: Text(amount(_minor(state._savingsPot))),
            ),
            for (final deposit in upcoming.take(2))
              ListTile(
                leading: const _IconChip(Icons.account_balance_outlined),
                title: const Text('Fixed deposit'),
                subtitle: Text(
                  'Matures ${DateFormat.yMMMd().format(deposit.maturityDate)}',
                ),
                trailing: Text(amount(_minor(deposit.amount))),
              ),
            if (upcoming.isEmpty)
              const ListTile(
                leading: _IconChip(Icons.event_outlined),
                title: Text('No upcoming maturities'),
              ),
          ],
        ),
      ),
    ];
  }
}

class _OverviewCard {
  const _OverviewCard({
    required this.title,
    required this.icon,
    required this.headline,
    required this.caption,
    required this.details,
    this.destination,
  });

  final String title;
  final IconData icon;
  final String headline;
  final String caption;
  final List<_FlowValue> details;
  final _Tools? destination;
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
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.state,
    required this.entry,
    this.showDate = true,
    this.hideAmount = false,
  });

  final _MainPageState state;
  final Transaction entry;
  final bool showDate;
  final bool hideAmount;

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
    final details = [
      description,
      if (showDate) DateFormat.MMMd().format(entry.date),
      if (entry.coverageDays > 1) '${entry.coverageDays} plan days',
    ];
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
        details.join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        hideAmount
            ? '••••'
            : '${transfer
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
    final today = DateUtils.dateOnly(DateTime.now());
    final entries = state._sortedTransactions.where((entry) {
      if (state._kindFilter case final type? when entry._kind != type) {
        return false;
      }
      final account = state._accountFilter ?? state._activeAccount.id;
      if (account.isNotEmpty && !entry.involvesAccount(account)) return false;
      if (state._categoryFilter case final id? when entry.categoryId != id) {
        return false;
      }
      if (state._activityRange case final range?) {
        final date = DateUtils.dateOnly(entry.date);
        final usePlanDates =
            state._usePlanDates && entry._kind == _EntryKind.expense;
        final firstDay = usePlanDates ? entry._planStart : date;
        final lastDay =
            usePlanDates
                ? _shiftBudgetDay(firstDay, entry.coverageDays - 1)
                : date;
        if (lastDay.isBefore(range.start) || firstDay.isAfter(range.end)) {
          return false;
        }
        if (state._usePlanDates && date.isAfter(today)) return false;
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
          subtitle:
              state._accountFilter == ''
                  ? 'All accounts'
                  : state._accountName(
                    state._accountFilter ?? state._activeAccount.id,
                  ),
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
    final today = DateUtils.dateOnly(DateTime.now());
    final period = state._reportPeriod;
    final date = state._reportDate;
    final window = period.range(date);
    final current = period.start(date) == period.start(today);
    final end = current ? today : window.end;
    final account = state._activeAccount;
    final data = state._transactions.where(
      (entry) => state._reportAllAccounts || entry.involvesAccount(account.id),
    );
    Iterable<Transaction> within(DateTimeRange range) => data.where((entry) {
      final day = DateUtils.dateOnly(entry.date);
      return !day.isBefore(range.start) &&
          !day.isAfter(range.end) &&
          !day.isAfter(today);
    });
    final entries = within(window);
    final flow = _CashFlow(entries);
    final categories =
        flow.expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final dates = List.generate(6, (index) => period.move(date, index - 5));
    final trends = [
      for (final day in dates) _CashFlow(within(period.range(day))),
    ];
    final previous = period.range(period.move(date, -1));
    final previousDays = _budgetDays(
      previous,
    ).take(_budgetDays(DateTimeRange(start: window.start, end: end)).length);
    final previousSpent =
        _CashFlow(
          within(DateTimeRange(start: previous.start, end: previousDays.last)),
        ).spent;
    final delta = flow.spent - previousSpent;
    final comparison = switch (delta) {
      0 => 'Same spending',
      > 0 => '${state._money(delta)} more spent',
      _ => '${state._money(-delta)} less spent',
    };
    final trendDate = switch (period) {
      _BudgetPeriod.daily => DateFormat.E(),
      _BudgetPeriod.weekly => DateFormat.Md(),
      _BudgetPeriod.monthly => DateFormat.MMM(),
    };
    final peak = trends.fold(
      1,
      (top, point) => max(top, max(point.income, point.spent)),
    );
    return _Page(
      storageKey: 'insights',
      pinnedHeader: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(
            'Insights',
            subtitle: state._reportAllAccounts ? null : account.name,
            trailing: TextButton(
              onPressed: () => state._openTools(_Tools.reports),
              child: const Text('Detailed reports'),
            ),
          ),
          SegmentedButton<_BudgetPeriod>(
            showSelectedIcon: false,
            segments: [
              for (final option in _BudgetPeriod.values)
                ButtonSegment(value: option, label: Text(option.tab)),
            ],
            selected: {period},
            onSelectionChanged:
                (selection) => state._selectReportPeriod(selection.single),
          ),
          const SizedBox(height: 10),
          _Surface(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous ${period.unit}',
                  onPressed: () => state._moveReport(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: state._chooseReportDate,
                    child: Text(
                      period.dateLabel(date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next ${period.unit}',
                  onPressed: current ? null : () => state._moveReport(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          if (!current || state._ledger.accounts.length > 1)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (state._ledger.accounts.length > 1)
                  FilterChip(
                    label: const Text('All accounts'),
                    selected: state._reportAllAccounts,
                    onSelected: state._setReportAllAccounts,
                  ),
                if (!current)
                  TextButton(
                    onPressed: () => state._moveReport(0),
                    child: Text(
                      period == _BudgetPeriod.daily
                          ? 'Back to today'
                          : 'Back to this ${period.unit}',
                    ),
                  ),
              ],
            ),
        ],
      ),
      children: [
        const SizedBox(height: 8),
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
        if (flow.spent > 0 || previousSpent > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _Surface(
              child: _Metric(
                current && period != _BudgetPeriod.daily
                    ? 'Same days last ${period.unit}'
                    : 'Previous ${period.unit}',
                comparison,
                delta > 0 ? context.colors.error : context.positive,
              ),
            ),
          ),
        _Section('Last 6 ${period.unit}s'),
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
                  for (var index = 0; index < dates.length; index++)
                    Expanded(
                      child: Semantics(
                        label:
                            '${period.dateLabel(dates[index])}, income ${state._money(trends[index].income)}, spending ${state._money(trends[index].spent)}',
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
                              trendDate.format(dates[index]),
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
        if (flow.spent > 0 && period != _BudgetPeriod.daily) ...[
          _Section('Daily spending'),
          _Surface(
            child: _DailySpendingChart(
              state: state,
              range: DateTimeRange(start: window.start, end: end),
              entries: entries,
            ),
          ),
        ],
        _Section('Spending by category'),
        if (categories.isEmpty)
          _Empty(
            Icons.donut_large_rounded,
            'No spending this ${period.unit}',
            'Your category totals will appear here.',
          )
        else
          _Surface(
            child: Column(
              children: [
                SizedBox(
                  height: 176,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 44,
                      sectionsSpace: 2,
                      sections: [
                        for (final category in categories)
                          PieChartSectionData(
                            value: category.value.toDouble(),
                            color:
                                state._category(category.key)?.color ??
                                context.colors.primary,
                            radius: 26,
                            showTitle: false,
                          ),
                      ],
                    ),
                    duration:
                        MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 250),
                  ),
                ),

                for (final category in categories)
                  InkWell(
                    onTap:
                        () => state._openActivity(
                          category: category.key,
                          kind: _EntryKind.expense,
                          range: DateTimeRange(start: window.start, end: end),
                          account: state._reportAllAccounts ? '' : account.id,
                        ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color:
                                state._category(category.key)?.color ??
                                context.colors.primary,
                          ),
                          const SizedBox(width: 8),
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

class _DailySpendingChart extends StatelessWidget {
  const _DailySpendingChart({
    required this.state,
    required this.range,
    required this.entries,
  });

  final _MainPageState state;
  final DateTimeRange range;
  final Iterable<Transaction> entries;

  @override
  Widget build(BuildContext context) {
    final dates = _budgetDays(range).toList();
    final days = dates.length;
    final totals = <DateTime, int>{};
    for (final entry in entries) {
      if (entry._kind == _EntryKind.expense) {
        final day = DateUtils.dateOnly(entry.date);
        totals.update(
          day,
          (value) => value + _minor(entry.amount),
          ifAbsent: () => _minor(entry.amount),
        );
      }
    }
    final values = [for (final date in dates) totals[date] ?? 0];
    final accent = context.colors.primary;
    return Column(
      children: [
        SizedBox(
          height: 132,
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: max(2, days).toDouble(),
              minY: 0,
              maxY: max(1, values.reduce(max) * 1.12).toDouble(),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(drawVerticalLine: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems:
                      (spots) => [
                        for (final spot in spots)
                          LineTooltipItem(
                            '${DateFormat.MMMd().format(dates[(spot.x.toInt() - 1).clamp(0, dates.length - 1)])}\n${state._money(spot.y.toInt())}',
                            TextStyle(color: context.colors.onInverseSurface),
                          ),
                      ],
                  getTooltipColor: (_) => context.colors.inverseSurface,
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  color: accent,
                  barWidth: 3,
                  dotData: FlDotData(show: days == 1),
                  spots: [
                    for (final (index, value) in values.indexed)
                      FlSpot(index + 1.0, value.toDouble()),
                  ],
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accent.withValues(alpha: 0.28),
                        accent.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration:
                MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.MMMd().format(dates.first)),
            if (days > 1) Text(DateFormat.MMMd().format(dates.last)),
          ],
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
  Widget build(BuildContext context) => AnimatedContainer(
    duration:
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
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
