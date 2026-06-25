import '../../domain/entities/channel_entity.dart';
import 'package:uuid/uuid.dart';

class M3uParser {
  /// Parsea un string M3U y retorna una lista de ChannelEntity
  static List<ChannelEntity> parse(String m3uContent, String companyId) {
    final lines = m3uContent.split('\n');
    final List<ChannelEntity> channels = [];
    final uuid = const Uuid();

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentEpgId;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        // Extraer atributos
        currentLogo = _extractAttribute(line, 'tvg-logo');
        currentGroup = _extractAttribute(line, 'group-title');
        currentEpgId = _extractAttribute(line, 'tvg-id');
        
        // Extraer nombre (lo que está después de la última coma)
        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1 && commaIndex < line.length - 1) {
          currentName = line.substring(commaIndex + 1).trim();
        }
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        // Es una URL
        if (currentName != null) {
          final streamType = _determineStreamType(line);
          
          // Map tvg-id to downloaded local assets if matching
          String finalLogo = currentLogo ?? '';
          if (currentEpgId != null && currentEpgId.isNotEmpty) {
            final logoMapping = _localLogos[currentEpgId];
            if (logoMapping != null) {
              finalLogo = 'assets/logos/$logoMapping';
            }
          }
          
          // Determine category based on group-title or default to General
          final category = (currentGroup != null && currentGroup.isNotEmpty) ? currentGroup : 'General';

          channels.add(ChannelEntity(
            id: uuid.v4(),
            companyId: companyId,
            name: currentName,
            logo: finalLogo,
            categoryId: category,
            url: line,
            streamType: streamType,
            language: 'es',
            country: 'AR',
            epgId: currentEpgId ?? '',
            order: channels.length,
          ));
        }
        
        // Reset para la próxima entrada
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentEpgId = null;
      }
    }

    return channels;
  }

  // Static mapping of tvg-id to local downloaded logo filenames
  static const Map<String, String> _localLogos = {
    '5tv.ar@SD': '5tv_ar_SD.png',
    '247CanaldeNoticias.ar@SD': '247CanaldeNoticias_ar_SD.png',
    'ABTVBariloche.ar@SD': 'ABTVBariloche_ar_SD.png',
    'AiredeSantaFe.ar@SD': 'AiredeSantaFe_ar_SD.png',
    'AlternaTV.ar@SD': 'AlternaTV_ar_SD.png',
    'AmericaTV.ar@SD': 'AmericaTV_ar_SD.png',
    'ArgentinisimaSatelital.ar@SD': 'ArgentinisimaSatelital_ar_SD.png',
    'AtccoCanal2.ar@SD': 'AtccoCanal2_ar_SD.png',
    'ATVArgentina.ar@SD': 'ATVArgentina_ar_SD.png',
    'AzaharesRadiovisualMultimedia.ar@SD': 'AzaharesRadiovisualMultimedia_ar_SD.png',
    'BayresTV.ar@SD': 'BayresTV_ar_SD.png',
    'BeatsRadio.ar@SD': 'BeatsRadio_ar_SD.png',
    'BragadoTV.ar@SD': 'BragadoTV_ar_SD.png',
    'BravoTV.ar@SD': 'BravoTV_ar_SD.png',
    'CableImagenArmstrong.ar@SD': 'CableImagenArmstrong_ar_SD.png',
    'Cadena103TV.ar@SD': 'Cadena103TV_ar_SD.png',
    'Canal2deUshuaia.ar@SD': 'Canal2deUshuaia_ar_SD.png',
    'Canal2Gualeguay.ar@SD': 'Canal2Gualeguay_ar_SD.png',
    'Canal2MardelPlata.ar@SD': 'Canal2MardelPlata_ar_SD.jpeg',
    'Canal2Misiones.ar@SD': 'Canal2Misiones_ar_SD.png',
    'Canal3Formosa.ar@SD': 'Canal3Formosa_ar_SD.png',
    'Canal3LaPampa.ar@SD': 'Canal3LaPampa_ar_SD.png',
    'Canal3LasHeras.ar@SD': 'Canal3LasHeras_ar_SD.png',
    'Canal3Pinamar.ar@SD': 'Canal3Pinamar_ar_SD.png',
    'Canal3Tacural.ar@SD': 'Canal3Tacural_ar_SD.jpeg',
    'Canal4Jujuy.ar@SD': 'Canal4Jujuy_ar_SD.png',
    'Canal4Posadas.ar@SD': 'Canal4Posadas_ar_SD.png',
    'Canal4SanJuan.ar@SD': 'Canal4SanJuan_ar_SD.png',
    'Canal4Teleaire.ar@SD': 'Canal4Teleaire_ar_SD.png',
    'Canal5DelPueblo.ar@SD': 'Canal5DelPueblo_ar_SD.jpg',
    'Canal5SantaFe.ar@SD': 'Canal5SantaFe_ar_SD.png',
    'Canal5TVChepes.ar@SD': 'Canal5TVChepes_ar_SD.png',
    'Canal6Posadas.ar@SD': 'Canal6Posadas_ar_SD.png',
    'Canal7Jujuy.ar@SD': 'Canal7Jujuy_ar_SD.png',
    'Canal7Neuquen.ar@SD': 'Canal7Neuquen_ar_SD.png',
    'Canal7Salta.ar@SD': 'Canal7Salta_ar_SD.png',
    'Canal7TV.ar@SD': 'Canal7TV_ar_SD.png',
    'Canal9Litoral.ar@SD': 'Canal9Litoral_ar_SD.png',
    'Canal9Resistencia.ar@SD': 'Canal9Resistencia_ar_SD.png',
    'Canal10Cordoba.ar@SD': 'Canal10Cordoba_ar_SD.png',
    'Canal10MardelPlata.ar@SD': 'Canal10MardelPlata_ar_SD.png',
    'Canal11delaCosta.ar@SD': 'Canal11delaCosta_ar_SD.jpg',
    'Canal12Web.ar@SD': 'Canal12Web_ar_SD.png',
    'Canal13Jujuy.ar@SD': 'Canal13Jujuy_ar_SD.jpg',
    'Canal13LaRioja.ar@SD': 'Canal13LaRioja_ar_SD.png',
    'Canal13SanLuis.ar@SD': 'Canal13SanLuis_ar_SD.png',
    'Canal21TV.ar@SD': 'Canal21TV_ar_SD.png',
    'Canal22.ar@SD': 'Canal22_ar_SD.png',
    'Canal26.ar@SD': 'Canal26_ar_SD.png',
    'Canal34SanJuan.ar@SD': 'Canal34SanJuan_ar_SD.png',
  };

  static String _extractAttribute(String line, String attributeName) {
    final regex = RegExp('$attributeName="([^"]*)"');
    final match = regex.firstMatch(line);
    return match?.group(1) ?? '';
  }

  static String _determineStreamType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.m3u8')) return 'hls';
    if (lowerUrl.contains('.mpd')) return 'dash';
    if (lowerUrl.contains('rtmp://')) return 'rtmp';
    if (lowerUrl.contains('.mp4')) return 'mp4';
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) return 'youtube';
    return 'unknown';
  }
}
