import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aprender_es_divertido/models/ordenar_palabras_model.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/services/imagen_service.dart';
import 'package:aprender_es_divertido/widgets/imagen_ejercicio_widget.dart';
import 'package:aprender_es_divertido/widgets/acceso_maestra_denegado.dart';

class CrearContenidoOrdenarScreen extends StatefulWidget {
  const CrearContenidoOrdenarScreen({super.key});

  @override
  State<CrearContenidoOrdenarScreen> createState() => _CrearContenidoOrdenarScreenState();
}

class _CrearContenidoOrdenarScreenState extends State<CrearContenidoOrdenarScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  // Controladores para los campos
  final TextEditingController _palabraController = TextEditingController();
  final TextEditingController _pistaController = TextEditingController();

  // Variables para la imagen
  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

  bool _esEditando = false;
  String? _ejercicioId;
  
  // Estado para asignación de alumnos
  int _tipoAsignacion = 0; // 0 = Todos, 1 = Específicos
  List<String> _alumnosSeleccionados = [];
  
  bool get _esParaTodos => _tipoAsignacion == 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _palabraController.dispose();
    _pistaController.dispose();
    super.dispose();
  }

  void _playSound() {
    if (sonidoActivado) {
      _audioPlayer.play(AssetSource('sounds/softpop_sfx.mp3'));
    }
  }

  void _toggleSonido() {
    setState(() {
      sonidoActivado = !sonidoActivado;
    });
  }

  Future<void> _seleccionarImagen() async {
    _playSound();
    
    // Verificar permisos
    if (!kIsWeb) {
      // Para Android 13+, necesitamos permisos específicos
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        // Intentar con otro permiso para versiones anteriores
        final status2 = await Permission.storage.request();
        if (!status2.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Necesitamos permiso para acceder a la biblioteca de fotos'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }
    }
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _imagenSeleccionada = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar la imagen')),
        );
      }
    }
  }

  void _removerImagen() {
    _playSound();
    setState(() {
      _imagenSeleccionada = null;
    });
  }

  String _obtenerPalabraDesordenada() {
    final palabra = _palabraController.text;
    if (palabra.isEmpty) return '';
    
    final letras = palabra.split('');
    letras.shuffle();
    return letras.join('');
  }

  bool _validarFormulario() {
    if (_palabraController.text.isEmpty) {
      _mostrarError('Por favor, ingresa una palabra');
      return false;
    }
    
    if (_palabraController.text.length < 2) {
      _mostrarError('La palabra debe tener al menos 2 letras');
      return false;
    }
    
    if (_imagenSeleccionada == null) {
      _mostrarError('Por favor, selecciona una imagen');
      return false;
    }
    
    return true;
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _guardarEjercicio() async {
    if (!UsuarioRepository.esMaestraLogueada) return;
    _playSound();
    
    if (!_validarFormulario()) {
      return;
    }

    final palabra = _palabraController.text.trim();
    final pista = _pistaController.text.trim();
    
    // Guardar la imagen con el nombre de la palabra
    final imagenPath = await ImagenService.guardarImagen(
      _imagenSeleccionada!,
      palabra,
    );
    
    // Crear el ejercicio
    final ejercicio = OrdenarPalabraEjercicio(
      id: _ejercicioId ?? OrdenarPalabraRepository.generarId(),
      palabraCorrecta: palabra,
      imagenPath: imagenPath,
      pista: pista.isEmpty ? '¿Qué es esto?' : pista,
      alumnosAsignados: _alumnosSeleccionados,
      esParaTodos: _esParaTodos,
    );

    // Guardar en el repositorio
    await OrdenarPalabraRepository.agregarEjercicio(ejercicio);

    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ejercicio guardado con éxito. Palabra: ${ejercicio.palabraCorrecta.toUpperCase()} -> ${ejercicio.palabraDesordenada.toUpperCase()}')),
      );
    }

    // Limpiar formulario
    if (mounted) {
      _limpiarFormulario();
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _palabraController.clear();
      _pistaController.clear();
      _imagenSeleccionada = null;
      _esEditando = false;
      _ejercicioId = null;
      _tipoAsignacion = 0;
      _alumnosSeleccionados = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!UsuarioRepository.esMaestraLogueada) {
      return const AccesoMaestraDenegado();
    }
    final palabra = _palabraController.text;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _esEditando ? 'Editar Ejercicio - Ordenar Palabras' : 'Crear Ejercicio - Ordenar Palabras',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () {
            _playSound();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              sonidoActivado ? Icons.volume_up : Icons.volume_off,
              color: const Color(0xFF2E7D32),
            ),
            onPressed: _toggleSonido,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen seleccionada
              _buildSeccionImagen(),
              const SizedBox(height: 24),
              
              // Palabra
              Text(
                'Palabra correcta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _palabraController,
                decoration: InputDecoration(
                  hintText: 'Ejemplo: casa, perro, auto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.text_fields, color: Color(0xFF2E7D32)),
                ),
                onChanged: (value) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              
              // Visualización de palabra desordenada
              if (palabra.isNotEmpty) ...[
                Text(
                  'Palabra desordenada para el alumno:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 2),
                  ),
                  child: Text(
                    _obtenerPalabraDesordenada().toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0288D1),
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Pista
              Text(
                'Pista (opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pistaController,
                decoration: InputDecoration(
                  hintText: 'Ejemplo: Animal doméstico que dice guau',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lightbulb, color: Color(0xFF2E7D32)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Asignación de alumnos
              _buildSeccionAsignacionAlumnos(),
              
              const SizedBox(height: 32),
              
              // Botón guardar
              ElevatedButton(
                onPressed: _guardarEjercicio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Guardar Ejercicio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionAsignacionAlumnos() {
    final alumnos = UsuarioRepository.alumnos;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Asignar a:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        
        // Opción para todos
        Card(
          elevation: 0,
          color: _esParaTodos ? Colors.blue[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _esParaTodos ? Colors.blue : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _playSound();
              setState(() {
                _tipoAsignacion = 0;
                _alumnosSeleccionados = [];
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _esParaTodos ? Colors.orange[800]! : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: _esParaTodos
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange[800],
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Todos los alumnos',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  if (_esParaTodos)
                    const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Opción para alumnos específicos
        Card(
          elevation: 0,
          color: !_esParaTodos ? Colors.orange[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: !_esParaTodos ? Colors.orange : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _playSound();
              setState(() {
                _tipoAsignacion = 1;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: !_esParaTodos ? Colors.orange[800]! : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: !_esParaTodos
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange[800],
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Alumnos específicos',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  if (!_esParaTodos)
                    const Icon(Icons.check_circle, color: Colors.orange, size: 20),
                ],
              ),
            ),
          ),
        ),
        
        // Lista de alumnos (solo si no es para todos)
        if (!_esParaTodos && alumnos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.orange[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona los alumnos:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: alumnos.map((alumno) {
                    final estaSeleccionado = _alumnosSeleccionados.contains(alumno.id);
                    return FilterChip(
                      label: Text(alumno.nombre),
                      selected: estaSeleccionado,
                      onSelected: (selected) {
                        _playSound();
                        setState(() {
                          if (selected) {
                            _alumnosSeleccionados.add(alumno.id);
                          } else {
                            _alumnosSeleccionados.remove(alumno.id);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.orange[200],
                      checkmarkColor: Colors.orange[800],
                      labelStyle: TextStyle(
                        color: estaSeleccionado ? Colors.orange[800] : Colors.grey[700],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        
        if (!_esParaTodos && alumnos.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'No hay alumnos creados aún. Primero crea alumnos en la gestión de usuarios.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSeccionImagen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecciona una imagen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: kIsWeb ? null : _seleccionarImagen,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _imagenSeleccionada == null 
                    ? Colors.grey[400]! 
                    : Colors.green,
                width: 2,
              ),
            ),
            child: _imagenSeleccionada != null
                ? ImagenEjercicioWidget(
                    imagenPath: _imagenSeleccionada!.path,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        kIsWeb
                            ? 'Selección de imágenes no disponible en Web'
                            : 'Toca para seleccionar una imagen',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
        if (_imagenSeleccionada != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _removerImagen,
              tooltip: 'Remover imagen',
            ),
          ),
        ],
      ],
    );
  }
}
