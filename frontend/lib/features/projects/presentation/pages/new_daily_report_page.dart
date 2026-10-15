import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/daily_report_pdf_service.dart';
import '../../../../core/services/daily_report_service.dart';

class NewDailyReportPage extends StatefulWidget {
  final int projectId;
  final String projectName;
  final Map<String, dynamic>? existingReport;

  const NewDailyReportPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.existingReport,
  });

  @override
  State<NewDailyReportPage> createState() => _NewDailyReportPageState();
}

class _NewDailyReportPageState extends State<NewDailyReportPage> {
  // ============================================================
  // GENERAL
  // ============================================================

  int _currentStep = 0;
  bool _isSaving = false;

  bool get _isEditing => widget.existingReport != null;

  int? get _editingReportId =>
      widget.existingReport?['id'] as int?;

  final ImagePicker _imagePicker = ImagePicker();
  final DailyReportService _dailyReportService = DailyReportService();
  final DailyReportPdfService _pdfService = DailyReportPdfService();

  bool _isPrinting = false;

  static const List<String> _stepNames = [
    'Site Info',
    'Personnel',
    'Equipment',
    'Executed Work',
    'Materials',
    'Next Day',
    'Issues',
    'Photos & Files',
    'Endorsements',
  ];

  // ============================================================
  // STEP 1 - SITE INFORMATION
  // ============================================================

  DateTime _reportDate = DateTime.now();

  final TextEditingController _weatherController =
      TextEditingController(text: 'Sunny');

  final TextEditingController _windSpeedController =
      TextEditingController();

  final TextEditingController _temperatureController =
      TextEditingController();

  final TextEditingController _moistureController =
      TextEditingController();

  final TextEditingController _weatherNotesController =
      TextEditingController();

  // ============================================================
  // STEP 2 - PERSONNEL
  // ============================================================

  final List<PersonnelRow> _keyPersonnel = [
    PersonnelRow('Project Manager', 0),
    PersonnelRow('Site Manager', 0),
    PersonnelRow('Technical Office', 0),
    PersonnelRow('Land Surveying Engineer', 0),
    PersonnelRow('Assistant Surveyor', 0),
    PersonnelRow('Electrical & Auto Engineer', 0),
    PersonnelRow('Electrical Technician', 0),
    PersonnelRow('Mechanical Engineer', 0),
    PersonnelRow('HSE Engineer', 0),
    PersonnelRow('Doctor', 0),
    PersonnelRow('Foreman', 0),
    PersonnelRow('QA/QC Engineer', 0),
    PersonnelRow('Sandwich Panel Worker', 0),
    PersonnelRow('Metal Worker', 0),
    PersonnelRow('Road Workers', 0),
  ];

  final List<PersonnelRow> _administrationPersonnel = [
    PersonnelRow('Admin Officer', 0),
    PersonnelRow('Storekeeper', 0),
    PersonnelRow('Procurement Officer', 0),
    PersonnelRow('Material Accountant', 0),
    PersonnelRow('Laboratory Technician', 0),
    PersonnelRow('Chef', 0),
    PersonnelRow('Cleaner', 0),
  ];

  final List<PersonnelRow> _operatorsPersonnel = [
    PersonnelRow('B.P. Manager', 0),
    PersonnelRow('Mobile Crane Operator', 0),
    PersonnelRow('Gas Installer', 0),
    PersonnelRow('Car Mechanic', 0),
    PersonnelRow('Mixer Driver', 0),
    PersonnelRow('Truck Driver', 0),
    PersonnelRow('Driver', 0),
    PersonnelRow('Excavator Operator', 0),
    PersonnelRow('Machinery Mechanic', 0),
    PersonnelRow('Mechanical Technician', 0),
    PersonnelRow('Skilled Labour', 0),
    PersonnelRow('Unskilled Labour', 0),
  ];

  final List<PersonnelRow> _workers = [
    PersonnelRow('Formwork Labour', 0),
    PersonnelRow('Rebar Labour', 0),
    PersonnelRow('Welder', 0),
    PersonnelRow('Guard', 0),
    PersonnelRow('Pipe-layer', 0),
    PersonnelRow('Plasterer', 0),
    PersonnelRow('Facade Worker', 0),
    PersonnelRow('Bricklayer', 0),
    PersonnelRow('Roofer', 0),
    PersonnelRow('Puttyer', 0),
  ];

  // ============================================================
  // STEP 3 - EQUIPMENT
  // ============================================================

  final List<EquipmentRow> _equipment = [
    EquipmentRow('Excavator', 0, 0),
    EquipmentRow('Mobile Concrete Pump', 0, 0),
    EquipmentRow('Dump Truck', 0, 0),
    EquipmentRow('Grader Machine', 0, 0),
    EquipmentRow('Loader', 0, 0),
    EquipmentRow('Concrete Vibrator', 0, 0),
    EquipmentRow('Butterfly Trowel', 0, 0),
    EquipmentRow('Trowel Vibrator', 0, 0),
    EquipmentRow('Truck Mixer', 0, 0),
    EquipmentRow('Water Tank', 0, 0),
    EquipmentRow('Asphalt Paving Machine', 0, 0),
    EquipmentRow('Roller Compactor', 0, 0),
    EquipmentRow('Truck Mounted Crane', 0, 0),
    EquipmentRow('Dewatering Pumps', 0, 0),
    EquipmentRow('Bar Bending Machine', 0, 0),
    EquipmentRow('Fuel Tank', 0, 0),
    EquipmentRow('Welding Machine', 0, 0),
    EquipmentRow('Bar Cutting Machine', 0, 0),
    EquipmentRow('PVC/PE Welder', 0, 0),
    EquipmentRow('Mobile Crane', 0, 0),
    EquipmentRow('Compressor EPA', 0, 0),
    EquipmentRow('Car', 0, 0),
    EquipmentRow('Power Supply Generator 150 KVA', 0, 0),
    EquipmentRow('Transformer', 0, 0),
    EquipmentRow('Tractor', 0, 0),
    EquipmentRow('Power Supply Generator 250 KVA', 0, 0),
    EquipmentRow('Bus', 0, 0),
    EquipmentRow('GPS', 0, 0),
    EquipmentRow('Total Station', 0, 0),
    EquipmentRow('Minibus', 0, 0),
    EquipmentRow('Batching Plant', 0, 0),
  ];

  // ============================================================
  // STEP 4 - EXECUTED WORK
  // ============================================================

  final List<ExecutedWorkRow> _executedWork = [
    ExecutedWorkRow(
      location: '',
      description: '',
      unit: '',
      totalPhysicalVolume: '',
      sinceBeginning: '',
      quantity: '',
      completedPercent: '',
    ),
  ];

  // ============================================================
  // STEP 5 - MATERIALS
  // ============================================================

  final List<MaterialRow> _materials = [
    MaterialRow(
      material: '',
      unit: '',
      number: '',
    ),
  ];

  // ============================================================
  // STEP 6 - NEXT DAY
  // ============================================================

  final List<NextDayWorkRow> _nextDayWork = [
    NextDayWorkRow(
      location: '',
      description: '',
    ),
  ];

  // ============================================================
  // STEP 7 - GENERAL ISSUES
  // ============================================================

  final TextEditingController _generalIssuesController =
      TextEditingController();

  // ============================================================
  // STEP 8 - PHOTOS & FILES
  // ============================================================

  final List<ReportAttachment> _attachments = [];

  // ============================================================
  // STEP 9 - ENDORSEMENTS
  // ============================================================

  final TextEditingController _preparedByController =
      TextEditingController();

  final TextEditingController _preparedByPositionController =
      TextEditingController(text: 'Technical Office');

  final TextEditingController _confirmedByController =
      TextEditingController();

  final TextEditingController _confirmedByPositionController =
      TextEditingController(text: 'Site Manager');

  final TextEditingController _approvedByController =
      TextEditingController();

  final TextEditingController _approvedByPositionController =
      TextEditingController(text: 'Supervisor');

  // ============================================================
  // INIT (EDIT MODE PRE-FILL)
  // ============================================================

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic>? report = widget.existingReport;

    if (report == null) {
      return;
    }

    final String? reportDate = report['reportDate'] as String?;

    if (reportDate != null) {
      _reportDate = DateTime.parse(reportDate).toLocal();
    }

    _weatherController.text = (report['weather'] as String?) ?? '';
    _windSpeedController.text = _numberToText(report['windSpeed']);
    _temperatureController.text = _numberToText(report['temperature']);
    _moistureController.text = _numberToText(report['moisture']);
    _generalIssuesController.text =
        (report['generalIssues'] as String?) ?? '';

    _preparedByController.text = (report['preparedBy'] as String?) ?? '';
    _preparedByPositionController.text =
        (report['preparedByRole'] as String?) ?? 'Technical Office';

    _confirmedByController.text = (report['confirmedBy'] as String?) ?? '';
    _confirmedByPositionController.text =
        (report['confirmedByRole'] as String?) ?? 'Site Manager';

    _approvedByController.text = (report['approvedBy'] as String?) ?? '';
    _approvedByPositionController.text =
        (report['approvedByRole'] as String?) ?? 'Supervisor';

    final List<dynamic> personnel =
        (report['personnel'] as List<dynamic>?) ?? [];

    _fillPersonnelCategory(_keyPersonnel, personnel, 'Key Personnel');
    _fillPersonnelCategory(
      _administrationPersonnel,
      personnel,
      'Administration Staff',
    );
    _fillPersonnelCategory(_operatorsPersonnel, personnel, 'Operators');
    _fillPersonnelCategory(_workers, personnel, 'Worker');

    final List<dynamic> equipment =
        (report['equipment'] as List<dynamic>?) ?? [];

    if (equipment.isNotEmpty) {
      for (final item in _equipment) {
        item.dispose();
      }

      _equipment
        ..clear()
        ..addAll(
          equipment.map(
            (item) => EquipmentRow(
              (item['equipment'] as String?) ?? '',
              (item['active'] as num?)?.toInt() ?? 0,
              (item['total'] as num?)?.toInt() ?? 0,
            ),
          ),
        );
    }

    final List<dynamic> executedWork =
        (report['executedWork'] as List<dynamic>?) ?? [];

    if (executedWork.isNotEmpty) {
      for (final item in _executedWork) {
        item.dispose();
      }

      _executedWork
        ..clear()
        ..addAll(
          executedWork.map(
            (item) => ExecutedWorkRow(
              location: (item['location'] as String?) ?? '',
              description: (item['description'] as String?) ?? '',
              unit: (item['unit'] as String?) ?? '',
              totalPhysicalVolume:
                  (item['totalPhysicalVolume'] as String?) ?? '',
              sinceBeginning: (item['sinceBeginning'] as String?) ?? '',
              quantity: (item['quantity'] as String?) ?? '',
              completedPercent:
                  (item['completedPercent'] as String?) ?? '',
            ),
          ),
        );
    }

    final List<dynamic> materials =
        (report['materials'] as List<dynamic>?) ?? [];

    if (materials.isNotEmpty) {
      for (final item in _materials) {
        item.dispose();
      }

      _materials
        ..clear()
        ..addAll(
          materials.map(
            (item) => MaterialRow(
              material: (item['material'] as String?) ?? '',
              unit: (item['unit'] as String?) ?? '',
              number: (item['number'] as String?) ?? '',
            ),
          ),
        );
    }

    final List<dynamic> nextDayWork =
        (report['nextDayWork'] as List<dynamic>?) ?? [];

    if (nextDayWork.isNotEmpty) {
      for (final item in _nextDayWork) {
        item.dispose();
      }

      _nextDayWork
        ..clear()
        ..addAll(
          nextDayWork.map(
            (item) => NextDayWorkRow(
              location: (item['location'] as String?) ?? '',
              description: (item['description'] as String?) ?? '',
            ),
          ),
        );
    }

    final List<dynamic> attachments =
        (report['attachments'] as List<dynamic>?) ?? [];

    if (attachments.isNotEmpty) {
      _attachments.addAll(
        attachments.map(
          (item) => ReportAttachment(
            id: (item['id'] as num?)?.toInt(),
            name: (item['originalName'] as String?) ?? 'file',
            size: _formatFileSize(
              (item['fileSize'] as num?)?.toInt() ?? 0,
            ),
            isPhoto: item['isPhoto'] == true,
            url: _dailyReportService.attachmentUrl(
              (item['filePath'] as String?) ?? '',
            ),
          ),
        ),
      );
    }
  }

  void _fillPersonnelCategory(
    List<PersonnelRow> target,
    List<dynamic> source,
    String category,
  ) {
    final List<dynamic> matches = source
        .where((item) => item['category'] == category)
        .toList();

    if (matches.isEmpty) {
      return;
    }

    for (final item in target) {
      item.dispose();
    }

    target
      ..clear()
      ..addAll(
        matches.map(
          (item) => PersonnelRow(
            (item['position'] as String?) ?? '',
            (item['count'] as num?)?.toInt() ?? 0,
          ),
        ),
      );
  }

  String _numberToText(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is num) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }

      return value.toString();
    }

    return value.toString();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _weatherController.dispose();
    _windSpeedController.dispose();
    _temperatureController.dispose();
    _moistureController.dispose();
    _weatherNotesController.dispose();

    _generalIssuesController.dispose();

    _preparedByController.dispose();
    _preparedByPositionController.dispose();

    _confirmedByController.dispose();
    _confirmedByPositionController.dispose();

    _approvedByController.dispose();
    _approvedByPositionController.dispose();

    for (final item in _keyPersonnel) {
      item.dispose();
    }

    for (final item in _administrationPersonnel) {
      item.dispose();
    }

    for (final item in _operatorsPersonnel) {
      item.dispose();
    }

    for (final item in _workers) {
      item.dispose();
    }

    for (final item in _equipment) {
      item.dispose();
    }

    for (final item in _executedWork) {
      item.dispose();
    }

    for (final item in _materials) {
      item.dispose();
    }

    for (final item in _nextDayWork) {
      item.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Daily Report - ${widget.projectName}'
              : 'New Daily Report - ${widget.projectName}',
        ),
        centerTitle: false,
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Print / Export PDF',
              onPressed: _isPrinting ? null : _printReport,
              icon: _isPrinting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print_outlined),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 850;

          return Column(
            children: [
              if (isDesktop)
                _buildDesktopProgress()
              else
                _buildMobileProgress(),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 28 : 12,
                    vertical: 20,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1250,
                      ),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
              ),

              _buildNavigation(),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // PROGRESS BAR - DESKTOP
  // ============================================================

  Widget _buildDesktopProgress() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            _stepNames.length,
            (index) {
              final bool active = index == _currentStep;
              final bool completed = index < _currentStep;

              return Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: index <= _currentStep
                        ? () {
                            setState(() {
                              _currentStep = index;
                            });
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      child: SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor:
                                  active || completed
                                      ? AppColors.primary
                                      : AppColors.border,
                              child: completed
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stepNames[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (index < _stepNames.length - 1)
                    Container(
                      width: 22,
                      height: 2,
                      margin: const EdgeInsets.only(
                        bottom: 23,
                      ),
                      color: completed
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESS BAR - MOBILE
  // ============================================================

  Widget _buildMobileProgress() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1} of ${_stepNames.length}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _stepNames[_currentStep],
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _stepNames.length,
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT STEP
  // ============================================================

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSiteInformation();
      case 1:
        return _buildPersonnel();
      case 2:
        return _buildEquipment();
      case 3:
        return _buildExecutedWork();
      case 4:
        return _buildMaterials();
      case 5:
        return _buildNextDayWork();
      case 6:
        return _buildGeneralIssues();
      case 7:
        return _buildPhotosAndFiles();
      case 8:
        return _buildEndorsements();
      default:
        return _buildSiteInformation();
    }
  }

  // ============================================================
  // STEP 1 - SITE INFO
  // ============================================================

  Widget _buildSiteInformation() {
    return _sectionCard(
      title: 'Site Daily Report',
      subtitle: 'General information and site weather conditions',
      icon: Icons.assignment_outlined,
      children: [
        _projectInformationCard(),

        const SizedBox(height: 24),

        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Report Date *',
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            child: Text(
              _formatDate(_reportDate),
            ),
          ),
        ),

        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, constraints) {
            final bool mobile = constraints.maxWidth < 750;

            final fields = [
              _textField(
                controller: _weatherController,
                label: 'Weather *',
                hint: 'Sunny',
                icon: Icons.wb_sunny_outlined,
              ),
              _textField(
                controller: _windSpeedController,
                label: 'Wind Speed',
                hint: '1.8',
                icon: Icons.air,
                suffix: 'm/s',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _textField(
                controller: _temperatureController,
                label: 'Temperature *',
                hint: '38',
                icon: Icons.thermostat,
                suffix: '°C',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _textField(
                controller: _moistureController,
                label: 'Moisture',
                hint: '24',
                icon: Icons.water_drop_outlined,
                suffix: '%',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ];

            if (mobile) {
              return Column(
                children: [
                  for (int i = 0; i < fields.length; i++) ...[
                    fields[i],
                    if (i < fields.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (int i = 0; i < fields.length; i++) ...[
                  Expanded(child: fields[i]),
                  if (i < fields.length - 1)
                    const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        TextField(
          controller: _weatherNotesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Weather / Site Notes',
            hintText:
                'Optional notes about rain, heat, visibility, wind or site conditions...',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 22),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryBox(
              'Day',
              _reportDate.day.toString(),
            ),
            _summaryBox(
              'Month',
              _monthName(_reportDate.month),
            ),
            _summaryBox(
              'Year',
              _reportDate.year.toString(),
            ),
            _summaryBox(
              'Day of Week',
              _weekdayName(_reportDate),
            ),
          ],
        ),
      ],
    );
  }

  Widget _projectInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            child: Icon(
              Icons.business,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.projectName,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project ID: ${widget.projectId}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2 - PERSONNEL
  // ============================================================

  Widget _buildPersonnel() {
    final int keyTotal = _personnelTotal(_keyPersonnel);

    final int adminTotal =
        _personnelTotal(_administrationPersonnel);

    final int operatorsTotal =
        _personnelTotal(_operatorsPersonnel);

    final int workerTotal =
        _personnelTotal(_workers);

    final int total =
        keyTotal + adminTotal + operatorsTotal + workerTotal;

    return _sectionCard(
      title: '1. Contractor Personnel',
      subtitle:
          'Personnel working at the construction site today',
      icon: Icons.groups_outlined,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              'Key Personnel',
              keyTotal,
              Icons.engineering,
            ),
            _statCard(
              'Administration',
              adminTotal,
              Icons.admin_panel_settings_outlined,
            ),
            _statCard(
              'Operators',
              operatorsTotal,
              Icons.precision_manufacturing_outlined,
            ),
            _statCard(
              'Worker',
              workerTotal,
              Icons.construction,
            ),
            _statCard(
              'Total Personnel',
              total,
              Icons.people_alt_outlined,
            ),
          ],
        ),

        const SizedBox(height: 30),

        _personnelCategory(
          title: 'Key Personnel',
          list: _keyPersonnel,
        ),

        const SizedBox(height: 30),

        _personnelCategory(
          title: 'Administration Staff',
          list: _administrationPersonnel,
        ),

        const SizedBox(height: 30),

        _personnelCategory(
          title: 'Operators',
          list: _operatorsPersonnel,
        ),

        const SizedBox(height: 30),

        _personnelCategory(
          title: 'Worker',
          list: _workers,
        ),
      ],
    );
  }

  Widget _personnelCategory({
    required String title,
    required List<PersonnelRow> list,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Total: ${_personnelTotal(list)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...List.generate(
          list.length,
          (index) {
            return _personnelRow(
              list,
              index,
            );
          },
        ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              list.add(
                PersonnelRow('', 0),
              );
            });
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Personnel',
          ),
        ),
      ],
    );
  }

  Widget _personnelRow(
    List<PersonnelRow> list,
    int index,
  ) {
    final PersonnelRow row = list[index];

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 550) {
            return Column(
              children: [
                TextField(
                  controller: row.positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position / Job',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _quantityStepper(
                      controller: row.countController,
                      label: 'No.',
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () {
                        setState(() {
                          row.dispose();
                          list.removeAt(index);
                        });
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position / Job',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _quantityStepper(
                controller: row.countController,
                label: 'No.',
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Remove',
                onPressed: () {
                  setState(() {
                    row.dispose();
                    list.removeAt(index);
                  });
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _personnelTotal(
    List<PersonnelRow> list,
  ) {
    return list.fold<int>(
      0,
      (sum, item) => sum + item.count,
    );
  }

  // ============================================================
  // STEP 3 - EQUIPMENT
  // ============================================================

  Widget _buildEquipment() {
    return _sectionCard(
      title: '2. Contractor Site Equipment',
      subtitle:
          'Active equipment and total equipment available at site',
      icon: Icons.precision_manufacturing_outlined,
      children: [
        ...List.generate(
          _equipment.length,
          (index) => _equipmentRow(index),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _equipment.add(
                EquipmentRow('', 0, 0),
              );
            });
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Equipment',
          ),
        ),
      ],
    );
  }

  Widget _equipmentRow(int index) {
    final EquipmentRow item = _equipment[index];

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 620) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: item.nameController,
                      decoration: const InputDecoration(
                        labelText: 'Equipment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment:
                          WrapCrossAlignment.end,
                      children: [
                        _quantityStepper(
                          controller: item.activeController,
                          label: 'Active',
                        ),
                        _quantityStepper(
                          controller: item.totalController,
                          label: 'Total',
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              item.dispose();
                              _equipment.removeAt(index);
                            });
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Equipment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _quantityStepper(
                controller: item.activeController,
                label: 'Active',
              ),
              const SizedBox(width: 10),
              _quantityStepper(
                controller: item.totalController,
                label: 'Total',
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Remove',
                onPressed: () {
                  setState(() {
                    item.dispose();
                    _equipment.removeAt(index);
                  });
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STEP 4 - EXECUTED WORK
  // ============================================================

  Widget _buildExecutedWork() {
    return _sectionCard(
      title: '3. Executed Work',
      subtitle:
          'Record all activities completed during the reporting day',
      icon: Icons.handyman_outlined,
      children: [
        ...List.generate(
          _executedWork.length,
          (index) => _executedWorkCard(index),
        ),

        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _executedWork.add(
                ExecutedWorkRow(
                  location: '',
                  description: '',
                  unit: '',
                  totalPhysicalVolume: '',
                  sinceBeginning: '',
                  quantity: '',
                  completedPercent: '',
                ),
              );
            });
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Executed Work',
          ),
        ),
      ],
    );
  }

  Widget _executedWorkCard(int index) {
    final ExecutedWorkRow row =
        _executedWork[index];

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Work Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _executedWork.length == 1
                      ? null
                      : () {
                          setState(() {
                            row.dispose();
                            _executedWork.removeAt(index);
                          });
                        },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _responsiveFields([
              _fieldData(
                row.locationController,
                'Location',
              ),
              _fieldData(
                row.descriptionController,
                'Description of Work',
                flex: 2,
              ),
            ]),

            const SizedBox(height: 12),

            _responsiveFields([
              _fieldData(
                row.unitController,
                'Unit',
              ),
              _fieldData(
                row.totalPhysicalVolumeController,
                'Total Physical Volume',
              ),
              _fieldData(
                row.sinceBeginningController,
                'Since Beginning',
              ),
              _fieldData(
                row.quantityController,
                'Today Qty.',
              ),
              _fieldData(
                row.completedPercentController,
                'Completed %',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 5 - MATERIALS
  // ============================================================

  Widget _buildMaterials() {
    return _sectionCard(
      title: '4. Contractor Materials',
      subtitle:
          'Materials delivered, received or used at the site',
      icon: Icons.inventory_2_outlined,
      children: [
        ...List.generate(
          _materials.length,
          (index) => _materialRow(index),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _materials.add(
                MaterialRow(
                  material: '',
                  unit: '',
                  number: '',
                ),
              );
            });
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Material',
          ),
        ),
      ],
    );
  }

  Widget _materialRow(int index) {
    final MaterialRow item = _materials[index];

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: item.materialController,
                      decoration: const InputDecoration(
                        labelText: 'Material',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: item.unitController,
                            decoration:
                                const InputDecoration(
                              labelText: 'Unit',
                              border:
                                  OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller:
                                item.numberController,
                            decoration:
                                const InputDecoration(
                              labelText: 'Quantity',
                              border:
                                  OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              item.dispose();
                              _materials.removeAt(index);
                            });
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: item.materialController,
                  decoration: const InputDecoration(
                    labelText: 'Material',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: item.unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: item.numberController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    item.dispose();
                    _materials.removeAt(index);
                  });
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STEP 6 - NEXT DAY
  // ============================================================

  Widget _buildNextDayWork() {
    return _sectionCard(
      title: '5. Work Programme for the Next Day',
      subtitle:
          'Activities planned for the following working day',
      icon: Icons.event_note_outlined,
      children: [
        ...List.generate(
          _nextDayWork.length,
          (index) => _nextDayWorkRow(index),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _nextDayWork.add(
                NextDayWorkRow(
                  location: '',
                  description: '',
                ),
              );
            });
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Planned Work',
          ),
        ),
      ],
    );
  }

  Widget _nextDayWorkRow(int index) {
    final NextDayWorkRow item =
        _nextDayWork[index];

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: item.locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller:
                          item.descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText:
                            'Planned Activity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed:
                            _nextDayWork.length == 1
                                ? null
                                : () {
                                    setState(() {
                                      item.dispose();
                                      _nextDayWork
                                          .removeAt(index);
                                    });
                                  },
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: item.locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller:
                      item.descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Planned Activity',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextDayWork.length == 1
                    ? null
                    : () {
                        setState(() {
                          item.dispose();
                          _nextDayWork.removeAt(index);
                        });
                      },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STEP 7 - ISSUES
  // ============================================================

  Widget _buildGeneralIssues() {
    return _sectionCard(
      title: '6. General Issues',
      subtitle:
          'Important issues, delays, safety matters or observations',
      icon: Icons.report_problem_outlined,
      children: [
        TextField(
          controller: _generalIssuesController,
          minLines: 8,
          maxLines: 15,
          decoration: const InputDecoration(
            labelText: 'General Issues / Questions',
            hintText:
                'For example: delay, HSE issue, access problem, material shortage, coordination matter...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'If there are no important issues today, this section may be left empty.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 8 - PHOTOS AND FILES
  // ============================================================

  Widget _buildPhotosAndFiles() {
    final photos = _attachments
        .where((item) => item.isPhoto)
        .toList();

    final files = _attachments
        .where((item) => !item.isPhoto)
        .toList();

    return _sectionCard(
      title: '7. Daily Site Photos & Files',
      subtitle:
          'Attach site photos and supporting documents',
      icon: Icons.photo_library_outlined,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(
                Icons.camera_alt_outlined,
              ),
              label: const Text(
                'Take Photo',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(
                Icons.photo_library_outlined,
              ),
              label: const Text(
                'Choose Photos',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(
                Icons.attach_file,
              ),
              label: const Text(
                'Choose Files',
              ),
            ),
          ],
        ),

        const SizedBox(height: 25),

        if (_attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 50,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(
                color: AppColors.border,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No photos or files attached yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can add site photographs, PDF files, Word files, Excel files and other documents.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

        if (photos.isNotEmpty) ...[
          const Text(
            'Site Photos',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 2;

              if (constraints.maxWidth >= 1000) {
                columns = 4;
              } else if (constraints.maxWidth >= 650) {
                columns = 3;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: photos.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (context, index) {
                  return _photoTile(
                    photos[index],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 28),
        ],

        if (files.isNotEmpty) ...[
          const Text(
            'Attached Files',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...files.map(
            _attachmentFileTile,
          ),
        ],
      ],
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes =
          await image.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _attachments.add(
          ReportAttachment(
            name: image.name,
            size: _formatFileSize(bytes.length),
            isPhoto: true,
            bytes: bytes,
          ),
        );
      });
    } catch (e) {
      _showMessage(
        'Could not take photo: $e',
      );
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final List<XFile> images =
          await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isEmpty) {
        return;
      }

      final List<ReportAttachment> selected = [];

      for (final image in images) {
        final Uint8List bytes =
            await image.readAsBytes();

        selected.add(
          ReportAttachment(
            name: image.name,
            size: _formatFileSize(bytes.length),
            isPhoto: true,
            bytes: bytes,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _attachments.addAll(selected);
      });
    } catch (e) {
      _showMessage(
        'Could not select photos: $e',
      );
    }
  }

  Future<void> _pickFiles() async {
    try {
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );

      if (result == null) {
        return;
      }

      final List<ReportAttachment> selected = [];

      for (final PlatformFile file in result.files) {
        selected.add(
          ReportAttachment(
            name: file.name,
            size: _formatFileSize(file.size),
            isPhoto: false,
            bytes: file.bytes,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _attachments.addAll(selected);
      });
    } catch (e) {
      _showMessage(
        'Could not select files: $e',
      );
    }
  }

  Widget _attachmentImage(
    ReportAttachment item, {
    BoxFit fit = BoxFit.contain,
  }) {
    if (item.bytes != null) {
      return Image.memory(
        item.bytes!,
        fit: fit,
      );
    }

    if (item.url != null) {
      return Image.network(
        item.url!,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.background,
            child: const Icon(
              Icons.broken_image_outlined,
            ),
          );
        },
      );
    }

    return Container(
      color: AppColors.background,
      child: const Icon(
        Icons.image_outlined,
      ),
    );
  }

  void _removeAttachment(
    ReportAttachment item,
  ) {
    setState(() {
      _attachments.remove(item);
    });

    if (item.id != null) {
      _dailyReportService
          .deleteAttachment(item.id!)
          .catchError((Object e) {
        _showMessage(
          'Could not delete "${item.name}" from the server: $e',
        );
      });
    }
  }

  Widget _photoTile(
    ReportAttachment item,
  ) {
    return InkWell(
      onTap: () {
        _showPhotoPreview(item);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _attachmentImage(item, fit: BoxFit.cover),
          ),

          Positioned(
            top: 5,
            right: 5,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black54,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _removeAttachment(item);
                },
                icon: const Icon(
                  Icons.close,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            left: 5,
            right: 5,
            bottom: 5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoPreview(
    ReportAttachment item,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
              maxHeight: 700,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(item.name),
                  actions: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(
                        Icons.close,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: _attachmentImage(item),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentFileTile(
    ReportAttachment item,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: Icon(
          _fileIcon(item.name),
          color: AppColors.primary,
        ),
        title: Text(item.name),
        subtitle: Text(item.size),
        trailing: IconButton(
          tooltip: 'Remove',
          onPressed: () {
            _removeAttachment(item);
          },
          icon: const Icon(
            Icons.delete_outline,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 9 - ENDORSEMENTS
  // ============================================================

  Widget _buildEndorsements() {
    return _sectionCard(
      title: '8. Endorsements',
      subtitle:
          'Prepared By, Confirmed By and Approved By',
      icon: Icons.verified_user_outlined,
      children: [
        _endorsementCard(
          title: 'Prepared By *',
          nameController: _preparedByController,
          positionController:
              _preparedByPositionController,
          icon: Icons.edit_document,
        ),

        const SizedBox(height: 18),

        _endorsementCard(
          title: 'Confirmed By',
          nameController: _confirmedByController,
          positionController:
              _confirmedByPositionController,
          icon: Icons.fact_check_outlined,
        ),

        const SizedBox(height: 18),

        _endorsementCard(
          title: 'Approved By',
          nameController: _approvedByController,
          positionController:
              _approvedByPositionController,
          icon: Icons.verified_outlined,
        ),

        const SizedBox(height: 26),

        _buildFinalReview(),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Review the report above. Use Save Draft if the report is not finished, or Submit Report when it is ready.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _endorsementCard({
    required String title,
    required TextEditingController nameController,
    required TextEditingController positionController,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 650) {
                  return Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Name',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller:
                            positionController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Position / Department',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Name',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller:
                            positionController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Position / Department',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: AppColors.border,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Signature area',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalReview() {
    final int totalPersonnel =
        _personnelTotal(_keyPersonnel) +
            _personnelTotal(_administrationPersonnel) +
            _personnelTotal(_operatorsPersonnel) +
            _personnelTotal(_workers);

    final int photoCount = _attachments
        .where((item) => item.isPhoto)
        .length;

    final int fileCount = _attachments
        .where((item) => !item.isPhoto)
        .length;

    return Card(
      elevation: 0,
      color: AppColors.success.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.success,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Report Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _reviewLine(
              'Project',
              widget.projectName,
            ),

            _reviewLine(
              'Project ID',
              widget.projectId.toString(),
            ),

            _reviewLine(
              'Report Date',
              _formatDate(_reportDate),
            ),

            _reviewLine(
              'Weather',
              _weatherController.text.trim().isEmpty
                  ? '-'
                  : _weatherController.text.trim(),
            ),

            _reviewLine(
              'Total Personnel',
              totalPersonnel.toString(),
            ),

            _reviewLine(
              'Equipment Records',
              _equipment.length.toString(),
            ),

            _reviewLine(
              'Executed Work Items',
              _executedWork.length.toString(),
            ),

            _reviewLine(
              'Material Records',
              _materials.length.toString(),
            ),

            _reviewLine(
              'Next Day Activities',
              _nextDayWork.length.toString(),
            ),

            _reviewLine(
              'Photos',
              photoCount.toString(),
            ),

            _reviewLine(
              'Files',
              fileCount.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewLine(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_weatherController.text.trim().isEmpty) {
          _showMessage(
            'Please enter the weather.',
          );
          return false;
        }

        if (_temperatureController.text.trim().isEmpty) {
          _showMessage(
            'Please enter the temperature.',
          );
          return false;
        }

        final double? temperature =
            double.tryParse(
          _temperatureController.text.trim(),
        );

        if (temperature == null) {
          _showMessage(
            'Temperature must be a number.',
          );
          return false;
        }

        if (_windSpeedController.text.trim().isNotEmpty &&
            double.tryParse(
                  _windSpeedController.text.trim(),
                ) ==
                null) {
          _showMessage(
            'Wind speed must be a number.',
          );
          return false;
        }

        if (_moistureController.text.trim().isNotEmpty) {
          final double? moisture = double.tryParse(
            _moistureController.text.trim(),
          );

          if (moisture == null) {
            _showMessage(
              'Moisture must be a number.',
            );
            return false;
          }

          if (moisture < 0 || moisture > 100) {
            _showMessage(
              'Moisture must be between 0 and 100.',
            );
            return false;
          }
        }

        return true;

      case 1:
        final bool hasPersonnel = [
          ..._keyPersonnel,
          ..._administrationPersonnel,
          ..._operatorsPersonnel,
          ..._workers,
        ].any(
          (item) =>
              item.positionController.text
                  .trim()
                  .isNotEmpty &&
              item.count > 0,
        );

        if (!hasPersonnel) {
          _showMessage(
            'Please enter at least one personnel record.',
          );
          return false;
        }

        return true;

      case 2:
        return true;

      case 3:
        final bool hasWork = _executedWork.any(
          (item) =>
              item.locationController.text
                  .trim()
                  .isNotEmpty ||
              item.descriptionController.text
                  .trim()
                  .isNotEmpty,
        );

        if (!hasWork) {
          _showMessage(
            'Please enter at least one executed work item.',
          );
          return false;
        }

        return true;

      case 4:
        return true;

      case 5:
        return true;

      case 6:
        return true;

      case 7:
        return true;

      case 8:
        if (_preparedByController.text.trim().isEmpty) {
          _showMessage(
            'Please enter Prepared By.',
          );
          return false;
        }

        return true;

      default:
        return true;
    }
  }

  // ============================================================
  // SAVE DATABASE
  // ============================================================

  Future<void> _saveDraft() async {
    await _saveReport(
      'Draft',
      validateForSubmission: false,
    );
  }

  Future<void> _submitReport() async {
    if (!_validateCurrentStep()) {
      return;
    }

    await _saveReport(
      'Submitted',
      validateForSubmission: true,
    );
  }

  Future<int> _uploadPendingAttachments(int reportId) async {
    int failedUploads = 0;

    for (int i = 0; i < _attachments.length; i++) {
      final ReportAttachment item = _attachments[i];

      if (item.id != null || item.bytes == null) {
        continue;
      }

      try {
        final Map<String, dynamic> uploaded =
            await _dailyReportService.uploadAttachment(
          reportId: reportId,
          fileName: item.name,
          bytes: item.bytes!,
          isPhoto: item.isPhoto,
        );

        final String? filePath = uploaded['filePath'] as String?;

        _attachments[i] = item.copyWith(
          id: (uploaded['id'] as num?)?.toInt(),
          url: filePath != null
              ? _dailyReportService.attachmentUrl(filePath)
              : null,
        );
      } catch (_) {
        failedUploads++;
      }
    }

    return failedUploads;
  }

  Future<void> _saveReport(
    String status, {
    required bool validateForSubmission,
  }) async {
    if (_isSaving) {
      return;
    }

    if (validateForSubmission &&
        _preparedByController.text.trim().isEmpty) {
      _showMessage(
        'Please enter Prepared By before submitting.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final List<Map<String, dynamic>> personnel = [];

      _addPersonnelToPayload(
        personnel,
        _keyPersonnel,
        'Key Personnel',
      );

      _addPersonnelToPayload(
        personnel,
        _administrationPersonnel,
        'Administration Staff',
      );

      _addPersonnelToPayload(
        personnel,
        _operatorsPersonnel,
        'Operators',
      );

      _addPersonnelToPayload(
        personnel,
        _workers,
        'Worker',
      );

      final List<Map<String, dynamic>> equipment =
          _equipment
              .where(
                (item) => item.nameController.text
                    .trim()
                    .isNotEmpty,
              )
              .map(
                (item) => <String, dynamic>{
                  'equipment':
                      item.nameController.text.trim(),
                  'active': int.tryParse(
                        item.activeController.text.trim(),
                      ) ??
                      0,
                  'total': int.tryParse(
                        item.totalController.text.trim(),
                      ) ??
                      0,
                },
              )
              .toList();

      final List<Map<String, dynamic>> executedWork =
          _executedWork
              .where(
                (item) =>
                    item.locationController.text
                        .trim()
                        .isNotEmpty ||
                    item.descriptionController.text
                        .trim()
                        .isNotEmpty,
              )
              .map(
                (item) => <String, dynamic>{
                  'location':
                      item.locationController.text.trim(),
                  'description':
                      item.descriptionController.text
                          .trim(),
                  'unit': _nullIfEmpty(
                    item.unitController.text,
                  ),
                  'totalPhysicalVolume': _nullIfEmpty(
                    item.totalPhysicalVolumeController
                        .text,
                  ),
                  'sinceBeginning': _nullIfEmpty(
                    item.sinceBeginningController.text,
                  ),
                  'quantity': _nullIfEmpty(
                    item.quantityController.text,
                  ),
                  'completedPercent': _nullIfEmpty(
                    item.completedPercentController.text,
                  ),
                },
              )
              .toList();

      final List<Map<String, dynamic>> materials =
          _materials
              .where(
                (item) => item.materialController.text
                    .trim()
                    .isNotEmpty,
              )
              .map(
                (item) => <String, dynamic>{
                  'material':
                      item.materialController.text.trim(),
                  'unit': _nullIfEmpty(
                    item.unitController.text,
                  ),
                  'number': _nullIfEmpty(
                    item.numberController.text,
                  ),
                },
              )
              .toList();

      final List<Map<String, dynamic>> nextDayWork =
          _nextDayWork
              .where(
                (item) =>
                    item.locationController.text
                        .trim()
                        .isNotEmpty ||
                    item.descriptionController.text
                        .trim()
                        .isNotEmpty,
              )
              .map(
                (item) => <String, dynamic>{
                  'location':
                      item.locationController.text.trim(),
                  'description':
                      item.descriptionController.text
                          .trim(),
                },
              )
              .toList();

      final dynamic response = _isEditing
          ? await _dailyReportService.updateDailyReport(
              reportId: _editingReportId!,
              reportDate:
                  _reportDate.toUtc().toIso8601String(),
              weather: _nullIfEmpty(
                _weatherController.text,
              ),
              windSpeed: double.tryParse(
                _windSpeedController.text.trim(),
              ),
              temperature: double.tryParse(
                _temperatureController.text.trim(),
              ),
              moisture: double.tryParse(
                _moistureController.text.trim(),
              ),
              generalIssues: _buildGeneralIssuesForPayload(),
              status: status,
              preparedBy: _nullIfEmpty(
                _preparedByController.text,
              ),
              preparedByRole: _nullIfEmpty(
                _preparedByPositionController.text,
              ),
              confirmedBy: _nullIfEmpty(
                _confirmedByController.text,
              ),
              confirmedByRole: _nullIfEmpty(
                _confirmedByPositionController.text,
              ),
              approvedBy: _nullIfEmpty(
                _approvedByController.text,
              ),
              approvedByRole: _nullIfEmpty(
                _approvedByPositionController.text,
              ),
              personnel: personnel,
              equipment: equipment,
              executedWork: executedWork,
              materials: materials,
              nextDayWork: nextDayWork,
            )
          : await _dailyReportService.createDailyReport(
              projectId: widget.projectId,
              reportDate:
                  _reportDate.toUtc().toIso8601String(),
              weather: _nullIfEmpty(
                _weatherController.text,
              ),
              windSpeed: double.tryParse(
                _windSpeedController.text.trim(),
              ),
              temperature: double.tryParse(
                _temperatureController.text.trim(),
              ),
              moisture: double.tryParse(
                _moistureController.text.trim(),
              ),
              generalIssues: _buildGeneralIssuesForPayload(),
              status: status,
              preparedBy: _nullIfEmpty(
                _preparedByController.text,
              ),
              preparedByRole: _nullIfEmpty(
                _preparedByPositionController.text,
              ),
              confirmedBy: _nullIfEmpty(
                _confirmedByController.text,
              ),
              confirmedByRole: _nullIfEmpty(
                _confirmedByPositionController.text,
              ),
              approvedBy: _nullIfEmpty(
                _approvedByController.text,
              ),
              approvedByRole: _nullIfEmpty(
                _approvedByPositionController.text,
              ),
              personnel: personnel,
              equipment: equipment,
              executedWork: executedWork,
              materials: materials,
              nextDayWork: nextDayWork,
            );

      if (!mounted) {
        return;
      }

      dynamic reportId;

      if (response is Map) {
        reportId = response['id'];
      }

      final int? savedReportId = reportId is int
          ? reportId
          : int.tryParse(reportId?.toString() ?? '');

      int failedUploads = 0;

      if (savedReportId != null) {
        failedUploads = await _uploadPendingAttachments(
          savedReportId,
        );
      }

      if (!mounted) {
        return;
      }

      final String verb = _isEditing ? 'updated' : (status == 'Draft' ? 'saved as Draft' : 'submitted successfully');

      final String message = reportId != null
          ? 'Daily Report #$reportId $verb.'
          : 'Daily Report $verb.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failedUploads > 0
                ? '$message $failedUploads attachment(s) failed to upload.'
                : message,
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save Daily Report: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _buildGeneralIssuesForPayload() {
    final String issues =
        _generalIssuesController.text.trim();

    final String weatherNotes =
        _weatherNotesController.text.trim();

    if (issues.isEmpty && weatherNotes.isEmpty) {
      return null;
    }

    if (issues.isEmpty) {
      return 'Weather / Site Notes: $weatherNotes';
    }

    if (weatherNotes.isEmpty) {
      return issues;
    }

    return '$issues\n\nWeather / Site Notes: $weatherNotes';
  }

  void _addPersonnelToPayload(
    List<Map<String, dynamic>> payload,
    List<PersonnelRow> source,
    String category,
  ) {
    for (final PersonnelRow item in source) {
      final String position =
          item.positionController.text.trim();

      if (position.isEmpty) {
        continue;
      }

      payload.add({
        'category': category,
        'position': position,
        'count': item.count,
      });
    }
  }

  String? _nullIfEmpty(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildNavigation() {
  final bool isLastStep =
      _currentStep == _stepNames.length - 1;

  return SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool small =
              constraints.maxWidth < 650;

          if (small) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize:
                                const Size(0, 42),
                          ),
                          onPressed:
                              _currentStep == 0 ||
                                      _isSaving
                                  ? null
                                  : _previousStep,
                          icon: const Icon(
                            Icons.arrow_back,
                          ),
                          label: const Text(
                            'Previous',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize:
                                const Size(0, 42),
                          ),
                          onPressed: _isSaving
                              ? null
                              : _saveDraft,
                          icon: const Icon(
                            Icons.save_outlined,
                          ),
                          label: const Text(
                            'Save Draft',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: isLastStep
                      ? ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(0, 42),
                          ),
                          onPressed: _isSaving
                              ? null
                              : _submitReport,
                          icon: const Icon(
                            Icons.send,
                          ),
                          label: const Text(
                            'Submit Report',
                          ),
                        )
                      : ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(0, 42),
                          ),
                          onPressed: _isSaving
                              ? null
                              : _nextStep,
                          icon: const Icon(
                            Icons.arrow_forward,
                          ),
                          label: const Text(
                            'Next',
                          ),
                        ),
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 130,
                height: 42,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(0, 42),
                  ),
                  onPressed:
                      _currentStep == 0 || _isSaving
                          ? null
                          : _previousStep,
                  icon: const Icon(
                    Icons.arrow_back,
                  ),
                  label: const Text(
                    'Previous',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                width: 140,
                height: 42,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(0, 42),
                  ),
                  onPressed:
                      _isSaving ? null : _saveDraft,
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    'Save Draft',
                  ),
                ),
              ),

              const Spacer(),

              Text(
                'Step ${_currentStep + 1} of ${_stepNames.length}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: 180,
                height: 42,
                child: isLastStep
                    ? ElevatedButton.icon(
                        style:
                            ElevatedButton.styleFrom(
                          minimumSize:
                              const Size(0, 42),
                        ),
                        onPressed: _isSaving
                            ? null
                            : _submitReport,
                        icon: const Icon(
                          Icons.send,
                        ),
                        label: const Text(
                          'Submit Report',
                        ),
                      )
                    : ElevatedButton.icon(
                        style:
                            ElevatedButton.styleFrom(
                          minimumSize:
                              const Size(0, 42),
                        ),
                        onPressed: _isSaving
                            ? null
                            : _nextStep,
                        icon: const Icon(
                          Icons.arrow_forward,
                        ),
                        label: const Text(
                          'Next',
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

  void _previousStep() {
    if (_currentStep <= 0) {
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep >= _stepNames.length - 1) {
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  // ============================================================
  // COMMON COMPONENTS
  // ============================================================

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _quantityStepper({
    required TextEditingController controller,
    required String label,
  }) {
    final int value = int.tryParse(controller.text.trim()) ?? 0;

    void setValue(int newValue) {
      setState(() {
        controller.text = newValue.toString();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepperButton(
                icon: Icons.remove,
                onPressed: value > 0 ? () => setValue(value - 1) : null,
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _stepperButton(
                icon: Icons.add,
                onPressed: () => setValue(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 46,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: onPressed == null
            ? AppColors.border
            : AppColors.primary,
      ),
    );
  }

  Widget _summaryBox(
    String label,
    String value,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 145,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _responsiveFields(
    List<_InputFieldData> fields,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 750) {
          return Column(
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                _fieldWidget(fields[i]),
                if (i < fields.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < fields.length; i++) ...[
              Expanded(
                flex: fields[i].flex,
                child: _fieldWidget(fields[i]),
              ),
              if (i < fields.length - 1)
                const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  _InputFieldData _fieldData(
    TextEditingController controller,
    String label, {
    int flex = 1,
  }) {
    return _InputFieldData(
      controller: controller,
      label: label,
      flex: flex,
    );
  }

  Widget _fieldWidget(
    _InputFieldData data,
  ) {
    return TextField(
      controller: data.controller,
      decoration: InputDecoration(
        labelText: data.label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _reportDate = result;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _weekdayName(DateTime date) {
    const List<String> names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return names[date.weekday - 1];
  }

  String _monthName(int month) {
    const List<String> names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return names[month - 1];
  }

  // ============================================================
  // FILE HELPERS
  // ============================================================

  IconData _fileIcon(String name) {
    final String lower = name.toLowerCase();

    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    }

    if (lower.endsWith('.xlsx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.csv')) {
      return Icons.table_chart_outlined;
    }

    if (lower.endsWith('.doc') ||
        lower.endsWith('.docx')) {
      return Icons.description_outlined;
    }

    if (lower.endsWith('.ppt') ||
        lower.endsWith('.pptx')) {
      return Icons.slideshow_outlined;
    }

    if (lower.endsWith('.zip') ||
        lower.endsWith('.rar')) {
      return Icons.folder_zip_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ============================================================
  // PRINT / PDF EXPORT
  // ============================================================

  Future<void> _printReport() async {
    final int? reportId = _editingReportId;

    if (reportId == null || _isPrinting) {
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final fullReport = await _dailyReportService.getReportById(
        reportId,
      );

      final bytes = await _pdfService.generate(
        report: fullReport,
        projectName: widget.projectName,
        projectId: widget.projectId,
      );

      if (!mounted) {
        return;
      }

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Daily_Report_$reportId.pdf',
      );
    } catch (e) {
      _showMessage('Could not generate PDF: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ============================================================
// PERSONNEL MODEL
// ============================================================

class PersonnelRow {
  final TextEditingController positionController;
  final TextEditingController countController;

  PersonnelRow(
    String position,
    int count,
  )   : positionController = TextEditingController(
          text: position,
        ),
        countController = TextEditingController(
          text: count.toString(),
        );

  int get count {
    return int.tryParse(
          countController.text.trim(),
        ) ??
        0;
  }

  void dispose() {
    positionController.dispose();
    countController.dispose();
  }
}

// ============================================================
// EQUIPMENT MODEL
// ============================================================

class EquipmentRow {
  final TextEditingController nameController;
  final TextEditingController activeController;
  final TextEditingController totalController;

  EquipmentRow(
    String name,
    int active,
    int total,
  )   : nameController = TextEditingController(
          text: name,
        ),
        activeController = TextEditingController(
          text: active.toString(),
        ),
        totalController = TextEditingController(
          text: total.toString(),
        );

  void dispose() {
    nameController.dispose();
    activeController.dispose();
    totalController.dispose();
  }
}

// ============================================================
// EXECUTED WORK MODEL
// ============================================================

class ExecutedWorkRow {
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final TextEditingController unitController;

  final TextEditingController
      totalPhysicalVolumeController;

  final TextEditingController
      sinceBeginningController;

  final TextEditingController quantityController;

  final TextEditingController
      completedPercentController;

  ExecutedWorkRow({
    required String location,
    required String description,
    required String unit,
    required String totalPhysicalVolume,
    required String sinceBeginning,
    required String quantity,
    required String completedPercent,
  })  : locationController = TextEditingController(
          text: location,
        ),
        descriptionController = TextEditingController(
          text: description,
        ),
        unitController = TextEditingController(
          text: unit,
        ),
        totalPhysicalVolumeController =
            TextEditingController(
          text: totalPhysicalVolume,
        ),
        sinceBeginningController =
            TextEditingController(
          text: sinceBeginning,
        ),
        quantityController = TextEditingController(
          text: quantity,
        ),
        completedPercentController =
            TextEditingController(
          text: completedPercent,
        );

  void dispose() {
    locationController.dispose();
    descriptionController.dispose();
    unitController.dispose();
    totalPhysicalVolumeController.dispose();
    sinceBeginningController.dispose();
    quantityController.dispose();
    completedPercentController.dispose();
  }
}

// ============================================================
// MATERIAL MODEL
// ============================================================

class MaterialRow {
  final TextEditingController materialController;
  final TextEditingController unitController;
  final TextEditingController numberController;

  MaterialRow({
    required String material,
    required String unit,
    required String number,
  })  : materialController = TextEditingController(
          text: material,
        ),
        unitController = TextEditingController(
          text: unit,
        ),
        numberController = TextEditingController(
          text: number,
        );

  void dispose() {
    materialController.dispose();
    unitController.dispose();
    numberController.dispose();
  }
}

// ============================================================
// NEXT DAY WORK MODEL
// ============================================================

class NextDayWorkRow {
  final TextEditingController locationController;

  final TextEditingController
      descriptionController;

  NextDayWorkRow({
    required String location,
    required String description,
  })  : locationController = TextEditingController(
          text: location,
        ),
        descriptionController = TextEditingController(
          text: description,
        );

  void dispose() {
    locationController.dispose();
    descriptionController.dispose();
  }
}

// ============================================================
// ATTACHMENT MODEL
// ============================================================

class ReportAttachment {
  final int? id;
  final String name;
  final String size;
  final bool isPhoto;
  final Uint8List? bytes;
  final String? url;

  const ReportAttachment({
    this.id,
    required this.name,
    required this.size,
    required this.isPhoto,
    this.bytes,
    this.url,
  });

  ReportAttachment copyWith({
    int? id,
    String? url,
  }) {
    return ReportAttachment(
      id: id ?? this.id,
      name: name,
      size: size,
      isPhoto: isPhoto,
      bytes: bytes,
      url: url ?? this.url,
    );
  }
}

// ============================================================
// INPUT FIELD MODEL
// ============================================================

class _InputFieldData {
  final TextEditingController controller;
  final String label;
  final int flex;

  const _InputFieldData({
    required this.controller,
    required this.label,
    required this.flex,
  });
}