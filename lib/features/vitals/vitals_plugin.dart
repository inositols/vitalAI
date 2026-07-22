import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vitalai/core/database/db_service.dart';
import '../../core/plugin/module.dart';
import 'domain/repositories/vitals_repository.dart';
import 'data/repositories/vitals_repository_impl.dart';
import 'presentation/bloc/vitals_bloc.dart';
import 'presentation/widgets/vitals_metric_card.dart';

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
      () => VitalsRepositoryImpl(locator<DbService>()),
    );
    locator.registerFactory(
      () => VitalsBloc(vitalsRepository: locator<VitalsRepository>()),
    );
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
    return [
      VitalsMetricCard(metricType: 'bp', patientId: patientId),
      VitalsMetricCard(metricType: 'glucose', patientId: patientId),
    ];
  }

  @override
  Future<pw.Widget?> buildReportSection(
    String patientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
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
