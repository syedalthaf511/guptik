import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

import '../../models/home_control/room_model.dart';
import '../../screens/home_control/board_list_screen.dart';
import '../../providers/home_control/dynamic_theme_provider.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class RoomListScreen extends StatefulWidget {
  final String homeId;
  final String homeName;

  const RoomListScreen({
    super.key,
    required this.homeId,
    required this.homeName,
  });

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _rooms = <Room>[];
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Load rooms from the specific home with their associated boards
      final response = await _supabase
          .from('hc_rooms')
          .select('*, hc_boards(*)')
          .eq('home_id', widget.homeId)
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (mounted) {
        setState(() {
          _rooms.clear();
          _rooms.addAll((response as List).map((room) => Room.fromJson(room)));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Error loading rooms: ${e.toString()}');
      }
    }
  }

  Future<void> _addRoom(String name, String? description, String? icon) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final roomId = _uuid.v4();
      final response = await _supabase
          .from('hc_rooms')
          .insert({
            'id': roomId,
            'home_id': widget.homeId,
            'name': name,
            'description': description,
            'icon': icon,
            'display_order': _rooms.length,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final newRoom = Room.fromJson(response);

      if (mounted) {
        setState(() {
          _rooms.add(newRoom);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room "$name" added successfully', style: const TextStyle(color: Colors.black)),
            backgroundColor: _ancientGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error adding room: ${e.toString()}');
      }
    }
  }

  Future<void> _editRoom(
    Room room,
    String newName,
    String? newDescription,
    String? newIcon,
  ) async {
    try {
      await _supabase
          .from('hc_rooms')
          .update({
            'name': newName,
            'description': newDescription,
            'icon': newIcon,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', room.id);

      if (mounted) {
        setState(() {
          final index = _rooms.indexWhere((r) => r.id == room.id);
          if (index != -1) {
            _rooms[index] = room.copyWith(
              name: newName,
              description: newDescription,
              icon: newIcon,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room updated to "$newName"', style: const TextStyle(color: Colors.black)),
            backgroundColor: _ancientGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error updating room: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteRoom(Room room) async {
    try {
      // First, move all boards in this room to "unassigned" (null room_id)
      await _supabase
          .from('hc_boards')
          .update({'room_id': null})
          .eq('room_id', room.id);

      // Then delete the room
      await _supabase.from('hc_rooms').delete().eq('id', room.id);

      if (mounted) {
        setState(() {
          _rooms.removeWhere((r) => r.id == room.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room "${room.name}" deleted', style: const TextStyle(color: Colors.black)),
            backgroundColor: _ancientGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error deleting room: ${e.toString()}');
      }
    }
  }

  void _showAddRoomDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedIcon = 'meeting_room';

    final List<Map<String, dynamic>> roomIcons = [
      {'icon': Icons.meeting_room, 'name': 'meeting_room', 'label': 'Living Room'},
      {'icon': Icons.bed, 'name': 'bed', 'label': 'Bedroom'},
      {'icon': Icons.kitchen, 'name': 'kitchen', 'label': 'Kitchen'},
      {'icon': Icons.bathtub, 'name': 'bathtub', 'label': 'Bathroom'},
      {'icon': Icons.restaurant, 'name': 'dining_room', 'label': 'Dining Room'},
      {'icon': Icons.work, 'name': 'work', 'label': 'Office'},
      {'icon': Icons.garage, 'name': 'garage', 'label': 'Garage'},
      {'icon': Icons.stairs, 'name': 'stairs', 'label': 'Stairs'},
      {'icon': Icons.balcony, 'name': 'balcony', 'label': 'Balcony'},
      {'icon': Icons.room, 'name': 'room', 'label': 'Other Room'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _ancientGold, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Add New Room', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: _ancientGold),
                  decoration: InputDecoration(
                    labelText: 'Room Name',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    hintText: 'Enter room name',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: _ancientGold),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    hintText: 'Enter room description',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Select Icon:', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roomIcons.map((iconData) {
                    final isSelected = selectedIcon == iconData['name'];
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedIcon = iconData['name'];
                        });
                      },
                      child: Container(
                        width: 70,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _ancientGold.withValues(alpha: 0.2) : Colors.black,
                          border: Border.all(color: isSelected ? _ancientGold : Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData['icon'],
                              color: isSelected ? _ancientGold : Colors.white54,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iconData['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected ? _ancientGold : Colors.white54,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
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
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _addRoom(
                    name,
                    description.isEmpty ? null : description,
                    selectedIcon,
                  );
                }
              },
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomOptionsDialog(Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _ancientGold.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(room.name, style: const TextStyle(color: _ancientGold, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: _ancientGold),
              title: const Text('Edit Room', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showEditRoomDialog(room);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Delete Room', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(room);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditRoomDialog(Room room) {
    final nameController = TextEditingController(text: room.name);
    final descriptionController = TextEditingController(text: room.description ?? '');
    String selectedIcon = room.icon ?? 'meeting_room';

    final List<Map<String, dynamic>> roomIcons = [
      {'icon': Icons.meeting_room, 'name': 'meeting_room', 'label': 'Living Room'},
      {'icon': Icons.bed, 'name': 'bed', 'label': 'Bedroom'},
      {'icon': Icons.kitchen, 'name': 'kitchen', 'label': 'Kitchen'},
      {'icon': Icons.bathtub, 'name': 'bathtub', 'label': 'Bathroom'},
      {'icon': Icons.restaurant, 'name': 'dining_room', 'label': 'Dining Room'},
      {'icon': Icons.work, 'name': 'work', 'label': 'Office'},
      {'icon': Icons.garage, 'name': 'garage', 'label': 'Garage'},
      {'icon': Icons.stairs, 'name': 'stairs', 'label': 'Stairs'},
      {'icon': Icons.balcony, 'name': 'balcony', 'label': 'Balcony'},
      {'icon': Icons.room, 'name': 'room', 'label': 'Other Room'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _ancientGold, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Edit Room', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: _ancientGold),
                  decoration: InputDecoration(
                    labelText: 'Room Name',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: _ancientGold),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Select Icon:', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roomIcons.map((iconData) {
                    final isSelected = selectedIcon == iconData['name'];
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedIcon = iconData['name'];
                        });
                      },
                      child: Container(
                        width: 70,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _ancientGold.withValues(alpha: 0.2) : Colors.black,
                          border: Border.all(color: isSelected ? _ancientGold : Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData['icon'],
                              color: isSelected ? _ancientGold : Colors.white54,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iconData['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected ? _ancientGold : Colors.white54,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
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
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _editRoom(
                    room,
                    name,
                    description.isEmpty ? null : description,
                    selectedIcon,
                  );
                }
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Delete Room', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${room.name}"?\n\n'
          'This will move all boards in this room to unassigned. '
          'This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom(room);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromName(String? iconName) {
    switch (iconName) {
      case 'meeting_room': return Icons.meeting_room;
      case 'bed': return Icons.bed;
      case 'kitchen': return Icons.kitchen;
      case 'bathtub': return Icons.bathtub;
      case 'dining_room': return Icons.restaurant;
      case 'work': return Icons.work;
      case 'garage': return Icons.garage;
      case 'stairs': return Icons.stairs;
      case 'balcony': return Icons.balcony;
      case 'room':
      default:
        return Icons.room;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.black)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: _darkBg,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              widget.homeName,
              style: const TextStyle(
                color: _ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.black.withValues(alpha: 0.7),
            elevation: 0,
            iconTheme: const IconThemeData(color: _ancientGold),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.developer_board_off,
                  color: _ancientGold,
                ),
                tooltip: 'View Unassigned Boards',
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return ChangeNotifierProvider.value(
                          value: themeProvider,
                          child: BoardListScreen(
                            homeName: '${widget.homeName} (Unassigned)',
                            homeId: widget.homeId,
                            roomId: null, 
                          ),
                        );
                      },
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Cinematic Nebula Background
              const Positioned.fill(child: DynamicAppBackground()),

              // Main Content
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _ancientGold))
                  : _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 64,
                            color: _ancientGold.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No rooms added yet',
                            style: TextStyle(color: _ancientGold, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to add your first room',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        return Hero(
                          tag: 'room-${room.id}',
                          child: Card(
                            color: Colors.transparent,
                            elevation: 8,
                            shadowColor: _ancientGold.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) {
                                        return ChangeNotifierProvider.value(
                                          value: themeProvider,
                                          child: BoardListScreen(
                                            homeName: room.name, 
                                            homeId: widget.homeId,
                                            roomId: room.id, 
                                          ),
                                        );
                                      },
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      // Top row with menu button
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: _ancientGold,
                                                size: 20,
                                              ),
                                              onPressed: () => _showRoomOptionsDialog(room),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Center icon
                                      Expanded(
                                        child: Center(
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _ancientGold.withValues(alpha: 0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _getIconFromName(room.icon),
                                              size: 30,
                                              color: _ancientGold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Room name and board count
                                      Column(
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            room.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _ancientGold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${room.boards.length} boards',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddRoomDialog,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Add Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: _ancientGold,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
          ),
        );
      },
    );
  }
}
