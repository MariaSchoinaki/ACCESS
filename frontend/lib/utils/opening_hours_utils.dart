import 'package:flutter/material.dart';

List<Widget> buildOpeningHoursWidgets(Map<String, dynamic> openHours) {
  final List<Widget> children = [];
  print("hehehhehehehhehhhe"+ openHours.toString());
  if (openHours.containsKey('weekday_text')) {
    final List<dynamic> weekdayTextOuterList = openHours['weekday_text'];
    if (weekdayTextOuterList.isNotEmpty && weekdayTextOuterList[0] is List) {
      final List<dynamic> weekdayText = weekdayTextOuterList[0];
      const List<String> greekDays = [
        'Δευτέρα', 'Τρίτη', 'Τετάρτη', 'Πέμπτη',
        'Παρασκευή', 'Σάββατο', 'Κυριακή',
      ];
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Ώρες Λειτουργίας:', style: TextStyle(fontWeight: FontWeight.bold)),
      ));
      if (greekDays.length != weekdayText.length) {
        for (int i = 2; i < weekdayText.length; i++) {
          children.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text('${greekDays[i-2]}: ${weekdayText[i]}'),
          ));
        }
      } else {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: Text('Σφάλμα: Μη αναμενόμενος αριθμός ωρών λειτουργίας'),
        ));
        print('Σφάλμα: Μη αναμενόμενος αριθμός περιγραφών ημερών: ${weekdayText.length}');
      }
      return children;
    } else {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Σφάλμα: Μη αναμενόμενη δομή weekday_text'),
      ));
      print('Σφάλμα: Μη αναμενόμενη δομή weekday_text: $weekdayTextOuterList');
      return children;
    }
  }

  final List<dynamic>? periods = openHours['periods'];
  if (periods != null && periods.isNotEmpty) {
    children.add(const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Text('Ώρες Λειτουργίας:', style: TextStyle(fontWeight: FontWeight.bold)),
    ));

    for (final period in periods) {
      final open = period['open'] as Map<String, dynamic>?;
      final close = period['close'] as Map<String, dynamic>?;

      final int? openDay = open?['day'];
      final String? openTime = open?['time'];
      final int? closeDay = close?['day'];
      final String? closeTime = close?['time'];

      final String? formattedOpenTime = _formatTime(openTime);
      final String? formattedCloseTime = _formatTime(closeTime);
      final String? openDayStr = _dayToGreek(openDay);
      final String? closeDayStr = _dayToGreek(closeDay);

      String periodText;
      if (openDayStr == closeDayStr) {
        periodText = '$openDayStr: $formattedOpenTime - $formattedCloseTime';
      } else {
        periodText = '$openDayStr $formattedOpenTime - $closeDayStr $formattedCloseTime';
      }

      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(periodText),
      ));
    }
  }

  return children;
}

String? _formatTime(String? time) {
  if (time == null || time.length != 4) return null;
  final int hour = int.parse(time.substring(0, 2));
  final String minute = time.substring(2);
  final String periodAmPm = hour < 12 ? 'πμ' : 'μμ';
  final int formattedHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$formattedHour:$minute $periodAmPm';
}

String? _dayToGreek(int? day) {
  if (day == null) return null;
  const days = [
    'Κυριακή', 'Δευτέρα', 'Τρίτη', 'Τετάρτη',
    'Πέμπτη', 'Παρασκευή', 'Σάββατο',
  ];
  return (day >= 0 && day < days.length) ? days[day] : null;
}
