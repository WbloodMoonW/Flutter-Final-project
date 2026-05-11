import 'package:flutter/material.dart';

class WorkingHoursEntry {
  TimeOfDay from;
  TimeOfDay to;

  WorkingHoursEntry({required this.from, required this.to});

  Map<String, dynamic> toMap() => {
    'from': '${from.hour.toString().padLeft(2, '0')}:${from.minute.toString().padLeft(2, '0')}',
    'to': '${to.hour.toString().padLeft(2, '0')}:${to.minute.toString().padLeft(2, '0')}',
  };

  factory WorkingHoursEntry.fromMap(Map<String, dynamic> map) {
    final fromStr = map['from'] ?? '09:00';
    final toStr = map['to'] ?? '18:00';
    final fromParts = fromStr.split(':');
    final toParts = toStr.split(':');
    
    return WorkingHoursEntry(
      from: TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1])),
      to: TimeOfDay(hour: int.parse(toParts[0]), minute: int.parse(toParts[1])),
    );
  }
}
