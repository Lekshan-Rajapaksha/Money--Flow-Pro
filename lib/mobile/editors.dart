part of '../home.dart';

Future<T?> _showEditor<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 510),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
    );

class _Editor extends StatefulWidget {
  const _Editor({
    required this.title,
    required this.fields,
    required this.onSave,
    this.onRemove,
  });
  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;
  final VoidCallback? onRemove;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final _key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Form(
    key: _key,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final field in widget.fields)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: field),
        FilledButton(
          onPressed: () {
            if (_key.currentState!.validate()) widget.onSave();
          },
          child: const Text('Save'),
        ),
        if (widget.onRemove case final remove?)
          TextButton(
            onPressed: remove,
            child: Text(
              'Remove',
              style: TextStyle(color: context.colors.error),
            ),
          ),
      ],
    ),
  );
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    super.key,
    required this.label,
    required this.symbol,
    required this.onChanged,
    this.initial,
    this.controller,
    this.allowZero = false,
    this.allowNegative = false,
    this.validateAmount,
  });

  final String label;
  final String symbol;
  final ValueChanged<String> onChanged;
  final String? initial;
  final TextEditingController? controller;
  final bool allowZero;
  final bool allowNegative;
  final String? Function(int)? validateAmount;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: initial,
    keyboardType: TextInputType.numberWithOptions(
      decimal: true,
      signed: allowNegative,
    ),
    decoration: InputDecoration(labelText: label, prefixText: '$symbol '),
    onChanged: onChanged,
    validator: (value) {
      final cents = _parseMoney(value ?? '');
      if (cents == null ||
          (!allowZero && cents == 0) ||
          (!allowNegative && cents < 0)) {
        return 'Enter a valid amount with up to two decimal places';
      }
      return validateAmount?.call(cents);
    },
  );
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.label,
    required this.onChanged,
    this.initial,
    this.validateName,
  });
  final String label;
  final ValueChanged<String> onChanged;
  final String? Function(String)? validateName;
  final String? initial;
  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: initial,
    maxLength: 45,
    decoration: InputDecoration(labelText: label, counterText: ''),
    textCapitalization: TextCapitalization.sentences,
    onChanged: onChanged,
    validator: (value) {
      final name = value?.trim() ?? '';
      return name.isEmpty ? 'Enter a name' : validateName?.call(name);
    },
  );
}

class _EntryEditor extends StatefulWidget {
  const _EntryEditor({
    required this.state,
    this.entry,
    this.schedule,
    this.scheduling = false,
    this.initialCategory,
    this.initialDate,
  });
  final _MainPageState state;
  final Transaction? entry;
  final _ScheduledEntry? schedule;
  final bool scheduling;
  final String? initialCategory;
  final DateTime? initialDate;

  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  late final Transaction? _entry = widget.schedule?.template ?? widget.entry;
  late _EntryKind _kind = _entry?._kind ?? _EntryKind.expense;
  late String _account = _entry?.accountId ?? widget.state._activeAccount.id;
  late String? _destination = _entry?.destinationId;
  late String? _category = _entry?.categoryId ?? widget.initialCategory;
  late DateTime _date = DateUtils.dateOnly(
    widget.schedule?.due ??
        _entry?.date ??
        widget.initialDate ??
        DateTime.now(),
  );
  late int _coverageDays = _entry?.coverageDays ?? 1;
  late DateTime? _coverageStart = _entry?.coverageStart;
  late _Frequency _frequency = widget.schedule?.frequency ?? _Frequency.monthly;
  late final _amount = TextEditingController(
    text: _entry == null ? '' : _moneyText(_minor(_entry.amount)),
  );
  late final _note = TextEditingController(text: _entry?.description ?? '');

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit(String? category, String? destination) {
    final note = _note.text.trim();
    final date =
        !widget.scheduling &&
                _entry != null &&
                DateUtils.isSameDay(_date, _entry.date)
            ? _entry.date
            : _date;
    final originalSchedule = widget.schedule;
    final keepAnchor =
        originalSchedule != null &&
        DateUtils.isSameDay(_date, originalSchedule.due) &&
        _frequency == originalSchedule.frequency;
    final transaction = Transaction(
      id: _entry?.id,
      description: note.isEmpty ? null : note,
      amount: _parseMoney(_amount.text)! / 100,
      isExpense: _kind == _EntryKind.expense,
      categoryId: _kind == _EntryKind.transfer ? '' : category!,
      date: keepAnchor ? originalSchedule.template.date : date,
      accountId: _account,
      coverageDays: _kind == _EntryKind.expense ? _coverageDays : 1,
      coverageStart:
          _kind == _EntryKind.expense && _coverageDays > 1
              ? _coverageStart
              : null,
      destinationId: _kind == _EntryKind.transfer ? destination : null,
    );
    if (widget.scheduling) {
      Navigator.pop(
        context,
        _ScheduledEntry(
          id: keepAnchor ? originalSchedule.id : _identifier(),
          template: transaction,
          frequency: _frequency,
          occurrence: keepAnchor ? originalSchedule.occurrence : 0,
        ),
      );
    } else {
      Navigator.pop(context, transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.state._ledger.accounts;
    final categories =
        widget.state._categories
            .where(
              (category) => category.isExpense == (_kind == _EntryKind.expense),
            )
            .toList();
    final category =
        categories.any((item) => item.id == _category)
            ? _category
            : categories.firstOrNull?.id;
    final targets =
        accounts.where((account) => account.id != _account).toList();
    final target =
        targets.any((account) => account.id == _destination)
            ? _destination
            : targets.firstOrNull?.id;
    final transfer = _kind == _EntryKind.transfer;
    final allowTransfer = !widget.scheduling && accounts.length > 1;
    final title =
        widget.scheduling
            ? (widget.schedule == null
                ? 'Schedule transaction'
                : 'Edit schedule')
            : (widget.entry == null ? 'Add transaction' : 'Edit transaction');
    final canRemove = widget.entry != null || widget.schedule != null;
    final planStart = _coverageStart ?? _date;
    return _Editor(
      title: title,
      fields: [
        SegmentedButton<_EntryKind>(
          showSelectedIcon: false,
          segments: [
            const ButtonSegment(
              value: _EntryKind.expense,
              label: Text('Expense'),
            ),
            const ButtonSegment(
              value: _EntryKind.income,
              label: Text('Income'),
            ),
            if (allowTransfer)
              const ButtonSegment(
                value: _EntryKind.transfer,
                label: Text('Transfer'),
              ),
          ],
          selected: {_kind},
          onSelectionChanged: (value) => setState(() => _kind = value.single),
        ),
        _AmountField(
          label: 'Amount',
          symbol: widget.state.currencySymbol,
          controller: _amount,
          onChanged: (_) {},
        ),
        _select(
          key: ValueKey('source-$transfer'),
          value: _account,
          label: transfer ? 'From account' : 'Account',
          items: accounts.map((account) => (account.id, account.name)),
          onChanged: (value) => setState(() => _account = value!),
        ),
        if (transfer)
          _select(
            key: ValueKey(_account),
            value: target,
            label: 'To account',
            items: targets.map((account) => (account.id, account.name)),
            onChanged: (value) => setState(() => _destination = value),
          )
        else
          _select(
            key: ValueKey(_kind),
            value: category,
            label: 'Category',
            items: categories.map((item) => (item.id, item.name)),
            onChanged: (value) => setState(() => _category = value),
          ),
        TextFormField(
          controller: _note,
          maxLength: 160,
          decoration: InputDecoration(
            labelText: widget.scheduling ? 'Name or note' : 'Note (optional)',
            counterText: '',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        if (!widget.scheduling && _kind == _EntryKind.expense)
          _select(
            value: _coverageDays,
            label: 'Plan coverage',
            items: [
              (1, 'Purchase day only'),
              for (var days = 2; days <= 31; days++) (days, '$days days'),
            ],
            onChanged: (days) => setState(() => _coverageDays = days!),
          ),
        if (widget.scheduling)
          _select(
            value: _frequency,
            label: 'Repeat',
            items: _Frequency.values.map((item) => (item, item.label)),
            onChanged: (value) => setState(() => _frequency = value!),
          ),
        if (_kind == _EntryKind.expense && _coverageDays > 1)
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              'Plan dates: ${DateFormat.MMMd().format(planStart)} – '
              '${DateFormat.MMMd().format(_shiftBudgetDay(planStart, _coverageDays - 1))}',
            ),
            onPressed: () async {
              final now = DateTime.now();
              final firstDate = DateTime(1900);
              final lastDate = DateTime(now.year + 1, 12, 31);
              final start = await showDatePicker(
                context: context,
                helpText: 'First day covered by this purchase',
                initialDate: planStart,
                firstDate:
                    planStart.isBefore(firstDate) ? planStart : firstDate,
                lastDate: planStart.isAfter(lastDate) ? planStart : lastDate,
              );
              if (start != null && mounted) {
                setState(() => _coverageStart = start);
              }
            },
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(DateFormat.yMMMd().format(_date)),
          onPressed: () async {
            final now = DateUtils.dateOnly(DateTime.now());
            final date = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate:
                  _date.isBefore(DateTime(1900)) ? _date : DateTime(1900),
              lastDate:
                  widget.scheduling
                      ? DateTime(now.year + 30, 12, 31)
                      : (_date.isAfter(now) ? _date : now),
            );
            if (date != null && mounted) setState(() => _date = date);
          },
        ),
      ],
      onSave: () => _submit(category, target),
      onRemove: canRemove ? () => Navigator.pop(context, false) : null,
    );
  }
}

DropdownButtonFormField<T> _select<T>({
  Key? key,
  required T? value,
  required String label,
  required Iterable<(T, String)> items,
  required ValueChanged<T?> onChanged,
  bool required = true,
}) => DropdownButtonFormField<T>(
  key: key,
  initialValue: value,
  isExpanded: true,
  decoration: InputDecoration(labelText: label),
  items:
      items
          .map(
            (item) => DropdownMenuItem(
              value: item.$1,
              child: Text(item.$2, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
  onChanged: onChanged,
  validator: (value) => required && value == null ? 'Choose an option' : null,
);
