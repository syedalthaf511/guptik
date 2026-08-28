import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/models/mediaplyer/video_stricker_model.dart'; 
import '../../services/mediaplayer/mobile_bridge_service.dart';

/// MobileMonetizationScreen — mobile counterpart to desktop's
/// MonetizationDashboardScreen. Step 1: navigation shell only.
/// Earnings / Ad Settings / Memberships / Stickers tabs will be wired to
/// real data in a later step (needs new gateway endpoints, since desktop's
/// monetization data lives in local Postgres, unreachable directly from mobile).
class MobileMonetizationScreen extends StatefulWidget {
  final String channelId;

  const MobileMonetizationScreen({Key? key, required this.channelId}) : super(key: key);

  @override
  State<MobileMonetizationScreen> createState() => _MobileMonetizationScreenState();
}

class _MobileMonetizationScreenState extends State<MobileMonetizationScreen> {
  int _selectedTab = 0;

  // 🚀 ADDED: Stickers tab — video picker + read-only sticker list, mirroring
  // desktop's dashboard pattern (pick your own video, then view its stickers).
  // Creating stickers still requires desktop (no gateway write endpoint yet).
  bool _loadingVideos = true;
  List<Map<String, dynamic>> _myVideos = [];
  Map<String, dynamic>? _selectedVideo;
  bool _loadingStickers = false;
  List<VideoSticker> _videoStickers = [];

  // 🚀 ADDED: Add Sticker form state
  bool _isSavingSticker = false;

  final List<_TabInfo> _tabs = const [
    _TabInfo('Earnings', Icons.attach_money),
    _TabInfo('Ad Settings', Icons.ads_click),
    _TabInfo('Memberships', Icons.star),
    _TabInfo('Stickers', Icons.shopping_bag),
  ];

  @override
  void initState() {
    super.initState();
    _loadMyVideos();
  }

  Future<void> _loadMyVideos() async {
    try {
      // 🚀 THE FIX: OR-fallback on creator_uid too. Desktop's upload service had
      // a bug where channel_id was never written to Supabase's mp_videos table
      // (only to local Postgres), leaving it NULL there. Since channel_id ==
      // creator_uid for every normal (non-repost) upload, this fallback finds
      // videos published before that bug was fixed, without needing a backfill.
      final response = await Supabase.instance.client
          .from('mp_videos')
          .select('video_id, title, thumbnail_url, creator_cloudflare_url')
          .or('channel_id.eq.${widget.channelId},creator_uid.eq.${widget.channelId}')
          .order('published_at', ascending: false);
      if (mounted) {
        setState(() {
          _myVideos = List<Map<String, dynamic>>.from(response as List);
          _loadingVideos = false;
        });
      }
    } catch (e) {
      debugPrint('Load My Videos Error: $e');
      if (mounted) setState(() => _loadingVideos = false);
    }
  }

  Future<void> _selectVideo(Map<String, dynamic> video) async {
    setState(() {
      _selectedVideo = video;
      _loadingStickers = true;
      _videoStickers = [];
    });
    try {
      final gatewayUrl = video['creator_cloudflare_url']?.toString() ?? '';
      final bridge = MobileBridgeService(gatewayUrl: gatewayUrl);
      final raw = await bridge.fetchStickers(video['video_id'].toString());
      if (mounted) {
        setState(() {
          _videoStickers = raw
              .map((s) => VideoSticker.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList();
          _loadingStickers = false;
        });
      }
    } catch (e) {
      debugPrint('Load Video Stickers Error: $e');
      if (mounted) setState(() => _loadingStickers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Monetization',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: List.generate(_tabs.length, (i) => Expanded(child: _buildTab(i))),
            ),
          ),
          Expanded(
            child: _selectedTab == 3 ? _buildStickersTab() : _buildPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_tabs[_selectedTab].icon, color: Colors.white24, size: 56),
            const SizedBox(height: 16),
            Text(
              '${_tabs[_selectedTab].label} coming soon',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This tab will be wired to live data in a follow-up update.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 ADDED: mirrors desktop's Stickers tab — pick one of your own videos,
  // then view its stickers. Read-only: adding a new sticker still requires
  // the desktop app until a gateway write endpoint exists.
  Widget _buildStickersTab() {
    if (_selectedVideo == null) {
      if (_loadingVideos) {
        return const Center(child: CircularProgressIndicator(color: Colors.orange));
      }
      if (_myVideos.isEmpty) {
        return const Center(
          child: Text('You have no published videos yet.', style: TextStyle(color: Colors.grey)),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myVideos.length,
        itemBuilder: (context, index) {
          final v = _myVideos[index];
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  v['thumbnail_url']?.toString() ?? '',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[850],
                    child: const Icon(Icons.movie, color: Colors.white38),
                  ),
                ),
              ),
              title: Text(
                v['title']?.toString() ?? 'Untitled',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _selectVideo(v),
            ),
          );
        },
      );
    }

    // A video is selected — show its stickers
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() {
                  _selectedVideo = null;
                  _videoStickers = [];
                }),
              ),
              Expanded(
                child: Text(
                  _selectedVideo!['title']?.toString() ?? 'Untitled',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showAddStickerSheet(_selectedVideo!),
              icon: const Icon(Icons.add_shopping_cart, color: Colors.black, size: 18),
              label: const Text('Add Sticker to Video', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loadingStickers
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : _videoStickers.isEmpty
                  ? const Center(
                      child: Text('No stickers on this video yet.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _videoStickers.length,
                      itemBuilder: (context, index) {
                        final s = _videoStickers[index];
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: (s.imagePath != null && s.imagePath!.isNotEmpty)
                                  ? Image.network(
                                      s.imagePath!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.grey[850],
                                        child: const Icon(Icons.shopping_bag, color: Colors.white38, size: 20),
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey[850],
                                      child: const Icon(Icons.shopping_bag, color: Colors.white38, size: 20),
                                    ),
                            ),
                            title: Text(
                              s.title,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Shown at ${s.timestampInVideo.toStringAsFixed(0)}s • ${s.formattedSalePrice}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                            trailing: Text(
                              s.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: s.isActive ? Colors.greenAccent : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // 🚀 ADDED: Add Sticker form — mirrors desktop's Sticker Editor fields
  // (Sticker Image, Product Title, Description, MRP, Sale Price, Currency,
  // Product Link URL, Show Timing, Visible For), POSTing to the new gateway
  // endpoint via MobileBridgeService.addSticker().
  void _showAddStickerSheet(Map<String, dynamic> video) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final mrpController = TextEditingController();
    final priceController = TextEditingController();
    final linkController = TextEditingController();
    final timingController = TextEditingController(text: '0');
    final durationController = TextEditingController(text: '8');
    String currency = 'USD';
    File? pickedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Sticker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'For "${video['title'] ?? 'this video'}"',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Sticker image picker
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(pickedImage!, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.image_outlined, color: Colors.white24),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (result != null && result.files.single.path != null) {
                              setSheetState(() => pickedImage = File(result.files.single.path!));
                            }
                          },
                          icon: const Icon(Icons.upload, size: 16),
                          label: const Text('Pick Image', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _stickerField('Product Title', titleController, hint: 'e.g. Wireless Earbuds'),
                    const SizedBox(height: 12),
                    _stickerField('Description', descController, hint: 'Short product blurb...', maxLines: 3),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _stickerField('MRP', mrpController, hint: '29.99', keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _stickerField('Sale Price', priceController, hint: '19.99', keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Currency', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: currency,
                                    dropdownColor: const Color(0xFF1E1E1E),
                                    isDense: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    items: ['USD', 'EUR', 'GBP', 'INR']
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (v) => setSheetState(() => currency = v ?? 'USD'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _stickerField('Product Link URL', linkController, hint: 'https://...'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _stickerField('Show Timing (sec)', timingController, hint: '0', keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _stickerField('Visible For (sec)', durationController, hint: '8', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSavingSticker
                            ? null
                            : () async {
                                if (titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Product Title is required')),
                                  );
                                  return;
                                }
                                setSheetState(() => _isSavingSticker = true);

                                final gatewayUrl = video['creator_cloudflare_url']?.toString() ?? '';
                                final bridge = MobileBridgeService(gatewayUrl: gatewayUrl);
                                final success = await bridge.addSticker(
                                  videoId: video['video_id'].toString(),
                                  productName: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  timestampInVideo: double.tryParse(timingController.text) ?? 0,
                                  durationOnScreen: double.tryParse(durationController.text) ?? 8,
                                  mrp: double.tryParse(mrpController.text),
                                  salePrice: double.tryParse(priceController.text),
                                  currency: currency,
                                  linkUrl: linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                                  imageFile: pickedImage,
                                );

                                setSheetState(() => _isSavingSticker = false);
                                if (!mounted) return;

                                if (success) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sticker added!'), backgroundColor: Colors.green),
                                  );
                                  _selectVideo(video); // refresh the list
                                } else {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Failed to add sticker. Check connection.'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              },
                        child: _isSavingSticker
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('Add Sticker to Video', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _stickerField(String label, TextEditingController controller, {String? hint, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index) {
    final isSelected = _selectedTab == index;
    final tab = _tabs[index];
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, color: isSelected ? Colors.orange : Colors.grey, size: 18),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo(this.label, this.icon);
}