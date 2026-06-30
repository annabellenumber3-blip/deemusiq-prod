import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:deemusiq/utils/platform.dart';

class MetadataAuthEndpoint {
  MetadataAuthEndpoint();

  Stream get authStateStream {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> authenticate() async {
    throw UnimplementedError('Native plugin must override');
  }

  bool isAuthenticated() {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> logout() async {
    if (kIsMobile) {
      WebStorageManager.instance().deleteAllData();
      CookieManager.instance().deleteAllCookies();
    }
    if (kIsDesktop) {
      await WebviewWindow.clearAll();
    }
  }
}
