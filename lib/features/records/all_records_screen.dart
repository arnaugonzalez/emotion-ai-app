import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../../shared/services/sqlite_helper.dart';
import '../../shared/models/emotional_record.dart';
import '../../shared/models/breathing_session_data.dart';

final logger = Logger();

class AllRecordsScreen extends StatefulWidget {
  const AllRecordsScreen({super.key});

  @override
  State<AllRecordsScreen> createState() => _AllRecordsScreenState();
}

class _AllRecordsScreenState extends State<AllRecordsScreen> {
  final SQLiteHelper _sqliteHelper = SQLiteHelper();
  List<EmotionalRecord> _emotionalRecords = [];
  List<BreathingSessionData> _breathingSessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First try to fetch from backend
      await _fetchFromBackend();
    } catch (e) {
      logger.e('Error fetching from backend: $e');
      // If backend fails, fallback to local storage
      await _loadFromLocalStorage();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchFromBackend() async {
    try {
      // Fetch emotional records from backend
      final emotionalUrl = Uri.parse('http://10.0.2.2:8000/emotional_records/');
      final emotionalResponse = await http
          .get(emotionalUrl)
          .timeout(const Duration(seconds: 5));

      // Fetch breathing sessions from backend
      final breathingUrl = Uri.parse(
        'http://10.0.2.2:8000/breathing_sessions/',
      );
      final breathingResponse = await http
          .get(breathingUrl)
          .timeout(const Duration(seconds: 5));

      if (emotionalResponse.statusCode == 200 &&
          breathingResponse.statusCode == 200) {
        final List<dynamic> emotionalJson = jsonDecode(emotionalResponse.body);
        final List<dynamic> breathingJson = jsonDecode(breathingResponse.body);

        setState(() {
          _emotionalRecords =
              emotionalJson
                  .map((record) => EmotionalRecord.fromMap(record))
                  .toList();
          _breathingSessions =
              breathingJson
                  .map((session) => BreathingSessionData.fromMap(session))
                  .toList();
        });

        logger.i('Data fetched from backend successfully');
      } else {
        throw Exception('Failed to load data from backend');
      }
    } catch (e) {
      throw Exception('Backend connection failed: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      logger.i('Falling back to local SQLite storage');
      final emotionalRecords = await _sqliteHelper.getEmotionalRecords();
      final breathingSessions = await _sqliteHelper.getBreathingSessions();

      setState(() {
        _emotionalRecords = emotionalRecords;
        _breathingSessions = breathingSessions;
      });

      logger.i(
        'Data loaded from local storage: ${emotionalRecords.length} emotional records, ${breathingSessions.length} breathing sessions',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load local data: $e';
      });
      logger.e('Error loading from local storage: $e');
    }
  }

  Future<void> _deleteAllLocalData() async {
    // Show confirmation dialog first
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete All Local Data'),
                content: const Text(
                  'This will delete all emotional records and breathing sessions stored locally. This action cannot be undone. Backend data will not be affected.\n\nAre you sure?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete all local records
      await _sqliteHelper.deleteAllEmotionalRecords();
      await _sqliteHelper.deleteAllBreathingSessions();

      logger.i('All local data deleted successfully');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All local data deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload data from backend
      await _loadData();
    } catch (e) {
      logger.e('Error deleting local data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting local data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Records'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : RefreshIndicator(
                onRefresh: _loadData,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Delete All Data Button
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isDeleting ? null : _deleteAllLocalData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withAlpha(220),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.delete_forever),
                              label:
                                  _isDeleting
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text('Delete All Local Data'),
                            ),
                          ),

                          const Text(
                            'Emotional Records',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEmotionalRecordsList(),
                          const SizedBox(height: 32),
                          const Text(
                            'Breathing Sessions',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildBreathingSessionsList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildEmotionalRecordsList() {
    if (_emotionalRecords.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No emotional records found'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _emotionalRecords.length,
      itemBuilder: (context, index) {
        final record = _emotionalRecords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: record.emotion.color,
              child: Icon(_getEmotionIcon(record.emotion), color: Colors.white),
            ),
            title: Text(record.emotion.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.description),
                const SizedBox(height: 4),
                Text(
                  'Source: ${record.source}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Text(
              '${record.date.day}/${record.date.month}/${record.date.year}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreathingSessionsList() {
    if (_breathingSessions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No breathing sessions found'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _breathingSessions.length,
      itemBuilder: (context, index) {
        final session = _breathingSessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.lightBlue,
              child: Icon(Icons.air, color: Colors.white),
            ),
            title: Text(session.pattern.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pattern: ${session.pattern.inhaleSeconds}-${session.pattern.holdSeconds}-${session.pattern.exhaleSeconds}',
                ),
                const SizedBox(height: 4),
                Text('Rating: ${session.rating}/5'),
                if (session.comment.isNotEmpty)
                  Text('Comment: ${session.comment}'),
              ],
            ),
            trailing: Text(
              '${session.date.day}/${session.date.month}/${session.date.year}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        );
      },
    );
  }

  IconData _getEmotionIcon(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return Icons.sentiment_very_satisfied;
      case Emotion.excited:
        return Icons.celebration;
      case Emotion.tender:
        return Icons.favorite;
      case Emotion.scared:
        return Icons.sentiment_very_dissatisfied;
      case Emotion.angry:
        return Icons.mood_bad;
      case Emotion.sad:
        return Icons.sentiment_dissatisfied;
      case Emotion.anxious:
        return Icons.psychology;
    }
  }
}
