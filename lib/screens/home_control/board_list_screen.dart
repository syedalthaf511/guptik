import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/home_control/board_model.dart';
import '../../providers/home_control/dynamic_theme_provider.dart';
import 'switch_control_screen.dart';
import 'add_board_scan_screen.dart'; // <-- NEW IMPORT FOR THE SCANNER


// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

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
      ),
      body: Stack(
        children: [
          // The Shared Cinematic Nebula Background
          const Positioned.fill(child: DynamicAppBackground()),
          
          // Main Content
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _ancientGold))
              : _boards.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.developer_board,
                          size: 64,
                          color: _ancientGold.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No boards here yet.',
                          style: TextStyle(
                            color: _ancientGold, 
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap Scan Nearby to add a board',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    itemCount: _boards.length,
                    itemBuilder: (context, index) {
                      final board = _boards[index];
                      return Card(
                        color: Colors.transparent,
                        elevation: 8,
                        shadowColor: _ancientGold.withValues(alpha: 0.2),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _ancientGold.withValues(alpha: 0.4), 
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: board.status == BoardStatus.online
                                          ? Colors.greenAccent.withValues(alpha: 0.5)
                                          : Colors.redAccent.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.developer_board,
                                    color: board.status == BoardStatus.online
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                  ),
                                ),
                                title: Text(
                                  board.name,
                                  style: const TextStyle(
                                    color: _ancientGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  '${board.switches.length} Switches',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: _ancientGold,
                                  size: 16,
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
        onPressed: _openScannerScreen,
        backgroundColor: _ancientGold,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        icon: const Icon(Icons.radar, color: Colors.black),
        label: const Text(
          'Scan Nearby', 
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}