import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';
import '../models/session_model.dart';

const _uuid = Uuid();

class LocalStorageService {
  static Database? _db;

  Future<Database> get _database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'guffgaff.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            source TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<List<SessionModel>> getSessions() async {
    final db = await _database;
    final rows = await db.query('sessions', orderBy: 'updated_at DESC');
    return rows.map(_rowToSession).toList();
  }

  Future<SessionModel> createSession({String title = 'New Chat'}) async {
    final db = await _database;
    final now = DateTime.now();
    final session = SessionModel(
      id: _uuid.v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('sessions', _sessionToRow(session));
    return session;
  }

  Future<void> upsertSession(SessionModel session) async {
    final db = await _database;
    await db.insert(
      'sessions',
      _sessionToRow(session),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> renameSession(String id, String title) async {
    final db = await _database;
    await db.update(
      'sessions',
      {'title': title, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await _database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'session_id = ?', whereArgs: [id]);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Future<List<MessageModel>> getMessages(String sessionId) async {
    final db = await _database;
    final rows = await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_rowToMessage).toList();
  }

  Future<void> insertMessage(MessageModel msg, String sessionId) async {
    final db = await _database;
    await db.insert(
      'messages',
      {
        'id': msg.id,
        'session_id': sessionId,
        'role': msg.role,
        'content': msg.content,
        'source': msg.source,
        'created_at': msg.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.update(
      'sessions',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> upsertMessages(List<MessageModel> messages, String sessionId) async {
    final db = await _database;
    final batch = db.batch();
    for (final msg in messages) {
      batch.insert(
        'messages',
        {
          'id': msg.id,
          'session_id': sessionId,
          'role': msg.role,
          'content': msg.content,
          'source': msg.source,
          'created_at': msg.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  SessionModel _rowToSession(Map<String, dynamic> row) => SessionModel(
        id: row['id'] as String,
        title: row['title'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );

  Map<String, dynamic> _sessionToRow(SessionModel s) => {
        'id': s.id,
        'title': s.title,
        'created_at': s.createdAt.toIso8601String(),
        'updated_at': s.updatedAt.toIso8601String(),
      };

  MessageModel _rowToMessage(Map<String, dynamic> row) => MessageModel(
        id: row['id'] as String,
        role: row['role'] as String,
        content: row['content'] as String,
        source: row['source'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
