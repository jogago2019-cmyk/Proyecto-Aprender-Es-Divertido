import 'package:flutter/material.dart';
import 'package:aprender_es_divertido/models/completar_palabra_model.dart';
import 'package:aprender_es_divertido/models/ordenar_palabras_model.dart';
import 'package:aprender_es_divertido/models/acrostico_model.dart';
import 'package:aprender_es_divertido/models/user_model.dart';
import 'package:aprender_es_divertido/models/pdf_book_model.dart';
import 'package:aprender_es_divertido/screens/splash_screen.dart';

void main() async {
  // Inicializar WidgetsFlutterBinding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar repositorios
  await CompletarPalabraRepository.init();
  await OrdenarPalabraRepository.init();
  await AcrosticoRepository.init();
  await UsuarioRepository.init();
  await LibroPDFRepository.init();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aprender se hizo más divertido',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF81C784),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
