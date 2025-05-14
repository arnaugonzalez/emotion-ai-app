import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/models/emotional_record.dart';
import '../../shared/models/breathing_session_data.dart';
import '../../shared/services/sqlite_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<EmotionalRecord>> _emotionalEvents = {};
  Map<DateTime, List<BreathingSessionData>> _breathingEvents = {};

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final sqliteHelper = SQLiteHelper();

    try {
      // Fetch emotional records from the backend
      final emotionalResponse = await http.get(
        Uri.parse('http://localhost:8000/emotional_records/'),
      );
      if (emotionalResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(emotionalResponse.body);
        final Map<DateTime, List<EmotionalRecord>> events = {};

        for (var item in data) {
          final record = EmotionalRecord.fromMap(item);
          final date = DateTime(
            record.date.year,
            record.date.month,
            record.date.day,
          );
          events[date] = events[date] ?? [];
          events[date]!.add(record);
        }

        setState(() {
          _emotionalEvents = events;
        });
      } else {
        throw Exception('Failed to fetch emotional records');
      }

      // Fetch breathing sessions from the backend
      final breathingResponse = await http.get(
        Uri.parse('http://localhost:8000/breathing_sessions/'),
      );
      if (breathingResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(breathingResponse.body);
        final Map<DateTime, List<BreathingSessionData>> events = {};

        for (var item in data) {
          final session = BreathingSessionData.fromMap(item);
          final date = DateTime(
            session.date.year,
            session.date.month,
            session.date.day,
          );
          events[date] = events[date] ?? [];
          events[date]!.add(session);
        }

        setState(() {
          _breathingEvents = events;
        });
      } else {
        throw Exception('Failed to fetch breathing sessions');
      }
    } catch (e) {
      // Fallback to SQLite if the backend connection fails
      logger.e('Fetching data from SQLite due to error: $e');

      final emotionalRecords = await sqliteHelper.getEmotionalRecords();
      final Map<DateTime, List<EmotionalRecord>> emotionalEvents = {};
      for (var record in emotionalRecords) {
        final date = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        emotionalEvents[date] = emotionalEvents[date] ?? [];
        emotionalEvents[date]!.add(record);
      }

      final breathingSessions = await sqliteHelper.getBreathingSessions();
      final Map<DateTime, List<BreathingSessionData>> breathingEvents = {};
      for (var session in breathingSessions) {
        final date = DateTime(
          session.date.year,
          session.date.month,
          session.date.day,
        );
        breathingEvents[date] = breathingEvents[date] ?? [];
        breathingEvents[date]!.add(session);
      }

      setState(() {
        _emotionalEvents = emotionalEvents;
        _breathingEvents = breathingEvents;
      });
    }
  }

  List<Widget> _buildEventMarkers(DateTime day) {
    final emotionalRecords = _emotionalEvents[day] ?? [];
    final breathingSessions = _breathingEvents[day] ?? [];

    return [
      ...emotionalRecords.map(
        (record) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: record.emotion.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
      ...breathingSessions.map(
        (_) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 1.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDetailsForSelectedDay(DateTime day) {
    final emotionalRecords = _emotionalEvents[day] ?? [];
    final breathingSessions = _breathingEvents[day] ?? [];

    return [
      ...emotionalRecords.map(
        (record) => ListTile(
          title: Text('Emotion: ${record.emotion.name}'),
          subtitle: Text(record.description),
        ),
      ),
      ...breathingSessions.map(
        (session) => ListTile(
          title: Text('Breathing Session'),
          subtitle: Text(
            'Rating: ${session.rating}, Comment: ${session.comment}',
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildEventMarkers(day),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: _buildDetailsForSelectedDay(
                _selectedDay ?? _focusedDay,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
