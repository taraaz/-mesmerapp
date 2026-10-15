import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Renders an RFI (Request for Inspection) as a printable, A4-optimized
/// PDF laid out like the project's paper "Request for Inspection" form —
/// boxed header info, a purpose-of-inspection checklist, reviewer sign-off
/// row, and an engineer's inspection report / comments block.
class RfiPdfService {
  static const PdfColor _headerFill = PdfColor.fromInt(0xFFD9E2F3);
  static const PdfColor _sectionFill = PdfColor.fromInt(0xFFBFBFBF);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFF000000);

  Future<Uint8List> generate({
    required Map<String, dynamic> rfi,
    required String projectName,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildTitle(rfi, projectName),
          pw.SizedBox(height: 8),
          _buildLocationGrid(rfi),
          pw.SizedBox(height: 8),
          _sectionTitle('4. Purpose of the Inspection / Цель инспекции'),
          _buildPurposeSection(rfi),
          pw.SizedBox(height: 8),
          _sectionTitle(
            '5. Permitted Construction Works / Допускается выполнение строительных работ',
          ),
          _buildPermittedWorkSection(rfi),
          pw.SizedBox(height: 8),
          _sectionTitle('Reviewers / Инженеры'),
          _buildReviewersSection(rfi),
          pw.SizedBox(height: 8),
          _sectionTitle('Submission'),
          _buildSubmissionSection(rfi),
          pw.SizedBox(height: 8),
          _sectionTitle(
            '6. Inspection Report by Engineer / Отчет о проверке инженер',
          ),
          _buildInspectionReportSection(rfi),
          pw.SizedBox(height: 8),
          _sectionTitle(
            '7. Engineer\'s Comments / Комментария инженера',
          ),
          _buildCommentsSection(rfi),
          pw.SizedBox(height: 8),
          _buildStatusFooter(rfi),
        ],
      ),
    );

    return doc.save();
  }

  // ============================================================
  // TITLE
  // ============================================================

  pw.Widget _buildTitle(Map<String, dynamic> rfi, String projectName) {
    final String rfiNumber = (rfi['rfiNumber'] as String?) ?? '-';
    final DateTime? requestDate = _parseDate(rfi['requestDate']);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.8),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  rfiNumber,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'REQUEST FOR INSPECTION / ЗАПРОС НА ИНСПЕКЦИЮ РАБОТ',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  projectName,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'We request your attendance to inspect the following works / Мы просим вашего присутствия для осмотра следующих работ',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Date: ${requestDate != null ? _formatDate(requestDate) : '-'}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Rev.: ${(rfi['revision'] as String?) ?? '00'}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Enclosed: ${rfi['enclosedCount'] ?? 0}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Status: ${(rfi['status'] as String?) ?? 'Draft'}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      color: _sectionFill,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  // ============================================================
  // LOCATION / HEADER GRID
  // ============================================================

  pw.Widget _buildLocationGrid(Map<String, dynamic> rfi) {
    return _gridTable(
      headerRows: [
        ['Type / Тип', 'Inspection Time / Время', 'Sequence / Инспекция'],
      ],
      dataRows: [
        [
          (rfi['type'] as String?) ?? '-',
          '${(rfi['inspectionTimeFrom'] as String?) ?? '-'} - ${(rfi['inspectionTimeTo'] as String?) ?? '-'}',
          (rfi['inspectionSequence'] as String?) ?? '-',
        ],
      ],
      headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerFill: _headerFill,
    ).let((table) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          table,
          pw.SizedBox(height: 6),
          _gridTable(
            headerRows: [
              [
                'Location / Расположение',
                'Elev/Loc / Отм.',
                'Work Type / Тип работы',
                'Drawing No / Номер чертежа',
              ],
            ],
            dataRows: [
              [
                (rfi['location'] as String?) ?? '-',
                (rfi['elevationLocation'] as String?) ?? '-',
                (rfi['workType'] as String?) ?? '-',
                (rfi['drawingNo'] as String?) ?? '-',
              ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerFill: _headerFill,
          ),
        ],
      );
    });
  }

  // ============================================================
  // PURPOSE OF INSPECTION
  // ============================================================

  pw.Widget _buildPurposeSection(Map<String, dynamic> rfi) {
    final List<dynamic> items = (rfi['purposeItems'] as List<dynamic>?) ?? [];

    final byCategory = <String, List<String>>{};

    for (final item in items) {
      final category = (item['category'] as String?) ?? 'Other';
      final label = (item['item'] as String?) ?? '';
      byCategory.putIfAbsent(category, () => []).add(label);
    }

    final String others = (rfi['othersSpecify'] as String?)?.trim() ?? '';
    final String particulars =
        (rfi['particularDetails'] as String?)?.trim() ?? '';

    if (byCategory.isEmpty && others.isEmpty && particulars.isEmpty) {
      return _emptyNote();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (byCategory.isNotEmpty)
          pw.Wrap(
            spacing: 14,
            runSpacing: 6,
            children: byCategory.entries.map((entry) {
              return pw.Container(
                constraints: const pw.BoxConstraints(maxWidth: 240),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      entry.key,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    ...entry.value.map(
                      (label) => pw.Text(
                        '☑  $label',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (others.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'Others: $others',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
        if (particulars.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Particular Details: $particulars',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // PERMITTED WORK
  // ============================================================

  pw.Widget _buildPermittedWorkSection(Map<String, dynamic> rfi) {
    final String description =
        (rfi['permittedWorkDescription'] as String?)?.trim() ?? '';
    final String quantity = (rfi['approxQuantity'] as String?) ?? '-';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              description.isEmpty ? 'Not specified.' : description,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              'Approx. qty: $quantity',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REVIEWERS
  // ============================================================

  pw.Widget _buildReviewersSection(Map<String, dynamic> rfi) {
    final List<dynamic> reviewers =
        (rfi['reviewers'] as List<dynamic>?) ?? [];

    if (reviewers.isEmpty) {
      return _emptyNote();
    }

    return _simpleTable(
      columnHeaders: const ['Discipline / Дисциплина', 'Name / Название'],
      columnWidths: const {0: 3, 1: 3},
      rows: reviewers
          .map(
            (r) => [
              (r['discipline'] as String?) ?? '',
              (r['name'] as String?) ?? '',
            ],
          )
          .toList(),
    );
  }

  // ============================================================
  // SUBMISSION
  // ============================================================

  pw.Widget _buildSubmissionSection(Map<String, dynamic> rfi) {
    final createdBy = rfi['createdBy'] as Map?;
    final assignedTo = rfi['assignedTo'] as Map?;

    return _gridTable(
      headerRows: [
        [
          'Created By / Составил',
          'Submitted By / Представлено',
          'Received By / Получено',
          'Assigned / Referred To',
        ],
      ],
      dataRows: [
        [
          (createdBy?['name'] as String?) ?? '-',
          (rfi['submittedByName'] as String?) ?? '-',
          (rfi['receivedByName'] as String?) ?? '-',
          (assignedTo?['name'] as String?) ?? 'Unassigned',
        ],
      ],
      headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerFill: _headerFill,
    );
  }

  // ============================================================
  // INSPECTION REPORT
  // ============================================================

  pw.Widget _buildInspectionReportSection(Map<String, dynamic> rfi) {
    final List<dynamic> reports =
        (rfi['inspectionReports'] as List<dynamic>?) ?? [];

    if (reports.isEmpty) {
      return _emptyNote();
    }

    return _simpleTable(
      columnHeaders: const [
        'Discipline / Дисциплина',
        'Remarks / Примечания',
        'Name / Название',
      ],
      columnWidths: const {0: 2, 1: 4, 2: 2},
      rows: reports
          .map(
            (r) => [
              (r['discipline'] as String?) ?? '',
              (r['remarks'] as String?) ?? '',
              (r['name'] as String?) ?? '',
            ],
          )
          .toList(),
    );
  }

  // ============================================================
  // COMMENTS / APPROVAL
  // ============================================================

  pw.Widget _buildCommentsSection(Map<String, dynamic> rfi) {
    final String comment = (rfi['engineerComment'] as String?) ?? '';
    final String supervisor =
        (rfi['supervisorSignedName'] as String?)?.trim() ?? '';
    final DateTime? supervisorDate = _parseDate(
      rfi['supervisorSignedDate'],
    );

    const options = ['Approved', 'Approved as Noted', 'Rejected'];

    return pw.Row(
      children: [
        ...options.map((option) {
          final selected = comment == option;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(right: 18),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _borderColor, width: 0.7),
                    color: selected ? PdfColors.black : PdfColors.white,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(option, style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          );
        }),
        pw.Spacer(),
        pw.Text(
          'Signed by Supervisor: ${supervisor.isEmpty ? '-' : supervisor}'
          '${supervisorDate != null ? ' (${_formatDate(supervisorDate)})' : ''}',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS FOOTER
  // ============================================================

  pw.Widget _buildStatusFooter(Map<String, dynamic> rfi) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Text(
        'Generated from MESMER — AI Project Hub',
        style: pw.TextStyle(
          fontSize: 7,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  // ============================================================
  // SHARED TABLE HELPERS
  // ============================================================

  pw.Widget _gridTable({
    required List<List<String>> headerRows,
    required List<List<String>> dataRows,
    required pw.TextStyle headerStyle,
    required pw.TextStyle cellStyle,
    required PdfColor headerFill,
  }) {
    final columnCount = headerRows.first.length;

    pw.TableRow buildRow(
      List<String> cells,
      pw.TextStyle style, {
      PdfColor? fill,
    }) {
      return pw.TableRow(
        decoration: fill != null ? pw.BoxDecoration(color: fill) : null,
        children: cells
            .map(
              (text) => pw.Container(
                alignment: pw.Alignment.centerLeft,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: pw.Text(text, style: style),
              ),
            )
            .toList(),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.6),
      columnWidths: {
        for (int i = 0; i < columnCount; i++)
          i: const pw.FlexColumnWidth(1),
      },
      children: [
        ...headerRows.map(
          (row) => buildRow(row, headerStyle, fill: headerFill),
        ),
        ...dataRows.map((row) => buildRow(row, cellStyle)),
      ],
    );
  }

  pw.Widget _simpleTable({
    required List<String> columnHeaders,
    required Map<int, double> columnWidths,
    required List<List<String>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: {
        for (final entry in columnWidths.entries)
          entry.key: pw.FlexColumnWidth(entry.value),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerFill),
          children: columnHeaders
              .map(
                (text) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: row
                .map(
                  (text) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 2,
                    ),
                    child: pw.Text(
                      text,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _emptyNote() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        'No entries recorded.',
        style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;

    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
