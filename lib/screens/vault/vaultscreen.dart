import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:guptik/services/vault/sync_tracker.dart';
import 'package:guptik/services/vault/vault_sync_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'synced_files_screen.dart';

// IMPORT THE SHARED BACKGROUND
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  AssetPathEntity? _currentAlbum;
  final List<AssetEntity> _allAssets = [];
  final Map<String, List<AssetEntity>> _groupedAssets = {};

  Set<String> _liveDesktopIds = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasPermission = false;

  int _currentPage = 0;
  final int _pageSize = 80;
  int _totalAssetCount = 0;

  final ScrollController _scrollController = ScrollController();

  bool _isSyncing = false;
  bool _hasUnsyncedItems = false;
  
  bool _cancelSync = false; 

  // ==========================================
  // ValueNotifiers for 100% Live Dialog Updates
  // ==========================================
  final ValueNotifier<int> _liveSyncedNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _liveRemainingNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _syncTextNotifier = ValueNotifier<String>("");
  final ValueNotifier<double> _syncProgressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> _liveDataNotifier = ValueNotifier<String>("0.00 MB");
  
  final ValueNotifier<bool> _isPreparingNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _liveSyncedNotifier.dispose();
    _liveRemainingNotifier.dispose();
    _syncTextNotifier.dispose();
    _syncProgressNotifier.dispose();
    _liveDataNotifier.dispose();
    _isPreparingNotifier.dispose(); 
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreAssets();
    }
  }

  // ---------------------------------------------------------
  // DESKTOP LIVE CHECK (WITH SMART ID & EXTENSION PARSER)
  // ---------------------------------------------------------
  Future<Set<String>> _fetchActualDesktopFiles() async {
    try {
      final syncService = VaultSyncService();
      String? dynamicUrl = await syncService.getDesktopUrl();

      if (dynamicUrl == null || dynamicUrl.isEmpty) {
        return <String>{};
      }

      if (!dynamicUrl.startsWith('http')) {
        dynamicUrl = 'https://$dynamicUrl';
      }

      final Uri uri = Uri.parse('$dynamicUrl/vault/get_synced_ids');
      debugPrint("Asking Desktop at: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        Set<String> safeIds = {};

        List<dynamic> targetList = [];
        if (decoded is List) {
          targetList = decoded;
        } else if (decoded is Map && decoded['synced_ids'] != null) {
          targetList = decoded['synced_ids'];
        }

        for (var item in targetList) {
          String val = "";
          if (item is Map) {
            if (item['id'] != null) {
              val = item['id'].toString();
            } else if (item['filename'] != null) {
              val = item['filename'].toString();
            } else if (item['title'] != null) {
              val = item['title'].toString();
            }
          } else {
            val = item.toString();
          }

          if (val.isNotEmpty) {
            safeIds.add(val); 
            if (val.contains('.')) {
              safeIds.add(val.substring(0, val.lastIndexOf('.')));
            }
          }
        }
        return safeIds;
      } else {
        debugPrint("Desktop Error: ${response.statusCode}");
        return <String>{};
      }
    } catch (e) {
      debugPrint("Could not connect to desktop: $e");
      return <String>{};
    }
  }

  Future<void> _updateUIStatus() async {
    Set<String> desktopHas = await _fetchActualDesktopFiles();
    bool needsSync = false;

    if (_totalAssetCount > desktopHas.length) {
      needsSync = true;
    } else {
      for (var asset in _allAssets) {
        String titleNoExt = "";
        if (asset.title != null && asset.title!.contains('.')) {
          titleNoExt = asset.title!.substring(0, asset.title!.lastIndexOf('.'));
        } else if (asset.title != null) {
          titleNoExt = asset.title!;
        }

        bool isOnDesktop =
            desktopHas.contains(asset.id) ||
            (asset.title != null && desktopHas.contains(asset.title)) ||
            (titleNoExt.isNotEmpty && desktopHas.contains(titleNoExt));

        if (!isOnDesktop) {
          needsSync = true;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _liveDesktopIds = desktopHas;
        _hasUnsyncedItems = needsSync;
      });
    }
  }

  Future<void> _initialLoad() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
      return;
    }

    final FilterOptionGroup filterOption = FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _currentAlbum = albums[0];
    _totalAssetCount = await _currentAlbum!.assetCountAsync;

    final List<AssetEntity> newAssets = await _currentAlbum!.getAssetListPaged(
      page: 0,
      size: _pageSize,
    );

    _processAssets(newAssets);
    await _updateUIStatus();

    if (mounted) {
      setState(() {
        _hasPermission = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAssets() async {
    if (_isLoadingMore ||
        _allAssets.length >= _totalAssetCount ||
        _currentAlbum == null) {
      return;
    }

    setState(() => _isLoadingMore = true);
    _currentPage++;

    final List<AssetEntity> nextAssets = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    _processAssets(nextAssets);
    await _updateUIStatus();

    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _processAssets(List<AssetEntity> newAssets) {
    _allAssets.addAll(newAssets);
    for (var asset in newAssets) {
      String dateLabel = _getDateLabel(asset.createDateTime);
      if (_groupedAssets[dateLabel] == null) {
        _groupedAssets[dateLabel] = [];
      }
      _groupedAssets[dateLabel]!.add(asset);
    }
  }

  String _getDateLabel(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    if (_currentAlbum == null) return;

    setState(() => _isSyncing = true);
    
    _cancelSync = false; 
    _isPreparingNotifier.value = true; 
    _syncTextNotifier.value = "Scanning library & checking desktop...";
    _syncProgressNotifier.value = 0.0;
    _liveSyncedNotifier.value = 0;
    _liveRemainingNotifier.value = 0;
    _liveDataNotifier.value = "0.00 MB";

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) return;
              _cancelSync = true;
              Navigator.pop(dialogCtx);
            },
            child: AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: _ancientGold, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.cloud_sync, color: _ancientGold),
                  SizedBox(width: 10),
                  Text("Syncing Vault", style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
                ],
              ),
              content: ValueListenableBuilder<bool>(
                valueListenable: _isPreparingNotifier,
                builder: (context, isPreparing, child) {
                  
                  // STATE A: Scanning the files
                  if (isPreparing) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: _ancientGold),
                        const SizedBox(height: 20),
                        ValueListenableBuilder<String>(
                          valueListenable: _syncTextNotifier,
                          builder: (context, text, child) => Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  // STATE B: Uploading the files
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _ancientGold.withValues(alpha: 0.05),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Files: $_totalAssetCount",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<int>(
                              valueListenable: _liveSyncedNotifier,
                              builder: (context, value, child) => Text(
                                "Already Synced: $value",
                                style: const TextStyle(color: Colors.greenAccent),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<int>(
                              valueListenable: _liveRemainingNotifier,
                              builder: (context, value, child) => Text(
                                "Remaining to Sync: $value",
                                style: const TextStyle(color: Colors.orangeAccent),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(color: _ancientGold.withValues(alpha: 0.2)),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<String>(
                              valueListenable: _liveDataNotifier,
                              builder: (context, value, child) => Text(
                                "Data Uploaded: $value",
                                style: const TextStyle(
                                  color: _ancientGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ValueListenableBuilder<double>(
                        valueListenable: _syncProgressNotifier,
                        builder: (context, value, child) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white12,
                            color: _ancientGold,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String>(
                        valueListenable: _syncTextNotifier,
                        builder: (context, value, child) => Center(
                          child: Text(
                            value,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _cancelSync = true;
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      );
    }

    try {
      final syncService = VaultSyncService();
      String? dynamicUrl = await syncService.getDesktopUrl();

      if (dynamicUrl == null || dynamicUrl.isEmpty) {
        throw Exception("No Desktop Found.");
      }
      if (!dynamicUrl.startsWith('http')) dynamicUrl = 'https://$dynamicUrl';

      if (!await syncService.isGatewayOnline(dynamicUrl)) {
        throw Exception("Desktop Offline.");
      }

      Set<String> currentlyOnDesktop = await _fetchActualDesktopFiles();
      
      if (_cancelSync) throw Exception("Sync cancelled by user.");

      List<AssetEntity> missingFilesQueue = [];
      int safeBatchSize = 500;

      for (int i = 0; i < _totalAssetCount; i += safeBatchSize) {
        if (_cancelSync) throw Exception("Sync cancelled by user."); 

        int end = (i + safeBatchSize < _totalAssetCount) ? i + safeBatchSize : _totalAssetCount;
        
        _syncTextNotifier.value = "Analyzing items ${i} to $end...";
        
        List<AssetEntity> metadataBatch = await _currentAlbum!.getAssetListRange(start: i, end: end);

        for (var asset in metadataBatch) {
          String titleNoExt = "";
          if (asset.title != null && asset.title!.contains('.')) {
            titleNoExt = asset.title!.substring(0, asset.title!.lastIndexOf('.'));
          } else if (asset.title != null) {
            titleNoExt = asset.title!;
          }

          bool isOnDesktop =
              currentlyOnDesktop.contains(asset.id) ||
              (asset.title != null && currentlyOnDesktop.contains(asset.title)) ||
              (titleNoExt.isNotEmpty && currentlyOnDesktop.contains(titleNoExt));

          if (!isOnDesktop) {
            missingFilesQueue.add(asset);
          }
        }
      }

      int totalLocalFiles = _totalAssetCount;
      int targetUploadCount = missingFilesQueue.length;
      int alreadyOnDesktopCount = totalLocalFiles - targetUploadCount;

      if (targetUploadCount == 0) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Everything is already up to date! ☁️✓', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: _ancientGold,
          ),
        );
        setState(() => _isSyncing = false);
        return;
      }

      _liveSyncedNotifier.value = alreadyOnDesktopCount;
      _liveRemainingNotifier.value = targetUploadCount;
      _syncProgressNotifier.value = 0.0;
      _isPreparingNotifier.value = false;

      int successCount = 0;
      double totalMegabytesUploaded = 0.0;

      for (int i = 0; i < missingFilesQueue.length; i++) {
        if (!mounted || _cancelSync) {
          break; 
        }

        final asset = missingFilesQueue[i];
        final file = await asset.file;

        if (file != null) {
          int filesUploadedThisSession = i + 1;

          _syncTextNotifier.value = "Uploading file $filesUploadedThisSession of $targetUploadCount";
          _syncProgressNotifier.value = filesUploadedThisSession / targetUploadCount;
          await Future.delayed(const Duration(milliseconds: 10));

          bool success = await syncService.uploadFile(file, dynamicUrl);

          if (success) {
            successCount++;
            currentlyOnDesktop.add(asset.id);
            if (asset.title != null) currentlyOnDesktop.add(asset.title!);
            await SyncTracker.markAsSynced(asset.id);

            int fileBytes = file.lengthSync();
            totalMegabytesUploaded += (fileBytes / (1024 * 1024));

            if (totalMegabytesUploaded >= 1024) {
              double gb = totalMegabytesUploaded / 1024;
              _liveDataNotifier.value = "${gb.toStringAsFixed(2)} GB";
            } else {
              _liveDataNotifier.value = "${totalMegabytesUploaded.toStringAsFixed(2)} MB";
            }

            _liveSyncedNotifier.value++;
            if (_liveRemainingNotifier.value > 0) {
              _liveRemainingNotifier.value--;
            }

            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      }

      if (mounted) {
        if (!_cancelSync) Navigator.pop(context); 
        
        if (_cancelSync) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sync cancelled. Partial upload saved. 🛑', style: TextStyle(color: Colors.black)), backgroundColor: Colors.orangeAccent),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sync Complete! Uploaded $successCount missing files.', style: TextStyle(color: Colors.black)), backgroundColor: Colors.greenAccent),
          );
        }
        
        setState(() {
          _liveDesktopIds = currentlyOnDesktop;
          _hasUnsyncedItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (!_cancelSync) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e", style: const TextStyle(color: Colors.black)), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _openFullScreen(AssetEntity asset) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MediaViewerPage(asset: asset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // Cinematic Nebula Background
          const Positioned.fill(child: DynamicAppBackground()),
          
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                title: const Text(
                  "Guptik Vault",
                  style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.black.withValues(alpha: 0.7),
                elevation: 0,
                iconTheme: const IconThemeData(color: _ancientGold),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.cloud_upload,
                      color: _hasUnsyncedItems ? _ancientGold : Colors.grey[700],
                    ),
                    onPressed: _handleSync,
                    tooltip: "Sync to Desktop",
                  ),
                  const SizedBox(width: 5),
                  IconButton(
                    icon: const Icon(Icons.desktop_mac, color: _ancientGold),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SyncedFilesScreen(),
                        ),
                      );
                    },
                    tooltip: "View Desktop Files",
                  ),
                  const SizedBox(width: 10),
                  Container(
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _ancientGold, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black,
                      child: Text("G", style: TextStyle(color: _ancientGold, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1.0),
                  child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
                ),
              ),

              if (!_hasPermission && !_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _ancientGold, foregroundColor: Colors.black),
                      onPressed: PhotoManager.openSetting,
                      child: const Text("Open Settings", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _ancientGold)),
                ),

              if (_hasPermission && !_isLoading)
                ..._groupedAssets.entries.map((entry) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _DateHeaderDelegate(title: entry.key),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final asset = entry.value[index];

                            String titleNoExt = "";
                            if (asset.title != null && asset.title!.contains('.')) {
                              titleNoExt = asset.title!.substring(
                                0,
                                asset.title!.lastIndexOf('.'),
                              );
                            } else if (asset.title != null) {
                              titleNoExt = asset.title!;
                            }

                            final bool isOnDesktop =
                                _liveDesktopIds.contains(asset.id) ||
                                (asset.title != null && _liveDesktopIds.contains(asset.title)) ||
                                (titleNoExt.isNotEmpty && _liveDesktopIds.contains(titleNoExt));

                            return GestureDetector(
                              onTap: () => _openFullScreen(asset),
                              child: _RealMediaTile(
                                asset: asset,
                                isSynced: isOnDesktop,
                              ),
                            );
                          }, childCount: entry.value.length),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    ],
                  );
                }),

              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: _ancientGold)),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. FULL SCREEN VIEWER
// ==========================================
class MediaViewerPage extends StatefulWidget {
  final AssetEntity asset;
  const MediaViewerPage({super.key, required this.asset});

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  bool _isSharing = false;

  Future<void> _shareAsset() async {
    setState(() => _isSharing = true);
    try {
      final File? file = await widget.asset.file;
      if (file != null) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Shared from Guptik Vault');
      }
    } catch (e) {
      debugPrint("Share Error: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showInfo() async {
    final File? file = await widget.asset.file;
    final int sizeBytes = file?.lengthSync() ?? 0;
    final String sizeString = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
    final String path = file?.path ?? "Unknown Path";
    final String resolution = "${widget.asset.width} x ${widget.asset.height}";

    final String date = DateFormat(
      'EEE, MMM d, yyyy • h:mm a',
    ).format(widget.asset.createDateTime);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Info",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _ancientGold),
              ),
              const SizedBox(height: 20),
              _infoRow(Icons.calendar_today, "Date", date),
              Divider(color: _ancientGold.withValues(alpha: 0.2)),
              _infoRow(
                Icons.image,
                "Details",
                "${widget.asset.title ?? 'Unknown'}\n$resolution • ${sizeString}MB",
              ),
              Divider(color: _ancientGold.withValues(alpha: 0.2)),
              _infoRow(Icons.folder_open, "Path on Device", path),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _ancientGold),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        actions: [
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _ancientGold, strokeWidth: 2))),
                )
              : IconButton(
                  icon: const Icon(Icons.share, color: _ancientGold),
                  onPressed: _shareAsset,
                ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: _ancientGold),
            onPressed: _showInfo,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: widget.asset.type == AssetType.video
            ? _VideoPlayerItem(asset: widget.asset)
            : FutureBuilder<Uint8List?>(
                future: widget.asset.originBytes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator(color: _ancientGold);
                  }
                  return InteractiveViewer(
                    child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                  );
                },
              ),
      ),
    );
  }
}

class _VideoPlayerItem extends StatefulWidget {
  final AssetEntity asset;
  const _VideoPlayerItem({required this.asset});
  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final file = await widget.asset.file;
    if (file != null) {
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _controller!.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const CircularProgressIndicator(color: _ancientGold);
    }
    return GestureDetector(
      onTap: () {
        setState(
          () => _controller!.value.isPlaying
              ? _controller!.pause()
              : _controller!.play(),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (!_controller!.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: _ancientGold,
                size: 50,
              ),
            ),
        ],
      ),
    );
  }
}

class _RealMediaTile extends StatelessWidget {
  final AssetEntity asset;
  final bool isSynced;

  const _RealMediaTile({required this.asset, required this.isSynced});

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
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black,
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                ),
              );
            }
            return Container(color: Colors.black);
          },
        ),

        // Unsynced Overlay (Gold border + tint)
        if (!isSynced)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.6), width: 1.5),
            ),
          ),

        if (!isSynced)
          Positioned(
            bottom: 5,
            left: 5,
            child: Icon(
              Icons.cloud_upload_outlined, // Changed to outline for better visibility
              color: _ancientGold,
              size: 16,
            ),
          ),

        if (asset.type == AssetType.video)
          const Positioned(
            top: 5,
            right: 5,
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
        if (asset.type == AssetType.video)
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _formatDuration(asset.duration),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final min = duration.inMinutes;
    final sec = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  _DateHeaderDelegate({required this.title});
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
          top: BorderSide(color: _ancientGold.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: _ancientGold,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 45;
  @override
  double get minExtent => 45;
  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) =>
      oldDelegate.title != title;
}