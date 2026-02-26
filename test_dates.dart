void main() {
  DateTime date = DateTime(2026, 2, 22);

  List<DateTime> targetDatesMonth = [];
  final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
  final daysRemainingMonth = lastDayOfMonth
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  for (int i = 1; i <= daysRemainingMonth; i++) {
    targetDatesMonth.add(DateTime(date.year, date.month, date.day + i));
  }
  print("Monthly added: ${targetDatesMonth.length}");

  List<DateTime> targetDatesYear = [];
  final lastDayOfYear = DateTime(date.year, 12, 31);
  final daysRemainingYear = lastDayOfYear
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  for (int i = 1; i <= daysRemainingYear; i++) {
    targetDatesYear.add(DateTime(date.year, date.month, date.day + i));
  }
  print("Yearly added: ${targetDatesYear.length}");
  if (targetDatesYear.isNotEmpty) {
    print("Yearly last date: ${targetDatesYear.last}");
  }
}
