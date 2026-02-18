import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/journal_service.dart';
import '../../services/rest_auth_service.dart';
import '../../models/journal_entry.dart';
import '../../widgets/mood_widgets.dart';
import '../../services/mood_detection_service.dart';

class NewEntryScreen extends StatefulWidget {
  final JournalEntry? entry; // For editing existing entries

  const NewEntryScreen({super.key, this.entry});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  late final JournalService _journalService;

  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  List<String> _tags = [];
  String _selectedMood = '';
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Automatic mood detection
  MoodDetectionResult? _detectedMood;
  bool _showAutoDetection = true;

  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Happy',
      'icon': Icons.sentiment_very_satisfied,
      'color': Colors.green
    },
    {'name': 'Sad', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.blue},
    {
      'name': 'Excited',
      'icon': Icons.sentiment_very_satisfied_outlined,
      'color': Colors.orange
    },
    {'name': 'Calm', 'icon': Icons.self_improvement, 'color': Colors.teal},
    {
      'name': 'Angry',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.red
    },
    {'name': 'Grateful', 'icon': Icons.favorite, 'color': Colors.pink},
    {'name': 'Thoughtful', 'icon': Icons.psychology, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<RestAuthService>(context, listen: false);
    _journalService = JournalService(authService);
    _initializeEntry();
    _setupChangeListeners();
  }

  void _initializeEntry() {
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _tags = List.from(widget.entry!.tags);
      _selectedMood = widget.entry!.mood;
    }
  }

  void _setupChangeListeners() {
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Discard', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveEntry() async {
    debugPrint('🔍 NewEntryScreen: _saveEntry called');

    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      debugPrint('⚠️ NewEntryScreen: Empty title and content');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add a title or content',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    debugPrint('🔍 NewEntryScreen: Setting loading state to true');
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.entry == null) {
        debugPrint('🔍 NewEntryScreen: Creating new entry');
        // Create new entry
        final entryId = await _journalService.createEntry(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tags: _tags,
          mood: _selectedMood,
        );
        debugPrint('✅ NewEntryScreen: Entry created with ID: $entryId');

        if (mounted) {
          debugPrint(
              '🔍 NewEntryScreen: Showing success message and navigating back');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entry saved successfully!',
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Wait a moment for the snackbar to show
          await Future.delayed(const Duration(milliseconds: 500));

          debugPrint('🔍 NewEntryScreen: About to pop with true');
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        }
      } else {
        debugPrint('🔍 NewEntryScreen: Updating existing entry');
        // Update existing entry
        await _journalService.updateEntry(
          entryId: widget.entry!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tags: _tags,
          mood: _selectedMood,
        );
        debugPrint('✅ NewEntryScreen: Entry updated successfully');

        if (mounted) {
          debugPrint(
              '🔍 NewEntryScreen: Showing update success message and navigating back');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entry updated successfully!',
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Wait a moment for the snackbar to show
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      }

      setState(() {
        _hasUnsavedChanges = false;
      });
    } catch (e) {
      debugPrint('❌ NewEntryScreen: Error saving entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error saving entry: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      debugPrint('🔍 NewEntryScreen: Setting loading state to false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEntry() async {
    if (widget.entry == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Entry',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        debugPrint(
            '🗑️ NewEntryScreen: Starting delete for entry ID: ${widget.entry!.id}');
        await _journalService.deleteEntry(widget.entry!.id);
        debugPrint('✅ NewEntryScreen: Delete successful');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entry deleted successfully!',
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Wait a moment for the snackbar to show
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      } catch (e) {
        debugPrint('❌ NewEntryScreen: Error deleting entry: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting entry: $e',
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
        _hasUnsavedChanges = true;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasUnsavedChanges = true;
    });
  }

  void _selectMood(String mood) {
    setState(() {
      _selectedMood = _selectedMood == mood ? '' : mood;
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                navigator.pop();
              }
            },
          ),
          title: Text(
            widget.entry == null ? 'New Entry' : 'Edit Entry',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (widget.entry != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _isLoading ? null : _deleteEntry,
              ),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              onPressed: _isLoading ? null : _saveEntry,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Entry title...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 8),

              // Date display
              Text(
                widget.entry?.createdAt.toString().split('.')[0] ??
                    DateTime.now().toString().split('.')[0],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 24),

              // Mood Selection
              Text(
                'How are you feeling?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['name'];
                  return GestureDetector(
                    onTap: () => _selectMood(mood['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mood['color'].withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? mood['color']
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mood['icon'],
                            size: 18,
                            color: isSelected
                                ? mood['color']
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mood['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? mood['color']
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Content Input
              TextField(
                controller: _contentController,
                focusNode: _contentFocusNode,
                maxLines: null,
                minLines: 8,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind today?',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),

              // Automatic Mood Detection Widget
              if (_showAutoDetection &&
                  (_titleController.text.isNotEmpty ||
                      _contentController.text.isNotEmpty))
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Mood Detection',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showAutoDetection = false;
                              });
                            },
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      MoodAnalysisWidget(
                        text:
                            '${_titleController.text} ${_contentController.text}',
                        autoAnalyze: true,
                        onMoodDetected: (result) {
                          setState(() {
                            _detectedMood = result;
                            // Auto-select the detected mood if no mood manually selected
                            if (_selectedMood.isEmpty && result.isSuccess) {
                              _selectedMood = result.emotion.toLowerCase() ==
                                      'happy'
                                  ? 'Happy'
                                  : result.emotion.toLowerCase() == 'sad'
                                      ? 'Sad'
                                      : result.emotion.toLowerCase() == 'angry'
                                          ? 'Angry'
                                          : result.emotion.toLowerCase() ==
                                                  'fear'
                                              ? 'Calm'
                                              : result.emotion.toLowerCase() ==
                                                      'love'
                                                  ? 'Grateful'
                                                  : result.emotion
                                                              .toLowerCase() ==
                                                          'surprise'
                                                      ? 'Excited'
                                                      : result.emotion
                                                                  .toLowerCase() ==
                                                              'neutral'
                                                          ? 'Thoughtful'
                                                          : '';
                              _hasUnsavedChanges = true;
                            }
                          });
                        },
                      ),
                      if (_detectedMood != null && _detectedMood!.isSuccess)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'AI suggests: ${_detectedMood!.emotion} (${(_detectedMood!.confidence * 100).toStringAsFixed(0)}% confidence)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Tags Section
              Text(
                'Tags',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Tag Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add a tag...',
                        hintStyle: GoogleFonts.poppins(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tags Display
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
