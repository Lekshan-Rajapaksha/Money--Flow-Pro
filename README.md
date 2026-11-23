# Money Flow Pro

Money Flow Pro is an offline-first Flutter money tracker for Android and iOS. Record expenses, income, and transfers, manage accounts and spending limits, and see where your money went.

## Run locally

Install Flutter with Dart 3.7 or later and set up the Android SDK or Xcode. The iOS target requires iOS 15 or later.

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

```sh
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

An unsigned iOS build is for compilation checks. Select your development team in Xcode to run on a physical iPhone. Android release builds use the project's existing signing configuration when a local `android/key.properties` file is present.

## What you can track

- **Overview** shows current account balances, this month's income and spending, daily and monthly limits, upcoming payments, and recent activity.
- **Activity** supports editing, deletion with undo, search, account and category filters, date ranges, and CSV import and export. Transfers update both accounts and are excluded from spending and income reports.
- **Plan** includes daily, weekly, and monthly spending limits, manual savings goals, and one-time, weekly, monthly, or yearly payment schedules. Review and record each due item in the app. Recording a recurring item advances the schedule.
- **Insights** compares six months of income and spending. Tap a spending category to see its transactions for the selected month. Detailed reports include weekly and yearly views.
- **More** contains existing loan repayment tools, savings, fixed deposits, custom categories, and settings.

Existing transactions appear in a default account on upgrade. The app uses one base currency for all accounts. Its CSV export contains transaction history for spreadsheets. Planning and account data are stored on the device.

To change the theme, open **More → Settings → Appearance** and choose **System**, **Light**, or **Dark**. The app remembers your choice on this device.

### Plan a day, week, or month

Open **Plan → Budgets → Day** and tap **Breakfast** or **Dinner** under **Quick meal limits**. For example, enter 500 for breakfast and 400 for dinner to make a 900 daily plan. Tap **Add limit** to pick another category or create your own. Set **All expenses** to give the period a separate overall cap. The cap counts all expenses, including categories without individual limits.

Switch to **Week** or **Month** to set independent limits. Weeks run Monday through Sunday. Use the date arrows to plan ahead or review earlier spending. Each limit can repeat or apply to just the selected period. A limit for one period overrides the repeating limit for that category. Use the plus button on a category to log an expense directly against it.

### Import transaction history

On Android or iOS, open **More → Import transactions** and choose a UTF-8 CSV up to 5 MB. Include `Date` (YYYY-MM-DD), `Type` (expense, income, or transfer), and positive `Amount`. Optional columns are `Currency`, `Category`, `Account`, `Destination`, and `Note`. When supplied, currency must match the app setting, and account and category names must already exist. For transfers, provide a destination account. The app previews the number of new and duplicate records before saving anything.

```csv
Date,Type,Amount,Currency,Category,Account,Destination,Note
2026-01-08,expense,17.25,USD,Food,Main account,,Lunch
```

## Product research

| Reference | Patterns applied |
| --- | --- |
| [YNAB](https://www.ynab.com/features) | Category spending targets, savings progress, and accessible reports |
| [Monarch](https://help.monarch.com/hc/en-us/articles/21846787088916-Using-Reports) | A unified activity feed, cash flow, and reports that drill down to transactions |
| [Wallet by BudgetBakers](https://budgetbakers.com/en/products/wallet/) | Daily visibility into balances and planned payments |
| [Money Manager by Realbyte](https://realbyteapps.com/) | Quick manual entry, balances, and monthly category budgets |
| [Spendee](https://www.spendee.com/features/) | Separate accounts, transfers, and portable transaction history |
| [Rocket Money](https://www.rocketmoney.com/faq) | Recurring bills and subscriptions visible before they are due |
| [Cashew](https://cashewapp.web.app/faq.html) | Manual account tracking and category spending limits |
