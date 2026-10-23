import 'package:flutter/material.dart';

class CreditosScreen extends StatelessWidget {
  const CreditosScreen({super.key});

  static const _azul = Color(0xFF0288D1);
  static const _verde = Color(0xFF2E7D32);
  static const _fondo = Color(0xFFFDFCF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        title: const Text('Créditos'),
        backgroundColor: _fondo,
        foregroundColor: const Color(0xFF4A4A4A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE1F5FE), Color(0xFFE8F5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.school_rounded, color: _azul, size: 34),
                ),
                SizedBox(height: 16),
                Text(
                  'Aprender es Divertido',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF31515C),
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Un proyecto educativo hecho con dedicación',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF567078), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SeccionCreditos(
            icono: Icons.lightbulb_outline_rounded,
            etiqueta: 'PROPÓSITO',
            titulo: 'Aprender jugando',
            color: _verde,
            child: const Text(
              'La aplicación fue creada para apoyar el aprendizaje de niñas y '
              'niños de una manera entretenida e interactiva. Reúne actividades '
              'de lengua que les permiten practicar, explorar y aprender a su '
              'propio ritmo.',
              style: TextStyle(
                color: Color(0xFF5F6668),
                height: 1.55,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SeccionCreditos(
            icono: Icons.groups_2_outlined,
            etiqueta: 'DESARROLLADORES',
            titulo: 'Equipo creador',
            color: _azul,
            child: Column(
              children: [
                _Desarrollador(numero: '01', nombre: 'Gomez Jose Gabriel'),
                const Divider(height: 20),
                _Desarrollador(numero: '02', nombre: 'Espindola Pedro Daniel'),
                const Divider(height: 20),
                _Desarrollador(
                  numero: '03',
                  nombre: 'Donaire Claudia Marisol',
                ),
                const Divider(height: 20),
                _Desarrollador(
                  numero: '04',
                  nombre: 'Maldonado Roman Omar',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SeccionCreditos(
            icono: Icons.menu_book_outlined,
            etiqueta: 'FORMACIÓN',
            titulo: 'Materia y orientación',
            color: _verde,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DatoCreditos(
                  etiqueta: 'Materia',
                  valor:
                      'Programación de aplicaciones para dispositivos móviles',
                ),
                SizedBox(height: 14),
                _DatoCreditos(
                  etiqueta: 'Orientado por',
                  valor: 'Profesor Gerardo Rosales',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gracias por acompañarnos en esta aventura de aprendizaje.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7A8588),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionCreditos extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String titulo;
  final Color color;
  final Widget child;

  const _SeccionCreditos({
    required this.icono,
    required this.etiqueta,
    required this.titulo,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                etiqueta,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF3F4A4D),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Desarrollador extends StatelessWidget {
  final String numero;
  final String nombre;

  const _Desarrollador({required this.numero, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE1F5FE),
            shape: BoxShape.circle,
          ),
          child: Text(
            numero,
            style: const TextStyle(
              color: CreditosScreen._azul,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            nombre,
            style: const TextStyle(
              color: Color(0xFF50595B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DatoCreditos extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _DatoCreditos({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: Color(0xFF7A8588),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Color(0xFF50595B),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
