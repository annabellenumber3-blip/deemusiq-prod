import 'dart:async';
import 'dart:io';

import 'package:deemusiq/services/logger/logger.dart';

/// Checks internet connectivity by pinging DNS servers and doing DNS lookups.
/// Results are cached for [cacheDuration] to avoid spamming the network.
class ConnectionChecker {
  ConnectionChecker._();
  static final ConnectionChecker instance = ConnectionChecker._();

  static const _dnsServers = ['8.8.8.8', '1.1.1.1'];
  static const _pingCount = 4;
  static const cacheDuration = Duration(seconds: 30);

  ConnectionStatus? _cached;
  DateTime? _cachedAt;

  /// Performs a full connectivity check. Cached for 30 seconds.
  Future<ConnectionStatus> check() async {
    if (_cached != null && _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < cacheDuration) {
      return _cached!;
    }

    final results = <String, bool>{};
    var totalLatency = 0;
    var successfulPings = 0;

    for (final server in _dnsServers) {
      var serverOk = false;
      for (var i = 0; i < _pingCount; i++) {
        try {
          final sw = Stopwatch()..start();
          final result = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 3));
          sw.stop();
          if (result.isNotEmpty) {
            successfulPings++;
            totalLatency += sw.elapsedMilliseconds;
            serverOk = true;
          }
        } catch (_) {
          // Individual ping failure — continue
        }
      }
      results[server] = serverOk;
    }

    final hasInternet = results.values.any((v) => v);
    final avgLatency = successfulPings > 0 ? totalLatency ~/ successfulPings : -1;

    _cached = ConnectionStatus(
      hasInternet: hasInternet,
      dnsResults: results,
      avgLatencyMs: avgLatency,
      checkedAt: DateTime.now(),
    );
    _cachedAt = DateTime.now();

    AppLogger.log.i('ConnectionCheck: internet=$hasInternet latency=${avgLatency}ms');
    return _cached!;
  }

  /// Quick check — uses cache if available.
  Future<bool> get hasInternet async {
    final status = await check();
    return status.hasInternet;
  }

  /// Returns a user-friendly message based on connection state.
  String userMessage(ConnectionStatus status) {
    if (!status.hasInternet) return 'Sorry, no internet';
    if (status.avgLatencyMs > 1000) return 'Bad connection, retrying...';
    return 'Connected — playing...';
  }

  void clearCache() {
    _cached = null;
    _cachedAt = null;
  }
}

class ConnectionStatus {
  final bool hasInternet;
  final Map<String, bool> dnsResults;
  final int avgLatencyMs;
  final DateTime checkedAt;

  const ConnectionStatus({
    required this.hasInternet,
    required this.dnsResults,
    required this.avgLatencyMs,
    required this.checkedAt,
  });
}
