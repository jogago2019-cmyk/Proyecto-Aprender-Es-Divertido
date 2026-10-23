import 'package:flutter/material.dart';

class AccesoMaestraDenegado extends StatelessWidget {
  const AccesoMaestraDenegado({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso restringido')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Solo una maestra puede crear o modificar actividades.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
