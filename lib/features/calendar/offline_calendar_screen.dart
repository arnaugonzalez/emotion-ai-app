import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './events/offline_calendar_provider.dart';
import '../../shared/widgets/connectivity_widget.dart';
import '../../shared/services/offline_data_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class OfflineCalendarScreen extends ConsumerStatefulWidget {
  const OfflineCalendarScreen({super.key});

  @override
  ConsumerState<OfflineCalendarScreen> createState() =>
      _OfflineCalendarScreenState();
}

class _OfflineCalendarScreenState extends ConsumerState<OfflineCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoadingPresets = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    Future.microtask(() {
      OfflineDataService().initialize();
    });
  }

  Future<void> _loadPresetData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPresets = true;
    });

    try {
      await ref.read(offlineCalendarProvider.notifier).addPresetData();

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
    Map<DateTime, List<dynamic>> emotionalEvents,
    Map<DateTime, List<dynamic>> breathingEvents,
  ) {
    final normalizedDay = DateTime(day.year, day.month, day.day);

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

    const maxMarkers = 3;
    final totalEvents = emotionalRecords.length + breathingSessions.length;

    if (totalEvents == 0) return [];

    if (totalEvents <= maxMarkers) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          constraints: const BoxConstraints(maxWidth: 30, maxHeight: 20),
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              ...emotionalRecords.map((record) {
                final color =
                    record.customEmotionColor != null
                        ? Color(record.customEmotionColor!)
                        : Color(record.color);
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                );
              }),
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
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          constraints: const BoxConstraints(maxWidth: 30, maxHeight: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '+$totalEvents',
            style: TextStyle(
              fontSize: 8,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ];
    }
  }

  List<Widget> _buildDetailsForSelectedDay(
    DateTime day,
    Map<DateTime, List<dynamic>> emotionalEvents,
    Map<DateTime, List<dynamic>> breathingEvents,
  ) {
    final normalizedDay = DateTime(day.year, day.month, day.day);

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
                      : Color(record.color),
              radius: 16,
            ),
            title: Text(
              record.customEmotionName?.toUpperCase() ??
                  record.emotion.toUpperCase(),
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
            title: Text('Pattern: ${session.pattern}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rating: ${session.rating}/5'),
                if (session.comment != null && session.comment!.isNotEmpty)
                  Text('Comment: ${session.comment!}'),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(offlineCalendarProvider);

    return Scaffold(
      body: Column(
        children: [
          ConnectivityWidget(
            status: calendarState.connectivityStatus,
            error: calendarState.errorMessage,
            lastSync: calendarState.lastSync,
            isFromCache: calendarState.isFromCache,
            mode: ConnectivityWidgetMode.banner,
            onRetry:
                () => ref.read(offlineCalendarProvider.notifier).retryFetch(),
          ),

          Expanded(child: _buildMainContent(calendarState)),
        ],
      ),
    );
  }

  Widget _buildMainContent(CalendarState calendarState) {
    if (calendarState.state == CalendarLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (calendarState.state == CalendarLoadState.error &&
        calendarState.emotionalEvents.isEmpty &&
        calendarState.breathingEvents.isEmpty) {
      return ConnectivityWidget(
        status: calendarState.connectivityStatus,
        error: calendarState.errorMessage,
        mode: ConnectivityWidgetMode.fullscreen,
        onRetry: () => ref.read(offlineCalendarProvider.notifier).retryFetch(),
        child: ElevatedButton.icon(
          onPressed: _isLoadingPresets ? null : _loadPresetData,
          icon:
              _isLoadingPresets
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.data_array),
          label: const Text('Load Sample Data'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          // Calendar header with responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Small screen: stack vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'Calendar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (calendarState.connectivityStatus !=
                                ConnectivityStatus.online ||
                            calendarState.isFromCache)
                          Flexible(
                            child: ConnectivityWidget(
                              status: calendarState.connectivityStatus,
                              mode: ConnectivityWidgetMode.button,
                              onRetry:
                                  () =>
                                      ref
                                          .read(
                                            offlineCalendarProvider.notifier,
                                          )
                                          .retryFetch(),
                              onForceSync:
                                  () =>
                                      ref
                                          .read(
                                            offlineCalendarProvider.notifier,
                                          )
                                          .forceSyncAll(),
                            ),
                          ),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoadingPresets ? null : _loadPresetData,
                            icon:
                                _isLoadingPresets
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.data_array),
                            label: const Text('Load Test Data'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Large screen: side by side
                return Row(
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
                    Row(
                      children: [
                        if (calendarState.connectivityStatus !=
                                ConnectivityStatus.online ||
                            calendarState.isFromCache)
                          ConnectivityWidget(
                            status: calendarState.connectivityStatus,
                            mode: ConnectivityWidgetMode.button,
                            onRetry:
                                () =>
                                    ref
                                        .read(offlineCalendarProvider.notifier)
                                        .retryFetch(),
                            onForceSync:
                                () =>
                                    ref
                                        .read(offlineCalendarProvider.notifier)
                                        .forceSyncAll(),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoadingPresets ? null : _loadPresetData,
                          icon:
                              _isLoadingPresets
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.data_array),
                          label: const Text('Load Test Data'),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
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
                    calendarState.emotionalEvents,
                    calendarState.breathingEvents,
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
                calendarState.emotionalEvents,
                calendarState.breathingEvents,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
