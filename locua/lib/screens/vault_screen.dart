// vault_screen.dart
// Real Vault screen: shows the user's personal mnemonics (text or voice)
// per word, with the ability to add a new one. Voice notes are recorded
// and played back via RecorderService, and saved permanently via Hive.
//
// NOTE: voice recording AND playback only work on the native Android
// app, not in this Web preview.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mnemonic.dart';
import '../services/storage_service.dart';
import '../services/recorder_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _isRecording = false;
  String? _lastRecordedPath;

  String? _currentlyPlayingPath;
  StreamSubscription<void>? _playbackCompleteSub;

  @override
  void initState() {
    super.initState();
    _playbackCompleteSub = RecorderService.onPlaybackComplete.listen((_) {
      if (mounted) {
        setState(() => _currentlyPlayingPath = null);
      }
    });
  }

  @override
  void dispose() {
    _playbackCompleteSub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlayback(String path) async {
    if (_currentlyPlayingPath == path) {
      await RecorderService.stopPlayback();
      if (!mounted) return; // CHANGED: guards the setState below
      setState(() => _currentlyPlayingPath = null);
      return;
    }

    final started = await RecorderService.playRecording(path);
    if (!mounted) return; // CHANGED: guards the context use below
    if (started) {
      setState(() => _currentlyPlayingPath = path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Voice playback works on the real Android app — not supported in this web preview.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mnemonics = StorageService.mnemonicBox.values.toList();

    return Column(
      children: [
        Expanded(
          child: mnemonics.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      "Your Vault is empty. Add a mnemonic for any word you've learned.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mnemonics.length,
                  itemBuilder: (context, index) {
                    final m = mnemonics[index];
                    final isThisPlaying = _currentlyPlayingPath == m.audioFilePath;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.word.toUpperCase(),
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            if (m.textNote != null)
                              Text(m.textNote!,
                                  style: Theme.of(context).textTheme.bodyLarge),
                            if (m.audioFilePath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isThisPlaying
                                            ? Icons.stop_circle
                                            : Icons.play_circle,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      onPressed: () =>
                                          _togglePlayback(m.audioFilePath!),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(isThisPlaying
                                        ? 'Playing voice note...'
                                        : 'Voice note saved'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: OutlinedButton(
            onPressed: () => _showAddMnemonicDialog(context),
            child: const Text('+ Add a mnemonic'),
          ),
        ),
      ],
    );
  }

  void _showAddMnemonicDialog(BuildContext context) {
    final wordController = TextEditingController();
    final noteController = TextEditingController();
    _lastRecordedPath = null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add a Mnemonic'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: wordController,
                  decoration: const InputDecoration(labelText: 'Word'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration:
                      const InputDecoration(labelText: 'Your text mnemonic (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop Recording' : 'Record Voice Mnemonic'),
                  onPressed: () async {
                    if (!_isRecording) {
                      final path = await RecorderService.startRecording(
                          wordController.text.isEmpty ? 'temp' : wordController.text);
                      if (!mounted) return; // CHANGED
                      if (path != null) {
                        setDialogState(() {
                          _isRecording = true;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Voice recording works on the real Android app — not supported in this web preview.'),
                          ),
                        );
                      }
                    } else {
                      final finishedPath = await RecorderService.stopRecording();
                      if (!mounted) return; // CHANGED
                      setDialogState(() {
                        _isRecording = false;
                        _lastRecordedPath = finishedPath;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (wordController.text.trim().isEmpty) return;

                final mnemonic = Mnemonic(
                  word: wordController.text.trim(),
                  textNote: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                  audioFilePath: _lastRecordedPath,
                  createdAt: DateTime.now(),
                );
                await StorageService.mnemonicBox.add(mnemonic);

                setState(() {});
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}