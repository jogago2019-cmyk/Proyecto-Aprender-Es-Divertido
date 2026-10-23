// Modelo para un ejercicio de acróstico
import 'dart:ui';
import '../services/ejercicio_storage_service.dart';

// Helper function to safely parse List<dynamic> to List<String>
List<String> _safeParseStringList(dynamic data) {
  if (data == null) return [];
  if (data is List<String>) return data;
  if (data is List) {
    return data
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .cast<String>()
      .toList();
  }
  return [];
}

class AcrosticoEjercicio {
  String id;
  String titulo;
  String imagenPath; // Path local o URL de la imagen de cabecera
  List<String> palabras; // Lista de palabras del acróstico
  Color colorLetras; // Color seleccionado para las letras
  List<List<int>> letrasOcultasPorPalabra; // Lista de índices de letras a ocultar en cada palabra
  String pista; // Pista opcional para el alumno
  List<String> alumnosAsignados; // Lista de IDs de alumnos que pueden ver este ejercicio
  bool esParaTodos; // Si es true, todos los alumnos pueden verlo

  AcrosticoEjercicio({
    required this.id,
    required this.titulo,
    required this.imagenPath,
    required this.palabras,
    required this.colorLetras,
    List<List<int>>? letrasOcultasPorPalabra,
    this.pista = '',
    this.alumnosAsignados = const [],
    this.esParaTodos = true,
  }) : letrasOcultasPorPalabra = letrasOcultasPorPalabra ??
       List.generate(palabras.length, (_) => <int>[]); // Por defecto: no ocultar ninguna letra

  // Crear ejercicio desde datos básicos
  factory AcrosticoEjercicio.fromDatos({
    required String id,
    required String titulo,
    required String imagenPath,
    required List<String> palabras,
    required Color colorLetras,
    List<List<int>>? letrasOcultasPorPalabra,
    String pista = '',
    List<String> alumnosAsignados = const [],
    bool esParaTodos = true,
  }) {
    return AcrosticoEjercicio(
      id: id,
      titulo: titulo,
      imagenPath: imagenPath,
      palabras: palabras,
      colorLetras: colorLetras,
      letrasOcultasPorPalabra: letrasOcultasPorPalabra,
      pista: pista,
      alumnosAsignados: alumnosAsignados,
      esParaTodos: esParaTodos,
    );
  }

  // Obtener las palabras con las letras ocultas (según índices por palabra)
  List<String> get palabrasParaAlumno {
    return palabras.asMap().entries.map((entry) {
      final palabra = entry.value;
      final indicesOcultos = letrasOcultasPorPalabra[entry.key];
      
      if (indicesOcultos.isEmpty) {
        return palabra; // No ocultar nada si no hay índices
      }
      
      // Crear nueva palabra con las letras ocultas reemplazadas por '_'
      final caracteres = palabra.split('');
      for (final indice in indicesOcultos) {
        if (indice >= 0 && indice < caracteres.length) {
          caracteres[indice] = '_';
        }
      }
      return caracteres.join();
    }).toList();
  }

  // Obtener las palabras con las letras ocultas marcadas (para previsualización)
  List<String> get palabrasConLetraMarcada {
    return palabras.asMap().entries.map((entry) {
      final palabra = entry.value;
      final indicesOcultos = letrasOcultasPorPalabra[entry.key];
      
      if (indicesOcultos.isEmpty) {
        return palabra; // No marcar nada si no hay índices ocultos
      }
      
      // Crear palabra con las letras ocultas marcadas
      final caracteres = palabra.split('');
      for (final indice in indicesOcultos) {
        if (indice >= 0 && indice < caracteres.length) {
          caracteres[indice] = '*'; // Marcar con asterisco o cualquier otro símbolo
        }
      }
      return caracteres.join();
    }).toList();
  }

  // Obtener lista de posiciones de letras ocultas (para UI)
  // Ahora devuelve List<List<int>> para compatibilidad
  List<List<int>> get posicionesLetrasOcultas {
    return letrasOcultasPorPalabra.map((indices) => List<int>.from(indices)).toList();
  }

  // Verificar si una posición de letra está oculta para una palabra
  bool estaLetraOculta(int palabraIndex, int letraIndex) {
    if (palabraIndex < 0 || palabraIndex >= letrasOcultasPorPalabra.length) return false;
    final indicesOcultos = letrasOcultasPorPalabra[palabraIndex];
    return indicesOcultos.contains(letraIndex);
  }

  // Verificar si una posición de letra es válida para una palabra
  bool esPosicionValida(int palabraIndex, int letraIndex) {
    if (palabraIndex < 0 || palabraIndex >= palabras.length) return false;
    if (letraIndex < 0) return true; // -1 significa no ocultar
    return letraIndex < palabras[palabraIndex].length;
  }

  // Obtener la letra inicial del acróstico (primera letra de cada palabra)
  String get letrasAcrostico {
    if (palabras.isEmpty) return '';
    return palabras.map((palabra) => palabra.isNotEmpty ? palabra[0].toUpperCase() : '').join();
  }

  // Obtener la letra inicial del acróstico con las palabras para el alumno
  String get letrasAcrosticoParaAlumno {
    final palabrasAlumno = palabrasParaAlumno;
    if (palabrasAlumno.isEmpty) return '';
    
    return palabrasAlumno.map((palabra) => 
      palabra.isNotEmpty ? (palabra[0] == '_' ? '_' : palabra[0].toUpperCase()) : ''
    ).join();
  }

  // Verificar si una respuesta es correcta
  bool esRespuestaCorrecta(List<String> respuestas) {
    if (respuestas.length != palabras.length) {
      return false;
    }
    
    for (int i = 0; i < palabras.length; i++) {
      if (respuestas[i].toLowerCase() != palabras[i].toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  // Verificar si este ejercicio es visible para un alumno específico
  bool esVisibleParaAlumno(String? alumnoId) {
    if (esParaTodos) return true;
    if (alumnoId == null) return false; // Si no hay alumno seleccionado, no mostrar
    return alumnosAsignados.contains(alumnoId);
  }

  // Copiar con nuevos valores
  AcrosticoEjercicio copyWith({
    String? id,
    String? titulo,
    String? imagenPath,
    List<String>? palabras,
    Color? colorLetras,
    List<List<int>>? letrasOcultasPorPalabra,
    String? pista,
    List<String>? alumnosAsignados,
    bool? esParaTodos,
  }) {
    return AcrosticoEjercicio(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      imagenPath: imagenPath ?? this.imagenPath,
      palabras: palabras ?? this.palabras,
      colorLetras: colorLetras ?? this.colorLetras,
      letrasOcultasPorPalabra: letrasOcultasPorPalabra ?? this.letrasOcultasPorPalabra,
      pista: pista ?? this.pista,
      alumnosAsignados: alumnosAsignados ?? this.alumnosAsignados,
      esParaTodos: esParaTodos ?? this.esParaTodos,
    );
  }

  // Convertir a JSON para guardado (Color a int value)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagenPath': imagenPath,
      'palabras': palabras,
      'colorLetras': colorLetras.toARGB32().toRadixString(16),
      'letrasOcultasPorPalabra': letrasOcultasPorPalabra,
      'pista': pista,
      'alumnosAsignados': alumnosAsignados,
      'esParaTodos': esParaTodos,
    };
  }

  // Crear desde JSON
  factory AcrosticoEjercicio.fromJson(Map<String, dynamic> json) {
    // Cargar color
    Color colorLetras = const Color(0xFF000000); // Negro por defecto
    if (json['colorLetras'] != null) {
      try {
        final colorValue = json['colorLetras'];
        if (colorValue is int) {
          colorLetras = Color(colorValue);
        } else if (colorValue is String) {
          final intValue = int.tryParse(colorValue, radix: 16);
          colorLetras = intValue != null ? Color(intValue) : const Color(0xFF000000);
        }
      } catch (e) {
        colorLetras = const Color(0xFF000000);
      }
    }

    // Cargar alumnos asignados
    List<String> alumnosAsignados = [];
    if (json['alumnosAsignados'] != null) {
      final dynamic data = json['alumnosAsignados'];
      if (data is List) {
        alumnosAsignados = data.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).cast<String>().toList();
      }
    }
    
    // Cargar esParaTodos (por defecto true para compatibilidad)
    bool esParaTodos = json['esParaTodos'] as bool? ?? true;

    // Cargar letrasOcultasPorPalabra
    List<List<int>> letrasOcultasPorPalabra = [];
    if (json['letrasOcultasPorPalabra'] != null) {
      try {
        final dynamic data = json['letrasOcultasPorPalabra'];
        if (data is List) {
          // Manejar ambos formatos: antiguo List<int> y nuevo List<List<int>>
          if (data.isNotEmpty && data[0] is List) {
            // Formato nuevo: List<List<int>>
            letrasOcultasPorPalabra = data.map((item) {
              if (item is List) {
                return item.map((subItem) => subItem is int ? subItem : (subItem is num ? subItem.toInt() : -1)).cast<int>().toList();
              }
              return <int>[];
            }).cast<List<int>>().toList();
          } else {
            // Formato antiguo: List<int> - convertir a List<List<int>>
            final oldList = data.map((item) => item is int ? item : (item is num ? item.toInt() : -1)).cast<int>().toList();
            letrasOcultasPorPalabra = oldList.map((index) => index >= 0 ? [index] : <int>[]).toList();
          }
        }
      } catch (e) {
        // Si falla, crear lista vacía para cada palabra
        final palabras = _safeParseStringList(json['palabras']);
        letrasOcultasPorPalabra = List.generate(palabras.length, (_) => <int>[]);
      }
    } else if (json['letraParaQuitar'] != null) {
      // Compatibilidad con versión anterior: convertir letra global a lista de listas
      final letraGlobal = json['letraParaQuitar'] as int? ?? -1;
      final palabras = _safeParseStringList(json['palabras']);
      
      // Buscar la letra en cada palabra y ocultar todas sus apariciones
      letrasOcultasPorPalabra = palabras.map((palabra) {
        if (letraGlobal < 0 || letraGlobal >= 26) return <int>[];
        final letraABuscar = String.fromCharCode('A'.codeUnitAt(0) + letraGlobal);
        final indices = <int>[];
        for (int i = 0; i < palabra.length; i++) {
          if (palabra[i].toUpperCase() == letraABuscar) {
            indices.add(i);
          }
        }
        return indices;
      }).toList();
    }

    // Obtener palabras para crear el ejercicio
    final palabras = _safeParseStringList(json['palabras']);
    
    // Asegurar que letrasOcultasPorPalabra tenga el mismo largo que palabras
    if (letrasOcultasPorPalabra.length != palabras.length) {
      // Si no coincide, inicializar con lista vacía para todas
      letrasOcultasPorPalabra = List.generate(palabras.length, (_) => <int>[]);
    }

    return AcrosticoEjercicio(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      imagenPath: json['imagenPath'] ?? '',
      palabras: palabras,
      colorLetras: colorLetras,
      letrasOcultasPorPalabra: letrasOcultasPorPalabra,
      pista: json['pista'] ?? '',
      alumnosAsignados: alumnosAsignados,
      esParaTodos: esParaTodos,
    );
  }
}

// Clase para gestionar la colección de ejercicios de acróstico
class AcrosticoRepository {
  static final List<AcrosticoEjercicio> _ejercicios = [];
  static bool _cargadoInicial = false;

  // Inicializar el repositorio (cargar ejercicios guardados)
  static Future<void> init() async {
    if (_cargadoInicial) return;
    
    try {
      final ejerciciosGuardados = await EjercicioStorageService.obtenerEjerciciosAcrosticos();
      _ejercicios.clear();
      _ejercicios.addAll(ejerciciosGuardados);
      _cargadoInicial = true;
    } catch (e) {
      // Si hay error, continuar con lista vacía
      _cargadoInicial = true;
    }
  }

  static Future<bool> _guardarEnAlmacenamiento() async {
    try {
      return await EjercicioStorageService.guardarEjerciciosAcrosticos([..._ejercicios]);
    } catch (e) {
      return false;
    }
  }

  // Obtener todos los ejercicios
  static List<AcrosticoEjercicio> getEjercicios() {
    return [..._ejercicios];
  }

  // Agregar un nuevo ejercicio
  static Future<void> agregarEjercicio(AcrosticoEjercicio ejercicio) async {
    // Verificar si ya existe un ejercicio con el mismo ID
    _ejercicios.removeWhere((e) => e.id == ejercicio.id);
    _ejercicios.add(ejercicio);
    
    // Guardar en almacenamiento persistente
    await _guardarEnAlmacenamiento();
  }

  // Eliminar ejercicio por ID
  static Future<void> eliminarEjercicio(String id) async {
    _ejercicios.removeWhere((e) => e.id == id);
    
    // Guardar en almacenamiento persistente
    await _guardarEnAlmacenamiento();
  }

  // Obtener ejercicio por ID
  static AcrosticoEjercicio? getEjercicioPorId(String id) {
    try {
      return _ejercicios.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Generar ID único
  static String generarId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Limpiar todos los ejercicios
  static Future<void> limpiarEjercicios() async {
    _ejercicios.clear();
    await _guardarEnAlmacenamiento();
  }

  // Cargar ejercicios desde almacenamiento (para recargar manualmente)
  static Future<void> cargarEjercicios() async {
    await init();
  }

  // Obtener ejercicios filtrados por alumno
  static List<AcrosticoEjercicio> getEjerciciosParaAlumno(String? alumnoId) {
    if (alumnoId == null) {
      // Si no hay alumno seleccionado, devolver ejercicios para todos
      return _ejercicios.where((e) => e.esParaTodos).toList();
    }
    return _ejercicios.where((e) => e.esVisibleParaAlumno(alumnoId)).toList();
  }

  // Obtener ejercicios creados para todos
  static List<AcrosticoEjercicio> getEjerciciosParaTodos() {
    return _ejercicios.where((e) => e.esParaTodos).toList();
  }

  // Obtener ejercicios creados para un alumno específico
  static List<AcrosticoEjercicio> getEjerciciosParaAlumnoEspecifico(String alumnoId) {
    return _ejercicios.where((e) => !e.esParaTodos && e.alumnosAsignados.contains(alumnoId)).toList();
  }
}
