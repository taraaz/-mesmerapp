import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/daily_report_service.dart';
import 'daily_report_desktop_page.dart';
import 'rfi_list_page.dart';

class ProjectDashboardPage extends StatefulWidget {
  final int projectId;
  final String projectName;
  final String? projectCode;
  final String? projectDescription;
  final String? projectLocation;
  final String? projectStatus;
  final Color? avatarColor;

  const ProjectDashboardPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.projectCode,
    this.projectDescription,
    this.projectLocation,
    this.projectStatus,
    this.avatarColor,
  });

  @override
  State<ProjectDashboardPage> createState() =>
      _ProjectDashboardPageState();
}

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  final DailyReportService _dailyReportService = DailyReportService();

  bool _isLoadingStats = true;
  int _totalReports = 0;
  int _submittedReports = 0;
  int _pendingReports = 0;
  int _archivedReports = 0;

  String get _code =>
      (widget.projectCode?.trim().isNotEmpty ?? false)
          ? widget.projectCode!
          : widget.projectName;

  Color get _avatarColor => widget.avatarColor ?? AppColors.primary;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final reports = await _dailyReportService.getReportsByProject(
        widget.projectId,
      );

      if (!mounted) return;

      setState(() {
        _totalReports = reports.length;
        _submittedReports = reports
            .where((r) => r['status'] == 'Submitted')
            .length;
        _archivedReports = reports
            .where((r) => r['status'] == 'Archived')
            .length;
        _pendingReports =
            _totalReports - _submittedReports - _archivedReports;
        _isLoadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _code.length >= 2
                    ? _code.substring(0, 2).toUpperCase()
                    : _code.toUpperCase(),
                style: TextStyle(
                  color: _avatarColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _code,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.projectName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showProjectInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildOverviewRow(),

            const SizedBox(height: 24),

            const Text(
              'Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildFeaturesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow() {
    final tiles = [
      _StatTile(
        icon: Icons.description_outlined,
        color: AppColors.primary,
        value: _totalReports,
        label: 'Reports',
      ),
      _StatTile(
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        value: _submittedReports,
        label: 'Submitted',
      ),
      _StatTile(
        icon: Icons.access_time,
        color: AppColors.warning,
        value: _pendingReports < 0 ? 0 : _pendingReports,
        label: 'Pending',
      ),
      _StatTile(
        icon: Icons.archive_outlined,
        color: const Color(0xFF7C4DFF),
        value: _archivedReports,
        label: 'Archived',
      ),
    ];

    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 500 ? 4 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: tiles,
        );
      },
    );
  }

  Widget _buildFeaturesCard(BuildContext context) {
    const features = [
      _Feature(
        title: 'Daily Report',
        icon: Icons.assignment_outlined,
        description: 'Manage and submit daily reports',
        color: AppColors.success,
      ),
      _Feature(
        title: 'RFI',
        icon: Icons.help_outline,
        description: 'Request for Information',
        color: Color(0xFF7C4DFF),
      ),
      _Feature(
        title: 'Material Submittal',
        icon: Icons.folder_outlined,
        description: 'Submit and track materials',
        color: Color(0xFFF57C00),
      ),
      _Feature(
        title: 'Survey (KMZ, ...)',
        icon: Icons.location_on_outlined,
        description: 'Survey files and minor issues',
        color: AppColors.success,
      ),
      _Feature(
        title: 'Daily Photo',
        icon: Icons.photo_camera_outlined,
        description: 'Upload and manage daily photos',
        color: AppColors.primary,
      ),
      _Feature(
        title: 'MRI (Material Request for Inspect)',
        icon: Icons.image_outlined,
        description: 'Request materials for inspection',
        color: Color(0xFF7C4DFF),
      ),
      _Feature(
        title: 'NCR',
        icon: Icons.warning_amber_rounded,
        description: 'Non-Conformance Reports',
        color: AppColors.error,
      ),
      _Feature(
        title: 'News',
        icon: Icons.campaign_outlined,
        description: 'Project news and updates',
        color: AppColors.warning,
      ),
      _Feature(
        title: 'Personnel',
        icon: Icons.people_outline,
        description: 'Project team and personnel',
        color: Color(0xFF00897B),
      ),
      _Feature(
        title: 'Tech Office Instruction',
        icon: Icons.settings_outlined,
        description: 'Technical office instructions',
        color: AppColors.primary,
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (int i = 0; i < features.length; i++) ...[
            _buildFeatureTile(context, features[i]),
            if (i != features.length - 1)
              const Divider(height: 1, indent: 68),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, _Feature feature) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: feature.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(feature.icon, size: 20, color: feature.color),
      ),
      title: Text(
        feature.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        feature.description,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openFeature(context, feature.title),
    );
  }

  void _showProjectInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.projectName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _infoRow('Project Code', _code),
              if (widget.projectLocation != null)
                _infoRow('Location', widget.projectLocation!),
              if (widget.projectStatus != null)
                _infoRow('Status', widget.projectStatus!),
              if (widget.projectDescription != null &&
                  widget.projectDescription!.trim().isNotEmpty)
                _infoRow('Description', widget.projectDescription!),
              _infoRow('Project ID', '${widget.projectId}'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  void _openFeature(BuildContext context, String featureName) {
    if (featureName == 'Daily Report') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyReportDesktopPage(
            projectId: widget.projectId,
            projectName: widget.projectName,
            projectCode: widget.projectCode,
          ),
        ),
      ).then((_) => _loadStats());

      return;
    }

    if (featureName == 'RFI') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RfiListPage(
            projectId: widget.projectId,
            projectName: widget.projectName,
            projectCode: widget.projectCode,
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeaturePlaceholderPage(
          projectId: widget.projectId,
          featureName: featureName,
          projectName: widget.projectName,
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final String description;
  final Color color;

  const _Feature({
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
  });
}

class FeaturePlaceholderPage extends StatelessWidget {
  final int projectId;
  final String featureName;
  final String projectName;

  const FeaturePlaceholderPage({
    super.key,
    required this.projectId,
    required this.featureName,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(featureName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 70,
            ),

            const SizedBox(height: 20),

            Text(
              featureName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              projectName,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Project ID: $projectId',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'This feature will be implemented next.',
            ),
          ],
        ),
      ),
    );
  }
}
