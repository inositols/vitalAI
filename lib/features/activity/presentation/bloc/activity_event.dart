import 'package:equatable/equatable.dart';
import '../../data/models/activity_item.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

class ActivityListRequested extends ActivityEvent {
  final ActivityCategory category;

  const ActivityListRequested({this.category = ActivityCategory.all});

  @override
  List<Object?> get props => [category];
}

class ActivityLogged extends ActivityEvent {
  final ActivityItem item;

  const ActivityLogged(this.item);

  @override
  List<Object?> get props => [item];
}

class ActivityCleared extends ActivityEvent {
  const ActivityCleared();
}
