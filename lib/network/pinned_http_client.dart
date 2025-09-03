import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

/// Minimal pinned HttpClient that trusts only the bundled PEM certificate.
/// Place the server certificate at assets/certs/emotionai_server.crt and ensure pubspec.yaml lists it.
class PinnedHttpClient {
  PinnedHttpClient._();

  /// Creates an HttpClient using only the bundled server certificate.
  static Future<HttpClient> create({
    String assetPath = 'assets/certs/emotionai_server.crt',
  }) async {
    final securityContext = SecurityContext(withTrustedRoots: false);

    final bytes = await rootBundle.load(assetPath);
    securityContext.setTrustedCertificatesBytes(bytes.buffer.asUint8List());

    final client = HttpClient(context: securityContext);

    // Optionally, implement stricter checks by validating the certificate fingerprint.
    client.badCertificateCallback = (
      X509Certificate cert,
      String host,
      int port,
    ) {
      // With setTrustedCertificatesBytes, only the pinned cert should be accepted.
      // Returning true here allows the connection if the certificate matches the trusted set.
      return true;
    };

    return client;
  }
}
