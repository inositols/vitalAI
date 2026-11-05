import 'package:equatable/equatable.dart';
import 'package:vitalai/features/patients/data/models/clinical_note.dart';

abstract class ClinicalNotesEvent extends Equatable {
  const ClinicalNotesEvent();

  @override
  List<Object?> get props => [];
}

class ClinicalNotesRequested extends ClinicalNotesEvent {
  final int patientId;
  const ClinicalNotesRequested(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

class ClinicalNoteSaved extends ClinicalNotesEvent {
  final ClinicalNote note;
  const ClinicalNoteSaved(this.note);

  @override
  List<Object?> get props => [note];
}
