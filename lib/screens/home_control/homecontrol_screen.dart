import 'dart:io';
import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Models
import '../../models/home_control/home_model.dart';
import '../../services/home_control/home_control_services.dart';
import '../../providers/home_control/dynamic_theme_provider.dart';
import 'rooms_list_screen.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class HomecontrolScreen extends StatelessWidget {
  const HomecontrolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the DynamicThemeProvider here
    return ChangeNotifierProvider(
      create: (_) => DynamicThemeProvider(),
      child: const HomeControlBody(),
    );
  }
}

class HomeControlBody extends StatefulWidget {
  const HomeControlBody({super.key});

  @override
  State<HomeControlBody> createState() => _HomeControlBodyState();
}

class _HomeControlBodyState extends State<HomeControlBody> {
  final _supabase = Supabase.instance.client;
  final _wallpaperService = LocalWallpaperService();
  final _homeService = HomeControlService();
  List<Home> _homes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  Future<void> _loadHomes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch both boards and rooms to satisfy the Home model
      final response = await _supabase
          .from('hc_homes')
          .select('*, hc_boards(*), hc_rooms(*)')
          .eq('user_id', user.id);

      final homes = <Home>[];

      for (var data in response) {
        final home = Home.fromJson(data);
        final wallpaper = await _wallpaperService.getHomeWallpaper(home.id);

        // Reconstruct home with local wallpaper path
        homes.add(
          Home(
            id: home.id,
            userId: home.userId,
            name: home.name,
            wallpaperPath: wallpaper,
            boards: home.boards,
            rooms: home.rooms,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _homes = homes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading homes: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: _ancientGold,
          ),
        );
      }
    }
  }

  Future<void> _addHome() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('New Home', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: _ancientGold),
          decoration: InputDecoration(
            hintText: 'Home Name',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _ancientGold),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _ancientGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await _homeService.createHome(name: controller.text.trim());
                  _loadHomes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding home: $e', style: const TextStyle(color: Colors.black)),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHome(Home home) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Delete Home?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${home.name}"?\n\nThis will delete all rooms and boards associated with this home. This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('hc_homes').delete().eq('id', home.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Home "${home.name}" deleted', style: const TextStyle(color: Colors.black)),
            backgroundColor: _ancientGold,
          )
        );
        _loadHomes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting home: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _setWallpaper(Home home) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _wallpaperService.setHomeWallpaper(
        homeId: home.id,
        sourcePath: image.path,
      );
      _loadHomes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<DynamicThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: const Text(
          'My Homes',
          style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: _ancientGold.withValues(alpha: 0.2),
            height: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _ancientGold,
            ),
            onPressed: () => theme.updateDarkMode(!theme.isDarkMode),
          ),
        ],
      ),
      body: Stack(
        children: [
          // The Cinematic Nebula Background
          const Positioned.fill(child: DynamicAppBackground()),
          
          // The Main Content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _ancientGold),
                )
              : _homes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 64,
                        color: _ancientGold,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No homes yet',
                        style: TextStyle(color: _ancientGold, fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ancientGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _addHome,
                        child: const Text('Create First Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  itemCount: _homes.length,
                  itemBuilder: (context, index) {
                    final home = _homes[index];
                    return Card(
                      color: Colors.transparent,
                      elevation: 8,
                      shadowColor: _ancientGold.withValues(alpha: 0.2),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                          color: Colors.black.withValues(alpha: 0.6),
                          image: home.wallpaperPath != null
                              ? DecorationImage(
                                  image: FileImage(File(home.wallpaperPath!)),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withValues(alpha: 0.3), 
                                    BlendMode.darken
                                  ),
                                )
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: theme,
                                  child: RoomListScreen(
                                    homeId: home.id,
                                    homeName: home.name,
                                  ),
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Optional fallback gradient if no wallpaper is set
                                if (home.wallpaperPath == null)
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _ancientGold.withValues(alpha: 0.15),
                                          Colors.transparent,
                                          _ancientGold.withValues(alpha: 0.05),
                                        ],
                                      ),
                                    ),
                                  ),
                                
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Text(
                                    home.name,
                                    style: const TextStyle(
                                      color: _ancientGold,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          '${home.rooms.length} Rooms',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          '${home.boards.length} Boards',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: PopupMenuButton(
                                    color: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      side: const BorderSide(color: _ancientGold, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: _ancientGold,
                                    ),
                                    onSelected: (val) {
                                      if (val == 'wallpaper') _setWallpaper(home);
                                      if (val == 'delete') _deleteHome(home);
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'wallpaper',
                                        child: Text('Set Wallpaper', style: TextStyle(color: _ancientGold)),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete Home',
                                          style: TextStyle(color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHome,
        backgroundColor: _ancientGold,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}

