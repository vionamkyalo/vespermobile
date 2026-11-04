import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/sync/models/offline_queue_entry.dart';
import '../../../core/sync/repositories/offline_queue_repository.dart';
import '../../../core/sync/services/sync_service.dart';
import '../../../core/widgets/report_card.dart';
import '../models/inspection_report.dart';
import '../reports_repository.dart';

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel(
    this._repo, {
    OfflineQueueRepository? queue,
    Stream<SyncEvent>? syncEvents,
  }) : _queue = queue {
    _subscription = syncEvents?.listen((_) => load());
  }

  static const String inspectionsFilter = 'Inspections';
  static const String violationsFilter = 'Violations';
  static const String catchChecksFilter = 'Catch checks';
  static const List<String> filters = [
    inspectionsFilter,
    violationsFilter,
    catchChecksFilter,
  ];

  final ReportsRepository _repo;
  final OfflineQueueRepository? _queue;
  StreamSubscription<SyncEvent>? _subscription;

  bool _loading = false;
  bool _loadAgain = false;
  bool _disposed = false;
  String? _error;
  String _officerName = '';
  Map<String, String> _zones = {};
  List<InspectionReport> _inspections = [];
  List<ViolationRecord> _violations = [];
  List<CatchCheckRecord> _catchChecks = [];
  List<OfflineQueueEntry> _waiting = [];

  bool get loading => _loading;
  String? get error => _error;
  String get officerName => _officerName;
  List<InspectionReport> get inspections => List.unmodifiable(_inspections);

  bool get hasAnyReports =>
      _inspections.isNotEmpty ||
      _violations.isNotEmpty ||
      _catchChecks.isNotEmpty ||
      _waiting.isNotEmpty;

  String zoneName(String id) => _zones[id] ?? 'Unknown zone';

  Future<void> load() async {
    if (_loading) {
      _loadAgain = true;
      return;
    }
    _loading = true;
    _error = null;
    _notify();

    try {
      final me = await _repo.me();
      final (zones, inspections) = await (
        _repo.zoneNames(),
        _repo.inspections(me.id),
      ).wait;
      _officerName = me.fullName;
      _zones = zones;
      _inspections = inspections;

      final mine = {for (final i in inspections) i.id};
      _violations = [
        for (final v in await _orEmpty(_repo.violations, 'violation reports'))
          if (mine.contains(v.inspectionId)) v,
      ];
      _catchChecks = [
        for (final c in await _orEmpty(_repo.catchChecks, 'catch checks'))
          if (mine.contains(c.inspectionId)) c,
      ];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load your reports. Pull down to try again.';
    }

    _waiting = await _loadWaiting();

    _loading = false;
    _notify();

    if (_loadAgain) {
      _loadAgain = false;
      await load();
    }
  }

  List<ReportItem> itemsFor(String filter) {
    final rows = <(DateTime, ReportItem)>[];

    switch (filter) {
      case inspectionsFilter:
        for (final r in _inspections) {
          rows.add((r.inspectedAt, _inspectionItem(r)));
        }
        for (final e in _waitingOf(RecordType.inspection)) {
          rows.add(_waitingInspectionItem(e));
        }
      case violationsFilter:
        for (final v in _violations) {
          rows.add((v.recordedAt, _violationItem(v)));
        }
        for (final e in _waitingOf(RecordType.violationReport)) {
          rows.add(_waitingViolationItem(e));
        }
      case catchChecksFilter:
        for (final c in _catchChecks) {
          rows.add((c.checkedAt, _catchCheckItem(c)));
        }
        for (final e in _waitingOf(RecordType.catchCheck)) {
          rows.add(_waitingCatchCheckItem(e));
        }
    }

    rows.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final row in rows) row.$2];
  }

  ReportItem _inspectionItem(InspectionReport r) => _item(
    type: inspectionsFilter,
    title: 'Inspection - ${labelOf(r.type)}',
    time: r.inspectedAt,
    zoneId: r.zoneId,
    notes: _inspectionNotes(r.rigsObserved, r.outcome, r.notes),
  );

  ReportItem _violationItem(ViolationRecord v) => _item(
    type: violationsFilter,
    title: 'Violation - ${labelOf(v.violationType)}',
    time: v.recordedAt,
    zoneId: _zoneOfInspection(v.inspectionId),
    notes:
        'Rig: ${v.rigIdentifier}. Review: '
        '${labelOf(v.reviewStatus).toLowerCase()}.\n${v.description}',
  );

  ReportItem _catchCheckItem(CatchCheckRecord c) => _item(
    type: catchChecksFilter,
    title: 'Catch check - ${_fishName(c.typeOfFish)}',
    time: c.checkedAt,
    zoneId: _zoneOfInspection(c.inspectionId),
    notes: _catchNotes(c.catchWeightKg, c.rigNights, c.rigIdentifier, c.notes),
  );

  (DateTime, ReportItem) _waitingInspectionItem(OfflineQueueEntry e) {
    final p = e.payload;
    final time = _time(p['inspected_at'], e.createdAt);
    return (
      time,
      _item(
        type: inspectionsFilter,
        title:
            'Inspection - ${labelOf(_text(p['inspection_type']))}'
            '${_waitingTag(e)}',
        time: time,
        zoneId: _text(p['zone_id']),
        notes: _inspectionNotes(
          (p['rigs_observed'] as num?)?.toInt() ?? 0,
          _text(p['outcome']),
          p['notes'] as String?,
        ),
      ),
    );
  }

  (DateTime, ReportItem) _waitingViolationItem(OfflineQueueEntry e) {
    final p = e.payload;
    final time = _time(p['recorded_at'], e.createdAt);
    return (
      time,
      _item(
        type: violationsFilter,
        title:
            'Violation - ${labelOf(_text(p['violation_type']))}'
            '${_waitingTag(e)}',
        time: time,
        zoneId: _zoneOfInspection(_text(p['inspection_id'])),
        notes:
            'Rig: ${_text(p['rig_identifier'])}.\n'
            '${_text(p['description'])}',
      ),
    );
  }

  (DateTime, ReportItem) _waitingCatchCheckItem(OfflineQueueEntry e) {
    final p = e.payload;
    final time = _time(p['checked_at'], e.createdAt);
    return (
      time,
      _item(
        type: catchChecksFilter,
        title:
            'Catch check - ${_fishName(p['type_of_fish'] as String?)}'
            '${_waitingTag(e)}',
        time: time,
        zoneId: _zoneOfInspection(_text(p['inspection_id'])),
        notes: _catchNotes(
          double.tryParse('${p['catch_weight_kg']}') ?? 0,
          (p['rig_nights'] as num?)?.toInt() ?? 0,
          _text(p['rig_identifier']),
          p['notes'] as String?,
        ),
      ),
    );
  }

  ReportItem _item({
    required String type,
    required String title,
    required DateTime time,
    required String zoneId,
    required String notes,
  }) => ReportItem(
    type: type,
    title: title,
    received: formatDate(time),
    officer: _officerName.isEmpty ? '-' : _officerName,
    zone: zoneName(zoneId),
    notes: notes,
  );

  static String _inspectionNotes(int rigs, String outcome, String? notes) {
    final extra = (notes ?? '').trim();
    return '$rigs rigs observed. '
        'Outcome: ${labelOf(outcome).toLowerCase()}.'
        '${extra.isEmpty ? '' : ' $extra'}';
  }

  static String _catchNotes(
    double weightKg,
    int nights,
    String rig,
    String? notes,
  ) {
    final extra = (notes ?? '').trim();
    return '${weightKg.toStringAsFixed(1)} kg over $nights nights on rig $rig.'
        '${extra.isEmpty ? '' : ' $extra'}';
  }

  static String _fishName(String? fish) {
    final name = (fish ?? '').trim();
    return name.isEmpty ? 'Catch' : name;
  }

  static String _waitingTag(OfflineQueueEntry e) {
    final refused =
        e.status == QueueStatus.failed &&
        e.attemptCount >= OfflineQueueRepository.maxAttempts;
    return refused ? ' (not accepted)' : ' (waiting to send)';
  }

  String _zoneOfInspection(String inspectionId) {
    for (final i in _inspections) {
      if (i.id == inspectionId) return i.zoneId;
    }
    for (final e in _waitingOf(RecordType.inspection)) {
      if (e.recordId == inspectionId) return _text(e.payload['zone_id']);
    }
    return '';
  }

  Iterable<OfflineQueueEntry> _waitingOf(RecordType type) =>
      _waiting.where((e) => e.recordType == type);

  static String _text(Object? value) => value is String ? value : '';

  static DateTime _time(Object? value, DateTime fallback) =>
      (value is String ? DateTime.tryParse(value) : null) ?? fallback;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDate(DateTime utc) {
    final d = utc.toLocal();
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final suffix = d.hour >= 12 ? 'pm' : 'am';
    return '${d.day} ${_months[d.month - 1]} ${d.year} $hour12.$minute$suffix';
  }

  Future<List<T>> _orEmpty<T>(
    Future<List<T>> Function() fetch,
    String what,
  ) async {
    try {
      return await fetch();
    } catch (e) {
      debugPrint('Could not load $what: $e');
      return const [];
    }
  }

  Future<List<OfflineQueueEntry>> _loadWaiting() async {
    final queue = _queue;
    if (queue == null) return const [];
    try {
      return await queue.waiting();
    } catch (e) {
      debugPrint('Could not read reports on this phone: $e');
      return const [];
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
