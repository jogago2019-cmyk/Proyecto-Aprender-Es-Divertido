import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:aprender_es_divertido/models/pdf_book_model.dart';
import 'package:aprender_es_divertido/models/acrostico_model.dart';
import 'package:aprender_es_divertido/Ejercicios/LibrosPDF/responder_preguntas_screen.dart';
import 'package:aprender_es_divertido/Ejercicios/Acrostico/jugar_acrostico_screen.dart';

class VerLibroPDFScreen extends StatefulWidget {
  final LibroPDF libro;

  const VerLibroPDFScreen({super.key, required this.libro});

  @override
  State<VerLibroPDFScreen> createState() => _VerLibroPDFScreenState();
}

class _VerLibroPDFScreenState extends State<VerLibroPDFScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;
  PDFDocument? _document;
  PageController? _pageController;
  int _paginaActual = 1; // base 1 (la que ve el usuario)
  int _totalPaginas = 1;
  bool _cargando = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _paginaActual = widget.libro.paginaActual;
    _cargarDocumento();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _audioPlayer.dispose();
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

  Future<void> _cargarDocumento() async {
    try {
      setState(() {
        _cargando = true;
        _error = false;
      });

      // Cargar el documento desde el archivo local
      _document = await PDFDocument.fromFile(File(widget.libro.rutaPDF));

      // En advance_pdf_viewer el total de páginas es "count"
      _totalPaginas = _document!.count;

      if (_paginaActual > _totalPaginas || _paginaActual < 1) {
        _paginaActual = 1;
      }

      // El PageController empieza en 0
      _pageController?.dispose();
      _pageController = PageController(initialPage: _paginaActual - 1);

      setState(() => _cargando = false);
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = true;
      });
    }
  }

  void _paginaAnterior() {
    _playSound();
    if (_paginaActual > 1) {
      _moverAPagina(_paginaActual - 1);
    }
  }

  void _paginaSiguiente() {
    _playSound();
    if (_paginaActual < _totalPaginas) {
      _moverAPagina(_paginaActual + 1);
    }
  }

  Future<void> _guardarPaginaActual() async {
    await LibroPDFRepository.actualizarPaginaActual(
        widget.libro.id, _paginaActual);
  }

  // Mueve el visor y actualiza el estado (sin sonido)
  void _moverAPagina(int pagina) {
    if (pagina >= 1 && pagina <= _totalPaginas) {
      _pageController?.jumpToPage(pagina - 1);
      setState(() => _paginaActual = pagina);
      _guardarPaginaActual();
    }
  }

  // Igual que _moverAPagina pero con sonido (para el selector)
  void _irAPagina(int pagina) {
    _playSound();
    _moverAPagina(pagina);
  }

  void _terminarLectura() {
    switch (widget.libro.tipoActividadFinal) {
      case TipoActividadFinal.preguntas:
        _mostrarPreguntas();
        break;
      case TipoActividadFinal.acrostico:
        _mostrarSelectorAcrosticos();
        break;
      case TipoActividadFinal.ambos:
        _mostrarMenuActividades();
        break;
      case TipoActividadFinal.nada:
        _volverAtras();
        break;
    }
  }

  void _mostrarPreguntas() {
    _playSound();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResponderPreguntasScreen(libro: widget.libro),
      ),
    );
  }

  void _mostrarAcrostico({String? acrosticoId}) {
    final id = acrosticoId ?? widget.libro.idAcrosticoAsociado;
    if (id != null) {
      final acrostico = AcrosticoRepository.getEjercicioPorId(id);
      if (acrostico != null) {
        _playSound();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JugarAcrosticoScreen(acrostico: acrostico),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay acróstico asociado a este libro')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay acróstico asociado a este libro')),
      );
    }
  }

  void _mostrarSelectorAcrosticos() {
    final todosAcrosticos = AcrosticoRepository.getEjercicios();
    
    if (todosAcrosticos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ejercicios de acróstico disponibles')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona un ejercicio de acróstico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: todosAcrosticos.length,
                itemBuilder: (context, index) {
                  final acrostico = todosAcrosticos[index];
                  return ListTile(
                    leading: const Icon(Icons.text_fields, color: Color(0xFF6A1B9A)),
                    title: Text(acrostico.titulo),
                    subtitle: Text('Palabras: ${acrostico.palabras.length}'),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarAcrostico(acrosticoId: acrostico.id);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMenuActividades() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona la actividad final',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF6A1B9A)),
              title: const Text('Responder Preguntas'),
              subtitle:
                  Text('${widget.libro.preguntas.length} preguntas disponibles'),
              onTap: () {
                Navigator.pop(context);
                _mostrarPreguntas();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields, color: Color(0xFF6A1B9A)),
              title: const Text('Hacer Acróstico'),
              subtitle: const Text('Seleccionar de la lista de acrósticos'),
              onTap: () {
                Navigator.pop(context);
                _mostrarSelectorAcrosticos();
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _volverAtras() {
    _playSound();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.libro.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6A1B9A)),
          onPressed: _volverAtras,
        ),
        actions: [
          IconButton(
            icon: Icon(
              sonidoActivado ? Icons.volume_up : Icons.volume_off,
              color: const Color(0xFF6A1B9A),
            ),
            onPressed: _toggleSonido,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Error al cargar el libro PDF',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 10),
            const Text(
              'Asegúrate de que el archivo PDF existe y es accesible',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cargarDocumento,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: PDFViewer(
            document: _document!,
            controller: _pageController,
            showNavigation: false, // usamos nuestros propios botones
            showIndicator: false, // ya mostramos "Página X de Y"
            showPicker: false,
            onPageChanged: (page) {
              // "page" es base 0
              if (_paginaActual != page + 1) {
                setState(() => _paginaActual = page + 1);
                _guardarPaginaActual();
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Página $_paginaActual de $_totalPaginas',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 24),
            onPressed: _paginaAnterior,
            disabledColor: Colors.grey[300],
            color: const Color(0xFF6A1B9A),
          ),
          if (widget.libro.paginasConPreguntas.contains(_paginaActual))
            const Icon(
              Icons.help_outline,
              color: Colors.orange,
              size: 24,
            )
          else
            const SizedBox(width: 24),
          if (_totalPaginas > 10)
            IconButton(
              icon: const Icon(Icons.list, size: 24),
              onPressed: _mostrarSelectorPaginas,
              color: const Color(0xFF6A1B9A),
            )
          else
            const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 24),
            onPressed: _paginaSiguiente,
            disabledColor: Colors.grey[300],
            color: const Color(0xFF6A1B9A),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Terminar'),
            onPressed: _terminarLectura,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorPaginas() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        // StatefulBuilder para que el slider se actualice dentro del modal
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ir a página',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Página actual: $_paginaActual de $_totalPaginas',
                style: const TextStyle(fontSize: 14),
              ),
              Slider(
                value: _paginaActual.toDouble(),
                min: 1,
                max: _totalPaginas.toDouble(),
                divisions: _totalPaginas > 1 ? _totalPaginas - 1 : 1,
                label: 'Página $_paginaActual',
                onChanged: (value) {
                  _moverAPagina(value.toInt());
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 16),
              if (widget.libro.paginasConPreguntas.isNotEmpty) ...[
                const Text(
                  'Páginas con preguntas:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.libro.paginasConPreguntas.map((pagina) {
                    return FilterChip(
                      label: Text('Pág. $pagina'),
                      selected: pagina == _paginaActual,
                      onSelected: (selected) {
                        _irAPagina(pagina);
                        setModalState(() {});
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF6A1B9A),
                      labelStyle: TextStyle(
                        color: pagina == _paginaActual
                            ? Colors.white
                            : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}