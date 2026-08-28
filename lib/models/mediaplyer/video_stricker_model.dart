/// VideoSticker — In-video product/service sticker model used for monetization.
///
/// Mobile copy of the desktop model (kept in sync). A sticker is a clickable
/// product card that appears over a video at a specific timestamp, links out
/// to a product page, and shows an image with MRP + sale price.
class VideoSticker {
  final String id;
  final String videoId;
  final String productId;
  final String? serviceId;

  /// Timestamp (in seconds) inside the video when the sticker should appear.
  final double timestampInVideo;

  /// How long (in seconds) the sticker stays on screen after [timestampInVideo].
  final double durationOnScreen;

  final ClickableZone? clickableZone;

  final String title;
  final String description;
  final double mrp;
  final double salePrice;
  final String currency;
  final String? linkUrl;
  final String? imagePath;

  final String stockStatus;
  final int salesCountLocal;
  final int clickCountLocal;
  final int purchaseInitiatedCount;
  final int purchaseCompletedCount;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String stickerType; // 'product' | 'service'

  const VideoSticker({
    required this.id,
    required this.videoId,
    this.productId = '',
    this.serviceId,
    this.timestampInVideo = 0,
    this.durationOnScreen = 8,
    this.clickableZone,
    this.title = 'Untitled',
    this.description = '',
    this.mrp = 0,
    this.salePrice = 0,
    this.currency = 'USD',
    this.linkUrl,
    this.imagePath,
    this.stockStatus = 'in_stock',
    this.salesCountLocal = 0,
    this.clickCountLocal = 0,
    this.purchaseInitiatedCount = 0,
    this.purchaseCompletedCount = 0,
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
    this.stickerType = 'product',
  });

  /// Builds a [VideoSticker] from the gateway's JSON response
  /// (GET /player/video/stickers/<videoId>).
  factory VideoSticker.fromJson(Map<String, dynamic> json) {
    final dynamic rawMrp = json['mrp'] ?? json['mrp_price'];
    final dynamic rawSale = json['sale_price'] ?? json['price'];
    return VideoSticker(
      id: json['id']?.toString() ?? '',
      videoId: json['video_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      serviceId: json['service_id']?.toString(),
      timestampInVideo: _toDouble(json['timestamp_in_video'] ?? json['show_timing_start'] ?? 0),
      durationOnScreen: _toDouble(json['duration_on_screen'] ?? 8),
      clickableZone: json['clickable_zone'] != null
          ? ClickableZone.fromJson(json['clickable_zone'])
          : null,
      title: json['product_name']?.toString() ??
          json['service_name']?.toString() ??
          json['title']?.toString() ??
          'Untitled',
      description: json['description']?.toString() ?? '',
      mrp: _toDouble(rawMrp),
      salePrice: _toDouble(rawSale),
      currency: json['currency']?.toString() ?? 'USD',
      linkUrl: json['link_url']?.toString(),
      imagePath: json['image_path']?.toString(),
      stockStatus: json['stock_status']?.toString() ?? 'in_stock',
      salesCountLocal: _toInt(json['sales_count_local'] ?? json['sales_count'] ?? 0),
      clickCountLocal: _toInt(json['click_count_local'] ?? 0),
      purchaseInitiatedCount: _toInt(json['purchase_initiated_count'] ?? 0),
      purchaseCompletedCount: _toInt(json['purchase_completed_count'] ?? 0),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      stickerType: json['service_id'] != null ? 'service' : 'product',
    );
  }

  double get discountPercent {
    if (mrp <= 0 || salePrice >= mrp) return 0;
    return ((mrp - salePrice) / mrp) * 100;
  }

  String get formattedSalePrice => '$currencySymbol${salePrice.toStringAsFixed(2)}';
  String get formattedMrp => '$currencySymbol${mrp.toStringAsFixed(2)}';

  String get currencySymbol {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      default:
        return '';
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

/// ClickableZone — the rectangular region of the video frame where a sticker
/// is tappable. Normalized coordinates (0.0–1.0) so it scales with any
/// video resolution or screen size.
class ClickableZone {
  final double x;
  final double y;
  final double width;
  final double height;

  const ClickableZone({
    this.x = 0.7,
    this.y = 0.1,
    this.width = 0.28,
    this.height = 0.28,
  });

  factory ClickableZone.fromJson(dynamic json) {
    if (json == null) return const ClickableZone();
    final Map<String, dynamic> map =
        json is Map<String, dynamic> ? json : <String, dynamic>{};
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return ClickableZone(
      x: toDouble(map['x']),
      y: toDouble(map['y']),
      width: toDouble(map['width']),
      height: toDouble(map['height']),
    );
  }
}