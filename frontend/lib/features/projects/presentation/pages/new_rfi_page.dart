import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/project_service.dart';
import '../../../../core/services/rfi_pdf_service.dart';
import '../../../../core/services/rfi_service.dart';

const Map<String, List<String>> _purposeCatalog = {
  'Surveying': ['Setting Out', 'Levels', 'Vertically'],
  'Earthworks': ['Formation', 'Compaction', 'Levelling with gravel'],
  'Structural': ['Formwork', 'Reinforcement', 'Waterstop', 'Concreting'],
  'Electrical': ['First Fix', 'Second Fix'],
  'Mechanical': ['First Fix', 'Second Fix'],
  'Pipe Works': ['WWTP'],
  'Architectural': [
    'Blockwork',
    'Plaster',
    'Metals',
    'Woods & Plastics',
    'Doors & Windows',
    'Floor Finish',
    'False Ceilings',
    'Roofing',
    'Waterproofing',
    'Painting',
    'Furniture',
  ],
};

const List<String> _rfiTypes = [
  'Civil',
  'Structural',
  'Electrical',
  'Mechanical',
  'Architectural',
  'Pipe Works',
  'Other',
];

const List<String> _inspectionSequences = ['First', 'Second', 'Third'];

const List<String> _reviewerDisciplines = [
  'Electrical & Auto Engineer',
  'HSE Engineer',
  'Mechanical Engineer',
  'QA/QC Engineer',
  'Land Surveying Engineer',
  'Technical Office Engineer',
];

const List<String> _statuses = [
  'Draft',
  'Open',
  'Assigned',
  'Answered',
  'Closed',
];

const List<String> _engineerCommentOptions = [
  'Approved',
  'Approved as Noted',
  'Rejected',
];

class NewRfiPage extends StatefulWidget {
  final int projectId;
  final String projectName;
  final String? projectCode;
  final Map<String, dynamic>? existingRfi;
  final bool startAtReview;

  const NewRfiPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.projectCode,
    this.existingRfi,
    this.startAtReview = false,
  });

  @override
  State<NewRfiPage> createState() => _NewRfiPageState();
}

class _InspectionReportRow {
  int? id;
  final TextEditingController disciplineController;
  final TextEditingController remarksController;
  final TextEditingController nameController;

  _InspectionReportRow({
    this.id,
    String discipline = '',
    String remarks = '',
    String name = '',
  })  : disciplineController = TextEditingController(text: discipline),
        remarksController = TextEditingController(text: remarks),
        nameController = TextEditingController(text: name);

  void dispose() {
    disciplineController.dispose();
    remarksController.dispose();
    nameController.dispose();
  }
}

class _RfiAttachmentItem {
  final int? id;
  final String name;
  final int size;
  final Uint8List? bytes;
  final String? url;

  const _RfiAttachmentItem({
    this.id,
    required this.name,
    required this.size,
    this.bytes,
    this.url,
  });
}

class _NewRfiPageState extends State<NewRfiPage> {
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isPrinting = false;

  final RfiService _rfiService = RfiService();
  final RfiPdfService _pdfService = RfiPdfService();
  final ProjectService _projectService = ProjectService();

  bool get _isEditing => widget.existingRfi != null;
  int? get _editingId => widget.existingRfi?['id'] as int?;

  static const List<String> _stepNames = [
    'Basic Information',
    'Request Details',
    'References',
    'Assignment',
    'Response',
    'Review',
  ];

  // ============================================================
  // STEP 1 - BASIC INFORMATION
  // ============================================================

  final TextEditingController _subjectController = TextEditingController();
  String _type = _rfiTypes.first;
  final TextEditingController _revisionController =
      TextEditingController(text: '00');
  DateTime _requestDate = DateTime.now();
  final TextEditingController _timeFromController = TextEditingController();
  final TextEditingController _timeToController = TextEditingController();
  String? _inspectionSequence;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _elevationController = TextEditingController();
  final TextEditingController _workTypeController = TextEditingController();
  final TextEditingController _drawingNoController = TextEditingController();

  // ============================================================
  // STEP 2 - REQUEST / QUESTION DETAILS
  // ============================================================

  final Set<String> _selectedPurposeItems = {};
  final TextEditingController _othersController = TextEditingController();
  final TextEditingController _particularsController =
      TextEditingController();

  // ============================================================
  // STEP 3 - REFERENCES AND RELATED INFORMATION
  // ============================================================

  final TextEditingController _permittedWorkController =
      TextEditingController();
  final TextEditingController _approxQtyController = TextEditingController();
  final List<_RfiAttachmentItem> _attachments = [];

  // ============================================================
  // STEP 4 - ASSIGNMENT / RESPONSIBLE USER
  // ============================================================

  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = true;
  int? _assignedToId;
  final Map<String, TextEditingController> _reviewerControllers = {
    for (final d in _reviewerDisciplines) d: TextEditingController(),
  };
  final TextEditingController _submittedByController =
      TextEditingController();
  DateTime? _submittedDate;
  final TextEditingController _receivedByController =
      TextEditingController();
  DateTime? _receivedDate;

  // ============================================================
  // STEP 5 - RESPONSE / RESOLUTION
  // ============================================================

  final List<_InspectionReportRow> _inspectionRows = [];
  String? _engineerComment;
  final TextEditingController _supervisorNameController =
      TextEditingController();
  DateTime? _supervisorDate;
  String _status = _statuses.first;

  @override
  void initState() {
    super.initState();

    _loadMembers();

    if (_isEditing) {
      _populateFromExisting(widget.existingRfi!);
    }

    if (widget.startAtReview) {
      _currentStep = _stepNames.length - 1;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _revisionController.dispose();
    _timeFromController.dispose();
    _timeToController.dispose();
    _locationController.dispose();
    _elevationController.dispose();
    _workTypeController.dispose();
    _drawingNoController.dispose();
    _othersController.dispose();
    _particularsController.dispose();
    _permittedWorkController.dispose();
    _approxQtyController.dispose();
    _submittedByController.dispose();
    _receivedByController.dispose();
    _supervisorNameController.dispose();

    for (final c in _reviewerControllers.values) {
      c.dispose();
    }

    for (final row in _inspectionRows) {
      row.dispose();
    }

    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _projectService.getProjectMembers(
        widget.projectId,
      );

      if (!mounted) return;

      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMembers = false);
    }
  }

  void _populateFromExisting(Map<String, dynamic> rfi) {
    _subjectController.text = (rfi['subject'] as String?) ?? '';
    _type = (rfi['type'] as String?) ?? _rfiTypes.first;

    if (!_rfiTypes.contains(_type)) {
      _type = _rfiTypes.first;
    }

    _revisionController.text = (rfi['revision'] as String?) ?? '00';

    final requestDate = _parseDate(rfi['requestDate']);
    if (requestDate != null) _requestDate = requestDate;

    _timeFromController.text = (rfi['inspectionTimeFrom'] as String?) ?? '';
    _timeToController.text = (rfi['inspectionTimeTo'] as String?) ?? '';
    _inspectionSequence = rfi['inspectionSequence'] as String?;

    _locationController.text = (rfi['location'] as String?) ?? '';
    _elevationController.text = (rfi['elevationLocation'] as String?) ?? '';
    _workTypeController.text = (rfi['workType'] as String?) ?? '';
    _drawingNoController.text = (rfi['drawingNo'] as String?) ?? '';

    final purposeItems = (rfi['purposeItems'] as List<dynamic>?) ?? [];
    for (final item in purposeItems) {
      final category = item['category'] as String?;
      final label = item['item'] as String?;
      if (category != null && label != null) {
        _selectedPurposeItems.add('$category|$label');
      }
    }

    _othersController.text = (rfi['othersSpecify'] as String?) ?? '';
    _particularsController.text =
        (rfi['particularDetails'] as String?) ?? '';

    _permittedWorkController.text =
        (rfi['permittedWorkDescription'] as String?) ?? '';
    _approxQtyController.text = (rfi['approxQuantity'] as String?) ?? '';

    final attachments = (rfi['attachments'] as List<dynamic>?) ?? [];
    for (final item in attachments) {
      _attachments.add(
        _RfiAttachmentItem(
          id: (item['id'] as num?)?.toInt(),
          name: (item['originalName'] as String?) ?? 'file',
          size: (item['fileSize'] as num?)?.toInt() ?? 0,
          url: item['filePath'] != null
              ? _rfiService.attachmentUrl(item['filePath'] as String)
              : null,
        ),
      );
    }

    _assignedToId = (rfi['assignedToId'] as num?)?.toInt();

    final reviewers = (rfi['reviewers'] as List<dynamic>?) ?? [];
    for (final r in reviewers) {
      final discipline = r['discipline'] as String?;
      if (discipline != null && _reviewerControllers.containsKey(discipline)) {
        _reviewerControllers[discipline]!.text = (r['name'] as String?) ?? '';
      }
    }

    _submittedByController.text = (rfi['submittedByName'] as String?) ?? '';
    _submittedDate = _parseDate(rfi['submittedDate']);
    _receivedByController.text = (rfi['receivedByName'] as String?) ?? '';
    _receivedDate = _parseDate(rfi['receivedDate']);

    final inspectionReports =
        (rfi['inspectionReports'] as List<dynamic>?) ?? [];
    for (final report in inspectionReports) {
      _inspectionRows.add(
        _InspectionReportRow(
          id: (report['id'] as num?)?.toInt(),
          discipline: (report['discipline'] as String?) ?? '',
          remarks: (report['remarks'] as String?) ?? '',
          name: (report['name'] as String?) ?? '',
        ),
      );
    }

    _engineerComment = rfi['engineerComment'] as String?;
    _supervisorNameController.text =
        (rfi['supervisorSignedName'] as String?) ?? '';
    _supervisorDate = _parseDate(rfi['supervisorSignedDate']);

    _status = (rfi['status'] as String?) ?? _statuses.first;
    if (!_statuses.contains(_status)) {
      _status = _statuses.first;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
              ? 'RFI ${widget.existingRfi?['rfiNumber'] ?? ''}'
              : 'New RFI - ${widget.projectName}',
        ),
        centerTitle: false,
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Print RFI',
              onPressed: _isPrinting ? null : _printRfi,
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
          IconButton(
            tooltip: 'Cancel',
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 850;

          return Column(
            children: [
              _buildProgress(isDesktop),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 28 : 12,
                    vertical: 20,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
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

  Widget _buildProgress(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_stepNames.length, (index) {
            final bool active = index == _currentStep;
            final bool completed = index < _currentStep;

            return Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _currentStep = index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: active || completed
                              ? AppColors.primary
                              : AppColors.border,
                          child: completed
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 90,
                          child: Text(
                            _stepNames[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight:
                                  active ? FontWeight.bold : FontWeight.normal,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index != _stepNames.length - 1)
                  Container(
                    width: 24,
                    height: 2,
                    color: completed ? AppColors.primary : AppColors.border,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildRequestDetailsStep();
      case 2:
        return _buildReferencesStep();
      case 3:
        return _buildAssignmentStep();
      case 4:
        return _buildResponseStep();
      default:
        return _buildReviewStep();
    }
  }

  // ============================================================
  // STEP 1 - BASIC INFORMATION
  // ============================================================

  Widget _buildBasicInfoStep() {
    return _sectionCard(
      title: 'RFI Basic Information',
      subtitle: 'Type, timing and location of the requested inspection',
      icon: Icons.fact_check_outlined,
      children: [
        _textField(
          controller: _subjectController,
          label: 'Subject / Title',
          hint: 'e.g. Foundation formwork inspection',
          icon: Icons.title,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Type / Тип',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _rfiTypes
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _textField(
                controller: _revisionController,
                label: 'Revision',
                hint: '00',
                icon: Icons.tag,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _requestDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _requestDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date / Дата',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_requestDate)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _inspectionSequence,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Inspection / Инспекция',
                  prefixIcon: Icon(Icons.looks_one_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _inspectionSequences
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _inspectionSequence = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _timeFromController,
                label: 'Inspection Time From',
                hint: '10:00',
                icon: Icons.schedule,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _textField(
                controller: _timeToController,
                label: 'Inspection Time To',
                hint: '10:30',
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _textField(
          controller: _locationController,
          label: 'Location / Расположение',
          hint: 'Building, block, unit ...',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _textField(
          controller: _elevationController,
          label: 'Elevation / Loc.',
          hint: 'attached Dwg. Foundation +540.050',
          icon: Icons.height,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _workTypeController,
                label: 'Work Type / Тип работы',
                hint: 'Formwork, Reinforcement ...',
                icon: Icons.construction_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _textField(
                controller: _drawingNoController,
                label: 'Drawing No / Номер чертежа',
                hint: 'CHR-S-035-06-00',
                icon: Icons.description_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STEP 2 - REQUEST / QUESTION DETAILS
  // ============================================================

  Widget _buildRequestDetailsStep() {
    return _sectionCard(
      title: 'Request / Question Details',
      subtitle: 'Purpose of the inspection',
      icon: Icons.checklist_outlined,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: _purposeCatalog.entries.map((entry) {
            return SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...entry.value.map((item) {
                    final key = '${entry.key}|$item';
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(item, style: const TextStyle(fontSize: 13)),
                      value: _selectedPurposeItems.contains(key),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedPurposeItems.add(key);
                          } else {
                            _selectedPurposeItems.remove(key);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _textField(
          controller: _othersController,
          label: 'Others (specify)',
          hint: 'Anything not covered above',
          icon: Icons.more_horiz,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _particularsController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Particular Details',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 3 - REFERENCES AND RELATED INFORMATION
  // ============================================================

  Widget _buildReferencesStep() {
    return _sectionCard(
      title: 'References and Related Information',
      subtitle: 'Permitted works and supporting attachments',
      icon: Icons.link_outlined,
      children: [
        TextField(
          controller: _permittedWorkController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText:
                'Permitted construction works (e.g. "Pouring lean Concrete")',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _textField(
          controller: _approxQtyController,
          label: 'Approx. Quantity',
          hint: '45.8 m3',
          icon: Icons.straighten,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'Attachments / Enclosures',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _pickAttachments,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Add File'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_attachments.isEmpty)
          const Text(
            'No files attached yet.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ..._attachments.asMap().entries.map((entry) {
            final item = entry.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(item.name),
              subtitle: Text(_formatFileSize(item.size)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeAttachment(entry.key),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      for (final file in result.files) {
        if (file.bytes == null) continue;
        _attachments.add(
          _RfiAttachmentItem(
            name: file.name,
            size: file.size,
            bytes: file.bytes,
          ),
        );
      }
    });
  }

  Future<void> _removeAttachment(int index) async {
    final item = _attachments[index];

    if (item.id != null) {
      try {
        await _rfiService.deleteAttachment(item.id!);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove attachment: $e')),
        );
        return;
      }
    }

    setState(() => _attachments.removeAt(index));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ============================================================
  // STEP 4 - ASSIGNMENT / RESPONSIBLE USER
  // ============================================================

  Widget _buildAssignmentStep() {
    return _sectionCard(
      title: 'Assignment / Responsible User',
      subtitle:
          'Refer this RFI to a user with access to ${widget.projectCode ?? widget.projectName}',
      icon: Icons.person_outline,
      children: [
        if (_isLoadingMembers)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<int?>(
            initialValue: _assignedToId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Assign / Refer To',
              prefixIcon: Icon(Icons.assignment_ind_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Unassigned')),
              ..._members.map(
                (m) => DropdownMenuItem(
                  value: m['id'] as int,
                  child: Text(
                    '${m['name']} (${m['role']})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _assignedToId = value),
          ),
        if (!_isLoadingMembers && _members.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No other users have access to this project yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
        const Text(
          'Reviewers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ..._reviewerDisciplines.map(
          (discipline) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _textField(
              controller: _reviewerControllers[discipline]!,
              label: discipline,
              hint: 'Name',
              icon: Icons.engineering_outlined,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _submittedByController,
                label: 'Submitted By',
                hint: 'Name',
                icon: Icons.outbox_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _datePickerField(
              label: 'Submitted Date',
              value: _submittedDate,
              onChanged: (date) => setState(() => _submittedDate = date),
            )),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _receivedByController,
                label: 'Received By',
                hint: 'Name',
                icon: Icons.move_to_inbox_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _datePickerField(
              label: 'Received Date',
              value: _receivedDate,
              onChanged: (date) => setState(() => _receivedDate = date),
            )),
          ],
        ),
      ],
    );
  }

  Widget _datePickerField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(
          value != null ? DateFormat('yyyy-MM-dd').format(value) : '-',
        ),
      ),
    );
  }

  // ============================================================
  // STEP 5 - RESPONSE / RESOLUTION
  // ============================================================

  Widget _buildResponseStep() {
    return _sectionCard(
      title: 'Response / Resolution',
      subtitle: 'Inspection outcome and current RFI status',
      icon: Icons.rate_review_outlined,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _status,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'RFI Status',
            prefixIcon: Icon(Icons.flag_outlined),
            border: OutlineInputBorder(),
          ),
          items: _statuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _status = value);
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'Inspection Report by Engineer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _inspectionRows.add(_InspectionReportRow()));
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Row'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_inspectionRows.isEmpty)
          const Text(
            'No inspection report entries yet.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ..._inspectionRows.asMap().entries.map((entry) {
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: row.disciplineController,
                      decoration: const InputDecoration(
                        labelText: 'Discipline',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: row.remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: row.nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        row.dispose();
                        _inspectionRows.removeAt(entry.key);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        const Text(
          "Engineer's Comments",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Wrap(
          spacing: 8,
          children: _engineerCommentOptions
              .map(
                (option) => ChoiceChip(
                  label: Text(option),
                  selected: _engineerComment == option,
                  onSelected: (selected) {
                    setState(() {
                      _engineerComment = selected ? option : null;
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _supervisorNameController,
                label: 'Signed by Supervisor',
                hint: 'Name',
                icon: Icons.verified_user_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _datePickerField(
                label: 'Date',
                value: _supervisorDate,
                onChanged: (date) => setState(() => _supervisorDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STEP 6 - REVIEW AND CONFIRMATION
  // ============================================================

  Widget _buildReviewStep() {
    final assignedMember = _members.firstWhere(
      (m) => m['id'] == _assignedToId,
      orElse: () => const {},
    );

    return _sectionCard(
      title: 'Review and Confirmation',
      subtitle: _isEditing
          ? (widget.existingRfi?['rfiNumber'] as String?) ?? 'RFI'
          : 'This RFI number is generated automatically on save',
      icon: Icons.fact_check_outlined,
      children: [
        _reviewRow('Subject', _subjectController.text),
        _reviewRow('Type', _type),
        _reviewRow('Revision', _revisionController.text),
        _reviewRow('Date', DateFormat('yyyy-MM-dd').format(_requestDate)),
        _reviewRow(
          'Inspection Time',
          '${_timeFromController.text} - ${_timeToController.text}',
        ),
        _reviewRow('Inspection', _inspectionSequence ?? '-'),
        _reviewRow('Location', _locationController.text),
        _reviewRow('Elevation / Loc.', _elevationController.text),
        _reviewRow('Work Type', _workTypeController.text),
        _reviewRow('Drawing No', _drawingNoController.text),
        const Divider(height: 32),
        Text(
          'Purpose of Inspection',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        _selectedPurposeItems.isEmpty
            ? const Text(
                'None selected',
                style: TextStyle(color: AppColors.textSecondary),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedPurposeItems
                    .map((key) => Chip(label: Text(key.split('|').last)))
                    .toList(),
              ),
        _reviewRow('Others', _othersController.text),
        _reviewRow('Particular Details', _particularsController.text),
        const Divider(height: 32),
        _reviewRow('Permitted Work', _permittedWorkController.text),
        _reviewRow('Approx. Quantity', _approxQtyController.text),
        _reviewRow('Attachments', '${_attachments.length} file(s)'),
        const Divider(height: 32),
        _reviewRow(
          'Assigned To',
          assignedMember.isEmpty
              ? 'Unassigned'
              : '${assignedMember['name']} (${assignedMember['role']})',
        ),
        ..._reviewerDisciplines
            .where((d) => _reviewerControllers[d]!.text.trim().isNotEmpty)
            .map((d) => _reviewRow(d, _reviewerControllers[d]!.text)),
        _reviewRow('Submitted By', _submittedByController.text),
        _reviewRow('Received By', _receivedByController.text),
        const Divider(height: 32),
        _reviewRow('Status', _status),
        _reviewRow(
          "Engineer's Comment",
          _engineerComment ?? 'Pending',
        ),
        _reviewRow(
          'Inspection Report Rows',
          '${_inspectionRows.length} entr${_inspectionRows.length == 1 ? 'y' : 'ies'}',
        ),
        if (_isEditing) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isPrinting ? null : _printRfi,
              icon: const Icon(Icons.print_outlined),
              label: Text(_isPrinting ? 'Preparing PDF...' : 'Print RFI'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 27),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Widget _buildNavigation() {
    final bool isLastStep = _currentStep == _stepNames.length - 1;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool small = constraints.maxWidth < 700;

            final backButton = SizedBox(
              width: small ? null : 130,
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                onPressed: _currentStep == 0 || _isSaving
                    ? null
                    : () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            );

            final draftButton = SizedBox(
              width: small ? null : 140,
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                onPressed: _isSaving ? null : () => _submit('Draft'),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Draft'),
              ),
            );

            final nextButton = SizedBox(
              width: small ? null : 180,
              height: 42,
              child: isLastStep
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () => _submit(_status, isFinal: true),
                      icon: const Icon(Icons.send),
                      label: Text(_isEditing ? 'Update RFI' : 'Save RFI'),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () => setState(() => _currentStep++),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
            );

            if (small) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: backButton),
                      const SizedBox(width: 8),
                      Expanded(child: draftButton),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: nextButton),
                ],
              );
            }

            return Row(
              children: [
                backButton,
                const SizedBox(width: 12),
                draftButton,
                const Spacer(),
                Text(
                  'Step ${_currentStep + 1} of ${_stepNames.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                nextButton,
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Map<String, dynamic> _buildPayload(String status) {
    return {
      if (!_isEditing) 'projectId': widget.projectId,
      'subject': _nullIfEmpty(_subjectController.text),
      'type': _type,
      'revision': _nullIfEmpty(_revisionController.text) ?? '00',
      'requestDate': _requestDate.toUtc().toIso8601String(),
      'inspectionTimeFrom': _nullIfEmpty(_timeFromController.text),
      'inspectionTimeTo': _nullIfEmpty(_timeToController.text),
      'inspectionSequence': _inspectionSequence,
      'location': _nullIfEmpty(_locationController.text),
      'elevationLocation': _nullIfEmpty(_elevationController.text),
      'workType': _nullIfEmpty(_workTypeController.text),
      'drawingNo': _nullIfEmpty(_drawingNoController.text),
      'othersSpecify': _nullIfEmpty(_othersController.text),
      'particularDetails': _nullIfEmpty(_particularsController.text),
      'permittedWorkDescription': _nullIfEmpty(_permittedWorkController.text),
      'approxQuantity': _nullIfEmpty(_approxQtyController.text),
      'submittedByName': _nullIfEmpty(_submittedByController.text),
      'submittedDate': _submittedDate?.toUtc().toIso8601String(),
      'receivedByName': _nullIfEmpty(_receivedByController.text),
      'receivedDate': _receivedDate?.toUtc().toIso8601String(),
      'engineerComment': _engineerComment,
      'supervisorSignedName': _nullIfEmpty(_supervisorNameController.text),
      'supervisorSignedDate': _supervisorDate?.toUtc().toIso8601String(),
      'status': status,
      'assignedToId': _assignedToId,
      'purposeItems': _selectedPurposeItems.map((key) {
        final parts = key.split('|');
        return {'category': parts[0], 'item': parts[1]};
      }).toList(),
      'reviewers': _reviewerDisciplines
          .where((d) => _reviewerControllers[d]!.text.trim().isNotEmpty)
          .map(
            (d) => {
              'discipline': d,
              'name': _reviewerControllers[d]!.text.trim(),
            },
          )
          .toList(),
      'inspectionReports': _inspectionRows
          .where(
            (r) =>
                r.disciplineController.text.trim().isNotEmpty ||
                r.remarksController.text.trim().isNotEmpty ||
                r.nameController.text.trim().isNotEmpty,
          )
          .map(
            (r) => {
              'discipline': _nullIfEmpty(r.disciplineController.text),
              'remarks': _nullIfEmpty(r.remarksController.text),
              'name': _nullIfEmpty(r.nameController.text),
            },
          )
          .toList(),
    };
  }

  Future<void> _submit(String status, {bool isFinal = false}) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final payload = _buildPayload(status);

      final Map<String, dynamic> response = _isEditing
          ? await _rfiService.updateRfi(_editingId!, payload)
          : await _rfiService.createRfi(payload);

      final int? rfiId = (response['id'] as num?)?.toInt();

      int failedUploads = 0;

      if (rfiId != null) {
        for (final item in _attachments) {
          if (item.id != null || item.bytes == null) continue;

          try {
            await _rfiService.uploadAttachment(
              rfiId: rfiId,
              fileName: item.name,
              bytes: item.bytes!,
            );
          } catch (_) {
            failedUploads++;
          }
        }
      }

      if (!mounted) return;

      final String verb = _isEditing
          ? 'updated'
          : (status == 'Draft' ? 'saved as Draft' : 'created');

      final String message = response['rfiNumber'] != null
          ? 'RFI ${response['rfiNumber']} $verb.'
          : 'RFI $verb.';

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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save RFI: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _printRfi() async {
    if (_isPrinting || _editingId == null) return;

    setState(() => _isPrinting = true);

    try {
      final full = await _rfiService.getRfiById(_editingId!);

      final bytes = await _pdfService.generate(
        rfi: full,
        projectName: widget.projectName,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'RFI_${full['rfiNumber'] ?? _editingId}.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }
}
