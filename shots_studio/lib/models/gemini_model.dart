import 'dart:typed_data';
import 'package:shots_studio/models/screenshot_model.dart';

class GeminiModel {
  String base_url;
  String? model_name;
  String api_key;
  int timeout;
  int max_parallel;
  int? max_retries;

  GeminiModel({
    required this.model_name,
    required this.api_key,
    this.timeout = 30,
    this.max_parallel = 4,
    this.max_retries,
  }) : base_url = 'https://generativelanguage.googleapis.com/v1beta/models';

  String ask() {
    return 'hello ${model_name ?? ""}';
  }
}
