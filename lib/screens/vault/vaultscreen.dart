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
  
  // 🚀 ADDED: Flag to kill the sync loop instantly
  bool _cancelSync = false; 

  // ==========================================
  // ValueNotifiers for 100% Live Dialog Updates
  // ==========================================
  final ValueNotifier<int> _liveSyncedNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _liveRemainingNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _syncTextNotifier = ValueNotifier<String>("");
  final ValueNotifier<double> _syncProgressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> _liveDataNotifier = ValueNotifier<String>("0.00 MB");
  
  // 🚀 ADDED: Tracks if we are doing the 40-second math, or actually uploading
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
    _isPreparingNotifier.dispose(); // 🚀 Clean up memory
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
            } else if (item['filename'] != null)
              val = item['filename'].toString();
            else if (item['title'] != null)
              val = item['title'].toString();
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

  // ==========================================
  // 🚀 FIXED: INSTANT DIALOG & STOPPABLE QUEUE
  // ==========================================
  Future<void> _handleSync() async {
    if (_isSyncing) return;
    if (_currentAlbum == null) return;

    setState(() => _isSyncing = true);
    
    // 1. Reset our flags for the new session
    _cancelSync = false; 
    _isPreparingNotifier.value = true; // Show the spinner mode
    _syncTextNotifier.value = "Scanning library & checking desktop...";
    _syncProgressNotifier.value = 0.0;
    _liveSyncedNotifier.value = 0;
    _liveRemainingNotifier.value = 0;
    _liveDataNotifier.value = "0.00 MB";

    // 2. 🚀 INSTANT RESPONSE: Show the dialog immediately before doing math!
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          // 🚀 ADDED: PopScope catches the Android Back Button so we can cancel!
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) return;
              _cancelSync = true;
              Navigator.pop(dialogCtx);
            },
            child: AlertDialog(
              title: const Text("Syncing Vault"),
              content: ValueListenableBuilder<bool>(
                valueListenable: _isPreparingNotifier,
                builder: (context, isPreparing, child) {
                  
                  // STATE A: Scanning the files (The 40 second wait)
                  if (isPreparing) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.deepPurple),
                        const SizedBox(height: 20),
                        ValueListenableBuilder<String>(
                          valueListenable: _syncTextNotifier,
                          builder: (context, text, child) => Text(
                            text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Files: $_totalAssetCount",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<int>(
                              valueListenable: _liveSyncedNotifier,
                              builder: (context, value, child) => Text(
                                "Already Synced: $value",
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<int>(
                              valueListenable: _liveRemainingNotifier,
                              builder: (context, value, child) => Text(
                                "Remaining to Sync: $value",
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<String>(
                              valueListenable: _liveDataNotifier,
                              builder: (context, value, child) => Text(
                                "Data Uploaded: $value",
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ValueListenableBuilder<double>(
                        valueListenable: _syncProgressNotifier,
                        builder: (context, value, child) =>
                            LinearProgressIndicator(value: value),
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<String>(
                        valueListenable: _syncTextNotifier,
                        builder: (context, value, child) => Center(
                          child: Text(
                            value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              actions: [
                // 🚀 ADDED: Manual Cancel Button
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

      // STEP 1: Ask desktop exactly what it has
      Set<String> currentlyOnDesktop = await _fetchActualDesktopFiles();
      
      // Stop early if user canceled during fetching
      if (_cancelSync) throw Exception("Sync cancelled by user.");

      // STEP 2: BUILD QUEUE IN BATCHES (The 40 second math)
      List<AssetEntity> missingFilesQueue = [];
      int safeBatchSize = 500;

      for (int i = 0; i < _totalAssetCount; i += safeBatchSize) {
        if (_cancelSync) throw Exception("Sync cancelled by user."); // Check inside loop

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

      // STEP 3: EXACT MATH
      int totalLocalFiles = _totalAssetCount;
      int targetUploadCount = missingFilesQueue.length;
      int alreadyOnDesktopCount = totalLocalFiles - targetUploadCount;

      if (targetUploadCount == 0) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Close dialog early
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Everything is already up to date! ☁️✓')),
        );
        setState(() => _isSyncing = false);
        return;
      }

      // 🚀 The math is done! Tell the dialog to switch from "Spinner" to "Progress Bar"
      _liveSyncedNotifier.value = alreadyOnDesktopCount;
      _liveRemainingNotifier.value = targetUploadCount;
      _syncProgressNotifier.value = 0.0;
      _isPreparingNotifier.value = false;

      // STEP 4: Iterate ONLY through the exact missing files!
      int successCount = 0;
      double totalMegabytesUploaded = 0.0;

      for (int i = 0; i < missingFilesQueue.length; i++) {
        // 🚀 THE FIX: If back button was pressed, STOP the loop instantly!
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
        if (!_cancelSync) Navigator.pop(context); // Close dialog if it finished normally
        
        if (_cancelSync) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sync cancelled. Partial upload saved. 🛑'), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sync Complete! Uploaded $successCount missing files.'), backgroundColor: Colors.green),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text(
              "Guptik Vault",
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.cloud_upload,
                  color: _hasUnsyncedItems
                      ? Colors.deepPurpleAccent
                      : Colors.grey,
                ),
                onPressed: _handleSync,
                tooltip: "Sync to Desktop",
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: const Icon(Icons.desktop_mac, color: Colors.black),
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
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.purple,
                child: Text("G", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 15),
            ],
          ),

          if (!_hasPermission && !_isLoading)
            SliverFillRemaining(
              child: Center(
                child: TextButton(
                  onPressed: PhotoManager.openSetting,
                  child: const Text("Open Settings"),
                ),
              ),
            ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
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

                        // UI SMART MATCH
                        final bool isOnDesktop =
                            _liveDesktopIds.contains(asset.id) ||
                            (asset.title != null &&
                                _liveDesktopIds.contains(asset.title)) ||
                            (titleNoExt.isNotEmpty &&
                                _liveDesktopIds.contains(titleNoExt));

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
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
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
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Info",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _infoRow(Icons.calendar_today, "Date", date),
              const Divider(),
              _infoRow(
                Icons.image,
                "Details",
                "${widget.asset.title ?? 'Unknown'}\n$resolution • ${sizeString}MB",
              ),
              const Divider(),
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
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
        backgroundColor: Colors.black.withAlpha(150),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareAsset,
                ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Center(
        child: widget.asset.type == AssetType.video
            ? _VideoPlayerItem(asset: widget.asset)
            : FutureBuilder<Uint8List?>(
                future: widget.asset.originBytes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator(color: Colors.white);
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
      return const CircularProgressIndicator(color: Colors.white);
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
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
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
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            }
            return Container(color: Colors.grey[200]);
          },
        ),

        if (!isSynced)
          Positioned(
            bottom: 5,
            left: 5,
            child: Icon(
              Icons.cloud_off,
              color: Colors.white.withAlpha(200),
              size: 16,
            ),
          ),

        if (asset.type == AssetType.video)
          const Positioned(
            top: 5,
            right: 5,
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
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
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(asset.duration),
                style: const TextStyle(color: Colors.white, fontSize: 10),
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
      color: Colors.white.withAlpha(245),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w600,
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