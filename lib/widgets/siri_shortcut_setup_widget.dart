import 'package:flutter/material.dart';
import 'package:ledgerlite/services/siri_shortcut_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget for setting up Siri shortcuts
class SiriShortcutSetupWidget extends StatefulWidget {
  const SiriShortcutSetupWidget({super.key});

  @override
  State<SiriShortcutSetupWidget> createState() =>
      _SiriShortcutSetupWidgetState();
}

class _SiriShortcutSetupWidgetState extends State<SiriShortcutSetupWidget> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasSeenSetup = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_siri_setup') ?? false;
    setState(() {
      _hasSeenSetup = hasSeen;
      _isExpanded = !hasSeen; // Expand by default for first-time users
    });
  }

  Future<void> _markSetupAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_siri_setup', true);
    setState(() {
      _hasSeenSetup = true;
    });
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
          if (expanded && !_hasSeenSetup) {
            _markSetupAsSeen();
          }
        },
        leading: const Icon(Icons.mic, color: Colors.blue),
        title: Text(
          'Siri Shortcuts Setup',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: _hasSeenSetup
            ? null
            : const Text('Tap to set up voice commands'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable voice commands to add expenses hands-free with Siri. '
                  'Tap the button below to add shortcuts to Siri.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addShortcut,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                    ),
                  ],
                ),
                if (_statusMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusMessage.startsWith('Error')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Example commands you can use:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
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
    );
  }
}
