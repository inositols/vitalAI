import 'package:equatable/equatable.dart';
import '../../data/models/activity_item.dart';

abstract class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoadSuccess extends ActivityState {
  final List<ActivityItem> activities;
  final ActivityCategory selectedCategory;

  const ActivityLoadSuccess({
    required this.activities,
    this.selectedCategory = ActivityCategory.all,
  });

  @override
  List<Object?> get props => [activities, selectedCategory];
}

class ActivityFailure extends ActivityState {
  final String message;

  const ActivityFailure(this.message);

  @override
  List<Object?> get props => [message];
}
