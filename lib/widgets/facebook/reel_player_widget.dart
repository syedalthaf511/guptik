import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ReelPlayerWidget extends StatefulWidget {
  final String reelId;
  final String? thumbnailUrl;
  final String? videoUrl;

  const ReelPlayerWidget({
    super.key,
    required this.reelId,
    this.thumbnailUrl,
    this.videoUrl,
  });

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final embedUrl = 'https://www.instagram.com/reel/${widget.reelId}/embed';
    final alternativeEmbedUrl =
        'https://www.instagram.com/p/${widget.reelId}/embed';

    final String htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body { margin:0; padding:0; background:black; }
    .container { width:100vw; height:100vh; display:flex; justify-content:center; align-items:center; }
    iframe { width:100%; height:100%; border:none; }
  </style>
</head>
<body>
  <div class="container">
    <iframe src="$embedUrl"
            allow="autoplay; fullscreen"
            allowfullscreen>
    </iframe>
  </div>
  <script>
    var iframe = document.querySelector('iframe');
    iframe.onerror = function() {
      iframe.src = "$alternativeEmbedUrl";
    };
  </script>
</body>
</html>
    ''';

    final String base64Html = base64Encode(
      const Utf8Encoder().convert(htmlContent),
    );
    final String dataUri = 'data:text/html;base64,$base64Html';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            setState(() => _hasError = true);
            debugPrint('WebView error: $error');
          },
        ),
      )
      ..loadRequest(Uri.parse(dataUri));
  }

  void _openInBrowser() async {
    final url = 'https://www.instagram.com/reel/${widget.reelId}/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback &&
        widget.videoUrl != null &&
        widget.videoUrl!.isNotEmpty) {
      // Could eventually use a video player, but for now show browser button
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Unable to play reel',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _openInBrowser,
              child: const Text('Open in Instagram'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: Colors.black,
            child: Center(
              child: widget.thumbnailUrl != null
                  ? Image.network(widget.thumbnailUrl!, fit: BoxFit.cover)
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),
        if (_hasError)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Failed to load reel',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _useFallback = true;
                        _initializeWebView();
                      });
                    },
                    child: const Text('Try Alternative'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _openInBrowser,
                    child: const Text(
                      'Open in Browser',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}