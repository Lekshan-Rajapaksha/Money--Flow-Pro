part of '../home.dart';

typedef _EntryKey =
    (DateTime, _EntryKind, int, String, String, String?, String);

_EntryKey _entryKey(Transaction entry) => (
  DateUtils.dateOnly(entry.date),
  entry._kind,
  _minor(entry.amount),
  entry.categoryId,
  entry.accountId,
  entry.destinationId,
  entry.description ?? '',
);

List<List<String>> _csvRows(String source) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var closedQuote = false;
  for (var i = source.startsWith('\uFEFF') ? 1 : 0; i < source.length; i++) {
    final character = source[i];
    if (quoted) {
      if (character != '"') {
        field.write(character);
      } else if (i + 1 < source.length && source[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = false;
        closedQuote = true;
      }
    } else if (character == ',' || character == '\r' || character == '\n') {
      row.add(field.toString());
      field.clear();
      closedQuote = false;
      if (character != ',') {
        if (row.any((cell) => cell.isNotEmpty)) rows.add(row);
        row = [];
        if (character == '\r' &&
            i + 1 < source.length &&
            source[i + 1] == '\n') {
          i++;
        }
      }
    } else if (character == '"' && field.isEmpty && !closedQuote) {
      quoted = true;
    } else {
      if (closedQuote || character == '"') {
        throw const FormatException('A CSV field has invalid quotation marks.');
      }
      field.write(character);
    }
  }
  if (quoted) throw const FormatException('A quoted CSV field is incomplete.');
  row.add(field.toString());
  if (row.any((cell) => cell.isNotEmpty)) rows.add(row);
  return rows;
}

Future<void> _importTransactions(_MainPageState state) async {
  try {
    final bytes = await const MethodChannel(
      'com.lekshan.moneyflow/export',
    ).invokeMethod<Uint8List>('pickCsv');
    if (!state.mounted || bytes == null) return;

    final rows = _csvRows(utf8.decode(bytes));
    if (rows.isEmpty) throw const FormatException('The CSV file is empty.');
    final headers =
        rows.first.map((cell) => cell.trim().toLowerCase()).toList();
    if (!{'date', 'type', 'amount'}.every(headers.contains) ||
        headers.toSet().length != headers.length) {
      throw const FormatException(
        'Include unique Date, Type, and Amount columns.',
      );
    }

    final entries = <Transaction>[];
    var skipped = 0;
    final existing = <_EntryKey, int>{};
    for (final entry in state._transactions) {
      existing.update(
        _entryKey(entry),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    for (final (index, row) in rows.skip(1).indexed) {
      if (row.length != headers.length) {
        throw FormatException(
          'Data row ${index + 1} has the wrong number of fields.',
        );
      }
      final cells = Map.fromIterables(headers, row);
      try {
        final entry = _csvEntry(state, cells);
        final key = _entryKey(entry);
        if ((existing[key] ?? 0) > 0) {
          existing[key] = existing[key]! - 1;
          skipped++;
        } else {
          entries.add(entry);
        }
      } on FormatException catch (error) {
        throw FormatException('Data row ${index + 1}. ${error.message}');
      }
    }

    final confirmed = await showDialog<bool>(
      context: state.context,
      builder:
          (context) => AlertDialog(
            title: const Text('Import preview'),
            content: Text(
              '${entries.length} new transactions\n$skipped existing transactions skipped',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(entries.isEmpty ? 'Close' : 'Cancel'),
              ),
              if (entries.isNotEmpty)
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Import'),
                ),
            ],
          ),
    );

    if (!state.mounted || confirmed != true) return;
    state._commit(
      state._ledger.copyWith(
        transactions: [...entries, ...state._transactions],
      ),
    );
    state._openActivity();
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(content: Text('Imported ${entries.length} transactions.')),
    );
  } on FormatException catch (error) {
    if (state.mounted) {
      ScaffoldMessenger.of(
        state.context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  } on PlatformException catch (error) {
    if (state.mounted) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Couldn’t open the CSV file.')),
      );
    }
  } on MissingPluginException {
    if (state.mounted) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        const SnackBar(
          content: Text('CSV import is available on Android and iOS.'),
        ),
      );
    }
  }
}

Transaction _csvEntry(_MainPageState state, Map<String, String> cells) {
  String field(String name) => (cells[name] ?? '').trim();
  String unescape(String value) =>
      value.startsWith("'") &&
              _Ledger._spreadsheetFormula.hasMatch(value.substring(1))
          ? value.substring(1)
          : value;

  final dateText = field('date');
  final date = DateTime.tryParse(dateText);
  if (date == null ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText) ||
      DateFormat('yyyy-MM-dd').format(date) != dateText) {
    throw const FormatException('Use a valid date in YYYY-MM-DD format.');
  }
  final kind =
      _EntryKind.values
          .where((kind) => kind.name == field('type').toLowerCase())
          .firstOrNull;
  final amount = _parseMoney(field('amount'));
  if (kind == null || amount == null || amount <= 0) {
    throw const FormatException(
      'Use expense, income, or transfer and a positive amount.',
    );
  }
  final currency = field('currency').toUpperCase();
  if (currency.isNotEmpty && currency != state._selectedCurrency.name) {
    throw FormatException(
      'Set Currency to ${state._selectedCurrency.name} or leave it blank.',
    );
  }

  String accountId(String name) {
    final nameValue = unescape(field(name));
    final matches =
        state._ledger.accounts
            .where(
              (account) =>
                  account.name.toLowerCase() == nameValue.toLowerCase(),
            )
            .toList();
    if (matches.length != 1) {
      throw FormatException('Use an existing, unique account for $name.');
    }
    return matches.single.id;
  }

  final account =
      field('account').isEmpty
          ? state._ledger.accounts.first.id
          : accountId('account');
  final destination =
      kind == _EntryKind.transfer ? accountId('destination') : null;
  if (account == destination) {
    throw const FormatException('A transfer needs two different accounts.');
  }
  final expense = kind == _EntryKind.expense;
  final categoryName = unescape(field('category')).toLowerCase();
  final applicable = state._categories.where(
    (category) => category.isExpense == expense,
  );
  final fallbackId = expense ? 'other_expense' : 'other_income';
  final category =
      applicable
          .where(
            (category) =>
                categoryName.isEmpty
                    ? category.id == fallbackId
                    : category.name.toLowerCase() == categoryName,
          )
          .firstOrNull;
  if (kind != _EntryKind.transfer &&
      categoryName.isNotEmpty &&
      category == null) {
    throw const FormatException(
      'Use an existing category that matches the transaction type.',
    );
  }
  return Transaction(
    id: _identifier(),
    amount: amount / 100,
    isExpense: expense,
    categoryId:
        kind == _EntryKind.transfer
            ? ''
            : category?.id ?? applicable.firstOrNull?.id ?? fallbackId,
    date: date,
    accountId: account,
    destinationId: destination,
    description: unescape(cells['note'] ?? ''),
  );
}
