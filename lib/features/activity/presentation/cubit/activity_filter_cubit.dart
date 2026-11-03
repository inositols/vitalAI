import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/activity_item.dart';

class ActivityFilterState extends Equatable {
  final ActivityCategory selectedCategory;
  final String searchQuery;
  final bool isAscending;

  const ActivityFilterState({
    this.selectedCategory = ActivityCategory.all,
    this.searchQuery = '',
    this.isAscending = false,
  });

  ActivityFilterState copyWith({
    ActivityCategory? selectedCategory,
    String? searchQuery,
    bool? isAscending,
  }) {
    return ActivityFilterState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isAscending: isAscending ?? this.isAscending,
    );
  }

  @override
  List<Object?> get props => [selectedCategory, searchQuery, isAscending];
}

/// Cubit managing focused presentation filter state for activity logs.
class ActivityFilterCubit extends Cubit<ActivityFilterState> {
  ActivityFilterCubit() : super(const ActivityFilterState());

  void selectCategory(ActivityCategory category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void toggleSortOrder() {
    emit(state.copyWith(isAscending: !state.isAscending));
  }

  void reset() {
    emit(const ActivityFilterState());
  }
}
