import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/completar_palabra_model.dart';
import '../models/ordenar_palabras_model.dart';
import '../models/acrostico_model.dart';
import '../models/pdf_book_model.dart';

/// Servicio para guardar y recuperar ejercicios usando SharedPreferences
class EjercicioStorageService {
  static const String _ejerciciosKey = 'completar_palabra_ejercicios';
  static const String _ejerciciosOrdenarKey = 'ordenar_palabra_ejercicios';
  static const String _ejerciciosAcrosticoKey = 'acrostico_ejercicios';
  static const String _librosPDFKey = 'libros_pdf';
  static const String _librosPDFKeyBackup = 'libros_pdf_backup';

  /// Guarda todos los ejercicios en el almacenamiento persistente
  static Future<bool> guardarEjercicios(List<CompletarPalabraEjercicio> ejercicios) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir ejercicios a JSON
      final ejerciciosJson = ejercicios.map((e) => e.toJson()).toList();
      final ejerciciosJsonString = jsonEncode(ejerciciosJson);
      
      return await prefs.setString(_ejerciciosKey, ejerciciosJsonString);
    } catch (e) {
      return false;
    }
  }

  /// Recupera todos los ejercicios del almacenamiento persistente
  static Future<List<CompletarPalabraEjercicio>> obtenerEjercicios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ejerciciosJsonString = prefs.getString(_ejerciciosKey);
      
      if (ejerciciosJsonString == null || ejerciciosJsonString.isEmpty) {
        return [];
      }
      
      final ejerciciosJson = jsonDecode(ejerciciosJsonString) as List<dynamic>;
      return ejerciciosJson
          .map((json) => CompletarPalabraEjercicio.fromJson(json as Map<String, dynamic>))
          .cast<CompletarPalabraEjercicio>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Elimina todos los ejercicios guardados
  static Future<bool> eliminarTodosEjercicios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_ejerciciosKey);
    } catch (e) {
      return false;
    }
  }

  /// Guarda todos los ejercicios de ordenar palabras en el almacenamiento persistente
  static Future<bool> guardarEjerciciosOrdenar(List<OrdenarPalabraEjercicio> ejercicios) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir ejercicios a JSON
      final ejerciciosJson = ejercicios.map((e) => e.toJson()).toList();
      final ejerciciosJsonString = jsonEncode(ejerciciosJson);
      
      return await prefs.setString(_ejerciciosOrdenarKey, ejerciciosJsonString);
    } catch (e) {
      return false;
    }
  }

  /// Recupera todos los ejercicios de ordenar palabras del almacenamiento persistente
  static Future<List<OrdenarPalabraEjercicio>> obtenerEjerciciosOrdenar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ejerciciosJsonString = prefs.getString(_ejerciciosOrdenarKey);
      
      if (ejerciciosJsonString == null || ejerciciosJsonString.isEmpty) {
        return [];
      }
      
      final ejerciciosJson = jsonDecode(ejerciciosJsonString) as List<dynamic>;
      return ejerciciosJson
          .map((json) => OrdenarPalabraEjercicio.fromJson(json as Map<String, dynamic>))
          .cast<OrdenarPalabraEjercicio>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Elimina todos los ejercicios de ordenar palabras guardados
  static Future<bool> eliminarTodosEjerciciosOrdenar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_ejerciciosOrdenarKey);
    } catch (e) {
      return false;
    }
  }

  /// Guarda todos los ejercicios de acróstico en el almacenamiento persistente
  static Future<bool> guardarEjerciciosAcrosticos(List<AcrosticoEjercicio> ejercicios) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir ejercicios a JSON
      final ejerciciosJson = ejercicios.map((e) => e.toJson()).toList();
      final ejerciciosJsonString = jsonEncode(ejerciciosJson);
      
      return await prefs.setString(_ejerciciosAcrosticoKey, ejerciciosJsonString);
    } catch (e) {
      return false;
    }
  }

  /// Recupera todos los ejercicios de acróstico del almacenamiento persistente
  static Future<List<AcrosticoEjercicio>> obtenerEjerciciosAcrosticos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ejerciciosJsonString = prefs.getString(_ejerciciosAcrosticoKey);
      
      if (ejerciciosJsonString == null || ejerciciosJsonString.isEmpty) {
        return [];
      }
      
      final ejerciciosJson = jsonDecode(ejerciciosJsonString) as List<dynamic>;
      return ejerciciosJson
          .map((json) => AcrosticoEjercicio.fromJson(json as Map<String, dynamic>))
          .cast<AcrosticoEjercicio>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Elimina todos los ejercicios de acróstico guardados
  static Future<bool> eliminarTodosEjerciciosAcrosticos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_ejerciciosAcrosticoKey);
    } catch (e) {
      return false;
    }
  }

  /// Guarda todos los libros PDF en el almacenamiento persistente
  static Future<bool> guardarLibrosPDF(List<LibroPDF> libros) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir libros a JSON
      final librosJson = libros.map((libro) => libro.toJson()).toList();
      final librosJsonString = jsonEncode(librosJson);
      
      // Guardar en clave principal
      await prefs.setString(_librosPDFKey, librosJsonString);
      // Guardar copia de seguridad
      await prefs.setString(_librosPDFKeyBackup, librosJsonString);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Recupera todos los libros PDF del almacenamiento persistente
  static Future<List<LibroPDF>> obtenerLibrosPDF() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Intentar con clave principal primero
      String? librosJsonString = prefs.getString(_librosPDFKey);
      
      // Si no hay datos en clave principal, intentar con la copia de seguridad
      if (librosJsonString == null || librosJsonString.isEmpty) {
        librosJsonString = prefs.getString(_librosPDFKeyBackup);
      }
      
      if (librosJsonString == null || librosJsonString.isEmpty) {
        return [];
      }
      
      final librosJson = jsonDecode(librosJsonString) as List<dynamic>;
      return librosJson
          .map((json) => LibroPDF.fromJson(json as Map<String, dynamic>))
          .cast<LibroPDF>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Elimina todos los libros PDF guardados
  static Future<bool> eliminarTodosLibrosPDF() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_librosPDFKey);
      await prefs.remove(_librosPDFKeyBackup);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Guarda un solo libro PDF
  static Future<bool> guardarLibroPDF(LibroPDF libro) async {
    try {
      // Obtener libros existentes
      final librosExistentes = await obtenerLibrosPDF();
      
      // Eliminar libro con mismo ID si existe
      final librosActualizados = librosExistentes.where((l) => l.id != libro.id).toList();
      librosActualizados.add(libro);
      
      // Guardar lista actualizada
      return await guardarLibrosPDF(librosActualizados);
    } catch (e) {
      return false;
    }
  }

  /// Elimina un libro PDF por ID
  static Future<bool> eliminarLibroPDF(String libroId) async {
    try {
      // Obtener libros existentes
      final librosExistentes = await obtenerLibrosPDF();
      
      // Eliminar libro con ID especificado
      final librosActualizados = librosExistentes.where((l) => l.id != libroId).toList();
      
      // Guardar lista actualizada
      return await guardarLibrosPDF(librosActualizados);
    } catch (e) {
      return false;
    }
  }
}
