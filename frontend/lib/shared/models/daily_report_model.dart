import 'equipment_model.dart';
import 'material_model.dart';
import 'personnel_model.dart';
import 'visitor_model.dart';

class DailyReportModel {
  String reportNumber;
  String projectName;
  DateTime reportDate;
  String weather;
  double temperature;
  String shift;
  String preparedBy;
  String approvedBy;
  String workPerformed;
  String delays;
  String hse;
  String remarks;
  String status;

  List<PersonnelModel> personnel;
  List<EquipmentModel> equipment;
  List<MaterialModel> materials;
  List<VisitorModel> visitors;
  List<String> photos;

  DailyReportModel({
    required this.reportNumber,
    required this.projectName,
    required this.reportDate,
    required this.weather,
    required this.temperature,
    required this.shift,
    required this.preparedBy,
    required this.approvedBy,
    required this.workPerformed,
    required this.delays,
    required this.hse,
    required this.remarks,
    required this.status,
    required this.personnel,
    required this.equipment,
    required this.materials,
    required this.visitors,
    required this.photos,
  });
}