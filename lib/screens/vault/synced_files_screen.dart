import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED FOR CLIPBOARD
import 'dart:math'; // REQUIRED FOR TOKEN GENERATION
import 'package:guptik/services/vault/sync_tracker.dart';
import 'package:guptik/services/vault/vault_sync_service.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


// Ancient Gold Theme Constants
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

  // --- 🔒 SECURE TOKEN GENERATOR ---
  String _generateSecureToken(int length) {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  // --- 📱 MOBILE SHARE DIALOG WITH DATE PICKER ---
  void _showShareDialog(String fileName) {
    bool isPublic = false;
    TextEditingController emailController = TextEditingController();

    // Default expiration: 7 days from now
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
                      title: const Text(
                        "Make Public Link",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Anyone with the link can view",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      activeColor: Colors.black,
                      activeTrackColor: _ancientGold,
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.white24,
                      value: isPublic,
                      onChanged: (val) {
                        setDialogState(() => isPublic = val);
                      },
                    ),

                    Divider(color: _ancientGold.withValues(alpha: 0.2)),

                    // 📅 DATE PICKER UI
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Expires On:",
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      subtitle: Text(
                        selectedExpiryDate != null
                            ? "${selectedExpiryDate!.year}-${selectedExpiryDate!.month.toString().padLeft(2, '0')}-${selectedExpiryDate!.day.toString().padLeft(2, '0')}"
                            : "Never",
                        style: const TextStyle(
                          color: _ancientGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_month,
                        color: _ancientGold,
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedExpiryDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate:
                              DateTime.now(), // Can't pick a date in the past
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ), // Up to 1 year
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: _ancientGold,
                                  onPrimary: Colors.black,
                                  surface: Colors.black,
                                  onSurface: _ancientGold,
                                ),
                                dialogBackgroundColor: Colors.black,
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

                    // EMAIL INPUT (Only if private)
                    if (!isPublic) ...[
                      const SizedBox(height: 15),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: _ancientGold),
                        decoration: InputDecoration(
                          labelText: "Allowed Email Address",
                          labelStyle: TextStyle(color: Colors.grey[500]),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: _ancientGold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ancientGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _generateAndSaveLink(
                      fileName,
                      isPublic,
                      emailController.text.trim(),
                      selectedExpiryDate,
                    );
                  },
                  child: const Text(
                    "Generate Link",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 🗄️ DATABASE & CLIPBOARD LOGIC (DIRECT TO DOCKER) ---
  Future<void> _generateAndSaveLink(
    String fileName,
    bool isPublic,
    String email,
    DateTime? expiryDate,
  ) async {
    try {
      // 1. Get the Live URL using your existing VaultSyncService
      String? publicUrl = await _syncService.getDesktopUrl();
      if (publicUrl == null) {
        throw Exception("Desktop URL not found. Is your desktop synced?");
      }

      publicUrl = publicUrl
          .replaceAll('https://', '')
          .replaceAll('http://', '');
      if (publicUrl.endsWith('/')) {
        publicUrl = publicUrl.substring(0, publicUrl.length - 1);
      }

      // 2. Generate Token
      final token = isPublic ? null : _generateSecureToken(32);

      // 3. SEND THE RULE TO THE DESKTOP API
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

      if (response.statusCode != 200) {
        throw Exception("Desktop rejected the share rule: ${response.body}");
      }

      // 4. Build Link
      final safeName = Uri.encodeComponent(fileName);
      String finalLink = "https://$publicUrl/vault/files/$safeName";
      if (!isPublic && token != null) {
        finalLink += "?token=$token";
      }

      // 5. Copy to Mobile Clipboard
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
          SnackBar(
            content: Text("❌ Failed: $e", style: const TextStyle(color: Colors.black)), 
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- 🔄 LOAD FILES FROM CACHE & VERIFY WITH SERVER ---
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
          serverFileNames = serverFiles
              .map((f) => f['name'].toString())
              .toList();
          serverCheckSuccess = true;
        }
      }
    } catch (e) {
      print("Gateway offline, skipping live verification: $e");
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
            Text(
              "Successfully Synced",
              style: TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
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
          // The Shared Cinematic Nebula Background
          const Positioned.fill(child: AnimatedNebulaBackground()),

          // Main Content
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _ancientGold))
              : _syncedAssets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 80, color: _ancientGold.withValues(alpha: 0.8)),
                      const SizedBox(height: 20),
                      const Text(
                        "No files synced yet",
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(4, 100, 4, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _syncedAssets.length,
                  itemBuilder: (context, index) {
                    final asset = _syncedAssets[index];
                    return _SyncedTile(
                      asset: asset,
                      // 🔗 Trigger the share dialog and pass the file name!
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
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                }
                return Container(color: Colors.black);
              },
            ),
            // Share Icon (Top Right)
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
            // Checkmark (Bottom Right)
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