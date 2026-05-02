import 'package:flutter/material.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/home_control/switch_model.dart';
import '../../models/home_control/switch_type.dart';
import '../../models/home_control/timer_model.dart';



// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

enum TimerType { scheduled, prescheduled, countdown }

class TimerScreen extends StatefulWidget {
  final String boardId;
  final String boardName;
  final List<SwitchDevice> switches;
  final String? initialSwitchId;

  const TimerScreen({
    super.key,
    required this.boardId,
    required this.boardName,
    required this.switches,
    this.initialSwitchId,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final _supabase = Supabase.instance.client;
  List<SwitchTimer> _timers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimers();
  }

  Future<void> _loadTimers() async {
    try {
      final switchIds = widget.switches.map((s) => s.id).toList();
      if (switchIds.isEmpty) {
        setState(() {
          _timers = [];
          _isLoading = false;
        });
        return;
      }

      final response = await _supabase
          .from('hc_timers')
          .select('*')
          .filter('switch_id', 'in', switchIds);

      if (!mounted) return;

      setState(() {
        _timers = List<Map<String, dynamic>>.from(
          response,
        ).map((data) => SwitchTimer.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error loading timers: ${e.toString()}');
      }
    }
  }

  // Helper: Convert Day String to Integer for DB (1=Mon ... 7=Sun)
  int _dayToInt(String day) {
    switch (day) {
      case 'Mon': return 1;
      case 'Tue': return 2;
      case 'Wed': return 3;
      case 'Thu': return 4;
      case 'Fri': return 5;
      case 'Sat': return 6;
      case 'Sun': return 7;
      default: return 1;
    }
  }

  // Helper: Convert Integer to String for Display
  String _intToDay(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  // Helper to theme the Date/Time pickers so they match the app
  ThemeData _getPickerTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: _ancientGold,
        onPrimary: Colors.black,
        surface: Colors.black,
        onSurface: _ancientGold,
      ),
      dialogBackgroundColor: Colors.black,
    );
  }

  Future<void> _showAddTimerDialog() async {
    TimeOfDay selectedTime = TimeOfDay.now();

    SwitchDevice? selectedSwitch;
    // Logic to select initial switch safely
    if (widget.initialSwitchId != null) {
      try {
        selectedSwitch = widget.switches.firstWhere(
          (s) => s.id == widget.initialSwitchId,
        );
      } catch (_) {
        selectedSwitch = widget.switches.isNotEmpty ? widget.switches.first : null;
      }
    } else {
      selectedSwitch = widget.switches.isNotEmpty ? widget.switches.first : null;
    }

    bool turnOn = true;
    bool isTimerEnabled = true;
    TimerType timerType = TimerType.scheduled;
    List<String> selectedDays = [];
    DateTime? scheduledDate;
    int countdownMinutes = 30;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _ancientGold, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Add Timer', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<TimerType>(
                  initialValue: timerType,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: _ancientGold),
                  decoration: InputDecoration(
                    labelText: 'Timer Type',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                  ),
                  items: TimerType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    timerType = value!;
                    if (value == TimerType.prescheduled) {
                      scheduledDate = DateTime.now().add(const Duration(days: 1));
                    }
                  }),
                ),
                const SizedBox(height: 16),

                // --- SCHEDULED UI ---
                if (timerType == TimerType.scheduled) ...[
                  ListTile(
                    title: const Text('Time', style: TextStyle(color: Colors.white70)),
                    trailing: Builder(
                      builder: (innerContext) {
                        return TextButton(
                          style: TextButton.styleFrom(foregroundColor: _ancientGold),
                          child: Text(selectedTime.format(innerContext), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: innerContext,
                              initialTime: selectedTime,
                              builder: (context, child) => Theme(data: _getPickerTheme(), child: child!),
                            );
                            if (time != null) {
                              setState(() => selectedTime = time);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  Divider(color: _ancientGold.withValues(alpha: 0.2)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Select Days:', style: TextStyle(fontSize: 16, color: _ancientGold, fontWeight: FontWeight.bold)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map(
                          (day) => FilterChip(
                            label: Text(day),
                            labelStyle: TextStyle(
                              color: selectedDays.contains(day) ? Colors.black : Colors.white70,
                              fontWeight: selectedDays.contains(day) ? FontWeight.bold : FontWeight.normal,
                            ),
                            selected: selectedDays.contains(day),
                            selectedColor: _ancientGold,
                            checkmarkColor: Colors.black,
                            backgroundColor: Colors.black,
                            shape: StadiumBorder(side: BorderSide(color: _ancientGold.withValues(alpha: 0.5))),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ]
                // --- PRESCHEDULED UI ---
                else if (timerType == TimerType.prescheduled) ...[
                  ListTile(
                    title: const Text('Date and Time', style: TextStyle(color: Colors.white70)),
                    trailing: Builder(
                      builder: (innerContext) {
                        return TextButton(
                          style: TextButton.styleFrom(foregroundColor: _ancientGold),
                          child: Text(
                            scheduledDate != null
                                ? '${scheduledDate!.day}/${scheduledDate!.month} ${selectedTime.format(innerContext)}'
                                : 'Select',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final DateTime? date = await showDatePicker(
                              context: innerContext,
                              initialDate: scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) => Theme(data: _getPickerTheme(), child: child!),
                            );
                            if (date != null) {
                              setState(() => scheduledDate = date);
                              // ignore: use_build_context_synchronously
                              if (!innerContext.mounted) return;

                              final TimeOfDay? time = await showTimePicker(
                                context: innerContext,
                                initialTime: selectedTime,
                                builder: (context, child) => Theme(data: _getPickerTheme(), child: child!),
                              );
                              if (time != null) {
                                setState(() => selectedTime = time);
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ]
                // --- COUNTDOWN UI ---
                else if (timerType == TimerType.countdown) ...[
                  ListTile(
                    title: const Text('Duration (minutes)', style: TextStyle(color: Colors.white70)),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: _ancientGold),
                        decoration: InputDecoration(
                          labelText: 'Minutes',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                        ),
                        onChanged: (value) {
                          final minutes = int.tryParse(value);
                          if (minutes != null && minutes > 0) {
                            setState(() => countdownMinutes = minutes);
                          }
                        },
                        controller: TextEditingController(
                          text: countdownMinutes.toString(),
                        ),
                      ),
                    ),
                  ),
                ],
                Divider(color: _ancientGold.withValues(alpha: 0.2)),
                SwitchListTile(
                  title: const Text('Timer State', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Enable or disable this timer', style: TextStyle(color: Colors.grey[500])),
                  value: isTimerEnabled,
                  activeColor: Colors.black,
                  activeTrackColor: _ancientGold,
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.white24,
                  onChanged: (value) => setState(() => isTimerEnabled = value),
                ),
                Divider(color: _ancientGold.withValues(alpha: 0.2)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Select Switch:', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold, fontSize: 16)),
                ),

                // ✅ FIX: Replaced individual RadioListTile properties with RadioGroup
                if (widget.switches.isEmpty)
                  const Text(
                    "No switches found",
                    style: TextStyle(color: Colors.redAccent),
                  )
                else
                  RadioGroup<SwitchDevice>(
                    groupValue: selectedSwitch,
                    onChanged: (SwitchDevice? value) {
                      setState(() => selectedSwitch = value);
                    },
                    child: Column(
                      children: widget.switches
                          .map(
                            (switch_) => RadioListTile<SwitchDevice>(
                              title: Text(switch_.name, style: const TextStyle(color: Colors.white70)),
                              value: switch_,
                              groupValue: selectedSwitch,
                              activeColor: _ancientGold,
                              onChanged: (SwitchDevice? value) {
                                setState(() => selectedSwitch = value);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),

                Divider(color: _ancientGold.withValues(alpha: 0.2)),
                SwitchListTile(
                  title: const Text('Action', style: TextStyle(color: Colors.white)),
                  subtitle: Text(turnOn ? 'Turn ON' : 'Turn OFF', style: TextStyle(color: turnOn ? _ancientGold : Colors.redAccent)),
                  value: turnOn,
                  activeColor: Colors.black,
                  activeTrackColor: _ancientGold,
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.5),
                  onChanged: (value) => setState(() => turnOn = value),
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
              onPressed: selectedSwitch == null
                  ? null
                  : () async {
                      try {
                        if (timerType == TimerType.prescheduled && scheduledDate == null) {
                          throw Exception('Scheduled date is required');
                        }
                        if (timerType == TimerType.scheduled && selectedDays.isEmpty) {
                          throw Exception('At least one day must be selected');
                        }

                        final String timeStr;
                        if (timerType == TimerType.countdown) {
                          timeStr = countdownMinutes.toString();
                        } else {
                          timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                        }

                        List<int> dbDaysOfWeek = [];
                        if (timerType == TimerType.scheduled) {
                          dbDaysOfWeek = selectedDays.map((d) => _dayToInt(d)).toList();
                        }

                        // ✅ FIX: Fixed the DateTime.now() missing parentheses
                        final timerData = {
                          'id': const Uuid().v4(),
                          'switch_id': selectedSwitch!.id,
                          'user_id': _supabase.auth.currentUser!.id,
                          'name': 'Timer for ${selectedSwitch!.name}',
                          'is_enabled': isTimerEnabled,
                          'time': timeStr,
                          'days_of_week': dbDaysOfWeek,
                          'action': turnOn,
                          'type': timerType.name.toLowerCase(),
                          'scheduled_date': timerType == TimerType.prescheduled
                              ? DateTime(
                                  scheduledDate!.year,
                                  scheduledDate!.month,
                                  scheduledDate!.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                ).toUtc().toIso8601String()
                              : null,
                          'created_at': DateTime.now().toUtc().toIso8601String(),
                          'updated_at': DateTime.now().toUtc().toIso8601String(),
                        };

                        await _supabase.from('hc_timers').insert(timerData);

                        if (!context.mounted) return;

                        Navigator.pop(context);
                        _loadTimers();
                        _showMessage('Timer created successfully!');
                      } catch (e) {
                        if (context.mounted) {
                          _showError('Error creating timer: ${e.toString()}');
                        }
                      }
                    },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTimer(SwitchTimer timer) async {
    final newState = !timer.isActive;

    try {
      await _supabase
          .from('hc_timers')
          .update({
            'is_enabled': newState,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', timer.id);

      _loadTimers();
    } catch (e) {
      _showError('Error updating timer: ${e.toString()}');
    }
  }

  Future<void> _deleteTimer(SwitchTimer timer) async {
    try {
      await _supabase.from('hc_timers').delete().eq('id', timer.id);
      _loadTimers();
      _showMessage('Timer deleted successfully!');
    } catch (e) {
      _showError('Error deleting timer: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  String _getSwitchName(String switchId) {
    final switch_ = widget.switches.firstWhere(
      (s) => s.id == switchId,
      orElse: () => SwitchDevice(
        id: '',
        boardId: '',
        name: 'Unknown Switch',
        type: SwitchType.light,
        position: 0,
        state: false,
      ),
    );
    return switch_.name;
  }

  String _formatTimerTitle(SwitchTimer timer) {
    final switchName = _getSwitchName(timer.switchId);
    return '$switchName - ${timer.time.format(context)}';
  }

  String _formatTimerSubtitle(SwitchTimer timer) {
    final action = timer.action ? 'Turn ON' : 'Turn OFF';

    List<String> activeDays = [];
    for (int i = 0; i < 7; i++) {
      if (timer.repeatDays.length > i && timer.repeatDays[i]) {
        activeDays.add(_intToDay(i + 1));
      }
    }

    if (activeDays.isNotEmpty) {
      return '$action on ${activeDays.join(', ')}';
    }
    return '$action (Once)';
  }

  IconData _getTimerIcon(bool action) {
    return action ? Icons.power : Icons.power_off;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${widget.boardName} Timers', style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _ancientGold), onPressed: _loadTimers),
        ],
      ),
      body: Stack(
        children: [
          // The Shared Cinematic Nebula Background
          const Positioned.fill(child: AnimatedNebulaBackground()),
          
          // Main Content
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _ancientGold))
              : _timers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_off, size: 64, color: _ancientGold.withValues(alpha: 0.8)),
                      const SizedBox(height: 16),
                      const Text(
                        'No timers configured',
                        style: TextStyle(fontSize: 20, color: _ancientGold, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap + to add a timer',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  itemCount: _timers.length,
                  itemBuilder: (context, index) {
                    final timer = _timers[index];
                    return Card(
                      color: Colors.transparent,
                      elevation: 8,
                      shadowColor: _ancientGold.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: timer.action 
                                    ? Colors.greenAccent.withValues(alpha: 0.5) 
                                    : Colors.redAccent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Icon(
                              _getTimerIcon(timer.action),
                              color: timer.action ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                          title: Text(
                            _formatTimerTitle(timer),
                            style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _formatTimerSubtitle(timer),
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: timer.isActive,
                                activeColor: Colors.black,
                                activeTrackColor: _ancientGold,
                                inactiveThumbColor: Colors.grey[400],
                                inactiveTrackColor: Colors.white24,
                                onChanged: (value) => _toggleTimer(timer),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(color: _ancientGold, width: 1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text('Delete Timer', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      content: const Text('Are you sure you want to delete this timer?', style: TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.black,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteTimer(timer);
                                          },
                                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTimerDialog,
        backgroundColor: _ancientGold,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Add Timer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}