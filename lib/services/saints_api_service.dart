import 'package:flutter/foundation.dart';
import 'saints_service.dart';

/// Servicio para conectar con APIs de santos del día
/// Implementa fallback a contenido local si la API falla
class SaintsApiService {
  final SaintsService _localService = SaintsService();
  
  // TODO: Configurar estas variables cuando tengas API keys
  // ignore: unused_field
  static const String _apiBaseUrl = 'https://api.saints.example.com'; // URL de ejemplo
  // ignore: unused_field
  static const String _apiKey = ''; // API key aquí cuando esté disponible
  
  /// Obtiene el santo del día desde la API o fallback local
  Future<Map<String, dynamic>?> getTodaySaint() async {
    try {
      // TODO: Implementar llamada real a la API cuando esté disponible
      // final response = await http.get(
      //   Uri.parse('$_apiBaseUrl/saints/today?key=$_apiKey'),
      // );
      // if (response.statusCode == 200) {
      //   return json.decode(response.body) as Map<String, dynamic>;
      // }
      
      // Por ahora, usar fallback local
      return await _getLocalFallback();
    } catch (e) {
      debugPrint('Error fetching saint from API: $e');
      // Fallback a contenido local
      return await _getLocalFallback();
    }
  }

  /// Obtiene santos por fecha desde la API o fallback local
  Future<List<Map<String, dynamic>>> getSaintsByDate(DateTime date) async {
    try {
      // TODO: Implementar llamada real a la API
      // final response = await http.get(
      //   Uri.parse('$_apiBaseUrl/saints/date/${date.toIso8601String()}?key=$_apiKey'),
      // );
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   return data.cast<Map<String, dynamic>>();
      // }
      
      return await _getLocalSaintsByDate(date);
    } catch (e) {
      debugPrint('Error fetching saints by date from API: $e');
      return await _getLocalSaintsByDate(date);
    }
  }

  /// Obtiene un santo por nombre desde la API o fallback local
  Future<Map<String, dynamic>?> getSaintByName(String name) async {
    try {
      // TODO: Implementar llamada real a la API
      // final response = await http.get(
      //   Uri.parse('$_apiBaseUrl/saints/name/$name?key=$_apiKey'),
      // );
      // if (response.statusCode == 200) {
      //   return json.decode(response.body) as Map<String, dynamic>;
      // }
      
      return await _getLocalSaintByName(name);
    } catch (e) {
      debugPrint('Error fetching saint by name from API: $e');
      return await _getLocalSaintByName(name);
    }
  }

  /// Fallback: Obtiene santo del día desde contenido local
  Future<Map<String, dynamic>?> _getLocalFallback() async {
    try {
      await _localService.loadSaints();
      final saints = _localService.getAllSaints();
      if (saints.isEmpty) return null;
      
      // Retornar un santo aleatorio como ejemplo
      // En producción, se podría mapear por fecha
      return saints.first;
    } catch (e) {
      debugPrint('Error loading local saint: $e');
      return null;
    }
  }

  /// Fallback: Obtiene santos por fecha desde contenido local
  Future<List<Map<String, dynamic>>> _getLocalSaintsByDate(DateTime date) async {
    try {
      await _localService.loadSaints();
      // Por ahora retornar todos los santos disponibles
      // En el futuro, se puede implementar búsqueda por fecha de celebración
      return _localService.getAllSaints();
    } catch (e) {
      debugPrint('Error loading local saints by date: $e');
      return [];
    }
  }

  /// Fallback: Obtiene santo por nombre desde contenido local
  Future<Map<String, dynamic>?> _getLocalSaintByName(String name) async {
    try {
      await _localService.loadSaints();
      final saints = _localService.getAllSaints();
      return saints.firstWhere(
        (s) => (s['name'] as String).toLowerCase().contains(name.toLowerCase()),
        orElse: () => saints.isNotEmpty ? saints.first : <String, dynamic>{},
      );
    } catch (e) {
      debugPrint('Error loading local saint by name: $e');
      return null;
    }
  }

  /// Verifica si la API está disponible
  Future<bool> isApiAvailable() async {
    // TODO: Implementar verificación real
    // try {
    //   final response = await http.get(
    //     Uri.parse('$_apiBaseUrl/health'),
    //     headers: {'Authorization': 'Bearer $_apiKey'},
    //   ).timeout(const Duration(seconds: 5));
    //   return response.statusCode == 200;
    // } catch (e) {
    //   return false;
    // }
    return false; // Por ahora siempre usar local
  }
}

