import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './events/calendar_events_provider.dart';
import '../../shared/models/emotional_record.dart';
import '../../shared/models/breathing_session_data.dart';
import '../../shared/services/sqlite_helper.dart';
import '../../shared/services/data_presets.dart';
import 'package:table_calendar/table_calendar.dart';
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
  bool _isLoadingPresets = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Get provider reference before async gap
    final provider = Provider.of<CalendarEventsProvider>(
      context,
      listen: false,
    );

    Future.microtask(() {
      if (!mounted) return;
      provider.fetchEvents(
        onBackendError: (msg) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    });
  }

  Future<void> _loadPresetData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPresets = true;
    });

    try {
      final sqliteHelper = SQLiteHelper();
      final presetService = DataPresetService(sqliteHelper);
      final provider = Provider.of<CalendarEventsProvider>(
        context,
        listen: false,
      );

      await presetService.loadAllPresetData();
      if (!mounted) return;

      // Refresh calendar events
      await provider.fetchEvents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preset data loaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      logger.e('Error loading preset data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load preset data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPresets = false;
        });
      }
    }
  }

  List<Widget> _buildEventMarkers(
    DateTime day,
    Map<DateTime, List<EmotionalRecord>> emotionalEvents,
    Map<DateTime, List<BreathingSessionData>> breathingEvents,
  ) {
    // Normalize date to compare just year, month, and day
    final normalizedDay = DateTime(day.year, day.month, day.day);

    // Find matching events
    final emotionalRecords =
        emotionalEvents.entries
            .where(
              (entry) =>
                  entry.key.year == normalizedDay.year &&
                  entry.key.month == normalizedDay.month &&
                  entry.key.day == normalizedDay.day,
            )
            .expand((entry) => entry.value)
            .toList();

    final breathingSessions =
        breathingEvents.entries
            .where(
              (entry) =>
                  entry.key.year == normalizedDay.year &&
                  entry.key.month == normalizedDay.month &&
                  entry.key.day == normalizedDay.day,
            )
            .expand((entry) => entry.value)
            .toList();

    // Limit the number of markers to prevent overflow
    const maxMarkers = 3;
    final totalEvents = emotionalRecords.length + breathingSessions.length;

    if (totalEvents == 0) return [];

    if (totalEvents <= maxMarkers) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Wrap(
            spacing: 3,
            children: [
              ...emotionalRecords.map(
                (record) => Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        record.customEmotionColor != null
                            ? Color(record.customEmotionColor!)
                            : record.emotion.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              ...breathingSessions.map(
                (_) => Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    } else {
      // Show a counter instead when there are too many events
      return [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '+$totalEvents',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ];
    }
  }

  List<Widget> _buildDetailsForSelectedDay(
    DateTime day,
    Map<DateTime, List<EmotionalRecord>> emotionalEvents,
    Map<DateTime, List<BreathingSessionData>> breathingEvents,
  ) {
    // Normalize date to compare just year, month, and day
    final normalizedDay = DateTime(day.year, day.month, day.day);

    // Find matching events
    final emotionalRecords =
        emotionalEvents.entries
            .where(
              (entry) =>
                  entry.key.year == normalizedDay.year &&
                  entry.key.month == normalizedDay.month &&
                  entry.key.day == normalizedDay.day,
            )
            .expand((entry) => entry.value)
            .toList();

    final breathingSessions =
        breathingEvents.entries
            .where(
              (entry) =>
                  entry.key.year == normalizedDay.year &&
                  entry.key.month == normalizedDay.month &&
                  entry.key.day == normalizedDay.day,
            )
            .expand((entry) => entry.value)
            .toList();

    if (emotionalRecords.isEmpty && breathingSessions.isEmpty) {
      return [const ListTile(title: Text('No events for this day'))];
    }

    return [
      if (emotionalRecords.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8.0, left: 16.0, bottom: 4.0),
          child: Text(
            'Emotional Records',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ...emotionalRecords.map(
        (record) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  record.customEmotionColor != null
                      ? Color(record.customEmotionColor!)
                      : record.emotion.color,
              radius: 16,
            ),
            title: Text(
              record.customEmotionName?.toUpperCase() ??
                  record.emotion.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.description),
                Text(
                  'Source: ${record.source}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      if (breathingSessions.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 16.0, left: 16.0, bottom: 4.0),
          child: Text(
            'Breathing Sessions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ...breathingSessions.map(
        (session) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(Icons.air, color: Colors.white, size: 18),
            ),
            title: Text('Pattern: ${session.pattern.name}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rating: ${session.rating}/5'),
                if (session.comment.isNotEmpty)
                  Text('Comment: ${session.comment}'),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarEventsProvider>(
      builder: (context, provider, _) {
        if (provider.state == CalendarLoadState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.state == CalendarLoadState.error) {
          return Center(
            child: Text('Error loading calendar: ${provider.errorMessage}'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoadingPresets ? null : _loadPresetData,
                    icon:
                        _isLoadingPresets
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.data_array),
                    label: const Text('Load Test Data'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                calendarStyle: const CalendarStyle(
                  markersMaxCount: 3,
                  markerSize: 6,
                  markerMargin: EdgeInsets.symmetric(horizontal: 0.5),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildEventMarkers(
                        day,
                        provider.emotionalEvents,
                        provider.breathingEvents,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: _buildDetailsForSelectedDay(
                    _selectedDay ?? _focusedDay,
                    provider.emotionalEvents,
                    provider.breathingEvents,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
