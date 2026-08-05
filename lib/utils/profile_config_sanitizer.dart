import 'dart:convert';
import 'dart:io';

/// Fixes profile configs that the core rejects, especially XHTTP transports with
/// empty / zero `x_padding_bytes` ("xPaddingBytes cannot be disabled").
class ProfileConfigSanitizer {
  static const _disabledPaddingValues = {'', '0', '0-0'};

  /// Returns sanitized JSON string, or the original if unchanged / not JSON.
  static String sanitizeJsonString(String content) {
    final trimmed = content.trimLeft();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return content;
    }
    try {
      final decoded = jsonDecode(content);
      final changed = _sanitizeNode(decoded);
      if (!changed) return content;
      return jsonEncode(decoded);
    } catch (_) {
      return content;
    }
  }

  static Future<void> sanitizeFile(File file) async {
    if (!await file.exists()) return;
    final original = await file.readAsString();
    final sanitized = sanitizeJsonString(original);
    if (sanitized != original) {
      await file.writeAsString(sanitized);
    }
  }

  static bool _sanitizeNode(dynamic node) {
    var changed = false;
    if (node is Map) {
      final transport = node['transport'];
      if (transport is Map) {
        changed = _sanitizeTransport(transport) || changed;
      }
      for (final value in node.values) {
        changed = _sanitizeNode(value) || changed;
      }
    } else if (node is List) {
      for (final item in node) {
        changed = _sanitizeNode(item) || changed;
      }
    }
    return changed;
  }

  static bool _sanitizeTransport(Map transport) {
    var changed = false;
    // Remove disabled padding so core leaves XHTTP padding at its default.
    for (final key in ['x_padding_bytes', 'xPaddingBytes']) {
      final value = transport[key];
      if (value == null) continue;
      final asString = value.toString().trim();
      if (_disabledPaddingValues.contains(asString)) {
        transport.remove(key);
        changed = true;
      }
    }
    // Drop other empty optional string fields that can panic the core as "unknown value".
    for (final key in [
      'sc_max_each_post_bytes',
      'sc_min_posts_interval_ms',
      'sc_stream_up_server_secs',
      'scMaxEachPostBytes',
      'scMinPostsIntervalMs',
      'scStreamUpServerSecs',
    ]) {
      if (transport[key] == '') {
        transport.remove(key);
        changed = true;
      }
    }
    if (transport['xmux'] == null) {
      // keep null; some serializers include it explicitly — remove for cleanliness
      if (transport.containsKey('xmux') && transport['xmux'] == null) {
        transport.remove('xmux');
        changed = true;
      }
    }
    if (transport['download'] == null && transport.containsKey('download')) {
      transport.remove('download');
      changed = true;
    }
    return changed;
  }
}
