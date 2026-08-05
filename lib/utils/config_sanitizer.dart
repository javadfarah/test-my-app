import 'dart:convert';
import 'dart:io';

/// Fixes profile configs the core rejects at start.
///
/// Newer xray/sing-box rejects empty/`0`/`0-0` `x_padding_bytes` with
/// "xPaddingBytes cannot be disabled". Removing the field leaves padding at
/// the transport default instead of explicitly disabling it.
abstract final class ConfigSanitizer {
  static const _disabledPaddingValues = {'', '0', '0-0'};

  static const _emptyOptionalTransportKeys = {
    'x_padding_bytes',
    'sc_max_each_post_bytes',
    'sc_min_posts_interval_ms',
    'sc_stream_up_server_secs',
  };

  /// Returns sanitized JSON string, or the original if unchanged / not JSON.
  static String sanitizeJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return raw;
      final changed = sanitizeMap(decoded);
      if (!changed) return raw;
      return jsonEncode(decoded);
    } catch (_) {
      return raw;
    }
  }

  /// Mutates [config] in place. Returns whether anything changed.
  static bool sanitizeMap(Map<String, dynamic> config) {
    var changed = false;
    final outbounds = config['outbounds'];
    if (outbounds is! List) return false;

    for (final outbound in outbounds) {
      if (outbound is! Map) continue;
      final transport = outbound['transport'];
      if (transport is! Map) continue;

      for (final key in _emptyOptionalTransportKeys) {
        final value = transport[key];
        if (value == null) continue;
        final asString = value.toString().trim();
        if (_disabledPaddingValues.contains(asString) || asString.isEmpty) {
          transport.remove(key);
          changed = true;
        }
      }

      // Drop null xmux / download placeholders that confuse some parsers
      if (transport['xmux'] == null && transport.containsKey('xmux')) {
        transport.remove('xmux');
        changed = true;
      }
      if (transport['download'] == null && transport.containsKey('download')) {
        transport.remove('download');
        changed = true;
      }
    }
    return changed;
  }

  static Future<void> sanitizeFile(File file) async {
    if (!await file.exists()) return;
    final raw = await file.readAsString();
    final sanitized = sanitizeJsonString(raw);
    if (sanitized != raw) {
      await file.writeAsString(sanitized);
    }
  }

  /// Strip `enable-padding: false` from options JSON so the core does not
  /// force-disable xPaddingBytes on xhttp outbounds when TLS fragment is on.
  static Map<String, dynamic> sanitizeOptionsJson(Map<String, dynamic> options) {
    final copy = Map<String, dynamic>.from(options);
    final tls = copy['tls-tricks'];
    if (tls is Map) {
      final tlsCopy = Map<String, dynamic>.from(tls);
      if (tlsCopy['enable-padding'] == false) {
        tlsCopy.remove('enable-padding');
        tlsCopy.remove('padding-size');
      }
      copy['tls-tricks'] = tlsCopy;
    }
    return copy;
  }
}
