// Modelo para gestión de usuarios (maestra y alumnos)
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Tipos de usuario
enum TipoUsuario { maestra, alumno }

// Modelo de Usuario (para la maestra)
class Usuario {
  String usuario;
  String contrasena;
  String palabraRecuperacion;
  TipoUsuario tipo;

  Usuario({
    required this.usuario,
    required this.contrasena,
    this.palabraRecuperacion = '',
    required this.tipo,
  });

  Map<String, dynamic> toJson() {
    return {
      'usuario': usuario,
      'contrasena': contrasena,
      'palabraRecuperacion': palabraRecuperacion,
      'tipo': tipo.name,
    };
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      usuario: json['usuario'] ?? '',
      contrasena: json['contrasena'] ?? '',
      palabraRecuperacion: json['palabraRecuperacion'] ?? '',
      tipo: TipoUsuario.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoUsuario.alumno,
      ),
    );
  }

  // Validar credenciales
  bool validarCredenciales(String usuario, String contrasena) {
    return this.usuario == usuario && this.contrasena == contrasena;
  }
}

// Modelo de Alumno
class Alumno {
  String id;
  String nombre;
  DateTime fechaCreacion;

  Alumno({required this.id, required this.nombre, required this.fechaCreacion});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Alumno.fromJson(Map<String, dynamic> json) {
    return Alumno(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime.now(),
    );
  }
}

// Repositorio de Usuarios y Alumnos
class UsuarioRepository {
  static const String _alumnosKey = 'lista_alumnos';
  static const String _alumnoActualKey = 'alumno_actual';
  static const String _esMaestraKey = 'es_maestra_logueada';
  static const String _maestrasKey = 'lista_maestras';
  static const String _maestraActualKey = 'maestra_actual';

  // Lista de alumnos
  static List<Alumno> _alumnos = [];
  static List<Usuario> _maestras = [];
  static bool _cargado = false;

  // Alumno actualmente seleccionado
  static Alumno? _alumnoActual;
  static String? _maestraActual;
  static bool _esMaestraLogueada = false;

  // Inicializar repositorio
  static Future<void> init() async {
    if (_cargado) return;

    final prefs = await SharedPreferences.getInstance();

    final maestrasJson = prefs.getString(_maestrasKey);
    if (maestrasJson != null && maestrasJson.isNotEmpty) {
      final maestrasList = jsonDecode(maestrasJson) as List<dynamic>;
      _maestras = maestrasList
          .map((json) => Usuario.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    final alumnosJson = prefs.getString(_alumnosKey);
    if (alumnosJson != null && alumnosJson.isNotEmpty) {
      final alumnosList = jsonDecode(alumnosJson) as List<dynamic>;
      _alumnos = alumnosList
          .map((json) => Alumno.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    _maestraActual = prefs.getString(_maestraActualKey);
    _esMaestraLogueada = prefs.getBool(_esMaestraKey) ?? false;
    if (!_maestras.any(
      (maestra) =>
          maestra.usuario.toLowerCase() == _maestraActual?.toLowerCase(),
    )) {
      _esMaestraLogueada = false;
      _maestraActual = null;
    }

    final alumnoActualJson = prefs.getString(_alumnoActualKey);
    if (alumnoActualJson != null && alumnoActualJson.isNotEmpty) {
      _alumnoActual = Alumno.fromJson(
        jsonDecode(alumnoActualJson) as Map<String, dynamic>,
      );
    }

    _cargado = true;
  }

  // Guardar estado
  static Future<bool> _guardarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final maestrasJson = jsonEncode(_maestras.map((m) => m.toJson()).toList());
    final alumnosJson = jsonEncode(_alumnos.map((a) => a.toJson()).toList());
    final guardadoMaestras = await prefs.setString(_maestrasKey, maestrasJson);
    final guardadoAlumnos = await prefs.setString(_alumnosKey, alumnosJson);
    final guardadoSesion = await prefs.setBool(
      _esMaestraKey,
      _esMaestraLogueada,
    );
    if (_maestraActual != null) {
      await prefs.setString(_maestraActualKey, _maestraActual!);
    } else {
      await prefs.remove(_maestraActualKey);
    }

    if (_alumnoActual != null) {
      await prefs.setString(
        _alumnoActualKey,
        jsonEncode(_alumnoActual!.toJson()),
      );
    } else {
      await prefs.remove(_alumnoActualKey);
    }

    return guardadoMaestras && guardadoAlumnos && guardadoSesion;
  }

  static List<Usuario> get maestras => List.unmodifiable(_maestras);

  static bool existeUsuarioMaestra(String usuario) => _maestras.any(
    (maestra) => maestra.usuario.toLowerCase() == usuario.trim().toLowerCase(),
  );

  static Future<bool> registrarMaestra(
    String usuario,
    String contrasena,
    String palabraRecuperacion,
  ) async {
    final nombreUsuario = usuario.trim();
    final palabra = palabraRecuperacion.trim().toLowerCase();
    if (nombreUsuario.isEmpty ||
        contrasena.isEmpty ||
        palabra.isEmpty ||
        existeUsuarioMaestra(nombreUsuario)) {
      return false;
    }

    _maestras.add(
      Usuario(
        usuario: nombreUsuario,
        contrasena: contrasena,
        palabraRecuperacion: palabra,
        tipo: TipoUsuario.maestra,
      ),
    );
    try {
      final guardado = await _guardarEstado();
      if (guardado) return true;
      _maestras.removeWhere(
        (maestra) =>
            maestra.usuario.toLowerCase() == nombreUsuario.toLowerCase(),
      );
      return false;
    } catch (_) {
      _maestras.removeWhere(
        (maestra) =>
            maestra.usuario.toLowerCase() == nombreUsuario.toLowerCase(),
      );
      rethrow;
    }
  }

  static Future<bool> recuperarContrasena(
    String usuario,
    String palabraRecuperacion,
    String nuevaContrasena,
  ) async {
    final nombreUsuario = usuario.trim();
    final palabra = palabraRecuperacion.trim().toLowerCase();
    final indiceMaestra = _maestras.indexWhere(
      (maestra) =>
          maestra.usuario.toLowerCase() == nombreUsuario.toLowerCase() &&
          maestra.palabraRecuperacion == palabra,
    );
    if (nombreUsuario.isEmpty ||
        palabra.isEmpty ||
        nuevaContrasena.length < 6 ||
        indiceMaestra == -1) {
      return false;
    }

    final maestra = _maestras[indiceMaestra];
    final contrasenaAnterior = maestra.contrasena;
    maestra.contrasena = nuevaContrasena;
    try {
      if (!await _guardarEstado()) {
        throw StateError('No se pudo guardar la nueva contraseña.');
      }
      return true;
    } catch (_) {
      maestra.contrasena = contrasenaAnterior;
      rethrow;
    }
  }

  static Future<void> eliminarMaestra(String usuario) async {
    final eliminada = _maestras.firstWhere(
      (maestra) => maestra.usuario.toLowerCase() == usuario.toLowerCase(),
    );
    final eraMaestraActual =
        _maestraActual?.toLowerCase() == usuario.toLowerCase();
    final estadoSesionPrevio = _esMaestraLogueada;
    _maestras.removeWhere(
      (maestra) => maestra.usuario.toLowerCase() == usuario.toLowerCase(),
    );
    if (eraMaestraActual) {
      _maestraActual = null;
      _esMaestraLogueada = false;
    }
    try {
      if (!await _guardarEstado()) {
        throw StateError('No se pudo guardar la eliminación de la cuenta.');
      }
    } catch (_) {
      _maestras.add(eliminada);
      if (eraMaestraActual) _maestraActual = eliminada.usuario;
      _esMaestraLogueada = estadoSesionPrevio;
      rethrow;
    }
  }

  // Login de maestra
  static Future<bool> loginMaestra(String usuario, String contrasena) async {
    final credencialesValidas = _maestras.any(
      (maestra) => maestra.validarCredenciales(usuario, contrasena),
    );
    if (credencialesValidas) {
      _esMaestraLogueada = true;
      _maestraActual = usuario.trim();
      _alumnoActual = null; // Asegurar que no hay alumno seleccionado
      if (!await _guardarEstado()) {
        _esMaestraLogueada = false;
        _maestraActual = null;
        throw StateError('No se pudo guardar el inicio de sesión.');
      }
      return true;
    }
    return false;
  }

  // Logout
  static Future<void> logout() async {
    _esMaestraLogueada = false;
    _maestraActual = null;
    _alumnoActual = null;
    await _guardarEstado();
  }

  // Seleccionar alumno
  static Future<void> seleccionarAlumno(
    Alumno? alumno, {
    bool mantenerModoMaestra = false,
  }) async {
    _alumnoActual = alumno;
    // Si se selecciona un alumno (no null) y NO estamos en modo gestión,
    // la maestra deja de estar "logueada" temporalmente para que el alumno no pueda acceder al taller
    if (alumno != null && !mantenerModoMaestra) {
      _esMaestraLogueada = false;
    } else if (alumno == null) {
      _esMaestraLogueada = mantenerModoMaestra;
    }
    await _guardarEstado();
  }

  // ¿Está la maestra logueada?
  static bool get esMaestraLogueada => _esMaestraLogueada;

  static String? get maestraActual => _maestraActual;

  // ¿Hay un alumno seleccionado?
  static bool get hayAlumnoSeleccionado => _alumnoActual != null;

  // Restaurar modo maestra (para usar cuando se necesita volver de modo alumno a modo maestra)
  static Future<void> restaurarModoMaestra() async {
    _esMaestraLogueada = true;
    _alumnoActual = null;
    await _guardarEstado();
  }

  // Obtener alumno actual
  static Alumno? get alumnoActual => _alumnoActual;

  // Obtener lista de alumnos
  static List<Alumno> get alumnos => [..._alumnos];

  // Agregar alumno
  static Future<void> agregarAlumno(Alumno alumno) async {
    _alumnos.removeWhere(
      (a) =>
          a.id == alumno.id ||
          a.nombre.toLowerCase() == alumno.nombre.toLowerCase(),
    );
    _alumnos.add(alumno);
    await _guardarEstado();
  }

  // Eliminar alumno
  static Future<void> eliminarAlumno(String alumnoId) async {
    _alumnos.removeWhere((a) => a.id == alumnoId);

    // Si el alumno eliminado es el seleccionado, deseleccionar
    if (_alumnoActual?.id == alumnoId) {
      _alumnoActual = null;
    }

    await _guardarEstado();
  }

  // Obtener alumno por ID
  static Alumno? getAlumnoPorId(String id) {
    try {
      return _alumnos.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener alumno por nombre
  static Alumno? getAlumnoPorNombre(String nombre) {
    try {
      return _alumnos.firstWhere(
        (a) => a.nombre.toLowerCase() == nombre.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Generar ID único
  static String generarId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Verificar si un nombre de alumno ya existe
  static bool existeNombreAlumno(String nombre) {
    return _alumnos.any((a) => a.nombre.toLowerCase() == nombre.toLowerCase());
  }

  // Limpiar todos los datos
  static Future<void> limpiarTodo() async {
    _alumnos.clear();
    _alumnoActual = null;
    _esMaestraLogueada = false;
    await _guardarEstado();
  }
}
