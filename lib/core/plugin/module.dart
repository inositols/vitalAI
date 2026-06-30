import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;

/// The base contract for all plug-in modules in VitalAI.
/// Implementing this interface allows a module to extend the application's
/// routing, local database, dependency injection, dashboard tiles, and PDF reports.
abstract class VitalModule {
  /// The unique identifier of this module (e.g. "vitals", "sleep").
  String get id;

  /// The human-readable name of the module.
  String get name;

  /// The display icon associated with this module.
  IconData get icon;

  /// Register dependency injection elements for the module.
  void registerDependencies(GetIt locator);

  /// Define GoRouter sub-routes for this feature module.
  List<RouteBase> get routes;

  /// Build dashboard items for this module.
  /// Each item will be displayed as a widget card on the patient's dashboard.
  List<Widget> buildDashboardCards(BuildContext context, String patientId);

  /// Generate elements for this module to print on patient reports.
  /// If the module does not support report generation for the given patient, return null.
  Future<pw.Widget?> buildReportSection(
    String patientId,
    DateTime startDate,
    DateTime endDate,
  );
}
