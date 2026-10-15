import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/project_service.dart';
import '../../../../core/services/rfi_service.dart';
import 'new_rfi_page.dart';

class RfiListPage extends StatefulWidget {
  final int projectId;
  final String projectName;
  final String? projectCode;

  const RfiListPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.projectCode,
  });

  @override
  State<RfiListPage> createState() => _RfiListPageState();
}

class _RfiListPageState extends State<RfiListPage> {
  final RfiService _rfiService = RfiService();
  final ProjectService _projectService = ProjectService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rfis = [];
  List<Map<String, dynamic>> _members = [];

  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;
  int? _assignedFilter;
  DateTime? _dateFilter;

  static const List<String> _statuses = [
    'Draft',
    'Open',
    'Assigned',
    'Answered',
    'Closed',
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadRfis();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _projectService.getProjectMembers(
        widget.projectId,
      );
      if (!mounted) return;
      setState(() => _members = members);
    } catch (_) {
      // Assigned-user filter just stays empty if this fails.
    }
  }

  Future<void> _loadRfis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rfis = await _rfiService.getRfisByProject(
        widget.projectId,
        status: _statusFilter,
        assignedToId: _assignedFilter,
        rfiNumber: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        dateFrom: _dateFilter != null
            ? DateTime(
                _dateFilter!.year,
                _dateFilter!.month,
                _dateFilter!.day,
              ).toUtc().toIso8601String()
            : null,
        dateTo: _dateFilter != null
            ? DateTime(
                _dateFilter!.year,
                _dateFilter!.month,
                _dateFilter!.day,
                23,
                59,
                59,
              ).toUtc().toIso8601String()
            : null,
      );

      if (!mounted) return;

      setState(() {
        _rfis = rfis;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load RFIs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createNew() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewRfiPage(
          projectId: widget.projectId,
          projectName: widget.projectName,
          projectCode: widget.projectCode,
        ),
      ),
    );

    if (result == true) {
      _loadRfis();
    }
  }

  Future<void> _openRfi(Map<String, dynamic> rfi, {bool review = false}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewRfiPage(
          projectId: widget.projectId,
          projectName: widget.projectName,
          projectCode: widget.projectCode,
          existingRfi: rfi,
          startAtReview: review,
        ),
      ),
    );

    if (result == true) {
      _loadRfis();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('RFI – ${widget.projectCode ?? widget.projectName}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRfis,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(),
              const SizedBox(height: 16),
              _buildFilterCard(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _buildErrorState()
              else if (_rfis.isEmpty)
                _buildEmptyState()
              else
                _buildTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Requests for Inspection',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _createNew,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New RFI'),
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search RFI Number',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _loadRfis(),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String?>(
                initialValue: _statusFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._statuses.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s)),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                  _loadRfis();
                },
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int?>(
                initialValue: _assignedFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assigned To',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Anyone')),
                  ..._members.map(
                    (m) => DropdownMenuItem(
                      value: m['id'] as int,
                      child: Text(
                        m['name'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _assignedFilter = value);
                  _loadRfis();
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateFilter ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() => _dateFilter = picked);
                    _loadRfis();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(
                    _dateFilter != null
                        ? DateFormat('yyyy-MM-dd').format(_dateFilter!)
                        : 'Any date',
                  ),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _statusFilter = null;
                  _assignedFilter = null;
                  _dateFilter = null;
                });
                _loadRfis();
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
            ),
            ElevatedButton.icon(
              onPressed: _loadRfis,
              icon: const Icon(Icons.filter_alt_outlined, size: 18),
              label: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.06),
          ),
          columns: const [
            DataColumn(label: Text('RFI Number')),
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Created By')),
            DataColumn(label: Text('Assigned To')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Last Updated')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _rfis.map((rfi) {
            final createdBy = rfi['createdBy'] as Map?;
            final assignedTo = rfi['assignedTo'] as Map?;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    (rfi['rfiNumber'] as String?) ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      (rfi['subject'] as String?)?.trim().isNotEmpty == true
                          ? rfi['subject'] as String
                          : ((rfi['location'] as String?) ?? '-'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(_formatDate(rfi['requestDate']))),
                DataCell(Text((createdBy?['name'] as String?) ?? '-')),
                DataCell(Text((assignedTo?['name'] as String?) ?? 'Unassigned')),
                DataCell(_buildStatusBadge((rfi['status'] as String?) ?? 'Draft')),
                DataCell(Text(_formatDate(rfi['updatedAt']))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Open',
                        icon: const Icon(Icons.open_in_new, size: 18),
                        onPressed: () => _openRfi(rfi),
                      ),
                      IconButton(
                        tooltip: 'Print',
                        icon: const Icon(Icons.print_outlined, size: 18),
                        onPressed: () => _openRfi(rfi, review: true),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.primary;
      case 'Assigned':
        return const Color(0xFF7C4DFF);
      case 'Answered':
        return AppColors.success;
      case 'Closed':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  String _formatDate(dynamic value) {
    if (value is! String) return '-';

    try {
      final date = DateTime.parse(value).toLocal();
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return '-';
    }
  }

  Widget _buildEmptyState() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 56,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              const Text(
                'No RFIs found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create the first Request for Inspection for this project.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createNew,
                icon: const Icon(Icons.add),
                label: const Text('New RFI'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error ?? 'Something went wrong.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadRfis,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
