import 'package:equatable/equatable.dart';
import '../../data/models/vital_record.dart';

abstract class VitalsEvent extends Equatable {
  const VitalsEvent();

  @override
  List<Object?> get props => [];
}

class VitalsListRequested extends VitalsEvent {
  final int patientId;

  const VitalsListRequested(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

class VitalsFilteredRequested extends VitalsEvent {
  final int patientId;
  final String? vitalType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? abnormalOnly;

  const VitalsFilteredRequested({
    required this.patientId,
    this.vitalType,
    this.startDate,
    this.endDate,
    this.abnormalOnly,
  });

  @override
  List<Object?> get props => [patientId, vitalType, startDate, endDate, abnormalOnly];
}

class VitalsRecordSaved extends VitalsEvent {
  final VitalRecord record;

  const VitalsRecordSaved(this.record);

  @override
  List<Object?> get props => [record];
}

class VitalsRecordDeleted extends VitalsEvent {
  final int localId;
  final String remoteId;
  final int patientId;

  const VitalsRecordDeleted({
    required this.localId,
    required this.remoteId,
    required this.patientId,
  });

  @override
  List<Object?> get props => [localId, remoteId, patientId];
}
