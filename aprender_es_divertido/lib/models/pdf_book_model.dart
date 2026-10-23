// Modelo para libros PDF con preguntas de multiple choice
import '../services/ejercicio_storage_service.dart';

// Enum para el tipo de actividad al final del libro
enum TipoActividadFinal {
  preguntas,      // Solo preguntas
  acrostico,     // Solo acróstico
  ambos,         // Preguntas y acróstico
  nada,          // Solo lectura sin actividades
}

// Modelo para una opción de respuesta en una pregunta de multiple choice
class OpcionRespuesta {
  String id;
  String texto;
  bool esCorrecta;

  OpcionRespuesta({
    required this.id,
    required this.texto,
    this.esCorrecta = false,
  });

  // Crear desde JSON
  factory OpcionRespuesta.fromJson(Map<String, dynamic> json) {
    return OpcionRespuesta(
      id: json['id'] ?? '',
      texto: json['texto'] ?? '',
      esCorrecta: json['esCorrecta'] as bool? ?? false,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': texto,
      'esCorrecta': esCorrecta,
    };
  }

  // Copiar con nuevos valores
  OpcionRespuesta copyWith({
    String? id,
    String? texto,
    bool? esCorrecta,
  }) {
    return OpcionRespuesta(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      esCorrecta: esCorrecta ?? this.esCorrecta,
    );
  }
}

// Modelo para una pregunta de multiple choice
class PreguntaMultipleChoice {
  String id;
  String textoPregunta;
  List<OpcionRespuesta> opciones;
  int paginaAsociada; // Página del PDF a la que pertenece (-1 si es general)
  String? explicacion; // Explicación opcional

  PreguntaMultipleChoice({
    required this.id,
    required this.textoPregunta,
    required this.opciones,
    this.paginaAsociada = -1,
    this.explicacion,
  });

  // Crear pregunta nueva
  factory PreguntaMultipleChoice.nueva({
    required String textoPregunta,
    required List<OpcionRespuesta> opciones,
    int paginaAsociada = -1,
    String? explicacion,
  }) {
    return PreguntaMultipleChoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      textoPregunta: textoPregunta,
      opciones: opciones,
      paginaAsociada: paginaAsociada,
      explicacion: explicacion,
    );
  }

  // Obtener la respuesta correcta
  OpcionRespuesta? get respuestaCorrecta {
    try {
      return opciones.firstWhere((opcion) => opcion.esCorrecta);
    } catch (e) {
      return null;
    }
  }

  // Verificar si una opción es la correcta
  bool esOpcionCorrecta(String opcionId) {
    try {
      final opcion = opciones.firstWhere((o) => o.id == opcionId);
      return opcion.esCorrecta;
    } catch (e) {
      return false;
    }
  }

  // Verificar si hay al menos una respuesta correcta definida
  bool get tieneRespuestaCorrecta {
    return opciones.any((opcion) => opcion.esCorrecta);
  }

  // Validar que la pregunta tenga al menos 2 opciones y una correcta
  bool get esValida {
    return opciones.length >= 2 && tieneRespuestaCorrecta;
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'textoPregunta': textoPregunta,
      'opciones': opciones.map((o) => o.toJson()).toList(),
      'paginaAsociada': paginaAsociada,
      'explicacion': explicacion,
    };
  }

  // Crear desde JSON
  factory PreguntaMultipleChoice.fromJson(Map<String, dynamic> json) {
    final opcionesList = (json['opciones'] as List<dynamic>? ?? []).map((o) {
      if (o is Map<String, dynamic>) {
        return OpcionRespuesta.fromJson(o);
      }
      return OpcionRespuesta(id: '', texto: '', esCorrecta: false);
    }).toList();

    return PreguntaMultipleChoice(
      id: json['id'] ?? '',
      textoPregunta: json['textoPregunta'] ?? '',
      opciones: opcionesList,
      paginaAsociada: json['paginaAsociada'] as int? ?? -1,
      explicacion: json['explicacion'] as String?, 
    );
  }

  // Copiar con nuevos valores
  PreguntaMultipleChoice copyWith({
    String? id,
    String? textoPregunta,
    List<OpcionRespuesta>? opciones,
    int? paginaAsociada,
    String? explicacion,
  }) {
    return PreguntaMultipleChoice(
      id: id ?? this.id,
      textoPregunta: textoPregunta ?? this.textoPregunta,
      opciones: opciones ?? this.opciones,
      paginaAsociada: paginaAsociada ?? this.paginaAsociada,
      explicacion: explicacion ?? this.explicacion,
    );
  }
}

// Modelo principal para un libro PDF con preguntas
class LibroPDF {
  String id;
  String titulo;
  String rutaPDF; // Ruta local al archivo PDF
  int paginaActual; // Última página vista
  List<PreguntaMultipleChoice> preguntas;
  TipoActividadFinal tipoActividadFinal;
  String? idAcrosticoAsociado; // ID del acróstico generado a partir de este libro
  List<String> alumnosAsignados; // Lista de IDs de alumnos
  bool esParaTodos;
  DateTime fechaCreacion;

  LibroPDF({
    required this.id,
    required this.titulo,
    required this.rutaPDF,
    this.paginaActual = 1,
    this.preguntas = const [],
    this.tipoActividadFinal = TipoActividadFinal.nada,
    this.idAcrosticoAsociado,
    this.alumnosAsignados = const [],
    this.esParaTodos = true,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Crear libro nuevo
  factory LibroPDF.nuevo({
    required String titulo,
    required String rutaPDF,
    List<PreguntaMultipleChoice> preguntas = const [],
    TipoActividadFinal tipoActividadFinal = TipoActividadFinal.nada,
    String? idAcrosticoAsociado,
    List<String> alumnosAsignados = const [],
    bool esParaTodos = true,
  }) {
    return LibroPDF(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo,
      rutaPDF: rutaPDF,
      paginaActual: 1,
      preguntas: preguntas,
      tipoActividadFinal: tipoActividadFinal,
      idAcrosticoAsociado: idAcrosticoAsociado,
      alumnosAsignados: alumnosAsignados,
      esParaTodos: esParaTodos,
      fechaCreacion: DateTime.now(),
    );
  }

  // Obtener preguntas para una página específica
  List<PreguntaMultipleChoice> getPreguntasPorPagina(int pagina) {
    return preguntas.where((p) => p.paginaAsociada == pagina).toList();
  }

  // Obtener preguntas generales (no asociadas a ninguna página)
  List<PreguntaMultipleChoice> get preguntasGenerales {
    return preguntas.where((p) => p.paginaAsociada == -1).toList();
  }

  // Obtener todas las páginas que tienen preguntas asociadas
  List<int> get paginasConPreguntas {
    final paginas = <int>{};
    for (final pregunta in preguntas) {
      if (pregunta.paginaAsociada >= 1) {
        paginas.add(pregunta.paginaAsociada);
      }
    }
    return paginas.toList()..sort();
  }

  // Verificar si el libro tiene preguntas
  bool get tienePreguntas {
    return preguntas.isNotEmpty;
  }

  // Verificar si el libro tiene acróstico asociado
  bool get tieneAcrostico {
    return idAcrosticoAsociado != null && idAcrosticoAsociado!.isNotEmpty;
  }

  // Verificar si el libro requiere alguna actividad final
  bool get requiereActividadFinal {
    return tipoActividadFinal != TipoActividadFinal.nada;
  }

  // Verificar si el libro es visible para un alumno específico
  bool esVisibleParaAlumno(String? alumnoId) {
    if (esParaTodos) return true;
    if (alumnoId == null) return false;
    return alumnosAsignados.contains(alumnoId);
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'rutaPDF': rutaPDF,
      'paginaActual': paginaActual,
      'preguntas': preguntas.map((p) => p.toJson()).toList(),
      'tipoActividadFinal': tipoActividadFinal.name,
      'idAcrosticoAsociado': idAcrosticoAsociado,
      'alumnosAsignados': alumnosAsignados,
      'esParaTodos': esParaTodos,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  // Crear desde JSON
  factory LibroPDF.fromJson(Map<String, dynamic> json) {
    // Parsear tipo de actividad
    TipoActividadFinal tipoActividad = TipoActividadFinal.nada;
    final tipoStr = json['tipoActividadFinal'] as String?;
    if (tipoStr != null) {
      for (final value in TipoActividadFinal.values) {
        if (value.name == tipoStr) {
          tipoActividad = value;
          break;
        }
      }
    }

    // Parsear preguntas
    List<PreguntaMultipleChoice> preguntas = [];
    final preguntasList = json['preguntas'] as List<dynamic>? ?? [];
    for (final p in preguntasList) {
      if (p is Map<String, dynamic>) {
        preguntas.add(PreguntaMultipleChoice.fromJson(p));
      }
    }

    // Parsear alumnos asignados
    List<String> alumnosAsignados = [];
    final alumnosList = json['alumnosAsignados'] as List<dynamic>? ?? [];
    for (final a in alumnosList) {
      if (a is String && a.isNotEmpty) {
        alumnosAsignados.add(a);
      }
    }

    // Parsear fecha de creación
    DateTime fechaCreacion = DateTime.now();
    final fechaStr = json['fechaCreacion'] as String?;
    if (fechaStr != null) {
      try {
        fechaCreacion = DateTime.parse(fechaStr);
      } catch (e) {
        fechaCreacion = DateTime.now();
      }
    }

    return LibroPDF(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      rutaPDF: json['rutaPDF'] ?? '',
      paginaActual: json['paginaActual'] as int? ?? 1,
      preguntas: preguntas,
      tipoActividadFinal: tipoActividad,
      idAcrosticoAsociado: json['idAcrosticoAsociado'] as String?,
      alumnosAsignados: alumnosAsignados,
      esParaTodos: json['esParaTodos'] as bool? ?? true,
      fechaCreacion: fechaCreacion,
    );
  }

  // Copiar con nuevos valores
  LibroPDF copyWith({
    String? id,
    String? titulo,
    String? rutaPDF,
    int? paginaActual,
    List<PreguntaMultipleChoice>? preguntas,
    TipoActividadFinal? tipoActividadFinal,
    String? idAcrosticoAsociado,
    List<String>? alumnosAsignados,
    bool? esParaTodos,
    DateTime? fechaCreacion,
  }) {
    return LibroPDF(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      rutaPDF: rutaPDF ?? this.rutaPDF,
      paginaActual: paginaActual ?? this.paginaActual,
      preguntas: preguntas ?? this.preguntas,
      tipoActividadFinal: tipoActividadFinal ?? this.tipoActividadFinal,
      idAcrosticoAsociado: idAcrosticoAsociado ?? this.idAcrosticoAsociado,
      alumnosAsignados: alumnosAsignados ?? this.alumnosAsignados,
      esParaTodos: esParaTodos ?? this.esParaTodos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

// Repositorio para gestionar libros PDF
class LibroPDFRepository {
  static final List<LibroPDF> _libros = [];
  static bool _cargadoInicial = false;

  // Inicializar el repositorio
  static Future<void> init() async {
    if (_cargadoInicial) return;

    try {
      final librosGuardados = await EjercicioStorageService.obtenerLibrosPDF();
      _libros.clear();
      _libros.addAll(librosGuardados);
      _cargadoInicial = true;
    } catch (e) {
      _cargadoInicial = true;
    }
  }

  static Future<bool> _guardarEnAlmacenamiento() async {
    try {
      return await EjercicioStorageService.guardarLibrosPDF([..._libros]);
    } catch (e) {
      return false;
    }
  }

  // Obtener todos los libros
  static List<LibroPDF> getLibros() {
    return [..._libros];
  }

  // Obtener libro por ID
  static LibroPDF? getLibroPorId(String id) {
    try {
      return _libros.firstWhere((libro) => libro.id == id);
    } catch (e) {
      return null;
    }
  }

  // Agregar un nuevo libro
  static Future<void> agregarLibro(LibroPDF libro) async {
    _libros.removeWhere((l) => l.id == libro.id);
    _libros.add(libro);
    await _guardarEnAlmacenamiento();
  }

  // Eliminar libro por ID
  static Future<void> eliminarLibro(String id) async {
    _libros.removeWhere((libro) => libro.id == id);
    await _guardarEnAlmacenamiento();
  }

  // Actualizar la página actual de un libro
  static Future<void> actualizarPaginaActual(String libroId, int pagina) async {
    final libro = getLibroPorId(libroId);
    if (libro != null) {
      final index = _libros.indexWhere((l) => l.id == libroId);
      if (index != -1) {
        _libros[index] = libro.copyWith(paginaActual: pagina);
        await _guardarEnAlmacenamiento();
      }
    }
  }

  // Agregar pregunta a un libro
  static Future<void> agregarPregunta(String libroId, PreguntaMultipleChoice pregunta) async {
    final libro = getLibroPorId(libroId);
    if (libro != null) {
      final index = _libros.indexWhere((l) => l.id == libroId);
      if (index != -1) {
        final nuevasPreguntas = List<PreguntaMultipleChoice>.from(libro.preguntas);
        nuevasPreguntas.add(pregunta);
        _libros[index] = libro.copyWith(preguntas: nuevasPreguntas);
        await _guardarEnAlmacenamiento();
      }
    }
  }

  // Eliminar pregunta de un libro
  static Future<void> eliminarPregunta(String libroId, String preguntaId) async {
    final libro = getLibroPorId(libroId);
    if (libro != null) {
      final index = _libros.indexWhere((l) => l.id == libroId);
      if (index != -1) {
        final nuevasPreguntas = libro.preguntas.where((p) => p.id != preguntaId).toList();
        _libros[index] = libro.copyWith(preguntas: nuevasPreguntas);
        await _guardarEnAlmacenamiento();
      }
    }
  }

  // Actualizar tipo de actividad final
  static Future<void> actualizarTipoActividadFinal(String libroId, TipoActividadFinal tipo) async {
    final libro = getLibroPorId(libroId);
    if (libro != null) {
      final index = _libros.indexWhere((l) => l.id == libroId);
      if (index != -1) {
        _libros[index] = libro.copyWith(tipoActividadFinal: tipo);
        await _guardarEnAlmacenamiento();
      }
    }
  }

  // Asociar acróstico a un libro
  static Future<void> asociarAcrostico(String libroId, String acrosticoId) async {
    final libro = getLibroPorId(libroId);
    if (libro != null) {
      final index = _libros.indexWhere((l) => l.id == libroId);
      if (index != -1) {
        _libros[index] = libro.copyWith(idAcrosticoAsociado: acrosticoId);
        await _guardarEnAlmacenamiento();
      }
    }
  }

  // Generar ID único
  static String generarId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Limpiar todos los libros
  static Future<void> limpiarLibros() async {
    _libros.clear();
    await _guardarEnAlmacenamiento();
  }

  // Cargar libros desde almacenamiento (para recargar manualmente)
  static Future<void> cargarLibros() async {
    await init();
  }

  // Obtener libros filtrados por alumno
  static List<LibroPDF> getLibrosParaAlumno(String? alumnoId) {
    if (alumnoId == null) {
      return _libros.where((libro) => libro.esParaTodos).toList();
    }
    return _libros.where((libro) => libro.esVisibleParaAlumno(alumnoId)).toList();
  }
}
