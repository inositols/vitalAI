import 'package:equatable/equatable.dart';

/// Represents a discrete choice option for single-choice and multiple-choice GenUI components.
class GenUiOption extends Equatable {
  final String id;
  final String label;
  final dynamic value;
  final String? subtitle;
  final String? iconName;
  final bool isSelected;
  final bool isExclusive;
  final Map<String, dynamic> metadata;

  const GenUiOption({
    required this.id,
    required this.label,
    required this.value,
    this.subtitle,
    this.iconName,
    this.isSelected = false,
    this.isExclusive = false,
    this.metadata = const {},
  });

  factory GenUiOption.fromJson(Map<String, dynamic> json) {
    return GenUiOption(
      id: json['id']?.toString() ?? json['value']?.toString() ?? UniqueOptionId.generate(),
      label: json['label']?.toString() ?? json['title']?.toString() ?? 'Option',
      value: json['value'] ?? json['id'] ?? json['label'],
      subtitle: json['subtitle']?.toString(),
      iconName: json['icon']?.toString() ?? json['iconName']?.toString(),
      isSelected: json['isSelected'] == true || json['selected'] == true,
      isExclusive: json['isExclusive'] == true,
      metadata: (json['metadata'] is Map)
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'value': value,
        if (subtitle != null) 'subtitle': subtitle,
        if (iconName != null) 'icon': iconName,
        'isSelected': isSelected,
        'isExclusive': isExclusive,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  GenUiOption copyWith({
    String? id,
    String? label,
    dynamic value,
    String? subtitle,
    String? iconName,
    bool? isSelected,
    bool? isExclusive,
    Map<String, dynamic>? metadata,
  }) {
    return GenUiOption(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      subtitle: subtitle ?? this.subtitle,
      iconName: iconName ?? this.iconName,
      isSelected: isSelected ?? this.isSelected,
      isExclusive: isExclusive ?? this.isExclusive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        value,
        subtitle,
        iconName,
        isSelected,
        isExclusive,
        metadata,
      ];
}

class UniqueOptionId {
  static int _counter = 0;
  static String generate() => 'opt_${DateTime.now().microsecondsSinceEpoch}_${++_counter}';
}

