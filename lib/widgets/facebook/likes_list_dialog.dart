import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';

class LikesListDialog extends StatelessWidget {
  final List<Map<String, dynamic>> likes;
  final SocialPlatform platform;
  final bool isLoading;

  const LikesListDialog({
    super.key,
    required this.likes,
    required this.platform,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: platform == SocialPlatform.facebook
                            ? Colors.blue[50]
                            : Colors.pink[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        platform == SocialPlatform.facebook
                            ? FontAwesomeIcons.facebook
                            : FontAwesomeIcons.instagram,
                        size: 16,
                        color: platform == SocialPlatform.facebook
                            ? Colors.blue
                            : Colors.pink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'People who liked this',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (likes.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No likes yet',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: likes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final like = likes[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: platform == SocialPlatform.facebook
                            ? Colors.blue[100]
                            : Colors.pink[100],
                        child: Text(
                          (like['name'] ?? like['username'] ?? 'U')[0]
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: platform == SocialPlatform.facebook
                                ? Colors.blue
                                : Colors.pink,
                          ),
                        ),
                      ),
                      title: Text(
                        like['name'] ?? like['username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: like.containsKey('username')
                          ? Text(
                              '@${like['username']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}