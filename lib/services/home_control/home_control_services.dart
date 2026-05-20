import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class HomeControlService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  Future<Map<String, dynamic>> createHome({required String name}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final email = user.email ?? '';
    // Append 8 chars of the user's ID so the username is always unique
    // even when two accounts share the same email prefix.
    final uniqueUsername =
        '${email.isNotEmpty ? email.split('@').first : 'user'}'
        '_${user.id.replaceAll('-', '').substring(0, 8)}';

    // Ensure user_profiles row exists with a valid role.
    // The hc_homes RLS policy reads user_profiles.role; when no row exists
    // it evaluates to NULL / '' and PostgreSQL throws error 22023.
    // We SELECT first to avoid colliding on the username UNIQUE constraint.
    final existingProfile = await _supabase
        .from('user_profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existingProfile == null) {
      try {
        await _supabase.from('user_profiles').insert({
          'id': user.id,
          'username': uniqueUsername,
          'email': email,
          'role': 'user',
          'timezone': 'UTC',
        });
      } catch (_) {
        // Another concurrent insert may have won the race — safe to ignore.
      }
    }

    // Ensure user_api_settings has a valid hc_role.
    // Do NOT use ignoreDuplicates — we must also update rows that already
    // exist but have an empty/null hc_role, which also causes error 22023.
    await _supabase.from('user_api_settings').upsert({
      'user_id': user.id,
      'hc_role': 'user',
    }, onConflict: 'user_id');

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

  // Add this import at the top if not already there for date formatting
// import 'package:intl/intl.dart'; // Add 'intl' package to pubspec.yaml

  Future<String> generateShareCode(String homeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Generate date format: YYYYMMDDHHMM
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    // Format IDs as requested: ownerFirst-ownerLast-homeFirst-homeLast-date
    final ownerFirst = user.id.split('-').first;
    final ownerLast = user.id.split('-').last;
    final homeFirst = homeId.split('-').first;
    final homeLast = homeId.split('-').last;

    final referralCode = '$ownerFirst-$ownerLast-$homeFirst-$homeLast-$dateStr';

    // Set expiration to 7 days from now (adjustable)
    final expiresAt = now.add(const Duration(days: 7)).toIso8601String();

    await _supabase.from('hc_home_shares').insert({
      'home_id': homeId,
      'owner_id': user.id,
      'referral_code': referralCode,
      'expires_at': expiresAt,
      'can_control': true,
      'is_active': true,
      // shared_with_id is left null until someone claims it
    });

    return referralCode;
  }

  Future<void> joinSharedHome(String referralCode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Find the share record
    final shareResponse = await _supabase
        .from('hc_home_shares')
        .select()
        .eq('referral_code', referralCode.trim())
        .maybeSingle();

    if (shareResponse == null) {
      throw Exception('Invalid referral code.');
    }

    if (shareResponse['is_active'] == false) {
      throw Exception('This share link has been deactivated.');
    }

    final expiresAt = DateTime.parse(shareResponse['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('This share link has expired.');
    }

    if (shareResponse['shared_with_id'] != null && shareResponse['shared_with_id'] != user.id) {
      throw Exception('This code has already been claimed by another user.');
    }
    
    if (shareResponse['owner_id'] == user.id) {
      throw Exception('You already own this home!');
    }

    // 2. Claim the share by updating shared_with_id
    await _supabase
        .from('hc_home_shares')
        .update({'shared_with_id': user.id})
        .eq('id', shareResponse['id']);
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
