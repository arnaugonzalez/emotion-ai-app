import 'package:flutter/material.dart';
import '../../shared/models/breathing_pattern.dart';
import '../../shared/services/sqlite_helper.dart';
import '../../shared/widgets/breating_session.dart';
import 'create_pattern_dialog.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class BreathingMenuScreen extends StatefulWidget {
  const BreathingMenuScreen({super.key});

  @override
  State<BreathingMenuScreen> createState() => _BreathingMenuScreenState();
}

class _BreathingMenuScreenState extends State<BreathingMenuScreen> {
  late Future<List<BreathingPattern>> _patternsFuture;

  @override
  void initState() {
    super.initState();
    _patternsFuture = _fetchBreathingPatterns();
  }

  Future<List<BreathingPattern>> _fetchBreathingPatterns() async {
    final sqliteHelper = SQLiteHelper();
    final patterns = await sqliteHelper.getBreathingPatterns();
    logger.i('Fetched ${patterns.length} breathing patterns');
    return patterns;
  }

  void _refreshPatterns() {
    setState(() {
      _patternsFuture = _fetchBreathingPatterns();
    });
  }

  void _showCreatePatternDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CreatePatternDialog(onPatternCreated: _refreshPatterns),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Patterns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPatterns,
            tooltip: 'Refresh patterns',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePatternDialog,
        tooltip: 'Add new breathing pattern',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<BreathingPattern>>(
        future: _patternsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshPatterns,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.air, size: 64, color: Colors.blueGrey),
                  const SizedBox(height: 16),
                  const Text(
                    'No breathing patterns available',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreatePatternDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Pattern'),
                  ),
                ],
              ),
            );
          }

          final patterns = snapshot.data!;
          return ListView.builder(
            itemCount: patterns.length,
            itemBuilder: (context, index) {
              final pattern = patterns[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              pattern.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Start'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => BreathingSessionScreen(
                                        pattern: pattern,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            'Inhale',
                            '${pattern.inhaleSeconds}s',
                            Colors.blue,
                          ),
                          _buildInfoChip(
                            'Hold',
                            '${pattern.holdSeconds}s',
                            Colors.purple,
                          ),
                          _buildInfoChip(
                            'Exhale',
                            '${pattern.exhaleSeconds}s',
                            Colors.teal,
                          ),
                          _buildInfoChip(
                            'Cycles',
                            '${pattern.cycles}',
                            Colors.orange,
                          ),
                          _buildInfoChip(
                            'Rest',
                            '${pattern.restSeconds}s',
                            Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Chip(
      backgroundColor: color.withValues(alpha: 38),
      side: BorderSide(color: color.withValues(alpha: 77)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 51),
        radius: 10,
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
