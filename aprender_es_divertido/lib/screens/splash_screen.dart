import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Pre-cargar imagen
    _precacheImage();
    
    // Configurar controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Animación de fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Animación de scale (zoom suave)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Animación de bounce (pequeño rebote al final)
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 0.9, curve: Curves.elasticOut),
      ),
    );

    // Iniciar animación
    _animationController.forward();

    // Esperar 100ms y reproducir audio
    Future.delayed(const Duration(milliseconds: 100), () {
      _playLogoSound();
    });

    // Navegar a LoginScreen después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playLogoSound() {
    try {
      _audioPlayer.setVolume(1.0);
      _audioPlayer.play(AssetSource('sounds/audio_logo.mp3'));
    } catch (e) {
      // Reintentar después de 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          _audioPlayer.play(AssetSource('sounds/audio_logo.mp3'));
        } catch (e) {
          // Ignorar
        }
      });
    }
  }

  void _precacheImage() {
    try {
      precacheImage(const AssetImage('assets/imagends/logo_aprender_es_divertido.png'), context).then((_) {
        if (mounted) {
          setState(() => _imageLoaded = true);
        }
      }).catchError((_) {
        if (mounted) {
          setState(() => _imageLoaded = true);
        }
      });
      // Pre-cargar también el fondo
      precacheImage(const AssetImage('assets/imagends/fondo_logo.jpg'), context);
    } catch (e) {
      // Ignorar
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.5; // 50% del ancho de la pantalla
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/imagends/fondo_logo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _imageLoaded
                        ? Image.asset(
                            'assets/imagends/logo_aprender_es_divertido.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, st) => const Icon(
                              Icons.image,
                              size: 100,
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox(
                            width: 320,
                            height: 320,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
