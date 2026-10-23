// Modelo para un ejercicio de ordenar palabras (palabras desordenadas)
import '../services/ejercicio_storage_service.dart';

class OrdenarPalabraEjercicio {
  String id;
  String palabraCorrecta;
  String imagenPath; // Path local o URL de la imagen
  String pista; // Pista opcional para el alumno
  String? _palabraDesordenadaCache;
  List<String> alumnosAsignados; // Lista de IDs de alumnos que pueden ver este ejercicio
  bool esParaTodos; // Si es true, todos los alumnos pueden verlo

  OrdenarPalabraEjercicio({
    required this.id,
    required this.palabraCorrecta,
    required this.imagenPath,
    this.pista = '',
    this.alumnosAsignados = const [],
    this.esParaTodos = true,
  });

  // Crear ejercicio desde palabra correcta
  factory OrdenarPalabraEjercicio.fromPalabra({
    required String id,
    required String palabraCorrecta,
    required String imagenPath,
    String pista = '',
    List<String> alumnosAsignados = const [],
    bool esParaTodos = true,
  }) {
    return OrdenarPalabraEjercicio(
      id: id,
      palabraCorrecta: palabraCorrecta,
      imagenPath: imagenPath,
      pista: pista,
      alumnosAsignados: alumnosAsignados,
      esParaTodos: esParaTodos,
    );
  }

  // Generar palabra desordenada (mezclando las letras)
  String get palabraDesordenada {
    if (_palabraDesordenadaCache == null) {
      final letras = palabraCorrecta.split('');
      letras.shuffle();
      _palabraDesordenadaCache = letras.join('');
    }
    return _palabraDesordenadaCache!;
  }

  // Verificar si una palabra proporcionada es correcta
  bool esPalabraCorrecta(String palabraRespuesta) {
    return palabraRespuesta.toLowerCase() == palabraCorrecta.toLowerCase();
  }

  // Convertir a JSON para guardado
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'palabraCorrecta': palabraCorrecta,
      'imagenPath': imagenPath,
      'pista': pista,
      'alumnosAsignados': alumnosAsignados,
      'esParaTodos': esParaTodos,
    };
  }

  // Crear desde JSON
  factory OrdenarPalabraEjercicio.fromJson(Map<String, dynamic> json) {
    // Cargar alumnos asignados
    List<String> alumnosAsignados = [];
    if (json['alumnosAsignados'] != null) {
      alumnosAsignados = List<String>.from(json['alumnosAsignados']);
    }
    
    // Cargar esParaTodos (por defecto true para compatibilidad)
    bool esParaTodos = json['esParaTodos'] as bool? ?? true;

    return OrdenarPalabraEjercicio(
      id: json['id'] ?? '',
      palabraCorrecta: json['palabraCorrecta'] ?? '',
      imagenPath: json['imagenPath'] ?? '',
      pista: json['pista'] ?? '',
      alumnosAsignados: alumnosAsignados,
      esParaTodos: esParaTodos,
    );
  }

  // Verificar si este ejercicio es visible para un alumno específico
  bool esVisibleParaAlumno(String? alumnoId) {
    if (esParaTodos) return true;
    if (alumnoId == null) return false; // Si no hay alumno seleccionado, no mostrar
    return alumnosAsignados.contains(alumnoId);
  }

  // Copiar con nueva asignación de alumnos
  OrdenarPalabraEjercicio copyWith({
    String? id,
    String? palabraCorrecta,
    String? imagenPath,
    String? pista,
    List<String>? alumnosAsignados,
    bool? esParaTodos,
  }) {
    return OrdenarPalabraEjercicio(
      id: id ?? this.id,
      palabraCorrecta: palabraCorrecta ?? this.palabraCorrecta,
      imagenPath: imagenPath ?? this.imagenPath,
      pista: pista ?? this.pista,
      alumnosAsignados: alumnosAsignados ?? this.alumnosAsignados,
      esParaTodos: esParaTodos ?? this.esParaTodos,
    );
  }
}

// Clase para gestionar la coleccion de ejercicios de ordenar palabras
class OrdenarPalabraRepository {
  static final List<OrdenarPalabraEjercicio> _ejercicios = [];
  static bool _cargadoInicial = false;

  // Inicializar el repositorio (cargar ejercicios guardados)
  static Future<void> init() async {
    if (_cargadoInicial) return;
    
    try {
      final ejerciciosGuardados = await EjercicioStorageService.obtenerEjerciciosOrdenar();
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
      return await EjercicioStorageService.guardarEjerciciosOrdenar([..._ejercicios]);
    } catch (e) {
      return false;
    }
  }

  // Obtener todos los ejercicios
  static List<OrdenarPalabraEjercicio> getEjercicios() {
    return [..._ejercicios];
  }

  // Agregar un nuevo ejercicio
  static Future<void> agregarEjercicio(OrdenarPalabraEjercicio ejercicio) async {
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
  static OrdenarPalabraEjercicio? getEjercicioPorId(String id) {
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
  static List<OrdenarPalabraEjercicio> getEjerciciosParaAlumno(String? alumnoId) {
    if (alumnoId == null) {
      // Si no hay alumno seleccionado, devolver ejercicios para todos
      return _ejercicios.where((e) => e.esParaTodos).toList();
    }
    return _ejercicios.where((e) => e.esVisibleParaAlumno(alumnoId)).toList();
  }

  // Obtener ejercicios creados para todos
  static List<OrdenarPalabraEjercicio> getEjerciciosParaTodos() {
    return _ejercicios.where((e) => e.esParaTodos).toList();
  }

  // Obtener ejercicios creados para un alumno específico
  static List<OrdenarPalabraEjercicio> getEjerciciosParaAlumnoEspecifico(String alumnoId) {
    return _ejercicios.where((e) => !e.esParaTodos && e.alumnosAsignados.contains(alumnoId)).toList();
  }
}
