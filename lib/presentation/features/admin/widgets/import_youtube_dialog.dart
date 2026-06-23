import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/entities/channel_entity.dart';
import '../providers/channel_admin_provider.dart';

class ImportYoutubeDialog extends ConsumerStatefulWidget {
  const ImportYoutubeDialog({super.key});

  @override
  ConsumerState<ImportYoutubeDialog> createState() => _ImportYoutubeDialogState();
}

class _ImportYoutubeDialogState extends ConsumerState<ImportYoutubeDialog> {
  final _textContentController = TextEditingController();
  bool _isImporting = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _textContentController.dispose();
    super.dispose();
  }

  String? _extractYoutubeId(String url) {
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url.trim());
    if (match != null && match.groupCount >= 2) {
      final id = match.group(2);
      if (id != null && id.length == 11) {
        return id;
      }
    }
    return null;
  }

  Future<void> _startImport() async {
    final text = _textContentController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor pega la lista de enlaces de YouTube';
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = '';
    });

    try {
      final lines = text.split('\n');
      final List<ChannelEntity> channelsToImport = [];
      final uuid = const Uuid();

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        String name = '';
        String url = '';

        // Check if there is a separator (comma, hyphen, or pipe)
        if (trimmedLine.contains(',')) {
          final parts = trimmedLine.split(',');
          name = parts[0].trim();
          url = parts.sublist(1).join(',').trim();
        } else if (trimmedLine.contains('|')) {
          final parts = trimmedLine.split('|');
          name = parts[0].trim();
          url = parts.sublist(1).join('|').trim();
        } else if (trimmedLine.contains(' - ')) {
          final parts = trimmedLine.split(' - ');
          name = parts[0].trim();
          url = parts.sublist(1).join(' - ').trim();
        } else {
          url = trimmedLine;
        }

        final videoId = _extractYoutubeId(url);
        if (videoId != null) {
          if (name.isEmpty) {
            name = 'YouTube Live $videoId';
          }
          channelsToImport.add(ChannelEntity(
            id: uuid.v4(),
            companyId: 'tajamar',
            name: name,
            logo: 'assets/images/youtube_logo.png',
            categoryId: 'YouTube',
            url: url,
            streamType: 'youtube',
            language: 'es',
            country: 'AR',
            epgId: '',
            order: 0, // Will be ordered dynamically or default
          ));
        }
      }

      if (channelsToImport.isEmpty) {
        throw Exception('No se encontraron enlaces válidos de YouTube. Asegúrate de que las URLs tengan el formato correcto.');
      }

      final repository = ref.read(channelRepositoryProvider);
      int importedCount = 0;
      for (final channel in channelsToImport) {
        await repository.addChannel(channel);
        importedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Importación exitosa! Se agregaron $importedCount canales de YouTube.'),
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
              'Importar Canales de YouTube',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pega una lista de enlaces de YouTube (uno por línea).\nPuedes incluir un nombre separado por coma.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ejemplos:\n• TN en Vivo, https://www.youtube.com/watch?v=coYw5G6tLyY\n• https://youtu.be/coYw5G6tLyY',
              style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _textContentController,
              maxLines: 8,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Lista de Enlaces',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.purple),
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Nombre, URL\nNombre, URL',
                hintStyle: const TextStyle(color: Colors.white24),
              ),
            ),

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
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
