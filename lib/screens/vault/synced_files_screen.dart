import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'dart:math'; 
import 'package:guptik/services/vault/sync_tracker.dart';
import 'package:guptik/services/vault/vault_sync_service.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:guptik/widgets/mediaplayer/mobile_video_player_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class SyncedFilesScreen extends StatefulWidget {
  const SyncedFilesScreen({super.key});

  @override
  State<SyncedFilesScreen> createState() => _SyncedFilesScreenState();
}

class _SyncedFilesScreenState extends State<SyncedFilesScreen> {
  List<AssetEntity> _syncedAssets = [];
  bool _isLoading = true;
  final VaultSyncService _syncService = VaultSyncService();

  @override
  void initState() {
    super.initState();
    _loadSyncedAssets();
  }

  String _generateSecureToken(int length) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  void _showShareDialog(String fileName) {
    bool isPublic = false;
    TextEditingController emailController = TextEditingController();
    DateTime? selectedExpiryDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: _ancientGold, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Share Securely",
                style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text("Make Public Link", style: TextStyle(color: Colors.white)),
                      subtitle: Text("Anyone with the link can view", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      activeThumbColor: Colors.black,
                      activeTrackColor: _ancientGold,
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.white24,
                      value: isPublic,
                      onChanged: (val) {
                        setDialogState(() => isPublic = val);
                      },
                    ),
                    Divider(color: _ancientGold.withValues(alpha: 0.2)),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Expires On:", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      subtitle: Text(
                        selectedExpiryDate != null
                            ? "${selectedExpiryDate!.year}-${selectedExpiryDate!.month.toString().padLeft(2, '0')}-${selectedExpiryDate!.day.toString().padLeft(2, '0')}"
                            : "Never",
                        style: const TextStyle(color: _ancientGold, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.calendar_month, color: _ancientGold),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedExpiryDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(), 
                          lastDate: DateTime.now().add(const Duration(days: 365)), 
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: _ancientGold,
                                  onPrimary: Colors.black,
                                  surface: Colors.black,
                                  onSurface: _ancientGold,
                                ),
                                dialogTheme: const DialogThemeData(backgroundColor: Colors.black),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => selectedExpiryDate = picked);
                        }
                      },
                    ),
                    if (!isPublic) ...[
                      const SizedBox(height: 15),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: _ancientGold),
                        decoration: InputDecoration(
                          labelText: "Allowed Email Address",
                          labelStyle: TextStyle(color: Colors.grey[500]),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _ancientGold, foregroundColor: Colors.black),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _generateAndSaveLink(
                      fileName,
                      isPublic,
                      emailController.text.trim(),
                      selectedExpiryDate,
                    );
                  },
                  child: const Text("Generate Link", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateAndSaveLink(
    String fileName,
    bool isPublic,
    String email,
    DateTime? expiryDate,
  ) async {
    try {
      String? publicUrl = await _syncService.getDesktopUrl();
      if (publicUrl == null) throw Exception("Desktop URL not found. Is your desktop synced?");

      publicUrl = publicUrl.replaceAll('https://', '').replaceAll('http://', '');
      if (publicUrl.endsWith('/')) publicUrl = publicUrl.substring(0, publicUrl.length - 1);

      final token = isPublic ? null : _generateSecureToken(32);
      final now = DateTime.now().toUtc();

      final shareData = {
        'file_name': fileName,
        'is_public': isPublic,
        'access_token': token,
        'emails_access_to': isPublic ? [] : [email],
        'created_at': now.toIso8601String(),
        'expires_at': expiryDate?.toUtc().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('https://$publicUrl/vault/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(shareData),
      );

      if (response.statusCode != 200) throw Exception("Desktop rejected the share rule: ${response.body}");

      final safeName = Uri.encodeComponent(fileName);
      String finalLink = "https://$publicUrl/vault/files/$safeName";
      if (!isPublic && token != null) finalLink += "?token=$token";

      await Clipboard.setData(ClipboardData(text: finalLink));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Secure Link Copied!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: $e", style: const TextStyle(color: Colors.black)), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _loadSyncedAssets() async {
    final List<String> syncedIds = await SyncTracker.getSyncedIds();

    if (syncedIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    bool serverCheckSuccess = false;
    List<String> serverFileNames = [];
    try {
      final String? baseUrl = await _syncService.getDesktopUrl();
      if (baseUrl != null) {
        final response = await http.get(Uri.parse('$baseUrl/vault/list'));
        if (response.statusCode == 200) {
          final List<dynamic> serverFiles = jsonDecode(response.body);
          serverFileNames = serverFiles.map((f) => f['name'].toString()).toList();
          serverCheckSuccess = true;
        }
      }
    } catch (e) {
      debugPrint("Gateway offline, skipping live verification: $e");
    }

    final List<AssetEntity> assets = [];
    for (String id in List.from(syncedIds)) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        if (serverCheckSuccess) {
          final fileName = asset.title ?? 'unknown';
          if (!serverFileNames.contains(fileName)) {
            await SyncTracker.removeSyncedId(id);
            continue;
          }
        }
        assets.add(asset);
      } else {
        await SyncTracker.removeSyncedId(id);
      }
    }

    if (mounted) {
      setState(() {
        _syncedAssets = assets;
        _isLoading = false;
      });
    }
  }

  void _openSystemFolder(String title) async {
    String type = 'drafts';
    IconData icon = Icons.edit;
    Color color = Colors.purpleAccent;

    if (title == "Posted Videos") {
      type = 'posted';
      icon = Icons.cloud_done;
      color = const Color(0xFF00E5FF);
    } else if (title == "Saved Videos") {
      type = 'saved';
      icon = Icons.bookmark;
      color = Colors.amberAccent;
    } else if (title == "Repost Videos") {
      type = 'repost';
      icon = Icons.repeat;
      color = Colors.lightGreenAccent;
    } else if (title == "Sticker Products") { 
      // 🚀 Added Sticker Folder routing
      type = 'stickers';
      icon = Icons.shopping_bag;
      color = Colors.pinkAccent;
    } else if (title == "Vault Folder") {
      type = 'vault_sys';
      icon = Icons.shield;
      color = Colors.orangeAccent;
    }

    final String? desktopUrl = await _syncService.getDesktopUrl();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MobileSystemFolderScreen(
            folderType: type,
            folderTitle: title,
            folderIcon: icon,
            folderColor: color,
            desktopUrl: desktopUrl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Desktop Cloud", style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Successfully Synced", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _ancientGold),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadSyncedAssets();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicAppBackground()),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _ancientGold))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(4, 100, 4, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _syncedAssets.length + 6, // 🚀 Incremented count for new folder
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildVirtualFolderTile("Posted Videos", Icons.cloud_done, const Color(0xFF00E5FF));
                    if (index == 1) return _buildVirtualFolderTile("Saved Videos", Icons.bookmark, Colors.amberAccent);
                    if (index == 2) return _buildVirtualFolderTile("Drafts", Icons.edit, Colors.purpleAccent);
                    if (index == 3) return _buildVirtualFolderTile("Repost Videos", Icons.repeat, Colors.lightGreenAccent);
                    if (index == 4) return _buildVirtualFolderTile("Sticker Products", Icons.shopping_bag, Colors.pinkAccent); // 🚀 Added Sticker Folder
                    if (index == 5) return _buildVirtualFolderTile("Vault Folder", Icons.shield, Colors.orangeAccent);

                    final asset = _syncedAssets[index - 6]; // 🚀 Adjusted Offset
                    return _SyncedTile(
                      asset: asset,
                      onShare: () {
                        final fileName = asset.title ?? 'unknown_${asset.id}';
                        _showShareDialog(fileName);
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildVirtualFolderTile(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () => _openSystemFolder(title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text("System Folder", style: TextStyle(color: Colors.grey[500], fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _SyncedTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onShare;

  const _SyncedTile({required this.asset, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                }
                return Container(color: Colors.black);
              },
            ),
            Positioned(
              top: 4,
              right: 4,
              child: SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.share, color: _ancientGold, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.7), 
                    side: BorderSide(color: _ancientGold.withValues(alpha: 0.5), width: 1),
                  ),
                  onPressed: onShare,
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileSystemFolderScreen extends StatefulWidget {
  final String folderType;
  final String folderTitle;
  final IconData folderIcon;
  final Color folderColor;
  final String? desktopUrl;

  const MobileSystemFolderScreen({
    super.key,
    required this.folderType,
    required this.folderTitle,
    required this.folderIcon,
    required this.folderColor,
    required this.desktopUrl,
  });

  @override
  State<MobileSystemFolderScreen> createState() => _MobileSystemFolderScreenState();
}

class _MobileSystemFolderScreenState extends State<MobileSystemFolderScreen> {
  List<dynamic> _folderItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRemoteFolderContent();
  }

  Future<void> _fetchRemoteFolderContent() async {
    if (widget.desktopUrl == null || widget.desktopUrl!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final endpoint = '${widget.desktopUrl}/vault/system-folder/${widget.folderType}';
      final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          _folderItems = decodedData;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Network folder stream tracking error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatSize(dynamic sizeBytes) {
    if (sizeBytes == null) return '0 B';
    int bytes = int.tryParse(sizeBytes.toString()) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        iconTheme: const IconThemeData(color: _ancientGold),
        title: Row(
          children: [
            Icon(widget.folderIcon, color: widget.folderColor, size: 22),
            const SizedBox(width: 10),
            Text(widget.folderTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicAppBackground()),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _ancientGold))
              : _folderItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.folderIcon, size: 60, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text("This folder is empty.", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _folderItems.length,
                      itemBuilder: (context, index) {
                        final item = _folderItems[index];
                        final bool isSticker = item['is_sticker'] == true;
                        // 🚀 FIX: for stickers, always prefer the REAL video's
                        // title/channel (now returned by the gateway via a
                        // JOIN) instead of the sticker's own product name and
                        // the generic 'Local Vault' label — shown both in this
                        // grid tile and when the video is opened, matching the
                        // same correctness fix already applied on desktop.
                        final displayTitle = isSticker
                            ? (item['video_title']?.toString().isNotEmpty == true
                                ? item['video_title'].toString()
                                : (item['title'] ?? 'Shared Media'))
                            : (item['title'] ?? 'Shared Media');
                        final displayChannelName = isSticker
                            ? (item['channel_name']?.toString().isNotEmpty == true
                                ? item['channel_name'].toString()
                                : 'Local Vault')
                            : 'Local Vault';
                        final displayChannelId = isSticker
                            ? (item['channel_id']?.toString() ?? 'guest')
                            : 'guest';
                        final filename = displayTitle;
                        final videoId = item['video_id'] ?? '';
                        final sizeStr = _formatSize(item['size_bytes']);

                        String cleanBaseUrl = widget.desktopUrl ?? '';
                        if (cleanBaseUrl.endsWith('/')) {
                          cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length - 1);
                        }
                        // 🚀 FIX: stickers use their own image_url (already a full
                        // URL from the gateway), not the video thumbnail route —
                        // a sticker's id isn't a real video, so that route would 404.
                        final thumbUrl = isSticker
                            ? (item['image_url']?.toString() ?? '')
                            : '$cleanBaseUrl/player/video/thumbnail/$videoId';

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    iconTheme: const IconThemeData(color: Colors.orange),
                                    title: Text(displayTitle, style: const TextStyle(color: Colors.white)),
                                  ),
                                  body: MobileVideoPlayerWidget(
                                    // 🚀 COMPILER FIX: Instantiating PlayerVideo with all required fields from Step 1
                                    video: PlayerVideo(
                                      videoId: videoId,
                                      title: displayTitle,
                                      creatorUrl: widget.desktopUrl ?? '',
                                      channelName: displayChannelName, // 🚀 FIX: real channel name for stickers
                                      viewCount: 0,
                                      creatorUid: displayChannelId, // 🚀 FIX: real channel id for stickers
                                      description: '',
                                      filePath: '',
                                      likeCount: 0,
                                      commentCount: 0,
                                      createdAt: DateTime.now().toIso8601String(),
                                      isReel: false,
                                      visibility: 'public',
                                      madeForKids: false,
                                      ageRating: 'all',
                                      category: 'Uncategorized',
                                      tags: const [],
                                      isMonetized: false,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.folderColor.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    child: thumbUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: Image.network(
                                              thumbUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                isSticker ? Icons.shopping_bag : Icons.play_circle_outline,
                                                color: widget.folderColor.withValues(alpha: 0.7),
                                                size: 40,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            isSticker ? Icons.shopping_bag : Icons.insert_drive_file,
                                            color: widget.folderColor.withValues(alpha: 0.7),
                                            size: 40,
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        filename,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      // 🚀 FIX: show price for stickers instead of a meaningless "0 B" file size
                                      Text(
                                        isSticker ? '${item['price'] ?? '-'} ${item['currency'] ?? ''}' : sizeStr,
                                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}