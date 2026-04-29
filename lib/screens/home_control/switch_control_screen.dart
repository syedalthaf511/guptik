import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/home_control/switch_model.dart';
import '../../models/home_control/switch_type.dart';
import '../../providers/home_control/dynamic_theme_provider.dart';
import '../../widgets/home_control/home_control_widgets.dart';
import 'timer_screen.dart';

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
  bool _isReordering = false; // Prevents stream listener from overriding UI mid-drag

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
    setState(() {
      final index = _switches.indexWhere((e) => e.id == s.id);
      if (index != -1) {
        _switches[index] = s.copyWith(state: !s.state);
      }
    });

    try {
      await _supabase
          .from('hc_switches')
          .update({'state': !s.state})
          .eq('id', s.id);
    } catch (e) {
      _loadSwitches();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        _supabase.from('hc_switches').update({'position': -(updatedSwitch1.position)}).eq('id', updatedSwitch1.id),
        _supabase.from('hc_switches').update({'position': -(updatedSwitch2.position)}).eq('id', updatedSwitch2.id),
      ]);

      // STEP 2: Save their final swapped positive positions
      await Future.wait([
        _supabase.from('hc_switches').update({'position': updatedSwitch1.position}).eq('id', updatedSwitch1.id),
        _supabase.from('hc_switches').update({'position': updatedSwitch2.position}).eq('id', updatedSwitch2.id),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to swap positions. Check connection.')),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          title: const Text('Add Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SwitchType>(
                // ignore: deprecated_member_use
                value: selectedType, 
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: SwitchType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(_getIconForType(t), size: 16),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addSwitch(nameController.text.trim(), selectedType);
                }
              },
              child: const Text('Add'),
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
          title: const Text('Edit Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SwitchType>(
                // ignore: deprecated_member_use
                value: selectedType,
                items: SwitchType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  _editSwitch(device, nameController.text, selectedType),
              child: const Text('Save'),
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
        title: const Text('Delete Device?'),
        content: Text('Are you sure you want to delete "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteSwitch(device.id),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(SwitchDevice device) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(device.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    _getIconForType(device.type),
                    size: 40,
                    color: device.state
                        ? Colors.yellowAccent
                        : Colors.white54,
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Switch(
                  value: device.state,
                  onChanged: (val) => _toggle(device),
                  activeTrackColor: Colors.cyanAccent,
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(
                Icons.alarm,
                color: Colors.white70,
                size: 20,
              ),
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
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white54,
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
    final theme = Provider.of<DynamicThemeProvider>(context);
    
    // Using MediaQuery to calculate exact tile dimensions for seamless dragging feedback
    final crossAxisCount = 2;
    final spacing = 16.0;
    final paddingX = 16.0 * 2;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - paddingX - (spacing * (crossAxisCount - 1))) / crossAxisCount;
    final itemHeight = itemWidth / 1.1; // Derived from childAspectRatio

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.boardName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedSkyBackground(
        isDarkMode: theme.isDarkMode,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white30, width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _showAddSwitchDialog,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 40,
                                color: Colors.white70,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Add Switch",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
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
      ),
    );
  }
}