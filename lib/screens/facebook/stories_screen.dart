import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/models/facebook/meta_story_reel_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:image_picker/image_picker.dart';

class StoriesScreen extends StatefulWidget {
  final SocialPlatform platform;

  const StoriesScreen({super.key, required this.platform});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final MetaService _metaService = MetaService();
  final ImagePicker _imagePicker = ImagePicker();
  List<MetaStory> _stories = [];
  List<MetaStory> _filteredStories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'engagement', 'views'
  DateTime _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _filterEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await _metaService.getStories(widget.platform);
      if (mounted) {
        setState(() {
          _stories = stories;
          _applyFiltersAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error loading stories: $e");
    }
  }

  void _applyFiltersAndSort() {
    // Start with all stories
    _filteredStories = List.from(_stories);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredStories = _filteredStories
          .where(
            (story) =>
                story.caption?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false,
          )
          .toList();
    }

    // Apply date range filter
    _filteredStories = _filteredStories.where((story) {
      try {
        final storyDate = DateTime.parse(story.createdTime);
        return storyDate.isAfter(_filterStartDate) &&
            storyDate.isBefore(_filterEndDate);
      } catch (_) {
        return true;
      }
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'engagement':
        _filteredStories.sort(
          (a, b) => (b.views + b.replies).compareTo(a.views + a.replies),
        );
        break;
      case 'views':
        _filteredStories.sort((a, b) => b.views.compareTo(a.views));
        break;
      case 'date':
      default:
        _filteredStories.sort((a, b) {
          try {
            final dateA = DateTime.parse(a.createdTime);
            final dateB = DateTime.parse(b.createdTime);
            return dateB.compareTo(dateA);
          } catch (_) {
            return 0;
          }
        });
    }
  }

  Future<void> _postStory() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (!mounted) return;

    // Show caption dialog
    final caption = await showDialog<String>(
      context: context,
      builder: (ctx) => _buildCaptionDialog(ctx),
    );

    if (!mounted) return;

    // Show loading
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Posting story...')));

    try {
      final success = await _metaService.postStory(
        widget.platform,
        image as dynamic,
        caption,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story posted successfully!')),
        );
        _loadStories(); // Refresh list
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post story')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _editStory(MetaStory story) async {
    final newCaption = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: story.caption);
        return AlertDialog(
          title: const Text('Edit Caption'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Edit caption...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (newCaption != null && newCaption.isNotEmpty && mounted) {
      try {
        final success = await _metaService.editStory(story.id, newCaption);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story updated successfully!')),
          );
          _loadStories();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update story')),
          );
        }
      }
    }
  }

  Future<void> _archiveStory(MetaStory story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Story?'),
        content: const Text('This story will be hidden but not deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _metaService.archiveStory(story.id);
        if (success && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Story archived')));
          _loadStories();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to archive story')),
          );
        }
      }
    }
  }

  Future<void> _deleteStory(MetaStory story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Story?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _metaService.deleteStory(story.id);
        if (success && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Story deleted')));
          _loadStories();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete story')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platform.name.toUpperCase()} Stories'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStories),
          IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterMenu),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _postStory,
        backgroundColor: const Color(0xFF1877F2),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStories,
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFiltersAndSort();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search stories...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  // Stories list
                  Expanded(
                    child: _filteredStories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No stories yet'
                                      : 'No matching stories',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Tap + to post your first story'
                                      : 'Try a different search',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: _filteredStories.length,
                            itemBuilder: (context, index) {
                              final story = _filteredStories[index];
                              return _buildStoryCard(story);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStoryCard(MetaStory story) {
    return GestureDetector(
      onLongPress: () => _showStoryMenu(story),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                story.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey[600], size: 32),
                  );
                },
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Story Info
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.caption != null && story.caption!.isNotEmpty)
                    Text(
                      story.caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    story.timeElapsed,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),

            // Views badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      story.views.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryMenu(MetaStory story) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Story Details'),
              onTap: () {
                Navigator.pop(ctx);
                _showStoryDetails(story);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Caption'),
              onTap: () {
                Navigator.pop(ctx);
                _editStory(story);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: Colors.orange),
              title: const Text(
                'Archive',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _archiveStory(story);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Story',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _deleteStory(story);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryDetails(MetaStory story) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Story Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Views', story.views.toString()),
            _buildDetailRow('Replies', story.replies.toString()),
            _buildDetailRow('Engagement', '${story.views + story.replies}'),
            _buildDetailRow('Posted', story.timeElapsed),
            if (story.caption != null && story.caption!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Caption',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(story.caption!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['date', 'engagement', 'views'].map((sort) {
                return FilterChip(
                  label: Text(sort.toUpperCase()),
                  selected: _sortBy == sort,
                  onSelected: (_) {
                    Navigator.pop(ctx);
                    setState(() {
                      _sortBy = sort;
                      _applyFiltersAndSort();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Last 7 Days'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _filterStartDate = DateTime.now().subtract(
                    const Duration(days: 7),
                  );
                  _filterEndDate = DateTime.now();
                  _applyFiltersAndSort();
                });
              },
            ),
            ListTile(
              title: const Text('Last 30 Days'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _filterStartDate = DateTime.now().subtract(
                    const Duration(days: 30),
                  );
                  _filterEndDate = DateTime.now();
                  _applyFiltersAndSort();
                });
              },
            ),
            ListTile(
              title: const Text('All Time'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _filterStartDate = DateTime(2020); // Arbitrary past date
                  _filterEndDate = DateTime.now();
                  _applyFiltersAndSort();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCaptionDialog(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Add Caption (Optional)'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Add a caption to your story...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Done'),
        ),
      ],
    );
  }
}