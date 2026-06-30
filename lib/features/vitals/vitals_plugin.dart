import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/plugin/module.dart';
import 'domain/repositories/vitals_repository.dart';
import 'data/repositories/vitals_repository_impl.dart';
import 'presentation/bloc/vitals_bloc.dart';

/// Pluggable health vitals module registration wrapper.
class VitalsPlugin implements VitalModule {
  @override
  String get id => 'vitals';

  @override
  String get name => 'Health Vitals';

  @override
  IconData get icon => Icons.favorite;

  @override
  void registerDependencies(GetIt locator) {
    locator.registerLazySingleton<VitalsRepository>(
      () => VitalsRepositoryImpl(locator()),
    );
    locator.registerFactory(() => VitalsBloc(vitalsRepository: locator()));
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: '/vitals/add',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text("Add Vital Reading Screen"))),
    ),
  ];

  @override
  List<Widget> buildDashboardCards(BuildContext context, String patientId) {
    // Return custom trend tiles for display on active patient dashboard
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Blood Pressure Summary",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Latest: 120/80 mmHg (Normal)",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Blood Glucose Trend",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Latest: 95 mg/dL (Fasting - Normal)",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Future<pw.Widget?> buildReportSection(
    String patientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Build a neat PDF text section for report rendering
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Health Vitals Log Summary",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            "Report shows recorded blood pressure, blood glucose, temperature, pulse rate, oxygen saturation and body weight trends between ${startDate.toLocal()} and ${endDate.toLocal()}.",
          ),
        ],
      ),
    );
  }
}
