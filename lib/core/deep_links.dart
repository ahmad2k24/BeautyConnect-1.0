import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  void initDeepLinkListener() async {
    // Handle app launch from terminated state
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        handleUri(initialLink);
      }
    } catch (err) {
      print("Initial app link error: $err");
    }

    // Listen for app links while app is running
    _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) handleUri(uri);
      },
      onError: (err) {
        print("App link stream error: $err");
      },
    );
  }

  void handleUri(Uri uri) {
    print("Received deep link: $uri");

    switch (uri.host) {
      case 'stripe-onboarding-done':
        print("Stripe onboarding completed for user!");
        // TODO: Navigate or update state
        break;
      case 'stripe-reauth':
        print("User needs to retry Stripe onboarding.");
        // TODO: Retry onboarding
        break;
      default:
        print("Unhandled deep link: $uri");
    }
  }
}
