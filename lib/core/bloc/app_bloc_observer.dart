import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Custom [BlocObserver] that provides diagnostic logging during development
/// while strictly preventing the leakage or logging of sensitive Patient Health
/// Information (PHI) or personal data.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      debugPrint('[Bloc Created] ${bloc.runtimeType}');
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode) {
      // Log event type only to protect patient confidentiality and avoid dumping PHI
      debugPrint('[Bloc Event] ${bloc.runtimeType} -> ${event.runtimeType}');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      // Only log the state types, never dump the internal fields directly
      debugPrint(
        '[Bloc Change] ${bloc.runtimeType}: '
        '${change.currentState.runtimeType} -> ${change.nextState.runtimeType}',
      );
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      debugPrint(
        '[Bloc Transition] ${bloc.runtimeType}: '
        '${transition.event.runtimeType} -> ${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (kDebugMode) {
      debugPrint('[Bloc Error] ${bloc.runtimeType}: ${error.runtimeType}');
    }
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (kDebugMode) {
      debugPrint('[Bloc Closed] ${bloc.runtimeType}');
    }
  }
}
