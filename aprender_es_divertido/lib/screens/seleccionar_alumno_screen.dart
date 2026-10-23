import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/user_model.dart';
import '../models/menu_principal.dart';
import '../widgets/acceso_maestra_denegado.dart';

class SeleccionarAlumnoScreen extends StatefulWidget {
  final bool esParaJugar; // Si es true, es para que el alumno juegue

  const SeleccionarAlumnoScreen({super.key, this.esParaJugar = false});

  @override
  State<SeleccionarAlumnoScreen> createState() =>
      _SeleccionarAlumnoScreenState();
}

class _SeleccionarAlumnoScreenState extends State<SeleccionarAlumnoScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _nuevoAlumnoController = TextEditingController();
  bool _sonidoActivado = true;
  String? _errorMensaje;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _nuevoAlumnoController.dispose();
    super.dispose();
  }

  void _playSound() {
    if (_sonidoActivado) {
      _audioPlayer.play(AssetSource('sounds/softpop_sfx.mp3'));
    }
  }

  void _toggleSonido() {
    setState(() {
      _sonidoActivado = !_sonidoActivado;
    });
  }

  Future<void> _seleccionarAlumno(Alumno? alumno) async {
    _playSound();

    // Si estamos en modo gestión (esParaJugar: false), mantener el modo maestra
    // Solo cambiamos a modo alumno cuando esParaJugar: true
    await UsuarioRepository.seleccionarAlumno(
      alumno,
      mantenerModoMaestra: !widget.esParaJugar,
    );
    if (!mounted) return;

    // Al iniciar el modo alumno, eliminar las pantallas de la maestra de la pila.
    if (widget.esParaJugar) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MenuPrincipal()),
        (route) => false,
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MenuPrincipal()),
    );
  }

  Future<void> _agregarAlumno() async {
    _playSound();

    final nombre = _nuevoAlumnoController.text.trim();

    if (nombre.isEmpty) {
      setState(() {
        _errorMensaje = 'Por favor, ingresa un nombre';
      });
      return;
    }

    if (UsuarioRepository.existeNombreAlumno(nombre)) {
      setState(() {
        _errorMensaje = 'Ya existe un alumno con ese nombre';
      });
      return;
    }

    // Crear nuevo alumno
    final nuevoAlumno = Alumno(
      id: UsuarioRepository.generarId(),
      nombre: nombre,
      fechaCreacion: DateTime.now(),
    );

    await UsuarioRepository.agregarAlumno(nuevoAlumno);
    if (!mounted) return;

    setState(() {
      _nuevoAlumnoController.clear();
      _errorMensaje = null;
    });
  }

  Future<void> _eliminarAlumno(String alumnoId) async {
    _playSound();

    // Mostrar confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alumno'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este alumno?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await UsuarioRepository.eliminarAlumno(alumnoId);
      if (!mounted) return;
      setState(() {});
    }
  }

  void _mostrarDialogoNuevoAlumno() {
    _playSound();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Alumno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nuevoAlumnoController,
              decoration: InputDecoration(
                labelText: 'Nombre del alumno',
                hintText: 'Ejemplo: José',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            if (_errorMensaje != null) ...[
              const SizedBox(height: 8),
              Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _playSound();
              Navigator.pop(context);
              setState(() {
                _errorMensaje = null;
              });
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _agregarAlumno,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.esParaJugar && !UsuarioRepository.esMaestraLogueada) {
      return const AccesoMaestraDenegado();
    }
    final alumnos = UsuarioRepository.alumnos;
    final hayAlumnos = alumnos.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F5FE),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.esParaJugar
              ? 'Selecciona tu nombre'
              : 'Selecciona o crea un alumno',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0288D1),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0288D1)),
          onPressed: () {
            _playSound();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _sonidoActivado ? Icons.volume_up : Icons.volume_off,
              color: const Color(0xFF0288D1),
            ),
            onPressed: _toggleSonido,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.esParaJugar &&
                  UsuarioRepository.esMaestraLogueada) ...[
                // Solo la maestra puede crear/eliminar alumnos
                Text(
                  'Alumnos registrados (${alumnos.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),

                // Botón para agregar alumno
                ElevatedButton.icon(
                  onPressed: _mostrarDialogoNuevoAlumno,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Agregar Alumno',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Expanded(
                child: hayAlumnos
                    ? ListView.builder(
                        itemCount: alumnos.length,
                        itemBuilder: (context, index) {
                          final alumno = alumnos[index];
                          return _AlumnoCard(
                            alumno: alumno,
                            esParaJugar: widget.esParaJugar,
                            onTap: () => _seleccionarAlumno(alumno),
                            onDelete:
                                !widget.esParaJugar &&
                                    UsuarioRepository.esMaestraLogueada
                                ? () => _eliminarAlumno(alumno.id)
                                : null,
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_disabled,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay alumnos registrados',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!widget.esParaJugar &&
                                UsuarioRepository.esMaestraLogueada)
                              Text(
                                'Presiona "Agregar Alumno" para crear uno',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
              ),

              // Opción "Todos los alumnos" solo si es para jugar y hay alumnos
              if (widget.esParaJugar &&
                  hayAlumnos &&
                  UsuarioRepository.esMaestraLogueada) ...[
                const SizedBox(height: 16),
                _AlumnoCard(
                  alumno: Alumno(
                    id: 'todos',
                    nombre: 'Todos los alumnos',
                    fechaCreacion: DateTime.now(),
                  ),
                  esParaJugar: true,
                  onTap: () =>
                      _seleccionarAlumno(null), // null significa ver todos
                  onDelete: null,
                  esEspecial: true,
                ),
              ],

              // Botón para cerrar sesión (si es maestra)
              if (UsuarioRepository.esMaestraLogueada &&
                  !widget.esParaJugar) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      _playSound();
                      await UsuarioRepository.logout();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MenuPrincipal(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AlumnoCard extends StatelessWidget {
  final Alumno alumno;
  final bool esParaJugar;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool esEspecial;

  const _AlumnoCard({
    required this.alumno,
    required this.esParaJugar,
    required this.onTap,
    this.onDelete,
    this.esEspecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esEspecial ? Colors.blue[200]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: esEspecial ? Colors.blue[50] : Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  esEspecial ? Icons.group : Icons.person,
                  size: 24,
                  color: esEspecial ? Colors.blue : const Color.fromARGB(255, 255, 123, 0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno.nombre,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: esEspecial ? Colors.blue[800] : Colors.grey[800],
                      ),
                    ),
                    if (!esEspecial)
                      Text(
                        'ID: ${alumno.id.substring(0, 8)}...',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ] else if (esParaJugar) ...[
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
