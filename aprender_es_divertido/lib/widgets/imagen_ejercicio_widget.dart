import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:aprender_es_divertido/services/imagen_service.dart';

/// Widget para mostrar imágenes de ejercicios de forma segura
/// Funciona en móvil (con Image.file) y en Web (con placeholder)
class ImagenEjercicioWidget extends StatelessWidget {
  final String imagenPath;
  final double width;
  final double height;
  final BoxFit fit;

  const ImagenEjercicioWidget({
    super.key,
    required this.imagenPath,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // En Web, Image.file no funciona
    if (kIsWeb) {
      return _buildPlaceholder();
    }

    // Verificar si la ruta es de assets
    if (imagenPath.contains('assets/')) {
      try {
        return Image.asset(
          imagenPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    // En móviles, verificar si el archivo existe
    if (imagenPath.isNotEmpty && ImagenService.imagenExiste(imagenPath)) {
      try {
        return Image.file(
          File(imagenPath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    // Si no existe la imagen, mostrar placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 32, color: Colors.grey),
    );
  }
}

/// Widget para mostrar la imagen de ejercicio en un círculo
class ImagenEjercicioCircular extends StatelessWidget {
  final String imagenPath;
  final double size;

  const ImagenEjercicioCircular({
    super.key,
    required this.imagenPath,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: ImagenEjercicioWidget(
        imagenPath: imagenPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
