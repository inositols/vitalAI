import 'package:equatable/equatable.dart';
import '../../data/models/vital_record.dart';

abstract class VitalsState extends Equatable {
  const VitalsState();

  @override
  List<Object?> get props => [];
}

class VitalsInitial extends VitalsState {}

class VitalsLoading extends VitalsState {}

class VitalsLoadSuccess extends VitalsState {
  final List<VitalRecord> records;

  const VitalsLoadSuccess(this.records);

  @override
  List<Object?> get props => [records];
}

class VitalsFailure extends VitalsState {
  final String message;

  const VitalsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
