import 'switch_type.dart';

class SwitchDevice {
  final String id;
  final String boardId;
  final String name;
  final SwitchType type;
  final int position;
  final bool state;
  final bool isEnabled;

  SwitchDevice({
    required this.id,
    required this.boardId,
    required this.name,
    required this.type,
    required this.position,
    required this.state,
    this.isEnabled = true,
  });

  factory SwitchDevice.fromJson(Map<String, dynamic> json) {
    return SwitchDevice(
      id: json['id'],
      boardId: json['board_id'],
      name: json['name'],
      type: SwitchType.values.firstWhere(
        (t) => t.name == (json['type'] ?? 'light'),
        orElse: () => SwitchType.light,
      ),
      position: json['position'] ?? 0,
      state: json['state'] ?? false,
      isEnabled: json['is_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'name': name,
      'type': type.name,
      'position': position,
      'state': state,
      'is_enabled': isEnabled,
    };
  }

  SwitchDevice copyWith({
    String? name, 
    SwitchType? type, 
    bool? state, 
    int? position,
  }) {
    return SwitchDevice(
      id: id,
      boardId: boardId,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      state: state ?? this.state,
      isEnabled: isEnabled,
    );
  }
}