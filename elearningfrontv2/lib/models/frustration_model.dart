// lib/models/frustration_model.dart

import 'dart:typed_data';
import 'package:flutter/services.dart'; // Nécessaire pour rootBundle
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FrustrationModel {
  Interpreter? _interpreter;
  
  final int inputSize = 224; 
  final double predictionThreshold = 0.3759; 
  static const String _modelPath = 'assets/model_tflite_rebuilt.tflite';


  // Constructeur standard (utilisé pour obtenir l'instance sans charger le modèle)
  FrustrationModel();

  // 💡 NOUVEAU CONSTRUCTEUR SYNCHRONE POUR L'ISOLATE
  // Crée l'interpréteur à partir des octets du modèle passés en argument.
  FrustrationModel.fromBuffer(Uint8List buffer) {
    try {
      _interpreter = Interpreter.fromBuffer(buffer);
    } catch (e) {
      print('❌ Erreur lors du chargement synchrone du modèle TFLite: $e');
      rethrow;
    }
  }

  /// 1. Méthode statique pour pré-charger les octets du modèle (appelée dans LessonStudentScreen)
  static Future<Uint8List> loadModelBuffer() async {
    final ByteData data = await rootBundle.load(_modelPath);
    return data.buffer.asUint8List();
  }

  /// Effectue le pré-traitement (MobileNetV2) et la prédiction.
  double predict(img.Image image) {
    assert(_interpreter != null, "L'interpréteur TFLite n'a pas été initialisé.");
    if (_interpreter == null) return 0.0;
    
    // Redimensionner l'image à 224x224
    final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
    
    // Créer le buffer d'entrée [1, 224, 224, 3] (Float32)
    var input = Float32List(1 * inputSize * inputSize * 3).reshape([1, inputSize, inputSize, 3]);

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y); 
        final double r = pixel.r.toDouble(); 
        final double g = pixel.g.toDouble();
        final double b = pixel.b.toDouble();
        
        // Normalisation MobileNetV2: (value - 127.5) / 127.5 => Plage [-1, 1]
        input[0][y][x][0] = (r - 127.5) / 127.5; // R
        input[0][y][x][1] = (g - 127.5) / 127.5; // G
        input[0][y][x][2] = (b - 127.5) / 127.5; // B
      }
    }
    
    // Préparer le buffer de sortie (1 valeur Float)
    var output = List.filled(1, 0.0).reshape([1, 1]); 
    
    // Exécuter l'inférence
    _interpreter!.run(input, output);
    
    // Renvoyer le score de frustration (entre 0.0 et 1.0)
    return output[0][0];
  }
  
  /// Fonction pour déterminer le label (Rouge/Vert)
  String getLabel(double score) {
    return score > predictionThreshold ? 'FRUSTRATION 🔴' : 'CALM 🟢';
  }

  /// Nettoie les ressources TFLite
  void close() {
    _interpreter?.close();
  }
}