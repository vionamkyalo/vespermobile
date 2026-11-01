import 'package:flutter/material.dart';

import '../../app/navigator_key.dart';
import 'models/offline_queue_entry.dart';
import 'repositories/offline_queue_repository.dart';
import 'services/sync_service.dart';

/// Shows a banner on top of every screen when a queued record syncs or fails.
void listenForSyncNotifications(
  SyncService sync,
  OfflineQueueRepository queue,
) {
  sync.events.listen((event) {
    debugPrint('SYNC EVENT: ${event.kind} ${event.entry.recordType}');
    final what = _label(event.entry.recordType);

    if (event.kind == SyncEventKind.synced) {
      _showBanner('✓ $what synced', Colors.green.shade700);
      return;
    }

    final reason = event.message.length > 140
        ? '${event.message.substring(0, 140)}…'
        : event.message;
    _showBanner(
      "$what couldn't be sent. It's still saved on this phone.\n$reason",
      Colors.red.shade700,
      onRetry: () async {
        await queue.retry(event.entry.queueId);
        await sync.syncNow();
      },
    );
  });
}

OverlayEntry? _current;

void _showBanner(String text, Color color, {VoidCallback? onRetry}) {
  final overlay = appNavigatorKey.currentState?.overlay;
  if (overlay == null) {
    debugPrint('SYNC BANNER: app not ready, banner skipped');
    return;
  }
  _current?.remove();
  _current = null;

  late final OverlayEntry entry;
  void close() {
    if (_current == entry) {
      entry.remove();
      _current = null;
    }
  }

  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 16,
      right: 16,
      bottom: 96, // above the bottom navigation bar
      child: Material(
        color: color,
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    close();
                    onRetry();
                  },
                  child: const Text(
                    'RETRY',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  _current = entry;
  overlay.insert(entry);
  Future.delayed(Duration(seconds: onRetry == null ? 4 : 10), close);
}

String _label(RecordType type) => switch (type) {
  RecordType.inspection => 'Inspection',
  RecordType.violationReport => 'Violation report',
  RecordType.catchCheck => 'Catch check',
  RecordType.location => 'Location update',
};
