part of '../home.dart';

class _PlanNotifications {
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static const _prefix = 'plan-reminder:';
  static const _loanPrefix = 'loan-reminder:';
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void> _initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_plan_reminder'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<List<PendingNotificationRequest>> _pending() async {
    try {
      await (_initialization ??= _initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
    return _plugin.pendingNotificationRequests();
  }

  String key(String bucket, String category) =>
      '$_prefix${jsonEncode([bucket, category])}';

  String loanKey(String id) => '$_loanPrefix$id';

  Future<Set<String>> reconcile(_Ledger ledger, List<Loan> loans) async {
    if (!supported) return {};
    final valid = {
      for (final loan in loans)
        if (!loan.isPaid && !loan.isDeleted) loanKey(loan.id),
      for (final id in ledger.budgets.keys) key('monthly', id),
      for (final bucket in ledger.periodBudgets.entries)
        for (final id in bucket.value.keys) key(bucket.key, id),
    };
    final active = <String>{};
    for (final request in await _pending()) {
      final payload = request.payload;
      if (payload == null ||
          !(payload.startsWith(_prefix) || payload.startsWith(_loanPrefix))) {
        continue;
      }
      if (valid.contains(payload)) {
        active.add(payload);
      } else {
        await _plugin.cancel(request.id);
      }
    }
    return active;
  }

  Future<void> remove(String key) async {
    for (final request in await _pending()) {
      if (request.payload == key) await _plugin.cancel(request.id);
    }
  }

  Future<bool> schedule({
    required String key,
    required String name,
    required _BudgetPeriod period,
    required DateTimeRange window,
    required bool repeats,
    required TimeOfDay time,
  }) => _schedule(
    key: key,
    title: '$name plan',
    body: 'Review your spending and what you have left.',
    time: time,
    match:
        !repeats
            ? null
            : switch (period) {
              _BudgetPeriod.daily => DateTimeComponents.time,
              _BudgetPeriod.weekly => DateTimeComponents.dayOfWeekAndTime,
              _BudgetPeriod.monthly => DateTimeComponents.dayOfMonthAndTime,
            },
    chooseDay: (now, at) {
      var day = window.start;
      if (repeats) {
        day = period.start(now);
        if (!at(day).isAfter(now)) day = period.move(day, 1);
      } else {
        if (day.isBefore(DateUtils.dateOnly(now)))
          day = DateUtils.dateOnly(now);
        if (!at(day).isAfter(now)) day = _shiftBudgetDay(day, 1);
        if (day.isAfter(window.end)) {
          throw const FormatException(
            'Choose a future reminder time in this period.',
          );
        }
      }
      return day;
    },
  );

  Future<bool> scheduleLoan(Loan loan, DateTime date, TimeOfDay time) =>
      _schedule(
        key: loanKey(loan.id),
        title: '${loan.personName} loan reminder',
        body:
            loan.type == LoanType.given
                ? 'Follow up on the remaining balance.'
                : 'Review your remaining payment.',
        time: time,
        chooseDay: (now, at) {
          if (!at(date).isAfter(now)) {
            throw const FormatException(
              'Choose a reminder time in the future.',
            );
          }
          return date;
        },
        loan: true,
      );

  Future<bool> _schedule({
    required String key,
    required String title,
    required String body,
    required TimeOfDay time,
    required DateTime Function(tz.TZDateTime, tz.TZDateTime Function(DateTime))
    chooseDay,
    DateTimeComponents? match,
    bool loan = false,
  }) async {
    final pending = await _pending();
    final permission = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      _ => await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true),
    };
    if (permission != true) return false;

    final zone = await const MethodChannel(
      'com.lekshan.moneyflow/export',
    ).invokeMethod<String>('timeZone');
    tz_data.initializeTimeZones();
    final location = tz.getLocation(zone!);
    final now = tz.TZDateTime.now(location);
    tz.TZDateTime at(DateTime date) => tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final day = chooseDay(now, at);
    final existing = pending.where((item) => item.payload == key).firstOrNull;
    if (existing == null &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        pending.length >= 64) {
      throw const FormatException('Remove a reminder before adding another.');
    }
    final ids = pending.map((item) => item.id).toSet();
    var id = existing?.id ?? 1;
    if (existing == null) {
      while (ids.contains(id)) {
        id++;
      }
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      at(day),
      NotificationDetails(
        android:
            loan
                ? const AndroidNotificationDetails(
                  'loan_reminders',
                  'Loan reminders',
                )
                : const AndroidNotificationDetails(
                  'plan_reminders',
                  'Plan reminders',
                ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: match,
      payload: key,
    );
    return true;
  }
}

extension _PlanReminderControls on _MainPageState {
  IconButton _reminderButton(String category, bool repeats) {
    final period = _budgetPeriod;
    final date = _budgetDate;
    final key = _planNotifications.key(period.key(date, repeats), category);
    final active = _activeReminders.contains(key);
    return IconButton(
      tooltip:
          active
              ? 'Edit ${_budgetName(category)} reminder'
              : 'Set ${_budgetName(category)} reminder',
      icon: Icon(
        active ? Icons.notifications_active_outlined : Icons.notifications_none,
      ),
      onPressed:
          _remindersBusy
              ? null
              : () => _editPlanReminder(key, category, period, date, repeats),
    );
  }
}
