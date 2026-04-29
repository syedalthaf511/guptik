
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED FOR CLIPBOARD
import 'dart:math'; // REQUIRED FOR TOKEN GENERATION
import 'package:guptik/services/vault/sync_tracker.dart';
import 'package:guptik/services/vault/vault_sync_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
              backgroundColor: const Color(0xFF1E293B),
              title: const Text(
                "Share Securely",
                style: TextStyle(color: Colors.white),
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
                      subtitle: const Text(
                        "Anyone with the link can view",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      activeThumbColor: Colors.cyanAccent,
                      value: isPublic,
                      onChanged: (val) {
                        setDialogState(() => isPublic = val);
                      },
                    ),

                    // 📅 DATE PICKER UI
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Expires On:",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      subtitle: Text(
                        selectedExpiryDate != null
                            ? "${selectedExpiryDate!.year}-${selectedExpiryDate!.month.toString().padLeft(2, '0')}-${selectedExpiryDate!.day.toString().padLeft(2, '0')}"
                            : "Never",
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_month,
                        color: Colors.cyanAccent,
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
                                  primary: Colors.cyanAccent,
                                  onPrimary: Colors.black,
                                  surface: Color(0xFF1E293B),
                                  onSurface: Colors.white,
                                ),
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
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Allowed Email Address",
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyanAccent),
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
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
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
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
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
            content: Text("✅ Secure Link Copied!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: $e"), backgroundColor: Colors.red),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Desktop Cloud", style: TextStyle(color: Colors.black)),
            Text(
              "Successfully Synced",
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadSyncedAssets();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _syncedAssets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "No files synced yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
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
    );
  }
}

class _SyncedTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onShare;

  const _SyncedTile({required this.asset, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<Uint8List?>(
          future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            }
            return Container(color: Colors.grey[100]);
          },
        ),
        // Share Icon (Top Right)
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(
                0.4,
              ), // Dark background so it's visible over photos
            ),
            onPressed: onShare,
          ),
        ),
        // Checkmark (Bottom Right)
        const Positioned(
          bottom: 5,
          right: 5,
          child: Icon(Icons.check_circle, color: Colors.green, size: 20),
        ),
      ],
    );
  }
}
