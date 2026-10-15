import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/daily_report_model.dart';

final dailyReportProvider =
    StateNotifierProvider<DailyReportNotifier, DailyReportModel>(
  (ref) => DailyReportNotifier(),
);

class DailyReportNotifier extends StateNotifier<DailyReportModel> {
  DailyReportNotifier()
      : super(
          DailyReportModel(
            reportNumber: 'DR-0001',
            projectName: '',
            reportDate: DateTime.now(),
            weather: '',
            temperature: 0,
            shift: '',
            preparedBy: '',
            approvedBy: '',
            workPerformed: '',
            delays: '',
            hse: '',
            remarks: '',
            status: 'Draft',
            personnel: [],
            equipment: [],
            materials: [],
            visitors: [],
            photos: [],
          ),
        );

  //-------------------------
  // Report Information
  //-------------------------

  void setProjectName(String value) {
    state.projectName = value;
    state = state;
  }

  void setReportDate(DateTime value) {
    state.reportDate = value;
    state = state;
  }

  void setWeather(String value) {
    state.weather = value;
    state = state;
  }

  void setTemperature(double value) {
    state.temperature = value;
    state = state;
  }

  void setShift(String value) {
    state.shift = value;
    state = state;
  }

  void setPreparedBy(String value) {
    state.preparedBy = value;
    state = state;
  }

  void setApprovedBy(String value) {
    state.approvedBy = value;
    state = state;
  }

  //-------------------------
  // Work
  //-------------------------

  void setWorkPerformed(String value) {
    state.workPerformed = value;
    state = state;
  }

  void setDelays(String value) {
    state.delays = value;
    state = state;
  }

  //-------------------------
  // HSE
  //-------------------------

  void setHse(String value) {
    state.hse = value;
    state = state;
  }

  //-------------------------
  // Remarks
  //-------------------------

  void setRemarks(String value) {
    state.remarks = value;
    state = state;
  }

  //-------------------------
  // Status
  //-------------------------

  void setStatus(String value) {
    state.status = value;
    state = state;
  }

  //-------------------------
  // Entire Report
  //-------------------------

  void replaceReport(DailyReportModel report) {
    state = report;
  }

  //-------------------------
  // Reset
  //-------------------------

  void reset() {
    state = DailyReportModel(
      reportNumber: 'DR-0001',
      projectName: '',
      reportDate: DateTime.now(),
      weather: '',
      temperature: 0,
      shift: '',
      preparedBy: '',
      approvedBy: '',
      workPerformed: '',
      delays: '',
      hse: '',
      remarks: '',
      status: 'Draft',
      personnel: [],
      equipment: [],
      materials: [],
      visitors: [],
      photos: [],
    );
  }
}