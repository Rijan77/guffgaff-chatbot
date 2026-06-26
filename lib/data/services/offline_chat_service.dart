import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// Offline keyword-scoring search over the bundled manual_data.json.
/// Mirrors the Python Jaccard logic in backend/app/services/manual_service.py.
class OfflineChatService {
  static const double _exactThreshold = 0.72;

  List<Map<String, dynamic>>? _entries;

  Future<void> _ensureLoaded() async {
    if (_entries != null) return;
    final raw = await rootBundle.loadString('assets/manual_data.json');
    _entries = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  /// Returns a curated answer if score ≥ threshold, otherwise null.
  Future<String?> findOfflineAnswer(String query) async {
    await _ensureLoaded();
    final scored = _scoreAll(query);
    if (scored.isEmpty) return null;
    final best = scored.first;
    if (best['score'] as double >= _exactThreshold) {
      return best['answer'] as String;
    }
    return null;
  }

  List<Map<String, dynamic>> _scoreAll(String query) {
    final queryTokens = _tokenize(query);
    final results = <Map<String, dynamic>>[];

    for (final entry in _entries!) {
      final score = _score(queryTokens, entry);
      results.add({'score': score, 'answer': entry['answer']});
    }

    results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return results;
  }

  double _score(Set<String> queryTokens, Map<String, dynamic> entry) {
    final questionTokens = _tokenize(entry['question'] as String);
    final questionScore = _jaccard(queryTokens, questionTokens);

    final kwTokens = <String>{};
    for (final kw in (entry['keywords'] as List)) {
      kwTokens.addAll(_tokenize(kw as String));
    }

    final kwScore = kwTokens.isEmpty
        ? 0.0
        : queryTokens.intersection(kwTokens).length / kwTokens.length;

    return max(questionScore * 0.45 + kwScore * 0.55, kwScore);
  }

  Set<String> _tokenize(String text) {
    return RegExp(r'\b[a-zA-Z]{2,}\b')
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toSet();
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    return a.intersection(b).length / a.union(b).length;
  }
}
