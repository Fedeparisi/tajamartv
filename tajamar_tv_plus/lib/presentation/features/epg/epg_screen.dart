import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class EpgScreen extends StatelessWidget {
  const EpgScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // UI simplificada de la Guía EPG
    final hours = List.generate(12, (index) => '${(index + 12) % 24}:00');
    final channels = List.generate(20, (index) => 'Canal ${index + 1}');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Guía de Programación',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Row(
        children: [
          // Columna de canales
          SizedBox(
            width: 120,
            child: ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 80,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.glassBorder),
                      right: BorderSide(color: AppColors.glassBorder),
                    ),
                  ),
                  child: Text(channels[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          // Scroll horizontal de programas
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  // Fila de horas
                  Row(
                    children: hours.map((hour) {
                      return Container(
                        width: 200,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.glassBorder),
                          ),
                        ),
                        child: Text(hour, style: const TextStyle(color: AppColors.textSecondary)),
                      );
                    }).toList(),
                  ),
                  // Grilla de programas
                  Expanded(
                    child: SizedBox(
                      width: hours.length * 200.0,
                      child: ListView.builder(
                        itemCount: channels.length,
                        itemBuilder: (context, channelIndex) {
                          return Row(
                            children: List.generate(
                              6,
                              (progIndex) => Container(
                                width: (hours.length * 200.0) / 6,
                                height: 80,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.panel,
                                  border: Border.all(color: AppColors.background),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Programa ${progIndex + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cine / Acción',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
