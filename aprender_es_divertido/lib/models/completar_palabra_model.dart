// Modelo para un ejercicio de completar palabra
import '../services/ejercicio_storage_service.dart';

class CompletarPalabraEjercicio {
  String id;
  String palabraCompleta;
  String imagenPath; // Path local o URL de la imagen
  List<int> posicionesFaltantes; // Posiciones donde van las letras faltantes (0-based)
  String pista; // Pista opcional para el alumno
  List<String> alumnosAsignados; // Lista de IDs de alumnos que pueden ver este ejercicio
  bool esParaTodos; // Si es true, todos los alumnos pueden verlo

  CompletarPalabraEjercicio({
    required this.id,
    required this.palabraCompleta,
    required this.imagenPath,
    required this.posicionesFaltantes,
    this.pista = '',
    this.alumnosAsignados = const [],
    this.esParaTodos = true,
  });

  // Crear ejercicio desde palabra completa y posiciones
  factory CompletarPalabraEjercicio.fromPalabraYPosiciones({
    required String id,
    required String palabraCompleta,
    required String imagenPath,
    required List<int> posicionesFaltantes,
    String pista = '',
    List<String> alumnosAsignados = const [],
    bool esParaTodos = true,
  }) {
    return CompletarPalabraEjercicio(
      id: id,
      palabraCompleta: palabraCompleta,
      imagenPath: imagenPath,
      posicionesFaltantes: posicionesFaltantes,
      pista: pista,
      alumnosAsignados: alumnosAsignados,
      esParaTodos: esParaTodos,
    );
  }

  // Generar palabra con guiones bajos para el alumno
  String get palabraParaAlumno {
    if (posicionesFaltantes.isEmpty) {
      return palabraCompleta;
    }
    
    // Ordenar posiciones para procesar en orden descendente
    // para que los indices no se desplace al reemplazar
    final posicionesOrdenadas = [...posicionesFaltantes]..sort((a, b) => b.compareTo(a));
    String resultado = palabraCompleta;
    
    for (final pos in posicionesOrdenadas) {
      if (pos >= 0 && pos < resultado.length) {
        resultado = '${resultado.substring(0, pos)}_${resultado.substring(pos + 1)}';
      }
    }
    
    return resultado;
  }

  // Obtener las letras que faltan (para verificar respuestas)
  List<String> get letrasFaltantes {
    return posicionesFaltantes
        .where((pos) => pos >= 0 && pos < palabraCompleta.length)
        .map((pos) => palabraCompleta[pos])
        .toList();
  }

  // Verificar si una letra en una posicion especifica es correcta
  bool esLetraCorrectaEnPosicion(int posicion, String letra) {
    if (posicion < 0 || posicion >= palabraCompleta.length) {
      return false;
    }
    if (!posicionesFaltantes.contains(posicion)) {
      return false;
    }
    return letra.toLowerCase() == palabraCompleta[posicion].toLowerCase();
  }

  // Verificar si todas las letras proporcionadas son correctas
  bool sonLetrasCorrectas(Map<int, String> letrasRespuesta) {
    // Verificar que se proporcionaron respuestas para todas las posiciones faltantes
    if (letrasRespuesta.length != posicionesFaltantes.length) {
      return false;
    }
    
    for (final pos in posicionesFaltantes) {
      if (!letrasRespuesta.containsKey(pos)) {
        return false;
      }
      if (!esLetraCorrectaEnPosicion(pos, letrasRespuesta[pos]!)) {
        return false;
      }
    }
    return true;
  }

  // Obtener las letras correctas para las posiciones faltantes
  Map<int, String> get letrasCorrectas {
    final mapa = <int, String>{};
    for (final pos in posicionesFaltantes) {
      if (pos >= 0 && pos < palabraCompleta.length) {
        mapa[pos] = palabraCompleta[pos];
      }
    }
    return mapa;
  }

  // Verificar si este ejercicio es visible para un alumno específico
  bool esVisibleParaAlumno(String? alumnoId) {
    if (esParaTodos) return true;
    if (alumnoId == null) return false; // Si no hay alumno seleccionado, no mostrar
    return alumnosAsignados.contains(alumnoId);
  }

  // Copiar con nueva asignación de alumnos
  CompletarPalabraEjercicio copyWith({
    String? id,
    String? palabraCompleta,
    String? imagenPath,
    List<int>? posicionesFaltantes,
    String? pista,
    List<String>? alumnosAsignados,
    bool? esParaTodos,
  }) {
    return CompletarPalabraEjercicio(
      id: id ?? this.id,
      palabraCompleta: palabraCompleta ?? this.palabraCompleta,
      imagenPath: imagenPath ?? this.imagenPath,
      posicionesFaltantes: posicionesFaltantes ?? this.posicionesFaltantes,
      pista: pista ?? this.pista,
      alumnosAsignados: alumnosAsignados ?? this.alumnosAsignados,
      esParaTodos: esParaTodos ?? this.esParaTodos,
    );
  }

  // Convertir a JSON para guardado
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'palabraCompleta': palabraCompleta,
      'imagenPath': imagenPath,
      'posicionesFaltantes': posicionesFaltantes,
      'pista': pista,
      'alumnosAsignados': alumnosAsignados,
      'esParaTodos': esParaTodos,
    };
  }

  // Crear desde JSON
  factory CompletarPalabraEjercicio.fromJson(Map<String, dynamic> json) {
    // Para mantener compatibilidad con versiones antiguas
    final posiciones = json['posicionesFaltantes'] as List?;
    final posicionLegacy = json['posicionLetra'] as int?;
    
    List<int> posicionesFaltantes = [];
    if (posiciones != null) {
      posicionesFaltantes = List<int>.from(posiciones);
    } else if (posicionLegacy != null) {
      // Convertir formato antiguo (una sola posicion) al nuevo
      posicionesFaltantes = [posicionLegacy];
    }

    // Cargar alumnos asignados
    List<String> alumnosAsignados = [];
    if (json['alumnosAsignados'] != null) {
      alumnosAsignados = List<String>.from(json['alumnosAsignados']);
    }
    
    // Cargar esParaTodos (por defecto true para compatibilidad)
    bool esParaTodos = json['esParaTodos'] as bool? ?? true;

    return CompletarPalabraEjercicio(
      id: json['id'] ?? '',
      palabraCompleta: json['palabraCompleta'] ?? '',
      imagenPath: json['imagenPath'] ?? '',
      posicionesFaltantes: posicionesFaltantes,
      pista: json['pista'] ?? '',
      alumnosAsignados: alumnosAsignados,
      esParaTodos: esParaTodos,
    );
  }
}

// Clase para gestionar la coleccion de ejercicios
class CompletarPalabraRepository {
  static final List<CompletarPalabraEjercicio> _ejercicios = [];
  static bool _cargadoInicial = false;

  // Inicializar el repositorio (cargar ejercicios guardados)
  static Future<void> init() async {
    if (_cargadoInicial) return;
    
    try {
      final ejerciciosGuardados = await EjercicioStorageService.obtenerEjercicios();
      _ejercicios.clear();
      _ejercicios.addAll(ejerciciosGuardados);
      _cargadoInicial = true;
    } catch (e) {
      // Si hay error, continuar con lista vacia
      _cargadoInicial = true;
    }
  }

  static Future<bool> _guardarEnAlmacenamiento() async {
    try {
      return await EjercicioStorageService.guardarEjercicios([..._ejercicios]);
    } catch (e) {
      return false;
    }
  }

  // Obtener todos los ejercicios
  static List<CompletarPalabraEjercicio> getEjercicios() {
    return [..._ejercicios];
  }

  // Agregar un nuevo ejercicio
  static Future<void> agregarEjercicio(CompletarPalabraEjercicio ejercicio) async {
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
  static CompletarPalabraEjercicio? getEjercicioPorId(String id) {
    try {
      return _ejercicios.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Generar ID unico
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
  static List<CompletarPalabraEjercicio> getEjerciciosParaAlumno(String? alumnoId) {
    if (alumnoId == null) {
      // Si no hay alumno seleccionado, devolver ejercicios para todos
      return _ejercicios.where((e) => e.esParaTodos).toList();
    }
    return _ejercicios.where((e) => e.esVisibleParaAlumno(alumnoId)).toList();
  }

  // Obtener ejercicios creados para todos
  static List<CompletarPalabraEjercicio> getEjerciciosParaTodos() {
    return _ejercicios.where((e) => e.esParaTodos).toList();
  }

  // Obtener ejercicios creados para un alumno específico
  static List<CompletarPalabraEjercicio> getEjerciciosParaAlumnoEspecifico(String alumnoId) {
    return _ejercicios.where((e) => !e.esParaTodos && e.alumnosAsignados.contains(alumnoId)).toList();
  }
}
