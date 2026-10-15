import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:web/web.dart' as web;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/daily_report_pdf_service.dart';
import '../../../../core/services/daily_report_service.dart';
import '../../../../core/services/project_service.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import 'new_daily_report_page.dart';
import 'project_dashboard_page.dart';
import 'projects_page.dart';
import 'rfi_list_page.dart';

class _NavItem {
  final String title;
  final IconData icon;
  final Color color;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}

const List<_NavItem> _featureNavItems = [
  _NavItem(
    title: 'Daily Report',
    icon: Icons.assignment_outlined,
    color: AppColors.success,
  ),
  _NavItem(
    title: 'RFI',
    icon: Icons.help_outline,
    color: Color(0xFF7C4DFF),
  ),
  _NavItem(
    title: 'Material Submittal',
    icon: Icons.folder_outlined,
    color: Color(0xFFF57C00),
  ),
  _NavItem(
    title: 'Survey (KMZ, ...)',
    icon: Icons.location_on_outlined,
    color: AppColors.success,
  ),
  _NavItem(
    title: 'Daily Photo',
    icon: Icons.photo_camera_outlined,
    color: AppColors.primary,
  ),
  _NavItem(
    title: 'MRI (Material Request for Inspect)',
    icon: Icons.image_outlined,
    color: Color(0xFF7C4DFF),
  ),
  _NavItem(
    title: 'NCR',
    icon: Icons.warning_amber_rounded,
    color: AppColors.error,
  ),
  _NavItem(
    title: 'News',
    icon: Icons.campaign_outlined,
    color: AppColors.warning,
  ),
  _NavItem(
    title: 'Personnel',
    icon: Icons.people_outline,
    color: Color(0xFF00897B),
  ),
  _NavItem(
    title: 'Tech Office Instruction',
    icon: Icons.settings_outlined,
    color: AppColors.primary,
  ),
];

class DailyReportDesktopPage extends ConsumerStatefulWidget {
  final int projectId;
  final String projectName;
  final String? projectCode;

  const DailyReportDesktopPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.projectCode,
  });

  @override
  ConsumerState<DailyReportDesktopPage> createState() =>
      _DailyReportDesktopPageState();
}

class _DailyReportDesktopPageState
    extends ConsumerState<DailyReportDesktopPage> {
  final DailyReportService _dailyReportService = DailyReportService();
  final DailyReportPdfService _pdfService = DailyReportPdfService();
  final ProjectService _projectService = ProjectService();

  late int _projectId;
  late String _projectName;
  String? _projectCode;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _reports = [];
  List<Project> _allProjects = [];

  bool _sidebarCollapsed = false;
  bool _showFullArchive = false;

  int? _expandedId;
  int _activeDetailTab = 0;
  final Map<int, Map<String, dynamic>> _detailCache = {};
  bool _isLoadingDetail = false;

  int? _printingReportId;

  String get _code =>
      (_projectCode?.trim().isNotEmpty ?? false) ? _projectCode! : _projectName;

  @override
  void initState() {
    super.initState();
    _projectId = widget.projectId;
    _projectName = widget.projectName;
    _projectCode = widget.projectCode;
    _loadReports();
    _loadProjects();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports =
          await _dailyReportService.getReportsByProject(_projectId);

      if (!mounted) return;

      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load Daily Reports: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProjects() async {
    try {
      final data = await _projectService.getProjects();

      if (!mounted) return;

      setState(() {
        _allProjects = data.map((json) => Project.fromJson(json)).toList();
      });
    } catch (_) {
      // Project switcher just stays limited to the current project.
    }
  }

  void _switchProject(Project project) {
    if (project.id == _projectId) return;

    setState(() {
      _projectId = project.id;
      _projectName = project.name;
      _projectCode = project.code;
      _expandedId = null;
      _detailCache.clear();
      _showFullArchive = false;
    });

    _loadReports();
  }

  List<Map<String, dynamic>> get _sortedReports {
    final list = [..._reports];
    list.sort((a, b) {
      final aDate = a['reportDate'] as String? ?? '';
      final bDate = b['reportDate'] as String? ?? '';
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Future<void> _toggleExpand(Map<String, dynamic> report) async {
    final int? id = report['id'] as int?;
    if (id == null) return;

    if (_expandedId == id) {
      setState(() {
        _expandedId = null;
      });
      return;
    }

    setState(() {
      _expandedId = id;
      _activeDetailTab = 0;
    });

    if (_detailCache.containsKey(id)) return;

    setState(() => _isLoadingDetail = true);

    try {
      final full = await _dailyReportService.getReportById(id);
      if (!mounted) return;

      setState(() {
        _detailCache[id] = full;
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingDetail = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load report details: $e')),
      );
    }
  }

  Future<void> _createNewReport() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewDailyReportPage(
          projectId: _projectId,
          projectName: _projectName,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily Report saved successfully.')),
      );
      _detailCache.clear();
      _loadReports();
    }
  }

  Future<void> _editReport(int reportId) async {
    Map<String, dynamic>? full = _detailCache[reportId];

    try {
      full ??= await _dailyReportService.getReportById(reportId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Daily Report: $e')),
      );
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewDailyReportPage(
          projectId: _projectId,
          projectName: _projectName,
          existingReport: full,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily Report updated successfully.')),
      );
      _detailCache.remove(reportId);
      _loadReports();
    }
  }

  void _handleSaveTap() {
    if (_expandedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a report above to edit and save it.'),
        ),
      );
      return;
    }

    _editReport(_expandedId!);
  }

  Future<void> _printReport(int reportId) async {
    if (_printingReportId != null) return;

    setState(() => _printingReportId = reportId);

    try {
      final full =
          _detailCache[reportId] ?? await _dailyReportService.getReportById(reportId);

      final bytes = await _pdfService.generate(
        report: full,
        projectName: _projectName,
        projectId: _projectId,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Daily_Report_$reportId.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _printingReportId = null);
    }
  }

  void _openFeaturePlaceholder(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeaturePlaceholderPage(
          projectId: _projectId,
          featureName: title,
          projectName: _projectName,
        ),
      ),
    );
  }

  void _goToProjectsList() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 900;

          return Row(
            children: [
              if (isWide) _buildSidebar(context, collapsible: true),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(context, isWide),
                    Expanded(child: _buildMainContent()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      endDrawer: Drawer(
        child: _buildSidebar(context, collapsible: false, inDrawer: true),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context, {
    required bool collapsible,
    bool inDrawer = false,
  }) {
    final bool collapsed = collapsible && _sidebarCollapsed && !inDrawer;
    final double width = collapsed ? 76 : 260;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: inDrawer ? null : width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI Project Hub',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSidebarTile(
                    icon: Icons.space_dashboard_outlined,
                    color: AppColors.primary,
                    title: 'Dashboard',
                    collapsed: collapsed,
                    active: false,
                    onTap: () {
                      if (inDrawer) Navigator.pop(context);
                      Navigator.maybePop(context);
                    },
                  ),
                  for (final item in _featureNavItems)
                    _buildSidebarTile(
                      icon: item.icon,
                      color: item.color,
                      title: item.title,
                      collapsed: collapsed,
                      active: item.title == 'Daily Report',
                      onTap: () {
                        if (inDrawer) Navigator.pop(context);
                        if (item.title == 'Daily Report') return;
                        if (item.title == 'RFI') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RfiListPage(
                                projectId: _projectId,
                                projectName: _projectName,
                                projectCode: _projectCode,
                              ),
                            ),
                          );
                          return;
                        }
                        _openFeaturePlaceholder(item.title);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildSidebarTile(
              icon: Icons.image_outlined,
              color: AppColors.textSecondary,
              title: 'Conduction Report Page',
              collapsed: collapsed,
              active: false,
              onTap: () {
                if (inDrawer) Navigator.pop(context);
                _openFeaturePlaceholder('Conduction Report Page');
              },
            ),
            _buildSidebarTile(
              icon: Icons.save_outlined,
              color: AppColors.primary,
              title: 'Save',
              collapsed: collapsed,
              active: false,
              onTap: () {
                if (inDrawer) Navigator.pop(context);
                _handleSaveTap();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required Color color,
    required String title,
    required bool collapsed,
    required bool active,
    required VoidCallback onTap,
  }) {
    final tile = Material(
      color: active ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? AppColors.primary : color,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.primary : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return collapsed ? Tooltip(message: title, child: tile) : tile;
  }

  Widget _buildTopBar(BuildContext context, bool isWide) {
    final user = ref.watch(authProvider).user;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (isWide) {
                setState(() => _sidebarCollapsed = !_sidebarCollapsed);
              } else {
                Scaffold.of(context).openEndDrawer();
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _breadcrumbLink('Projects', _goToProjectsList),
                    _breadcrumbSeparator(),
                    _breadcrumbLink(_code, () => Navigator.maybePop(context)),
                    _breadcrumbSeparator(),
                    const Text(
                      'Daily Report',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          if (user != null) _buildAccountMenu(context, user),
        ],
      ),
    );
  }

  Widget _breadcrumbLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _breadcrumbSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '>',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildAccountMenu(BuildContext context, AppUser user) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      onSelected: (value) async {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
          return;
        }

        if (value == 'logout') {
          await ref.read(authProvider.notifier).logout();
          if (!context.mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                appRoleLabel(user.role),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.background,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectSwitcherRow(),
            const SizedBox(height: 16),
            _buildHeaderCard(),
            const SizedBox(height: 16),
            if (!_isLoading && _error == null) _buildStatsRow(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorState()
            else ...[
              _buildReportListCard(),
              const SizedBox(height: 20),
              _buildArchiveTable(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSwitcherRow() {
    return Row(
      children: [
        const Text('Project', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        const Text('·', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _allProjects.any((p) => p.id == _projectId) ? _projectId : null,
              isExpanded: true,
              hint: Text(
                '$_code - $_projectName',
                overflow: TextOverflow.ellipsis,
              ),
              items: _allProjects
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.code} - ${p.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                final project = _allProjects.firstWhere((p) => p.id == value);
                _switchProject(project);
              },
            ),
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _goToProjectsList,
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: const Text('Change Project'),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_outlined, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Report – Project $_code',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Manage and submit daily reports',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _createNewReport,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Daily Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final int total = _reports.length;
    final int submitted = _reports.where((r) => r['status'] == 'Submitted').length;
    final int archived = _reports.where((r) => r['status'] == 'Archived').length;
    final int pending = total - submitted - archived;

    final tiles = [
      _StatTile(
        icon: Icons.description_outlined,
        color: AppColors.primary,
        value: total,
        label: 'Reports This Month',
      ),
      _StatTile(
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        value: submitted,
        label: 'Submitted',
      ),
      _StatTile(
        icon: Icons.access_time,
        color: AppColors.warning,
        value: pending < 0 ? 0 : pending,
        label: 'Pending',
      ),
      _StatTile(
        icon: Icons.archive_outlined,
        color: const Color(0xFF7C4DFF),
        value: archived,
        label: 'Archived',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 500 ? 4 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: tiles,
        );
      },
    );
  }

  Widget _buildReportListCard() {
    final reports = _sortedReports;

    if (reports.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.description_outlined, size: 56, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                const Text(
                  'No daily reports',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create the first Daily Report for this project.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createNewReport,
                  icon: const Icon(Icons.add),
                  label: const Text('New Daily Report'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (final report in reports) ...[
            _buildReportRow(report),
            if (report['id'] == _expandedId) _buildDetailPanel(report),
            if (report != reports.last) const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildReportRow(Map<String, dynamic> report) {
    final int? id = report['id'] as int?;
    final String status = (report['status'] as String?) ?? 'Draft';
    final bool expanded = _expandedId == id;

    return InkWell(
      onTap: () => _toggleExpand(report),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatReportDate(report['reportDate']),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _buildStatusBadge(status),
            const SizedBox(width: 8),
            SizedBox(
              width: 32,
              height: 32,
              child: _printingReportId == id
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: 'Print / Export PDF',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.print_outlined, size: 18),
                      onPressed: id == null ? null : () => _printReport(id),
                    ),
            ),
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel(Map<String, dynamic> report) {
    final int id = report['id'] as int;
    final String status = (report['status'] as String?) ?? 'Draft';
    final Map<String, dynamic>? full = _detailCache[id];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_formatReportDate(report['reportDate'])} – Daily Report',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _buildStatusBadge(status),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _toggleExpand(report),
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              ],
            ),
          ),
          if (_isLoadingDetail && full == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (full == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Text('Could not load report details.'),
            )
          else ...[
            _buildDetailTabBar(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDetailTabContent(full),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTabBar() {
    const tabs = ['Report Details', 'Daily Photo', 'Files', 'Archive'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            InkWell(
              onTap: () => setState(() => _activeDetailTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _activeDetailTab == i ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _activeDetailTab == i ? FontWeight.bold : FontWeight.w500,
                    color: _activeDetailTab == i ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailTabContent(Map<String, dynamic> full) {
    switch (_activeDetailTab) {
      case 1:
        return _buildPhotoTab(full);
      case 2:
        return _buildFilesTab(full);
      case 3:
        return _buildArchiveTab();
      default:
        return _buildReportDetailsTab(full);
    }
  }

  Widget _buildReportDetailsTab(Map<String, dynamic> full) {
    final List<dynamic> executedWork = (full['executedWork'] as List<dynamic>?) ?? [];
    final String workProgress = executedWork.isEmpty
        ? '-'
        : executedWork
            .map((w) => (w['description'] as String?)?.trim())
            .whereType<String>()
            .where((d) => d.isNotEmpty)
            .join('; ');

    final rows = <MapEntry<String, String>>[
      MapEntry('Project', _code),
      MapEntry('Date', _formatReportDate(full['reportDate'])),
      MapEntry('Prepared By', _valueOr(full['preparedBy'], 'Unassigned')),
      MapEntry('Weather', _valueOr(full['weather'], '-')),
      MapEntry('Work Progress', workProgress),
      MapEntry('Notes', _valueOr(full['generalIssues'], '-')),
      MapEntry('Status', (full['status'] as String?) ?? 'Draft'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    row.key,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: row.key == 'Status'
                      ? _buildStatusBadge(row.value)
                      : Text(row.value, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoTab(Map<String, dynamic> full) {
    final List<dynamic> attachments = (full['attachments'] as List<dynamic>?) ?? [];
    final photos = attachments.where((a) => a['isPhoto'] == true).toList();

    if (photos.isEmpty) {
      return const Text('No photos uploaded.', style: TextStyle(color: AppColors.textSecondary));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: photos.map((a) {
        final url = _dailyReportService.attachmentUrl(a['filePath'] as String);
        return GestureDetector(
          onTap: () => _showPhotoDialog(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                color: AppColors.border,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showPhotoDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }

  Widget _buildFilesTab(Map<String, dynamic> full) {
    final List<dynamic> attachments = (full['attachments'] as List<dynamic>?) ?? [];
    final files = attachments.where((a) => a['isPhoto'] != true).toList();

    if (files.isEmpty) {
      return const Text('No files uploaded.', style: TextStyle(color: AppColors.textSecondary));
    }

    return Column(
      children: files.map((f) {
        final url = _dailyReportService.attachmentUrl(f['filePath'] as String);
        final int? size = f['fileSize'] as int?;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text((f['originalName'] as String?) ?? 'File'),
          subtitle: size != null ? Text(_formatFileSize(size)) : null,
          trailing: IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => web.window.open(url, '_blank'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildArchiveTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This report\'s history is part of the full project archive below.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => setState(() => _showFullArchive = true),
          child: const Text('View All Archive'),
        ),
      ],
    );
  }

  Widget _buildArchiveTable() {
    final archive = [..._reports]
      ..sort((a, b) {
        final aDate = a['reportDate'] as String? ?? '';
        final bDate = b['reportDate'] as String? ?? '';
        return bDate.compareTo(aDate);
      });

    final visible = _showFullArchive ? archive : archive.take(5).toList();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Archive (All Reports for Project $_code)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (!_showFullArchive && archive.length > 5)
                  TextButton(
                    onPressed: () => setState(() => _showFullArchive = true),
                    child: const Text('View All Archive'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (archive.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No reports yet.', style: TextStyle(color: AppColors.textSecondary)),
              )
            else ...[
              const _ArchiveHeaderRow(),
              const Divider(height: 1),
              for (final report in visible) _buildArchiveRow(report),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveRow(Map<String, dynamic> report) {
    final int? id = report['id'] as int?;
    final String status = (report['status'] as String?) ?? 'Draft';
    final String preparedBy = _valueOr(report['preparedBy'], 'Unassigned');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(_formatReportDate(report['reportDate']))),
          Expanded(flex: 2, child: Text(preparedBy)),
          Expanded(flex: 2, child: _buildStatusBadge(status)),
          SizedBox(
            width: 76,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'View',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  onPressed: id == null ? null : () => _toggleExpand(report),
                ),
                IconButton(
                  tooltip: 'Download PDF',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  onPressed: id == null ? null : () => _printReport(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _handleSaveTap,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save'),
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
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBackgroundColor(status),
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
      case 'Submitted':
        return AppColors.success;
      case 'Draft':
        return AppColors.warning;
      case 'Archived':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  Color _statusBackgroundColor(String status) {
    switch (status) {
      case 'Submitted':
        return AppColors.success.withValues(alpha: 0.12);
      case 'Draft':
        return AppColors.warning.withValues(alpha: 0.14);
      case 'Archived':
        return AppColors.border.withValues(alpha: 0.5);
      default:
        return AppColors.primary.withValues(alpha: 0.12);
    }
  }

  String _valueOr(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  String _formatReportDate(dynamic value) {
    if (value is! String) return '-';

    try {
      final date = DateTime.parse(value).toLocal();
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return value;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ArchiveHeaderRow extends StatelessWidget {
  const _ArchiveHeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Date', style: style)),
          Expanded(flex: 2, child: Text('Prepared By', style: style)),
          Expanded(flex: 2, child: Text('Status', style: style)),
          SizedBox(width: 76, child: Text('Actions', style: style)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
