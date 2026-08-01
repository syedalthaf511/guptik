import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HomeControlService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  Future<Map<String, dynamic>> createHome({required String name}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final homeId = _uuid.v4();
    return await _supabase
        .from('hc_homes')
        .insert({
          'id': homeId,
          'user_id': user.id,
          'name': name,
          'is_active': true,
        })
        .select()
        .single();
  }

  Future<Map<String, dynamic>> checkBoardAvailability(String boardId) async {
    final boardResponse = await _supabase
        .from('hc_boards')
        .select()
        .eq('id', boardId)
        .maybeSingle();
    if (boardResponse == null) {
      return {
        'exists': false,
        'available': true,
        'message': 'Board ready to be claimed!',
      };
    }
    final hasOwner = boardResponse['owner_id'] != null;
    return {
      'exists': true,
      'available': !hasOwner,
      'message': hasOwner ? 'Board already assigned' : 'Board is available!',
      'board_name': boardResponse['name'],
    };
  }

  Future<Map<String, dynamic>> validateAndClaimBoard({
    required String boardId,
    required String homeId,
    String? customName,
    String? roomId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final boardResponse = await _supabase
        .from('hc_boards')
        .select()
        .eq('id', boardId)
        .maybeSingle();

    if (boardResponse == null) {
      await _supabase.from('hc_boards').insert({
        'id': boardId,
        'home_id': homeId,
        'room_id': roomId,
        'owner_id': user.id,
        'name': customName ?? 'Smart Switch $boardId',
        'status': 'online',
        'is_claimed': true,
        'is_active': true,
      });
      for (var i = 1; i <= 4; i++) {
        await _supabase.from('hc_switches').insert({
          'id': '${boardId}_switch_$i',
          'board_id': boardId,
          'name': 'Switch $i',
          'position': i,
          'state': false,
          'is_enabled': true,
        });
      }
    } else {
      if (boardResponse['owner_id'] != null &&
          boardResponse['owner_id'] != user.id) {
        throw Exception('Board already assigned.');
      }
      await _supabase
          .from('hc_boards')
          .update({
            'home_id': homeId,
            'room_id': roomId ?? boardResponse['room_id'],
            'owner_id': user.id,
            'name': customName ?? boardResponse['name'],
            'status': 'online',
            'is_claimed': true,
          })
          .eq('id', boardId);

      // Create 4 switches if none exist yet (ESP board registered itself
      // via heartbeat but switches are only created on claim).
      final existingSwitches = await _supabase
          .from('hc_switches')
          .select('id')
          .eq('board_id', boardId);

      if ((existingSwitches as List).isEmpty) {
        for (var i = 1; i <= 4; i++) {
          await _supabase.from('hc_switches').insert({
            'id': '${boardId}_switch_$i',
            'board_id': boardId,
            'name': 'Switch $i',
            'position': i,
            'state': false,
            'is_enabled': true,
          });
        }
      }
    }
    return await _supabase
        .from('hc_boards')
        .select('*, hc_switches(*)')
        .eq('id', boardId)
        .single();
  }
}

class LocalWallpaperService {
  static const String _wallpaperPrefsKey = 'home_wallpapers';
  static const String _wallpaperDirName = 'wallpapers';

  Future<String?> getHomeWallpaper(String homeId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = jsonDecode(prefs.getString(_wallpaperPrefsKey) ?? '{}');
    return map[homeId];
  }

  Future<String?> setHomeWallpaper({
    required String homeId,
    required String sourcePath,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_wallpaperDirName');
    if (!await dir.exists()) await dir.create(recursive: true);

    final ext = sourcePath.split('.').last;
    final newPath =
        '${dir.path}/home_${homeId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(sourcePath).copy(newPath);

    final prefs = await SharedPreferences.getInstance();
    final map = Map<String, dynamic>.from(
      jsonDecode(prefs.getString(_wallpaperPrefsKey) ?? '{}'),
    );
    map[homeId] = newPath;
    await prefs.setString(_wallpaperPrefsKey, jsonEncode(map));
    return newPath;
  }

  Future<void> removeHomeWallpaper(String homeId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = Map<String, dynamic>.from(
      jsonDecode(prefs.getString(_wallpaperPrefsKey) ?? '{}'),
    );
    if (map.containsKey(homeId)) {
      final file = File(map[homeId]);
      if (await file.exists()) await file.delete();
      map.remove(homeId);
      await prefs.setString(_wallpaperPrefsKey, jsonEncode(map));
    }
  }
}
