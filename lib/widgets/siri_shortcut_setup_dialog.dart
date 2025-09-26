import 'package:flutter/material.dart';
import 'package:ledgerlite/services/siri_shortcut_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog for setting up Siri shortcuts
class SiriShortcutSetupDialog extends StatefulWidget {
  const SiriShortcutSetupDialog({super.key});

  @override
  State<SiriShortcutSetupDialog> createState() =>
      _SiriShortcutSetupDialogState();
}

class _SiriShortcutSetupDialogState extends State<SiriShortcutSetupDialog> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _markSetupAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_siri_setup', true);
  }

  Future<void> _addShortcut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening shortcut setup...';
    });

    try {
      final result = await SiriShortcutService.showAddShortcut();
      setState(() {
        _statusMessage = result;
      });
      // Mark as seen when user successfully interacts
      await _markSetupAsSeen();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openSiriSettings() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening Siri settings...';
    });

    try {
      final result = await SiriShortcutService.openSiriSettings();
      setState(() {
        _statusMessage = result;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.mic, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Siri Shortcuts Setup'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enable voice commands to add expenses hands-free with Siri. '
              'Set up shortcuts to quickly log expenses using your voice.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addShortcut,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Add to Siri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _openSiriSettings,
                  icon: const Icon(Icons.settings),
                  tooltip: 'Open Siri Settings',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),

            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.startsWith('Error')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.startsWith('Error')
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: _statusMessage.startsWith('Error')
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Example Commands Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Example voice commands:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• "Add \$25 food expense"\n'
                    '• "Log \$50 transport expense"\n'
                    '• "Record \$100 shopping expense"',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
