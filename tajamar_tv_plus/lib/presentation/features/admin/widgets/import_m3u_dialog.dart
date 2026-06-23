import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../data/utils/m3u_parser.dart';
import '../providers/channel_admin_provider.dart';

class ImportM3uDialog extends ConsumerStatefulWidget {
  const ImportM3uDialog({super.key});

  @override
  ConsumerState<ImportM3uDialog> createState() => _ImportM3uDialogState();
}

class _ImportM3uDialogState extends ConsumerState<ImportM3uDialog> {
  final _urlController = TextEditingController();
  final _textContentController = TextEditingController();
  bool _isImporting = false;
  String _errorMessage = '';
  int _importMethod = 0; // 0 for URL, 1 for Text paste

  @override
  void dispose() {
    _urlController.dispose();
    _textContentController.dispose();
    super.dispose();
  }

  Future<void> _startImport() async {
    setState(() {
      _isImporting = true;
      _errorMessage = '';
    });

    try {
      String m3uContent = '';

      if (_importMethod == 0) {
        final url = _urlController.text.trim();
        if (url.isEmpty) {
          throw Exception('Por favor ingresa una URL válida');
        }

        // Fetch playlist from URL using Dio
        final response = await Dio().get(url);
        if (response.data != null) {
          m3uContent = response.data.toString();
        } else {
          throw Exception('No se recibió contenido de la URL provista');
        }
      } else {
        m3uContent = _textContentController.text.trim();
        if (m3uContent.isEmpty) {
          throw Exception('Por favor pega el contenido de tu lista M3U');
        }
      }

      // Parse the content
      // Use a dummy companyId 'tajamar' for now
      final parsedChannels = M3uParser.parse(m3uContent, 'tajamar');

      if (parsedChannels.isEmpty) {
        throw Exception('No se encontraron canales válidos en el archivo M3U. Verifica el formato (#EXTM3U, #EXTINF, etc.)');
      }

      // Save parsed channels to local Hive database
      final repository = ref.read(channelRepositoryProvider);
      
      int importedCount = 0;
      for (final channel in parsedChannels) {
        await repository.addChannel(channel);
        importedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Importación exitosa! Se agregaron $importedCount canales.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Importar Lista M3U',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Toggle Segment / Tabs for Import Method
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _importMethod == 0 ? Colors.purple : Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => setState(() => _importMethod = 0),
                    child: const Text('Desde URL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _importMethod == 1 ? Colors.purple : Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => setState(() => _importMethod = 1),
                    child: const Text('Pegar Texto'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dialog Inputs based on selected method
            if (_importMethod == 0)
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'URL de la Lista M3U',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.purple),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'https://example.com/lista.m3u',
                  hintStyle: const TextStyle(color: Colors.white30),
                ),
              )
            else
              TextField(
                controller: _textContentController,
                maxLines: 10,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Pegar contenido M3U aquí',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.purple),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: '#EXTM3U\n#EXTINF:-1 tvg-logo="https://example.com/logo.png" group-title="General",Canal 1\nhttp://example.com/stream.m3u8',
                  hintStyle: const TextStyle(color: Colors.white24),
                ),
              ),

            // Error display
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isImporting ? null : _startImport,
                  child: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Importar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
