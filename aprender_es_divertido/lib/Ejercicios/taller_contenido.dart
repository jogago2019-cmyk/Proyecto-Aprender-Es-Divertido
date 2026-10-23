import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aprender_es_divertido/Ejercicios/menu_lengua_taller.dart';

class TallerContenido extends StatefulWidget {
  const TallerContenido({super.key});

  @override
  State<TallerContenido> createState() => _TallerContenidoState();
}

class _TallerContenidoState extends State<TallerContenido> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool sonidoActivado = true;

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Taller de Creación de Contenido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6A1B9A)),
          onPressed: () {
            _playSound();
            Navigator.pop(context);
          },
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crea y gestiona ejercicios de Lengua',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _BotonTaller(
                      icono: Icons.menu_book,
                      titulo: 'Lengua',
                      subtitulo: 'Crea y gestiona ejercicios de completar palabras, ordenar palabras y acrósticos',
                      colorFondo: const Color(0xFFF3E5F5),
                      colorIcono: const Color(0xFF6A1B9A),
                      onTap: () {
                        _playSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MenuLenguaTaller(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// Componente reutilizable para botones del taller
class _BotonTaller extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color colorFondo;
  final Color colorIcono;
  final VoidCallback onTap;

  const _BotonTaller({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.colorFondo,
    required this.colorIcono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Card(
        color: colorFondo,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorIcono.withAlpha(89),
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icono,
                    size: 30,
                    color: colorIcono,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
