import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Servicio para manejar el guardado y carga de imágenes de ejercicios
class ImagenService {
  /// Directorio base para almacenar imágenes de ejercicios
  static const String _directorioBase = 'CrearEjercicio';
  
  /// Ruta base para assets (nota: el directorio real es 'imagends' con esta ortografía)
  static const String _assetsBase = 'assets/imagends/CrearEjercicio';

  /// Extensión de los archivos de imagen
  static const String _extension = '.jpg';

  /// Obtiene el directorio de almacenamiento para las imágenes
  static Future<Directory> _getImagenesDirectory() async {
    final directory = kIsWeb
        ? await getApplicationDocumentsDirectory()
        : await getApplicationDocumentsDirectory();
    
    final imagenesDir = Directory(path.join(directory.path, _directorioBase));
    
    // Crear el directorio si no existe
    if (!await imagenesDir.exists()) {
      await imagenesDir.create(recursive: true);
    }
    
    return imagenesDir;
  }

  /// Guarda una imagen desde un File al almacenamiento local
  /// 
  /// [imagenFile] - El archivo de imagen a guardar
  /// [nombrePalabra] - El nombre de la palabra para usar como nombre del archivo
  /// 
  /// Devuelve la ruta del archivo guardado
  static Future<String> guardarImagen(File imagenFile, String nombrePalabra) async {
    try {
      final imagenesDir = await _getImagenesDirectory();
      
      // Sanitizar el nombre de la palabra para usarlo como nombre de archivo
      final nombreArchivo = _sanitizarNombreArchivo(nombrePalabra) + _extension;
      
      // Ruta final del archivo
      final rutaDestino = path.join(imagenesDir.path, nombreArchivo);
      
      // Copiar el archivo a la nueva ubicación
      final nuevoArchivo = await imagenFile.copy(rutaDestino);
      
      // También copiar al directorio de assets para desarrollo
      try {
        final assetsDir = Directory(_assetsBase);
        if (!await assetsDir.exists()) {
          await assetsDir.create(recursive: true);
        }
        final assetsRuta = path.join(_assetsBase, nombreArchivo);
        await imagenFile.copy(assetsRuta);
      } catch (e) {
        // Ignorar errores en assets (puede que no tengamos permiso en algunos sistemas)
      }
      
      return nuevoArchivo.path;
    } catch (e) {
      // Si hay error, devolver la ruta original
      return imagenFile.path;
    }
  }

  /// Sanitiza el nombre de la palabra para usarlo como nombre de archivo
  /// Eliminar espacios, caracteres especiales, etc.
  static String _sanitizarNombreArchivo(String nombre) {
    // Convertir a minúsculas
    var sanitizado = nombre.toLowerCase();
    
    // Reemplazar espacios con guiones
    sanitizado = sanitizado.replaceAll(' ', '_');
    
    // Eliminar caracteres especiales (solo permitir letras, números y guiones)
    sanitizado = sanitizado.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    
    // Si el nombre queda vacío, usar un nombre por defecto
    if (sanitizado.isEmpty) {
      return 'ejercicio_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return sanitizado;
  }

  /// Obtiene la ruta del directorio de imágenes
  static Future<String> getImagenesDirectoryPath() async {
    final dir = await _getImagenesDirectory();
    return dir.path;
  }

  /// Verifica si un archivo de imagen existe
  static bool imagenExiste(String ruta) {
    if (ruta.isEmpty) return false;
    return File(ruta).existsSync();
  }

  /// Obtiene la lista de todas las imágenes guardadas
  static Future<List<FileSystemEntity>> getTodasImagenes() async {
    try {
      final dir = await _getImagenesDirectory();
      return dir.listSync();
    } catch (e) {
      return [];
    }
  }

  /// Elimina una imagen por su ruta
  static Future<bool> eliminarImagen(String ruta) async {
    try {
      if (ruta.isNotEmpty && await File(ruta).exists()) {
        await File(ruta).delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Elimina una imagen por nombre de palabra
  static Future<bool> eliminarImagenPorPalabra(String nombrePalabra) async {
    try {
      final nombreArchivo = _sanitizarNombreArchivo(nombrePalabra) + _extension;
      final dir = await _getImagenesDirectory();
      final ruta = path.join(dir.path, nombreArchivo);
      
      if (await File(ruta).exists()) {
        await File(ruta).delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
