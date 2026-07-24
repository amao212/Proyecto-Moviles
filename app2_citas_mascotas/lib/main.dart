import 'package:flutter/material.dart';

import 'pages/agenda_veterinaria_page.dart';

void main() {
  runApp(const AppVeterinariaAgendaApp());
}

class AppVeterinariaAgendaApp extends StatelessWidget {
  const AppVeterinariaAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agenda Veterinaria',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF67A2C5)),
        useMaterial3: true,
      ),
      home: const AgendaVeterinariaPage(),
    );
  }

  /// Helper reutilizable para renderizar filas de información sin desbordamientos de pantalla
  static Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'No especificado' : value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis, // Si es muy largo agrega "..."
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}