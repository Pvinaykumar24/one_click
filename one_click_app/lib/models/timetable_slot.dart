class TimetableSlot {
  final String id;
  final int day;
  final String start;
  final String end;
  final String subject;
  final String room;
  final String type; // e.g. 'Lecture', 'Lab'
  final int credits;

  TimetableSlot({
    required this.id,
    required this.day,
    required this.start,
    required this.end,
    required this.subject,
    required this.room,
    required this.type,
    this.credits = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'start': start,
      'end': end,
      'subject': subject,
      'room': room,
      'type': type,
      'credits': credits,
    };
  }

  factory TimetableSlot.fromMap(Map<String, dynamic> map, String docId) {
    return TimetableSlot(
      id: docId,
      day: map['day'] ?? 1,
      start: map['start'] ?? '',
      end: map['end'] ?? '',
      subject: map['subject'] ?? '',
      room: map['room'] ?? '',
      type: map['type'] ?? 'Lecture',
      credits: map['credits'] ?? 3,
    );
  }

  TimetableSlot copyWith({
    String? id,
    int? day,
    String? start,
    String? end,
    String? subject,
    String? room,
    String? type,
    int? credits,
  }) {
    return TimetableSlot(
      id: id ?? this.id,
      day: day ?? this.day,
      start: start ?? this.start,
      end: end ?? this.end,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      type: type ?? this.type,
      credits: credits ?? this.credits,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableSlot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          day == other.day &&
          start == other.start &&
          end == other.end &&
          subject == other.subject &&
          room == other.room &&
          type == other.type &&
          credits == other.credits;

  @override
  int get hashCode =>
      id.hashCode ^
      day.hashCode ^
      start.hashCode ^
      end.hashCode ^
      subject.hashCode ^
      room.hashCode ^
      type.hashCode ^
      credits.hashCode;
}
