import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/home_control/board_model.dart';
import '../../providers/home_control/dynamic_theme_provider.dart';
import '../../widgets/home_control/home_control_widgets.dart';
import 'switch_control_screen.dart';
import 'add_board_scan_screen.dart'; // <-- NEW IMPORT FOR THE SCANNER

class BoardListScreen extends StatefulWidget {
  final String homeId;
  final String homeName;
  final String? roomId;

  const BoardListScreen({
    super.key,
    required this.homeId,
    required this.homeName,
    this.roomId,
  });

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  final _supabase = Supabase.instance.client;
  List<Board> _boards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    // Base query for the home
    var query = _supabase
        .from('hc_boards')
        .select('*, hc_switches(*)')
        .eq('home_id', widget.homeId);

    // Filter by room, or look for unassigned boards
    if (widget.roomId != null) {
      query = query.eq('room_id', widget.roomId!);
    } else {
      // Use isFilter for newer Supabase SDK versions
      query = query.isFilter('room_id', null); 
    }

    final res = await query;
    
    if (mounted) {
      setState(() {
        _boards = (res as List).map((e) => Board.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }

  // Navigate to the new Scanner Screen
  void _openScannerScreen() {
    final theme = Provider.of<DynamicThemeProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: theme,
          child: AddBoardScanScreen(
            homeId: widget.homeId,
            roomId: widget.roomId,
          ),
        ),
      ),
    ).then((_) {
      // Refresh the board list when we return from the scanner
      _loadBoards(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<DynamicThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.homeName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedSkyBackground(
        isDarkMode: theme.isDarkMode,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _boards.isEmpty 
              ? const Center(
                  child: Text(
                    'No boards here yet.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  )
                )
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                itemCount: _boards.length,
                itemBuilder: (context, index) {
                  final board = _boards[index];
                  return GlassCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: theme,
                          child: SwitchControlScreen(
                            boardId: board.id,
                            boardName: board.name,
                          ),
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.developer_board,
                        color: board.status == BoardStatus.online
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(
                        board.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${board.switches.length} Switches',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScannerScreen,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        icon: const Icon(Icons.radar, color: Colors.white),
        label: const Text('Scan Nearby', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}