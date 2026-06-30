import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'module.dart';

/// Manages and registers plugin modules in VitalAI.
class ModuleRegistry {
  ModuleRegistry._privateConstructor();
  static final ModuleRegistry instance = ModuleRegistry._privateConstructor();

  final List<VitalModule> _modules = [];

  /// Registered modules.
  List<VitalModule> get modules => List.unmodifiable(_modules);

  /// Register a module to plug it into the application lifecycle.
  void registerModule(VitalModule module) {
    if (!_modules.any((m) => m.id == module.id)) {
      _modules.add(module);
    }
  }

  /// Gather GoRouter sub-routes from all registered modules.
  List<RouteBase> get allRoutes {
    return _modules.expand((m) => m.routes).toList();
  }

  /// Registers dependencies of all modules into the service locator.
  void registerModuleDependencies(GetIt locator) {
    for (final module in _modules) {
      module.registerDependencies(locator);
    }
  }
}
