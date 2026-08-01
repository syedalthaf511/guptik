import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/home_control/switch_model.dart';
import '../../models/home_control/switch_type.dart';
import '../../services/home_control/hc_websocket_service.dart';
import 'timer_screen.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class SwitchControlScreen extends StatefulWidget {
  final String boardId;
  final String boardName;
  const SwitchControlScreen({
    super.key,
    required this.boardId,
    required this.boardName,
  });

  @override
  State<SwitchControlScreen> createState() => _SwitchControlScreenState();
}

class _SwitchControlScreenState extends State<SwitchControlScreen>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  List<SwitchDevice> _switches = [];
  bool _isLoading = true;
  bool _isReordering =
      false; // Prevents stream listener from overriding UI mid-drag

  late AnimationController _fanController;

  @override
  void initState() {
    super.initState();
    _fanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _loadSwitches();
    _subscribe();
  }

  @override
  void dispose() {
    _fanController.dispose();
    super.dispose();
  }

  void _subscribe() {
    _supabase
        .channel('public:hc_switches:board_id=${widget.boardId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hc_switches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: widget.boardId,
          ),
          callback: (payload) {
            // Ignore realtime updates if we are actively saving a reorder
            if (!_isReordering) {
              _loadSwitches();
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadSwitches() async {
    try {
      final res = await _supabase
          .from('hc_switches')
          .select()
          .eq('board_id', widget.boardId)
          .order('position');

      if (mounted) {
        setState(() {
          _switches = (res as List)
              .map((e) => SwitchDevice.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(SwitchDevice s) async {
    final newState = !s.state;

    setState(() {
      final index = _switches.indexWhere((e) => e.id == s.id);
      if (index != -1) {
        _switches[index] = s.copyWith(state: newState);
      }
    });

    try {
      // 1. Write to Supabase DB
      await _supabase
          .from('hc_switches')
          .update({'state': newState})
          .eq('id', s.id);

      // 2. Broadcast to ESP via WebSocket
      await HcWebSocketService().toggleSwitch(
        boardId: widget.boardId,
        position: s.position,
        state: newState,
      );
    } catch (e) {
      _loadSwitches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Handles drag & drop by SWAPPING the two switches
  Future<void> _reorderSwitches(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return; // Do nothing if dropped in the same spot

    setState(() {
      _isReordering = true;

      // 1. Get the two items being swapped
      final item1 = _switches[oldIndex];
      final item2 = _switches[newIndex];

      // 2. Save their current position numbers
      final pos1 = item1.position;
      final pos2 = item2.position;

      // 3. Put them in each other's spots in the local list, with swapped positions
      _switches[oldIndex] = item2.copyWith(position: pos1);
      _switches[newIndex] = item1.copyWith(position: pos2);
    });

    try {
      // Get the newly updated items from the list
      final updatedSwitch1 = _switches[oldIndex];
      final updatedSwitch2 = _switches[newIndex];

      // STEP 1: Move ONLY these two to temporary negative positions to clear the constraint
      await Future.wait([
        _supabase
            .from('hc_switches')
            .update({'position': -(updatedSwitch1.position)})
            .eq('id', updatedSwitch1.id),
        _supabase
            .from('hc_switches')
            .update({'position': -(updatedSwitch2.position)})
            .eq('id', updatedSwitch2.id),
      ]);

      // STEP 2: Save their final swapped positive positions
      await Future.wait([
        _supabase
            .from('hc_switches')
            .update({'position': updatedSwitch1.position})
            .eq('id', updatedSwitch1.id),
        _supabase
            .from('hc_switches')
            .update({'position': updatedSwitch2.position})
            .eq('id', updatedSwitch2.id),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to swap positions. Check connection.',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReordering = false;
        });
        _loadSwitches(); // Sync with database just to be 100% sure
      }
    }
  }

  // ... CRUD Actions ...

  Future<void> _addSwitch(String name, SwitchType type) async {
    try {
      await _supabase.from('hc_switches').insert({
        'id': _uuid.v4(),
        'board_id': widget.boardId,
        'name': name,
        'type': type.name,
        'position': _switches.length + 1,
        'state': false,
        'is_enabled': true,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _editSwitch(
    SwitchDevice s,
    String newName,
    SwitchType newType,
  ) async {
    try {
      await _supabase
          .from('hc_switches')
          .update({'name': newName, 'type': newType.name})
          .eq('id', s.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteSwitch(String id) async {
    try {
      await _supabase.from('hc_timers').delete().eq('switch_id', id);
      await _supabase.from('hc_switches').delete().eq('id', id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ... Dialogs ...

  void _showAddSwitchDialog() {
    final nameController = TextEditingController();
    SwitchType selectedType = SwitchType.light;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _ancientGold, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Add Device',
            style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: _ancientGold),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _ancientGold.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: _ancientGold),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SwitchType>(
                // ignore: deprecated_member_use
                value: selectedType,
                dropdownColor: Colors.black,
                style: const TextStyle(color: _ancientGold),
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _ancientGold.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: _ancientGold),
                  ),
                ),
                items: SwitchType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(
                              _getIconForType(t),
                              size: 16,
                              color: _ancientGold,
                            ),
                            const SizedBox(width: 8),
                            Text(t.name.toUpperCase()),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _ancientGold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addSwitch(nameController.text.trim(), selectedType);
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(SwitchDevice device) {
    final nameController = TextEditingController(text: device.name);
    SwitchType selectedType = device.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _ancientGold, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Edit Device',
            style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: _ancientGold),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _ancientGold.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: _ancientGold),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SwitchType>(
                // ignore: deprecated_member_use
                value: selectedType,
                dropdownColor: Colors.black,
                style: const TextStyle(color: _ancientGold),
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _ancientGold.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: _ancientGold),
                  ),
                ),
                items: SwitchType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(
                              _getIconForType(t),
                              size: 16,
                              color: _ancientGold,
                            ),
                            const SizedBox(width: 8),
                            Text(t.name.toUpperCase()),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _ancientGold,
                foregroundColor: Colors.black,
              ),
              onPressed: () =>
                  _editSwitch(device, nameController.text, selectedType),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(SwitchDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Delete Device?',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${device.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteSwitch(device.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(SwitchDevice device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
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
            Text(
              device.name,
              style: const TextStyle(
                color: _ancientGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: _ancientGold),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(device);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(SwitchType type) {
    switch (type) {
      case SwitchType.fan:
        return Icons.mode_fan_off;
      case SwitchType.ac:
        return Icons.ac_unit;
      case SwitchType.light:
        return Icons.lightbulb;
      case SwitchType.tv:
        return Icons.tv;
      default:
        return Icons.power_settings_new;
    }
  }

  // Refactored visual body of the Switch Card to reuse during Drag Feedback
  Widget _buildSwitchCard(SwitchDevice device) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ancientGold.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (device.type == SwitchType.fan && device.state)
                  RotationTransition(
                    turns: _fanController,
                    child: Icon(
                      _getIconForType(device.type),
                      size: 40,
                      color: _ancientGold,
                    ),
                  )
                else
                  Icon(
                    _getIconForType(device.type),
                    size: 40,
                    color: device.state ? _ancientGold : Colors.white30,
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: device.state ? _ancientGold : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Switch(
                  value: device.state,
                  onChanged: (val) => _toggle(device),
                  activeTrackColor: _ancientGold,
                  activeColor: Colors.black,
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.white24,
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.alarm, color: _ancientGold, size: 20),
              tooltip: 'Manage Timers',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimerScreen(
                      boardId: widget.boardId,
                      boardName: widget.boardName,
                      switches: _switches,
                      initialSwitchId: device.id,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              icon: Icon(
                Icons.more_vert,
                color: _ancientGold.withValues(alpha: 0.7),
                size: 20,
              ),
              tooltip: 'Options',
              onPressed: () => _showOptionsSheet(device),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using MediaQuery to calculate exact tile dimensions for seamless dragging feedback
    final crossAxisCount = 2;
    final spacing = 16.0;
    final paddingX = 16.0 * 2;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth =
        (screenWidth - paddingX - (spacing * (crossAxisCount - 1))) /
        crossAxisCount;
    final itemHeight = itemWidth / 1.1; // Derived from childAspectRatio

    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.boardName,
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
          child: Container(
            color: _ancientGold.withValues(alpha: 0.2),
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // The Shared Cinematic Nebula Background
          const Positioned.fill(child: DynamicAppBackground()),

          // Main Content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _ancientGold),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _switches.length + 1,
                  itemBuilder: (context, index) {
                    // Add Switch Button
                    if (index == _switches.length) {
                      return Card(
                        elevation: 0,
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _ancientGold.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _showAddSwitchDialog,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 40,
                                    color: _ancientGold.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Add Switch",
                                    style: TextStyle(
                                      color: _ancientGold.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // Switch Card wrapped in DragTarget & LongPressDraggable
                    final device = _switches[index];

                    return DragTarget<int>(
                      onAcceptWithDetails: (details) {
                        final oldIndex = details.data;
                        if (oldIndex != index) {
                          _reorderSwitches(oldIndex, index);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return LongPressDraggable<int>(
                          data: index,
                          // Ghost visualization held under the finger
                          feedback: Material(
                            type: MaterialType.transparency,
                            child: SizedBox(
                              width: itemWidth,
                              height: itemHeight,
                              child: Opacity(
                                opacity: 0.8,
                                child: _buildSwitchCard(device),
                              ),
                            ),
                          ),
                          // The faded original item left behind in the grid
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildSwitchCard(device),
                          ),
                          // Default non-dragging view
                          child: _buildSwitchCard(device),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
