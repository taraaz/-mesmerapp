import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'api_client.dart';
import 'daily_report_service.dart';

/// Renders a Daily Report as a printable PDF laid out like the
/// project's paper "Site Daily Report" form (bilingual English /
/// Russian headings, boxed header info, personnel/equipment/executed
/// work/materials/next-day tables, photos and a 3-way endorsement
/// block).
class DailyReportPdfService {
  static const PdfColor _headerFill = PdfColor.fromInt(0xFFD9E2F3);
  static const PdfColor _sectionFill = PdfColor.fromInt(0xFFBFBFBF);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFF000000);

  Future<Uint8List> generate({
    required Map<String, dynamic> report,
    required String projectName,
    required int projectId,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
    );

    final photoImages = await _loadPhotoImages(report);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          _buildTitle(projectName, projectId),
          _buildHeaderInfo(report),
          pw.SizedBox(height: 10),
          _sectionTitle(
            '1. Contractor\'s Personnel / Персонал подрядчика',
          ),
          _buildPersonnelSection(report),
          pw.SizedBox(height: 10),
          _sectionTitle(
            '2. Contractor\'s Site Equipment / Оборудование на объекте подрядчика',
          ),
          _buildEquipmentSection(report),
          pw.SizedBox(height: 10),
          _sectionTitle(
            '3. Executed Work / Выполненная работа',
          ),
          _buildExecutedWorkSection(report),
          pw.SizedBox(height: 10),
          _sectionTitle(
            '4. Contractor\'s Materials / Материалы Подрядчика',
          ),
          _buildMaterialsSection(report),
          pw.SizedBox(height: 10),
          _sectionTitle(
            '5. Work Programme (For the next day) / Рабочая программа (на следующий день)',
          ),
          _buildNextDaySection(report),
          pw.SizedBox(height: 10),
          _sectionTitle(
            '6. General Issues / Общие вопросы',
          ),
          _buildGeneralIssuesSection(report),
          pw.SizedBox(height: 10),
          _sectionTitle(
            '7. Daily Site Photos & Files / Ежедневные фотографии и файлы',
          ),
          _buildPhotosSection(report, photoImages),
          pw.SizedBox(height: 10),
          _sectionTitle(
            '8. Endorsements / Согласование',
          ),
          _buildEndorsementsSection(report),
        ],
      ),
    );

    return doc.save();
  }

  // ============================================================
  // TITLE
  // ============================================================

  pw.Widget _buildTitle(String projectName, int projectId) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Site Daily Report / Ежедневный отчет с объекта',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$projectName (Project ID: $projectId)',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      color: _sectionFill,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER INFO
  // ============================================================

  pw.Widget _buildHeaderInfo(Map<String, dynamic> report) {
    final DateTime? date = _parseDate(report['reportDate']);

    final headers = [
      'Day/\nдень',
      'Month/\nмесяц',
      'Year/\nгод',
      'Days of the week/\nДни недели',
      'Weather:/\nПогода',
      'Wind Speed/\nВетер скорость',
      'Temperature:/\nТемпература',
      'Moisture:/\nВлажность',
    ];

    final values = [
      date != null ? '${date.day}' : '-',
      date != null ? '${date.month}' : '-',
      date != null ? '${date.year}' : '-',
      date != null ? _weekdayName(date) : '-',
      (report['weather'] as String?) ?? '-',
      report['windSpeed'] != null ? '${report['windSpeed']} m/s' : '-',
      report['temperature'] != null
          ? '${report['temperature']} °C'
          : '-',
      report['moisture'] != null ? '${report['moisture']}%' : '-',
    ];

    return _gridTable(
      headerRows: [headers],
      dataRows: [values],
      headerStyle: pw.TextStyle(
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerFill: _headerFill,
    );
  }

  // ============================================================
  // PERSONNEL
  // ============================================================

  pw.Widget _buildPersonnelSection(Map<String, dynamic> report) {
    final personnel = (report['personnel'] as List<dynamic>?) ?? [];

    const categories = [
      ['Key Personnel', 'Key Personnel / Ключевой сотрудник'],
      [
        'Administration Staff',
        'Administration Staff / Административный персонал',
      ],
      ['Operators', 'Operators / Операторы'],
      ['Worker', 'Worker / Рабочий'],
    ];

    int totalOf(String category) {
      return personnel
          .where((item) => item['category'] == category)
          .fold<int>(
            0,
            (sum, item) => sum + ((item['count'] as num?)?.toInt() ?? 0),
          );
    }

    final total = categories.fold<int>(
      0,
      (sum, cat) => sum + totalOf(cat[0]),
    );

    final statsRow = _gridTable(
      headerRows: [
        [
          ...categories.map((c) => c[1]),
          'Total Personnel / Общее кол-во персонала',
        ],
      ],
      dataRows: [
        [
          ...categories.map((c) => '${totalOf(c[0])}'),
          '$total',
        ],
      ],
      headerStyle: pw.TextStyle(
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      headerFill: _headerFill,
    );

    final categoryTables = categories.map((cat) {
      final rows = personnel
          .where((item) => item['category'] == cat[0])
          .toList();

      if (rows.isEmpty) {
        return pw.SizedBox();
      }

      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              cat[1],
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            _simpleTable(
              columnHeaders: const ['Position / Должность', 'No. / №'],
              columnWidths: const {0: 6, 1: 1},
              rows: rows
                  .map(
                    (item) => [
                      (item['position'] as String?) ?? '',
                      '${(item['count'] as num?)?.toInt() ?? 0}',
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        statsRow,
        ...categoryTables,
      ],
    );
  }

  // ============================================================
  // EQUIPMENT
  // ============================================================

  pw.Widget _buildEquipmentSection(Map<String, dynamic> report) {
    final equipment = (report['equipment'] as List<dynamic>?) ?? [];

    if (equipment.isEmpty) {
      return _emptyNote();
    }

    return _simpleTable(
      columnHeaders: const [
        'Equipment / Оборудование',
        'Active / Total\nАктив / Всего',
      ],
      columnWidths: const {0: 6, 1: 2},
      rows: equipment
          .map(
            (item) => [
              (item['equipment'] as String?) ?? '',
              '${(item['active'] as num?)?.toInt() ?? 0}/${(item['total'] as num?)?.toInt() ?? 0}',
            ],
          )
          .toList(),
    );
  }

  // ============================================================
  // EXECUTED WORK
  // ============================================================

  pw.Widget _buildExecutedWorkSection(Map<String, dynamic> report) {
    final work = (report['executedWork'] as List<dynamic>?) ?? [];

    if (work.isEmpty) {
      return _emptyNote();
    }

    return _simpleTable(
      columnHeaders: const [
        '#',
        'Location /\nМестонахождение',
        'Description / Описание',
        'Unit /\nЕд.изм.',
        'Total physical\nvolume',
        'Since\nbeginning',
        'Qty /\nКол-во',
        'Completed\n%',
      ],
      columnWidths: const {
        0: 0.5,
        1: 2,
        2: 4,
        3: 1,
        4: 1.5,
        5: 1.5,
        6: 1,
        7: 1,
      },
      rows: List.generate(work.length, (index) {
        final item = work[index] as Map;
        return [
          '${index + 1}',
          (item['location'] as String?) ?? '',
          (item['description'] as String?) ?? '',
          (item['unit'] as String?) ?? '',
          (item['totalPhysicalVolume'] as String?) ?? '',
          (item['sinceBeginning'] as String?) ?? '',
          (item['quantity'] as String?) ?? '',
          (item['completedPercent'] as String?) ?? '',
        ];
      }),
    );
  }

  // ============================================================
  // MATERIALS
  // ============================================================

  pw.Widget _buildMaterialsSection(Map<String, dynamic> report) {
    final materials = (report['materials'] as List<dynamic>?) ?? [];

    if (materials.isEmpty ||
        materials.every(
          (item) =>
              ((item['material'] as String?) ?? '').trim().isEmpty,
        )) {
      return _emptyNote();
    }

    return _simpleTable(
      columnHeaders: const [
        'Material / Материал',
        'Unit / Ед.изм.',
        'No. / №',
      ],
      columnWidths: const {0: 4, 1: 2, 2: 1},
      rows: materials
          .where(
            (item) =>
                ((item['material'] as String?) ?? '').trim().isNotEmpty,
          )
          .map(
            (item) => [
              (item['material'] as String?) ?? '',
              (item['unit'] as String?) ?? '',
              (item['number'] as String?) ?? '',
            ],
          )
          .toList(),
    );
  }

  // ============================================================
  // NEXT DAY WORK
  // ============================================================

  pw.Widget _buildNextDaySection(Map<String, dynamic> report) {
    final nextDay = (report['nextDayWork'] as List<dynamic>?) ?? [];

    if (nextDay.isEmpty) {
      return _emptyNote();
    }

    return _simpleTable(
      columnHeaders: const [
        '#',
        'Location / Местонахождение',
        'Description / Описание',
      ],
      columnWidths: const {0: 0.5, 1: 3, 2: 6},
      rows: List.generate(nextDay.length, (index) {
        final item = nextDay[index] as Map;
        return [
          '${index + 1}',
          (item['location'] as String?) ?? '',
          (item['description'] as String?) ?? '',
        ];
      }),
    );
  }

  // ============================================================
  // GENERAL ISSUES
  // ============================================================

  pw.Widget _buildGeneralIssuesSection(Map<String, dynamic> report) {
    final issues = (report['generalIssues'] as String?)?.trim();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.6),
      ),
      child: pw.Text(
        (issues == null || issues.isEmpty)
            ? 'No issues reported.'
            : issues,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  // ============================================================
  // PHOTOS & FILES
  // ============================================================

  pw.Widget _buildPhotosSection(
    Map<String, dynamic> report,
    List<_LoadedPhoto> photos,
  ) {
    final attachments = (report['attachments'] as List<dynamic>?) ?? [];

    final files = attachments
        .where((item) => item['isPhoto'] != true)
        .map((item) => (item['originalName'] as String?) ?? 'file')
        .toList();

    if (photos.isEmpty && files.isEmpty) {
      return _emptyNote();
    }

    final widgets = <pw.Widget>[];

    if (photos.isNotEmpty) {
      widgets.add(
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: photos
              .map(
                (photo) => pw.Container(
                  width: 150,
                  height: 120,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: _borderColor,
                      width: 0.5,
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.ClipRect(
                          child: pw.Image(
                            photo.image,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          photo.name,
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          style: const pw.TextStyle(fontSize: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    if (files.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(
        pw.Text(
          'Attached files: ${files.join(', ')}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Future<List<_LoadedPhoto>> _loadPhotoImages(
    Map<String, dynamic> report,
  ) async {
    final attachments = (report['attachments'] as List<dynamic>?) ?? [];
    final dailyReportService = DailyReportService();
    final dio = ApiClient.instance.dio;

    final photos = <_LoadedPhoto>[];

    for (final item in attachments) {
      if (item['isPhoto'] != true) {
        continue;
      }

      final filePath = item['filePath'] as String?;

      if (filePath == null) {
        continue;
      }

      try {
        final response = await dio.get<List<int>>(
          dailyReportService.attachmentUrl(filePath),
          options: Options(responseType: ResponseType.bytes),
        );

        final bytes = Uint8List.fromList(response.data ?? []);

        if (bytes.isEmpty) {
          continue;
        }

        photos.add(
          _LoadedPhoto(
            name: (item['originalName'] as String?) ?? 'photo',
            image: pw.MemoryImage(bytes),
          ),
        );
      } catch (_) {
        // Skip photos that fail to download rather than failing
        // the whole PDF export.
      }
    }

    return photos;
  }

  // ============================================================
  // ENDORSEMENTS
  // ============================================================

  pw.Widget _buildEndorsementsSection(Map<String, dynamic> report) {
    return _gridTable(
      headerRows: [
        [
          'Prepared By / Подготовлено',
          'Confirmed By / Подтверждено',
          'Approved By / Одобрено',
        ],
      ],
      dataRows: [
        [
          (report['preparedBy'] as String?) ?? '-',
          (report['confirmedBy'] as String?) ?? '-',
          (report['approvedBy'] as String?) ?? '-',
        ],
        [
          (report['preparedByRole'] as String?) ?? '-',
          (report['confirmedByRole'] as String?) ?? '-',
          (report['approvedByRole'] as String?) ?? '-',
        ],
        ['', '', ''],
      ],
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerFill: _headerFill,
      dataRowHeights: const [16, 16, 30],
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
    List<double>? dataRowHeights,
  }) {
    final columnCount = headerRows.first.length;

    pw.TableRow buildRow(
      List<String> cells,
      pw.TextStyle style, {
      PdfColor? fill,
      double? height,
    }) {
      return pw.TableRow(
        decoration: fill != null
            ? pw.BoxDecoration(color: fill)
            : null,
        children: cells
            .map(
              (text) => pw.Container(
                height: height,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 3,
                ),
                child: pw.Text(
                  text,
                  textAlign: pw.TextAlign.center,
                  style: style,
                ),
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
        ...List.generate(dataRows.length, (i) {
          return buildRow(
            dataRows[i],
            cellStyle,
            height: dataRowHeights != null && i < dataRowHeights.length
                ? dataRowHeights[i]
                : null,
          );
        }),
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
        style: pw.TextStyle(
          fontSize: 8,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value is! String) {
      return null;
    }

    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _weekdayName(DateTime date) {
    const names = [
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
}

class _LoadedPhoto {
  final String name;
  final pw.MemoryImage image;

  const _LoadedPhoto({
    required this.name,
    required this.image,
  });
}
