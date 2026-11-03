import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'genui_question_type.dart';

/// Selectable option item for single-choice, multi-select, and ambiguous choices.
class FollowUpOption extends Equatable {
  final String label;
  final dynamic value;
  final String? subtitle;
  final IconData? icon;
  final bool isRecommended;
  final Map<String, dynamic> metadata;

  const FollowUpOption({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.isRecommended = false,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [label, value, subtitle, icon, isRecommended, metadata];
}

/// Follow-up question model driving interactive GenUI component rendering.
class FollowUpQuestion extends Equatable {
  final String id;
  final String targetField;
  final String promptText;
  final GenUiQuestionType questionType;
  final List<FollowUpOption> options;
  final Map<String, dynamic> metadata;
  final bool isOptional;
  final String? helpText;
  final dynamic initialValue;
  final String? unit;
  final double? minValue;
  final double? maxValue;

  const FollowUpQuestion({
    required this.id,
    required this.targetField,
    required this.promptText,
    required this.questionType,
    this.options = const [],
    this.metadata = const {},
    this.isOptional = false,
    this.helpText,
    this.initialValue,
    this.unit,
    this.minValue,
    this.maxValue,
  });

  FollowUpQuestion copyWith({
    String? id,
    String? targetField,
    String? promptText,
    GenUiQuestionType? questionType,
    List<FollowUpOption>? options,
    Map<String, dynamic>? metadata,
    bool? isOptional,
    String? helpText,
    dynamic initialValue,
    String? unit,
    double? minValue,
    double? maxValue,
  }) {
    return FollowUpQuestion(
      id: id ?? this.id,
      targetField: targetField ?? this.targetField,
      promptText: promptText ?? this.promptText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      metadata: metadata ?? this.metadata,
      isOptional: isOptional ?? this.isOptional,
      helpText: helpText ?? this.helpText,
      initialValue: initialValue ?? this.initialValue,
      unit: unit ?? this.unit,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
    );
  }

  @override
  List<Object?> get props => [
        id,
        targetField,
        promptText,
        questionType,
        options,
        metadata,
        isOptional,
        helpText,
        initialValue,
        unit,
        minValue,
        maxValue,
      ];
}
