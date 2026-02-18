import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/journal_service.dart';
import '../../services/rest_auth_service.dart';
import '../../models/journal_entry.dart';
import 'new_entry_screen.dart';

class EntriesListScreen extends StatefulWidget {
  const EntriesListScreen({super.key});

  @override
  State<EntriesListScreen> createState() => _EntriesListScreenState();
}

class _EntriesListScreenState extends State<EntriesListScreen> {
  late final JournalService _journalService;
  final _searchController = TextEditingController();

  List<JournalEntry> _entries = [];
  List<JournalEntry> _filteredEntries = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<RestAuthService>(context, listen: false);
    _journalService = JournalService(authService);
    _loadEntries();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterEntries();
    });
  }

  void _filterEntries() {
    if (_searchQuery.isEmpty) {
      _filteredEntries = List.from(_entries);
    } else {
      _filteredEntries = _entries
          .where((entry) =>
              entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              entry.content
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              entry.tags.any((tag) =>
                  tag.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }
  }

  Future<void> _loadEntries() async {
    try {
      debugPrint('📋 EntriesListScreen: Starting to load entries');
      setState(() {
        _isLoading = true;
      });

      final entries = await _journalService.getUserEntries();
      debugPrint('📋 EntriesListScreen: Loaded ${entries.length} entries');

      setState(() {
        _entries = entries;
        _filterEntries();
        _isLoading = false;
      });

      debugPrint(
          '📋 EntriesListScreen: Entries loaded and filtered successfully');
    } catch (e) {
      debugPrint('❌ EntriesListScreen: Error loading entries: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error loading entries: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _refreshEntries() async {
    await _loadEntries();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.blue;
      case 'excited':
        return Colors.orange;
      case 'calm':
        return Colors.teal;
      case 'angry':
        return Colors.red;
      case 'grateful':
        return Colors.pink;
      case 'thoughtful':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'excited':
        return Icons.sentiment_very_satisfied_outlined;
      case 'calm':
        return Icons.self_improvement;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'grateful':
        return Icons.favorite;
      case 'thoughtful':
        return Icons.psychology;
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Entries',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NewEntryScreen(),
                ),
              );
              if (result == true) {
                _loadEntries();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search entries...',
                hintStyle: GoogleFonts.poppins(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
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
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.poppins(),
            ),
          ),

          // Entries Count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredEntries.length} ${_filteredEntries.length == 1 ? 'entry' : 'entries'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    Text(
                      'Searching for "$_searchQuery"',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Entries List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshEntries,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index];
                            return _buildEntryCard(entry);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.book_outlined,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No entries found' : 'No entries yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start writing your first journal entry!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NewEntryScreen(),
                  ),
                );
                if (result == true) {
                  _loadEntries();
                }
              },
              icon: const Icon(Icons.add),
              label: Text('Write First Entry', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewEntryScreen(entry: entry),
            ),
          );
          if (result == true) {
            _loadEntries();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and mood
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(entry.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  if (entry.mood.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMoodColor(entry.mood).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _getMoodColor(entry.mood).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMoodIcon(entry.mood),
                            size: 14,
                            color: _getMoodColor(entry.mood),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.mood,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _getMoodColor(entry.mood),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              if (entry.title.isNotEmpty) ...[
                Text(
                  entry.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Content preview
              if (entry.content.isNotEmpty)
                Text(
                  entry.content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

              // Tags
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
