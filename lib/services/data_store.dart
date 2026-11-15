import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// A tiny document database interface. Two implementations:
///  * [LocalStore]      on-device (Demo mode). All accounts signed in on the
///                      same phone share it, so you can test the whole
///                      request/approval workflow by switching accounts.
///  * [FirestoreStore]  Cloud Firestore (real, shared, instant updates).
///
/// Documents are plain maps. Dates are stored as ISO-8601 strings.
abstract class DataStore {
  /// Live list of documents. Emits immediately, then on every change.
  /// Optional single filter: `field == equals`.
  Stream<List<Doc>> watch(String collection, {String? field, Object? equals});

  Future<Doc?> get(String collection, String id);

  /// Upsert. With [merge] only the given fields change.
  Future<void> set(String collection, String id, Doc data, {bool merge = true});

  Future<void> setMany(String collection, Map<String, Doc> docs);
  Future<void> delete(String collection, String id);
  Future<bool> isEmpty(String collection);
}

// ───────────────────────── Local (Demo) ─────────────────────────

class LocalStore implements DataStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;
  final Map<String, Map<String, Doc>> _cache = {};
  final Map<String, StreamController<void>> _changes = {};

  Map<String, Doc> _col(String c) => _cache.putIfAbsent(c, () {
        final raw = _prefs.getString('store_$c');
        if (raw == null) return <String, Doc>{};
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
        );
      });

  StreamController<void> _ctl(String c) =>
      _changes.putIfAbsent(c, () => StreamController<void>.broadcast());

  Future<void> _persist(String c) async {
    await _prefs.setString('store_$c', jsonEncode(_col(c)));
    _ctl(c).add(null);
  }

  List<Doc> _snapshot(String c, String? field, Object? equals) {
    final out = <Doc>[];
    _col(c).forEach((id, d) {
      if (field == null || d[field] == equals) {
        out.add({...d, 'id': id});
      }
    });
    return out;
  }

  @override
  Stream<List<Doc>> watch(String collection, {String? field, Object? equals}) {
    late StreamController<List<Doc>> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<List<Doc>>(
      onListen: () {
        controller.add(_snapshot(collection, field, equals));
        sub = _ctl(collection).stream.listen(
              (_) => controller.add(_snapshot(collection, field, equals)),
            );
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<Doc?> get(String collection, String id) async {
    final d = _col(collection)[id];
    return d == null ? null : {...d, 'id': id};
  }

  @override
  Future<void> set(String collection, String id, Doc data,
      {bool merge = true}) async {
    final col = _col(collection);
    col[id] = merge ? {...?col[id], ...data} : {...data};
    await _persist(collection);
  }

  @override
  Future<void> setMany(String collection, Map<String, Doc> docs) async {
    final col = _col(collection);
    docs.forEach((id, d) => col[id] = {...d});
    await _persist(collection);
  }

  @override
  Future<void> delete(String collection, String id) async {
    _col(collection).remove(id);
    await _persist(collection);
  }

  @override
  Future<bool> isEmpty(String collection) async => _col(collection).isEmpty;
}

// ───────────────────────── Cloud Firestore (real) ─────────────────────────

class FirestoreStore implements DataStore {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Query<Map<String, dynamic>> _query(String c, String? field, Object? equals) {
    Query<Map<String, dynamic>> q = _db.collection(c);
    if (field != null) q = q.where(field, isEqualTo: equals);
    return q;
  }

  @override
  Stream<List<Doc>> watch(String collection, {String? field, Object? equals}) {
    return _query(collection, field, equals).snapshots().map(
          (s) => s.docs.map((d) => <String, dynamic>{...d.data(), 'id': d.id}).toList(),
        );
  }

  @override
  Future<Doc?> get(String collection, String id) async {
    final s = await _db.collection(collection).doc(id).get();
    if (!s.exists) return null;
    return {...?s.data(), 'id': s.id};
  }

  @override
  Future<void> set(String collection, String id, Doc data,
      {bool merge = true}) {
    return _db
        .collection(collection)
        .doc(id)
        .set(data, SetOptions(merge: merge));
  }

  @override
  Future<void> setMany(String collection, Map<String, Doc> docs) async {
    final entries = docs.entries.toList();
    for (var i = 0; i < entries.length; i += 400) {
      final batch = _db.batch();
      for (final e in entries.skip(i).take(400)) {
        batch.set(_db.collection(collection).doc(e.key), e.value);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> delete(String collection, String id) =>
      _db.collection(collection).doc(id).delete();

  @override
  Future<bool> isEmpty(String collection) async {
    final s = await _db.collection(collection).limit(1).get();
    return s.docs.isEmpty;
  }
}
