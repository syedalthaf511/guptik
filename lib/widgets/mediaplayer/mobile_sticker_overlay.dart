import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/video_stricker_model.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/mediaplayer/mobile_bridge_service.dart';

/// MobileStickerOverlay — mobile counterpart to desktop's sticker_overlay.dart.
/// Fetches shoppable stickers for a video via the gateway's read-only
/// GET /player/video/stickers/<videoId> endpoint (already implemented as
/// MobileBridgeService.fetchStickers), and shows whichever sticker matches
/// the current playback position, timed to [timestampInVideo] +
/// [durationOnScreen], positioned via each sticker's normalized ClickableZone.
///
/// NOTE: click logging (PlayerMonetizationService.logStickerClick on desktop)
/// has no gateway POST endpoint yet, so clicks aren't recorded server-side
/// from mobile (or from any remote viewer) — this only opens the product link.
class MobileStickerOverlay extends StatefulWidget {
  final String videoId;
  final String gatewayUrl;
  final VideoPlayerController controller;

  const MobileStickerOverlay({
    Key? key,
    required this.videoId,
    required this.gatewayUrl,
    required this.controller,
  }) : super(key: key);

  @override
  State<MobileStickerOverlay> createState() => _MobileStickerOverlayState();
}

class _MobileStickerOverlayState extends State<MobileStickerOverlay> {
  late final MobileBridgeService _bridge;
  List<VideoSticker> _stickers = [];
  VideoSticker? _activeSticker;

  @override
  void initState() {
    super.initState();
    _bridge = MobileBridgeService(gatewayUrl: widget.gatewayUrl);
    _loadStickers();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  Future<void> _loadStickers() async {
    final raw = await _bridge.fetchStickers(widget.videoId);
    if (!mounted) return;
    setState(() {
      _stickers = raw
          .map((s) => VideoSticker.fromJson(Map<String, dynamic>.from(s as Map)))
          .where((s) => s.isActive)
          .toList();
    });
  }

  void _onTick() {
    if (_stickers.isEmpty) return;
    final positionSeconds = widget.controller.value.position.inMilliseconds / 1000.0;

    VideoSticker? match;
    for (final sticker in _stickers) {
      final start = sticker.timestampInVideo;
      final end = start + sticker.durationOnScreen;
      if (positionSeconds >= start && positionSeconds <= end) {
        match = sticker;
        break;
      }
    }

    if (match?.id != _activeSticker?.id) {
      setState(() => _activeSticker = match);
    }
  }

  Future<void> _openProduct(VideoSticker sticker) async {
    // NOTE: no click-logging endpoint exists on the gateway yet, so we skip
    // that call here (desktop's logStickerClick is local-Postgres only).
    if (sticker.linkUrl != null && sticker.linkUrl!.isNotEmpty) {
      final uri = Uri.tryParse(sticker.linkUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showProductSheet(VideoSticker sticker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (sticker.imagePath != null && sticker.imagePath!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      sticker.imagePath!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[800],
                        child: const Icon(Icons.shopping_bag, color: Colors.white54),
                      ),
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sticker.title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            sticker.formattedSalePrice,
                            style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (sticker.discountPercent > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              sticker.formattedMrp,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${sticker.discountPercent.toStringAsFixed(0)}% off',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (sticker.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                sticker.description,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openProduct(sticker);
                },
                child: const Text('View Product', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeSticker == null) return const SizedBox.shrink();
    final zone = _activeSticker!.clickableZone ?? const ClickableZone();

    // 🚀 FIX: previously this widget returned a bare LayoutBuilder → Positioned
    // directly as a Stack child. As a non-Positioned Stack child, its actual
    // rendered box wasn't guaranteed to match the video's real box (Stack's
    // default StackFit.loose sizing for plain children is ambiguous), which
    // caused the badge to stretch/spill above and below the visible video
    // instead of sitting neatly inside it. Positioned.fill unambiguously
    // fills the EXACT box of the parent Stack (the video's AspectRatio box),
    // and the nested Stack + LayoutBuilder inside it then measures that exact
    // box correctly before placing the badge as a fraction of it.
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: zone.x * constraints.maxWidth,
                top: zone.y * constraints.maxHeight,
                width: zone.width * constraints.maxWidth,
                height: zone.height * constraints.maxHeight,
                child: GestureDetector(
                  onTap: () => _showProductSheet(_activeSticker!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag, color: Colors.orange, size: 16),
                        const SizedBox(height: 2),
                        Text(
                          _activeSticker!.formattedSalePrice,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}