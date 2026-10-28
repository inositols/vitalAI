import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../data/models/activity_item.dart';
import 'activity_event.dart';
import 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository repository;

  ActivityBloc({required this.repository}) : super(ActivityInitial()) {
    on<ActivityListRequested>(_onActivityListRequested);
    on<ActivityLogged>(_onActivityLogged);
    on<ActivityCleared>(_onActivityCleared);
  }

  Future<void> _onActivityListRequested(
    ActivityListRequested event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    try {
      final items = await repository.getActivities(category: event.category);
      emit(ActivityLoadSuccess(
        activities: items,
        selectedCategory: event.category,
      ));
    } catch (e) {
      emit(ActivityFailure(e.toString()));
    }
  }

  Future<void> _onActivityLogged(
    ActivityLogged event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await repository.logActivity(event.item);
      final currentCategory = state is ActivityLoadSuccess
          ? (state as ActivityLoadSuccess).selectedCategory
          : ActivityCategory.all;
      final items = await repository.getActivities(category: currentCategory);
      emit(ActivityLoadSuccess(
        activities: items,
        selectedCategory: currentCategory,
      ));
    } catch (e) {
      emit(ActivityFailure(e.toString()));
    }
  }

  Future<void> _onActivityCleared(
    ActivityCleared event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    try {
      await repository.clearActivities();
      emit(const ActivityLoadSuccess(
        activities: [],
        selectedCategory: ActivityCategory.all,
      ));
    } catch (e) {
      emit(ActivityFailure(e.toString()));
    }
  }
}
