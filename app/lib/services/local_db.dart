import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_messenger.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table des discussions
        await db.execute('''
          CREATE TABLE chats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            lastMessage TEXT,
            updatedAt INTEGER NOT NULL
          )
        ''');

        // Table des messages (ajustée pour supporter tes GIFs et Emojis)
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chatId INTEGER NOT NULL,
            body TEXT,
            mediaPath TEXT, 
            type TEXT NOT NULL, 
            isMine INTEGER NOT NULL,
            status TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );

    await _seed();
  }

  // Initialisation avec un message de bienvenue "Aʀᴛㅤᴇᴜʀᴏㅤ❕"
  Future<void> _seed() async {
    final db = await database;
    final countResult = await db.rawQuery('SELECT COUNT(*) as c FROM chats');
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final chatId = await db.insert('chats', {
        'title': 'Aʀᴛㅤᴇᴜʀᴏㅤ❕ Room',
        'lastMessage': 'Système prêt ✅',
        'updatedAt': now,
      });

      await db.insert('messages', {
        'chatId': chatId,
        'body': 'Bienvenue Papa Euro ! Ton système de messagerie sécurisé est prêt.',
        'mediaPath': null,
        'type': 'text',
        'isMine': 0,
        'status': 'local',
        'createdAt': now,
      });
    }
  }

  // --- FONCTIONS DE RÉCUPÉRATION ---

  Future<List<Map<String, dynamic>>> getChats() async {
    final db = await database;
    return db.query('chats', orderBy: 'updatedAt DESC');
  }

  Future<List<Map<String, dynamic>>> getMessages(int chatId) async {
    final db = await database;
    return db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'createdAt ASC',
    );
  }

  // --- FONCTION D'AJOUT (Gère les GIFs automatiquement) ---

  Future<void> addMessage({
    required int chatId,
    String? body,
    String? mediaPath,
    required String type,
    required bool isMine,
    String status = 'local',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Logique de prévisualisation intelligente
    String preview = body ?? "Message";
    if (type == 'gif') preview = "🖼️ GIF envoyé";
    if (type == 'emoji') preview = body ?? "😊";

    await db.insert('messages', {
      'chatId': chatId,
      'body': body,
      'mediaPath': mediaPath,
      'type': type,
      'isMine': isMine ? 1 : 0,
      'status': status,
      'createdAt': now,
    });

    // Met à jour la discussion dans la liste
    await db.update(
      'chats',
      {
        'lastMessage': preview,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }
}
