import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/leaf_disease_service.dart';

class OfflineStorageService {
  static OfflineStorageService? _instance;
  static Database? _database;

  static const String _predictionsTable = 'predictions';
  static const String _feedbackTable = 'feedback';
  static const String _pendingSyncKey = 'pending_sync';
  static const String _predictionCountKey = 'prediction_count';

  OfflineStorageService._();

  static OfflineStorageService get instance {
    _instance ??= OfflineStorageService._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'banana_health.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_predictionsTable (
            id TEXT PRIMARY KEY,
            disease TEXT NOT NULL,
            confidence REAL NOT NULL,
            timestamp TEXT NOT NULL,
            imagePath TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $_feedbackTable (
            id TEXT PRIMARY KEY,
            predictionId TEXT NOT NULL,
            isAccurate INTEGER NOT NULL,
            correctDiagnosis TEXT,
            comments TEXT,
            timestamp TEXT NOT NULL,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY (predictionId) REFERENCES $_predictionsTable(id)
          )
        ''');
      },
    );
  }

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any((result) => 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );
  }

  Future<void> savePredictionLocally(DiseasePrediction prediction) async {
    final db = await database;
    await db.insert(
      _predictionsTable,
      {
        'id': prediction.id,
        'disease': prediction.disease,
        'confidence': prediction.confidence,
        'timestamp': prediction.timestamp.toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    await _markPendingSync(true);
  }

  Future<List<DiseasePrediction>> getLocalPredictions() async {
    final db = await database;
    final results = await db.query(
      _predictionsTable,
      orderBy: 'timestamp DESC',
    );
    
    return results.map((row) => DiseasePrediction(
      id: row['id'] as String,
      disease: row['disease'] as String,
      confidence: (row['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(row['timestamp'] as String),
    )).toList();
  }

  Future<void> saveFeedback({
    required String predictionId,
    required bool isAccurate,
    String? correctDiagnosis,
    String? comments,
  }) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    await db.insert(
      _feedbackTable,
      {
        'id': id,
        'predictionId': predictionId,
        'isAccurate': isAccurate ? 1 : 0,
        'correctDiagnosis': correctDiagnosis,
        'comments': comments,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      },
    );
    
    await _markPendingSync(true);
  }

  Future<List<Map<String, dynamic>>> getPendingFeedback() async {
    final db = await database;
    return await db.query(
      _feedbackTable,
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingPredictions() async {
    final db = await database;
    return await db.query(
      _predictionsTable,
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> _markPendingSync(bool hasPending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSyncKey, hasPending);
  }

  Future<bool> hasPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingSyncKey) ?? false;
  }

  Future<void> markPredictionSynced(String id) async {
    final db = await database;
    await db.update(
      _predictionsTable,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFeedbackSynced(String id) async {
    final db = await database;
    await db.update(
      _feedbackTable,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPredictionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_predictionCountKey) ?? 0;
  }

  Future<void> incrementPredictionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getPredictionCount();
    await prefs.setInt(_predictionCountKey, count + 1);
  }

  Future<bool> shouldShowFeedback() async {
    final count = await getPredictionCount();
    return (count + 1) % 2 == 0;
  }

  Future<void> resetPredictionCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_predictionCountKey, 0);
  }

  Future<void> syncPendingData({
    required Function(Map<String, dynamic>) uploadPrediction,
    required Function(Map<String, dynamic>) uploadFeedback,
  }) async {
    if (!await isOnline()) return;

    final pendingPredictions = await getPendingPredictions();
    for (final prediction in pendingPredictions) {
      try {
        await uploadPrediction(prediction);
        await markPredictionSynced(prediction['id'] as String);
      } catch (e) {
        print('Failed to sync prediction: $e');
      }
    }

    final pendingFeedback = await getPendingFeedback();
    for (final feedback in pendingFeedback) {
      try {
        await uploadFeedback(feedback);
        await markFeedbackSynced(feedback['id'] as String);
      } catch (e) {
        print('Failed to sync feedback: $e');
      }
    }

    final hasMorePending = await getPendingPredictions().then(
      (list) => list.isNotEmpty
    ) || await getPendingFeedback().then(
      (list) => list.isNotEmpty
    );
    
    await _markPendingSync(hasMorePending);
  }

  Future<void> clearLocalData() async {
    final db = await database;
    await db.delete(_predictionsTable);
    await db.delete(_feedbackTable);
    await _markPendingSync(false);
  }
}
