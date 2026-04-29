import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/models/facebook/meta_story_reel_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:guptik/config/app_theme.dart';

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
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    final newCaption = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: story.caption);
        return AlertDialog(
          title: Text('Edit Caption', style: AppTheme.textTheme.titleLarge),
          backgroundColor: AppTheme.surface,
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: AppTheme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Edit caption...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppTheme.lightGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppTheme.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: platformColor, width: 2),
              ),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.mediumGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: platformColor),
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.white),
              ),
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
        title: Text('Archive Story?', style: AppTheme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
        content: Text(
          'This story will be hidden but not deleted.',
          style: AppTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mediumGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.warning),
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
        title: Text('Delete Story?', style: AppTheme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
        content: Text(
          'This action cannot be undone.',
          style: AppTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mediumGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
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
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '${widget.platform.name.toUpperCase()} Stories',
          style: AppTheme.textTheme.headlineSmall,
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.dark,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: platformColor),
            onPressed: _loadStories,
          ),
          IconButton(
            icon: Icon(Icons.tune, color: platformColor),
            onPressed: _showFilterMenu,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _postStory,
        backgroundColor: platformColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(platformColor),
              ),
            )
          : RefreshIndicator(
              color: platformColor,
              onRefresh: _loadStories,
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFiltersAndSort();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search stories...',
                        prefixIcon: Icon(Icons.search, color: platformColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(color: AppTheme.lightGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(color: AppTheme.lightGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(
                            color: platformColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        filled: true,
                        fillColor: AppTheme.surface,
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
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: platformColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: platformColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No stories yet'
                                      : 'No matching stories',
                                  style: AppTheme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Tap + to post your first story'
                                      : 'Try a different search',
                                  style: AppTheme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: AppSpacing.lg,
                                  mainAxisSpacing: AppSpacing.lg,
                                ),
                            itemCount: _filteredStories.length,
                            itemBuilder: (context, index) {
                              final story = _filteredStories[index];
                              return _buildStoryCard(story, platformColor);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStoryCard(MetaStory story, Color platformColor) {
    return GestureDetector(
      onLongPress: () => _showStoryMenu(story),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: AppTheme.surface,
          border: Border.all(
            color: platformColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: AppShadows.light,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.network(
                story.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.lightGrey,
                    child: Icon(
                      Icons.image,
                      color: AppTheme.mediumGrey,
                      size: 32,
                    ),
                  );
                },
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Story Info
            Positioned(
              bottom: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
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
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),

            // Views badge
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: platformColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, size: 12, color: Colors.white),
                    const SizedBox(width: AppSpacing.sm),
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
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info, color: platformColor),
              title: const Text('Story Details'),
              onTap: () {
                Navigator.pop(ctx);
                _showStoryDetails(story);
              },
            ),
            Divider(color: AppTheme.lightGrey),
            ListTile(
              leading: Icon(Icons.edit, color: platformColor),
              title: const Text('Edit Caption'),
              onTap: () {
                Navigator.pop(ctx);
                _editStory(story);
              },
            ),
            Divider(color: AppTheme.lightGrey),
            ListTile(
              leading: const Icon(Icons.archive, color: AppTheme.warning),
              title: const Text(
                'Archive',
                style: TextStyle(color: AppTheme.warning),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _archiveStory(story);
              },
            ),
            Divider(color: AppTheme.lightGrey),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text(
                'Delete Story',
                style: TextStyle(color: AppTheme.error),
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
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Story Details', style: AppTheme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
        content: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: platformColor, width: 3)),
          ),
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Views', story.views.toString(), platformColor),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow(
                'Replies',
                story.replies.toString(),
                platformColor,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow(
                'Engagement',
                '${story.views + story.replies}',
                platformColor,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Posted', story.timeElapsed, platformColor),
              if (story.caption != null && story.caption!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Caption', style: AppTheme.textTheme.labelMedium),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: platformColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(story.caption!),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: platformColor)),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu() {
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: AppTheme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.lg),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['date', 'engagement', 'views'].map((sort) {
                  final isSelected = _sortBy == sort;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: FilterChip(
                      label: Text(
                        sort.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : platformColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        Navigator.pop(ctx);
                        setState(() {
                          _sortBy = sort;
                          _applyFiltersAndSort();
                        });
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: platformColor,
                      side: BorderSide(color: platformColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Date Range', style: AppTheme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.lightGrey)),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Last 7 Days'),
                    visualDensity: VisualDensity.compact,
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
                  Divider(color: AppTheme.lightGrey, height: 1),
                  ListTile(
                    title: const Text('Last 30 Days'),
                    visualDensity: VisualDensity.compact,
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
                  Divider(color: AppTheme.lightGrey, height: 1),
                  ListTile(
                    title: const Text('All Time'),
                    visualDensity: VisualDensity.compact,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _filterStartDate = DateTime(2020);
                        _filterEndDate = DateTime.now();
                        _applyFiltersAndSort();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.mediumGrey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildCaptionDialog(BuildContext context) {
    final controller = TextEditingController();
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return AlertDialog(
      title: Text(
        'Add Caption (Optional)',
        style: AppTheme.textTheme.titleLarge,
      ),
      backgroundColor: AppTheme.surface,
      content: TextField(
        controller: controller,
        maxLines: 3,
        style: AppTheme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Add a caption to your story...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppTheme.lightGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppTheme.lightGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: platformColor, width: 2),
          ),
          filled: true,
          fillColor: AppTheme.background,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Skip', style: TextStyle(color: AppTheme.mediumGrey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: ElevatedButton.styleFrom(backgroundColor: platformColor),
          child: const Text('Done', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}