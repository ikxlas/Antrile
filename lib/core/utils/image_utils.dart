import 'dart:convert';
import 'package:flutter/material.dart';

class SafeImage {
  static ImageProvider? getProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    
    if (url.startsWith('data:image')) {
      final base64Str = url.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(url);
  }

  static Widget build(String? url, {double? width, double? height, BoxFit? fit}) {
    if (url == null || url.isEmpty) {
      return _errorPlaceholder(width, height);
    }
    
    if (url.startsWith('data:image')) {
      final base64Str = url.split(',').last;
      return Image.memory(base64Decode(base64Str), width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => _errorPlaceholder(width, height));
    }
    return Image.network(url, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => _errorPlaceholder(width, height));
  }

  static Widget _errorPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
