import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DiseasePrediction {
  final String id;
  final String disease;
  final double confidence;
  final DateTime timestamp;

  DiseasePrediction({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.timestamp,
  });
}

class LeafDiseaseService {
  static LeafDiseaseService? _instance;
  Interpreter? _interpreter;
  bool _isInitialized = false;
  String? _initError;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _modelAssetPath = 'assets/leaf_disease_model.tflite';

  static const List<String> _labels = [
    // Must match training/export class_names.json order exactly.
    'BLACK SIGATOKA',
    'FUSARIUM WILT',
    'HEALTHY',
  ];

  static const int _modelSize = 224;
  static const double _minConfidenceForPrediction = 0.55; // 55%
  static const bool _debugForcePredictionEvenIfLowConfidence = true;

  LeafDiseaseService._();

  static LeafDiseaseService get instance {
    _instance ??= LeafDiseaseService._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      try {
        _interpreter = await Interpreter.fromAsset(_modelAssetPath);
      } catch (assetErr) {
        try {
          _interpreter = await Interpreter.fromAsset(
            _modelAssetPath.replaceFirst('assets/', ''),
          );
        } catch (_) {
          // Final fallback: load from a real file path.
          final data = await rootBundle.load(_modelAssetPath);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/leaf_disease_model.tflite');
          await file.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true,
          );
          _interpreter = Interpreter.fromFile(file);
        }
        // ignore: avoid_print
        print('LeafDiseaseService: asset load fallback due to $assetErr');
      }
      _isInitialized = true;
      _initError = null;
      // ignore: avoid_print
      print('LeafDiseaseService: model loaded');
    } catch (e, st) {
      // If the model asset isn't bundled (or fails to load), we keep the app
      // functional by returning "Unknown" instead of random guesses.
      _isInitialized = false;
      _interpreter = null;
      _initError = 'Error: ${e.toString()}';
      // ignore: avoid_print
      print('LeafDiseaseService: model load failed: $e\n$st');
    }
  }

  Float32List _preprocessImage(img.Image image) {
    // 1. Resize to 224x224
    final resized = img.copyResize(
      image,
      width: _modelSize,
      height: _modelSize,
      interpolation: img.Interpolation.linear,
    );

    final inputBuffer = Float32List(_modelSize * _modelSize * 3);
    int index = 0;

    // Training normalization: (pixel/255 - mean) / std
    // mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
    const meanR = 0.485;
    const meanG = 0.456;
    const meanB = 0.406;
    const stdR = 0.229;
    const stdG = 0.224;
    const stdB = 0.225;

    for (int y = 0; y < _modelSize; y++) {
      for (int x = 0; x < _modelSize; x++) {
        final pixel = resized.getPixel(x, y);
        
        final floatR = pixel.r.toDouble() / 255.0;
        final floatG = pixel.g.toDouble() / 255.0;
        final floatB = pixel.b.toDouble() / 255.0;

        inputBuffer[index++] = ((floatR - meanR) / stdR);
        inputBuffer[index++] = ((floatG - meanG) / stdG);
        inputBuffer[index++] = ((floatB - meanB) / stdB);
      }
    }

    return inputBuffer;
  }

  List<List<List<List<double>>>> _to4dInput(Float32List input) {
    // Shape: [1, 224, 224, 3]
    final result = List.generate(
      1,
      (_) => List.generate(
        _modelSize,
        (y) => List.generate(
          _modelSize,
          (x) {
            final base = (y * _modelSize + x) * 3;
            return <double>[
              input[base],
              input[base + 1],
              input[base + 2],
            ];
          },
        ),
      ),
    );
    return result;
  }

  List<double> _softmax(List<double> values) {
    final expValues = values.map((v) => exp(v)).toList();
    final sumExp = expValues.fold<double>(0.0, (sum, v) => sum + v);
    if (sumExp == 0) {
      return List<double>.filled(values.length, 1.0 / values.length);
    }
    return expValues.map((v) => v / sumExp).toList();
  }

  Future<DiseasePrediction> classifyImage(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    final timestamp = DateTime.now();

    if (_interpreter == null) {
      final prediction = DiseasePrediction(
        id: timestamp.millisecondsSinceEpoch.toString(),
        disease: _initError == null ? 'Unknown' : _initError!,
        confidence: 0,
        timestamp: timestamp,
      );
      _savePredictionToDatabase(prediction);
      return prediction;
    }

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      final prediction = DiseasePrediction(
        id: timestamp.millisecondsSinceEpoch.toString(),
        disease: 'Image decode failed',
        confidence: 0,
        timestamp: timestamp,
      );
      _savePredictionToDatabase(prediction);
      return prediction;
    }

    final input = _to4dInput(_preprocessImage(decoded));

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outShape = outputTensor.shape;
    final outLen = outShape.isNotEmpty ? outShape.last : _labels.length;
    final rawOutput = List<double>.filled(outLen, 0);

    // ignore: avoid_print
    print('LeafDiseaseService: inputShape=${inputTensor.shape} inputType=${inputTensor.type} outputShape=$outShape outputType=${outputTensor.type}');

    // Most common shapes:
    // - [1, N] => output is List<List<double>>
    // - [N]    => output is List<double>
    if (outShape.length == 2) {
      final output = [rawOutput];
      _interpreter!.run(input, output);
    } else {
      _interpreter!.run(input, rawOutput);
    }

    // ignore: avoid_print
    print('LeafDiseaseService: rawOutput=$rawOutput');

    final probs = _softmax(rawOutput);
    var bestIdx = 0;
    var bestProb = probs.isNotEmpty ? probs[0] : 0.0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > bestProb) {
        bestProb = probs[i];
        bestIdx = i;
      }
    }

    final shouldPredict = _debugForcePredictionEvenIfLowConfidence || bestProb >= _minConfidenceForPrediction;
    final disease = (shouldPredict && bestIdx < _labels.length) ? _labels[bestIdx] : 'Unknown';
    final confidence = bestProb * 100.0;
    // ignore: avoid_print
    print('LeafDiseaseService probs=$probs bestIdx=$bestIdx label=${bestIdx < _labels.length ? _labels[bestIdx] : 'out_of_range'} conf=$confidence');

    final prediction = DiseasePrediction(
      id: timestamp.millisecondsSinceEpoch.toString(),
      disease: disease,
      confidence: confidence,
      timestamp: timestamp,
    );

    _savePredictionToDatabase(prediction);
    return prediction;
  }

  Future<void> _savePredictionToDatabase(DiseasePrediction prediction) async {
    try {
      if (_userId != null) {
        await _dbRef.child('users').child(_userId!).child('predictions').push().set({
          'id': prediction.id,
          'disease': prediction.disease,
          'confidence': prediction.confidence,
          'timestamp': prediction.timestamp.toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving prediction to database: $e');
    }
  }

  Future<List<DiseasePrediction>> getPredictionHistory() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _dbRef
          .child('users')
          .child(_userId!)
          .child('predictions')
          .limitToLast(20)
          .get();

      if (snapshot.value == null) return [];

      final Map<dynamic, dynamic> data = snapshot.value as Map;
      return data.entries.map((entry) {
        final predictionData = entry.value as Map;
        return DiseasePrediction(
          id: predictionData['id'] ?? '',
          disease: predictionData['disease'] ?? 'Unknown',
          confidence: (predictionData['confidence'] ?? 0.0).toDouble(),
          timestamp: DateTime.parse(predictionData['timestamp'] ?? DateTime.now().toIso8601String()),
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error fetching prediction history: $e');
      return [];
    }
  }

  Future<void> clearPredictionHistory() async {
    try {
      if (_userId != null) {
        await _dbRef.child('users').child(_userId!).child('predictions').remove();
      }
    } catch (e) {
      print('Error clearing prediction history: $e');
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
