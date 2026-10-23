import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'login_screen.dart';

class GestionMaestrasScreen extends StatefulWidget {
  const GestionMaestrasScreen({super.key});

  @override
  State<GestionMaestrasScreen> createState() => _GestionMaestrasScreenState();
}

class _GestionMaestrasScreenState extends State<GestionMaestrasScreen> {
  bool _eliminando = false;

  Future<void> _eliminarCuenta(Usuario maestra) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta permanentemente'),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Advertencia: esta acción es permanente y no se puede deshacer. '
                'Se eliminará la cuenta de maestra "${maestra.usuario}" de este dispositivo.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _eliminando = true);
    try {
      await UsuarioRepository.eliminarMaestra(maestra.usuario);
      if (!mounted) return;
      final eliminarSesion =
          UsuarioRepository.maestras.isEmpty || !UsuarioRepository.esMaestraLogueada;
      setState(() => _eliminando = false);
      if (eliminarSesion) {
        await UsuarioRepository.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta eliminada.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la cuenta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!UsuarioRepository.esMaestraLogueada) {
      return const Scaffold(
        body: Center(child: Text('Esta sección es solo para maestras.')),
      );
    }

    final maestras = UsuarioRepository.maestras;
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        title: const Text('Cuentas de maestras'),
        backgroundColor: const Color(0xFFE1F5FE),
        foregroundColor: const Color(0xFF0288D1),
        centerTitle: true,
      ),
      body: _eliminando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Las cuentas quedan guardadas en este dispositivo hasta que una maestra las elimine.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                for (final maestra in maestras)
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE1F5FE),
                        child: Icon(Icons.school, color: Color(0xFF0288D1)),
                      ),
                      title: Text(maestra.usuario),
                      subtitle: const Text('Cuenta de maestra'),
                      trailing: IconButton(
                        tooltip: 'Eliminar cuenta',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _eliminarCuenta(maestra),
                      ),
                    ),
                  ),
                if (maestras.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No hay cuentas registradas.'),
                  ),
              ],
            ),
    );
  }
}
