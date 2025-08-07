import 'package:flutter/material.dart';

class AgentSelector extends StatelessWidget {
  final String selectedAgent;
  final Function(String) onAgentChanged;
  final List<Map<String, dynamic>> availableAgents;

  const AgentSelector({
    super.key,
    required this.selectedAgent,
    required this.onAgentChanged,
    this.availableAgents = const [
      {
        'type': 'therapy',
        'name': 'Therapy Agent',
        'description':
            'Provides therapeutic conversations and emotional support',
        'icon': Icons.psychology,
      },
      {
        'type': 'wellness',
        'name': 'Wellness Agent',
        'description':
            'Focuses on mindfulness, breathing exercises, and general wellness',
        'icon': Icons.spa,
      },
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose Your AI Assistant',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...availableAgents.map((agent) {
            final isSelected = selectedAgent == agent['type'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onAgentChanged(agent['type']),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color:
                        isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        agent['icon'] as IconData,
                        size: 32,
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? Theme.of(context).primaryColor
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              agent['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
