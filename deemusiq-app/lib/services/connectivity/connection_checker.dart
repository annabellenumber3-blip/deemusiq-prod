import 'dart:async';
import 'dart:io';

import 'package:deemusiq/services/logger/logger.dart';

/// Checks internet connectivity by doing DNS lookups against well-known hosts.
/// Results are cached for [cacheDuration] to avoid spamming the network.
class ConnectionChecker {
  ConnectionChecker._();
  static final ConnectionChecker instance = ConnectionChecker._();

  static const _lookupHosts = ['google.com', 'cloudflare.com', 'github.com'];
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

    // Try to resolve each host with a short timeout.
    // If any resolves, we have internet.
    for (final host in _lookupHosts) {
      try {
        final sw = Stopwatch()..start();
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 3));
        sw.stop();
        if (result.isNotEmpty && result.any((a) => a.rawAddress.isNotEmpty)) {
          successfulPings++;
          totalLatency += sw.elapsedMilliseconds;
          results[host] = true;
        } else {
          results[host] = false;
        }
      } catch (_) {
        results[host] = false;
      }
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

    AppLogger.log.i(
      'ConnectionCheck: internet=$hasInternet latency=${avgLatency}ms '
      'results=${results.entries.where((e) => e.value).map((e) => e.key).join(',')}',
    );
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
