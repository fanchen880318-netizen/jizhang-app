import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill.dart';

class ExcelService {
  /// 导出账单为 Excel 文件并分享
  static Future<void> exportAndShare(
    List<Bill> bills,
    double total,
    String title,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['账单'];

    // 标题行
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    _setCell(sheet, 0, 0, '日期', style: headerStyle);
    _setCell(sheet, 0, 1, '用途', style: headerStyle);
    _setCell(sheet, 0, 2, '金额', style: headerStyle);
    _setCell(sheet, 0, 3, '备注', style: headerStyle);

    // 数据行
    for (int i = 0; i < bills.length; i++) {
      final bill = bills[i];
      final row = i + 1;

      _setCell(sheet, row, 0, DateFormat('yyyy-MM-dd').format(bill.date));
      _setCell(sheet, row, 1, bill.category);
      _setCell(sheet, row, 2, bill.amount);
      _setCell(sheet, row, 3, bill.note);
    }

    // 合计行（加粗）
    final totalRow = bills.length + 1;
    final totalStyle = CellStyle(bold: true);
    _setCell(sheet, totalRow, 0, '');
    _setCell(sheet, totalRow, 1, '合计', style: totalStyle);
    _setCell(sheet, totalRow, 2, total, style: totalStyle);
    _setCell(sheet, totalRow, 3, '');

    // 列宽
    sheet.setColumnWidth(0, 14);  // 日期
    sheet.setColumnWidth(1, 10);  // 用途
    sheet.setColumnWidth(2, 14);  // 金额
    sheet.setColumnWidth(3, 30);  // 备注

    // 保存文件
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$title.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    // 分享
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: title,
      text: '$title - 合计 ¥${total.toStringAsFixed(2)}',
    );
  }

  static void _setCell(Sheet sheet, int row, int col, dynamic value, {CellStyle? style}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));

    if (value is String) {
      cell.value = TextCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is num) {
      cell.value = DoubleCellValue(value.toDouble());
    }

    if (style != null) {
      cell.cellStyle = style;
    }
  }
}
