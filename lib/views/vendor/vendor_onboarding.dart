import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VendorOnboarding extends StatefulWidget {
  final String onboardingUrl;
  const VendorOnboarding({super.key, required this.onboardingUrl});

  @override
  State<VendorOnboarding> createState() => _VendorOnboardingState();
}

class _VendorOnboardingState extends State<VendorOnboarding> {
  late final WebViewController _controller;
  double _progress = 0.0;
  String _currentUrl = "";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _currentUrl = url;
              _progress = 0.0;
            });
          },
          onProgress: (progress) {
            setState(() => _progress = progress / 100);
          },
          onPageFinished: (url) {
            setState(() {
              _currentUrl = url;
              _progress = 1.0;
            });
          },
          onWebResourceError: (error) {
            debugPrint("❌ WebView error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.onboardingUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Stripe Onboarding", style: TextStyle(fontSize: 16)),
            Text(
              _currentUrl,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: _progress < 1.0
              ? LinearProgressIndicator(value: _progress)
              : const SizedBox.shrink(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
