import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'models/bill_model.dart';
import '../../core/constants.dart';

class BillPdfGenerator {
  static Future<Uint8List> generate(BillModel bill) async {
    final pdf = pw.Document();

    final goldColor = PdfColor.fromHex('C9A84C');
    final greenColor = PdfColor.fromHex('1B3A2D');
    final lightGoldBg = PdfColor.fromHex('FBF5E6');
    final lightGrey = PdfColor.fromHex('F0EBE0');

    final arabicFont = await PdfGoogleFonts.amiriRegular();
    final arabicFontBold = await PdfGoogleFonts.amiriBold();

    final headerImageBytes = (await rootBundle.load('assets/images/billHeader.jpeg')).buffer.asUint8List();
    final headerImage = pw.MemoryImage(headerImageBytes);

    final dateStr = DateFormat('dd/MM/yyyy').format(bill.date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                height: 230,
                width: double.infinity,
                child: pw.Image(headerImage, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(height: 10),
              _buildClientInfo(greenColor, goldColor, bill, dateStr),
              _buildItemsTable(ctx, greenColor, goldColor, lightGoldBg, lightGrey, bill),
              _buildTotal(greenColor, goldColor, bill),
              _buildNote(greenColor, goldColor),
              _buildFooter(greenColor, goldColor),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildClientInfo(PdfColor green, PdfColor gold, BillModel bill, String dateStr) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Text('Boujaad, le : ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                 child: pw.Container(
                   margin: const pw.EdgeInsets.only(top: 8),
                   decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(style: pw.BorderStyle.dotted, width: 1.5))),
                   alignment: pw.Alignment.center,
                   child: pw.Text(dateStr, style: pw.TextStyle(fontSize: 12)),
                 )
              ),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(' : ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('ابي الجعد، في', textDirection: pw.TextDirection.rtl, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Text('M(me) : ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(top: 8),
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(style: pw.BorderStyle.dotted, width: 1.5))),
                  alignment: pw.Alignment.center,
                  child: pw.Text(bill.clientName, textDirection: pw.TextDirection.rtl, style: pw.TextStyle(fontSize: 12)),
                )
              ),
              pw.Text('السيد(ة) : ', textDirection: pw.TextDirection.rtl, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    pw.Context ctx,
    PdfColor green,
    PdfColor gold,
    PdfColor lightGoldBg,
    PdfColor lightGrey,
    BillModel bill,
  ) {
    const headers = [
      'Prix / الثمن',
      'Poids / الميزان',
      'Karat / العيار',
      'Article / المجوهرات',
      'Qté / العدد'
    ];
    const colWidths = [
      pw.FlexColumnWidth(2),
      pw.FlexColumnWidth(2),
      pw.FlexColumnWidth(1.5),
      pw.FlexColumnWidth(3.7),
      pw.FlexColumnWidth(1.3),
    ];

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: pw.Table(
        columnWidths: {
          0: colWidths[0],
          1: colWidths[1],
          2: colWidths[2],
          3: colWidths[3],
          4: colWidths[4],
        },
        border: pw.TableBorder.all(color: gold.shade(0.4), width: 0.5),
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: green),
            children: headers.map((h) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  color: gold,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )).toList(),
          ),
          // Data rows
          ...bill.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isEven = i.isEven;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isEven ? lightGoldBg : PdfColors.white,
              ),
              children: [
                _cell('${item.total.toStringAsFixed(2)}', gold: true),
                _cell('${item.weight} g', gold: false),
                _cell(item.karat, gold: false),
                _cell(item.jewelryType, align: pw.TextAlign.right, gold: false),
                _cell('${item.quantity}', gold: false),
              ],
            );
          }),
          // Fill empty rows up to 12
          ...List.generate(
            12 - bill.items.length > 0 ? 12 - bill.items.length : 0,
            (i) => pw.TableRow(
              decoration: pw.BoxDecoration(
                color: (bill.items.length + i).isEven ? lightGoldBg : PdfColors.white,
              ),
              children: List.generate(5, (_) => _cell('', gold: false)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {pw.TextAlign align = pw.TextAlign.center, bool gold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          fontSize: 11,
          color: gold ? PdfColor.fromHex('9C7C2E') : PdfColors.black,
          fontWeight: gold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildTotal(PdfColor green, PdfColor gold, BillModel bill) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 200,
            height: 100,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: green, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: pw.BoxDecoration(
              color: green,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: gold, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Total (MAD) / المجموع الإجمالي',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  bill.total.toStringAsFixed(2),
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(
                    color: gold,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNote(PdfColor green, PdfColor gold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: gold.shade(0.5), width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          color: PdfColor.fromHex('FBF8EE'),
        ),
        child: pw.Text(
          AppConstants.invoiceNote,
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: green,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(PdfColor green, PdfColor gold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        color: green,
        child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.RichText(
                textAlign: pw.TextAlign.center,
                text: pw.TextSpan(
                  style: pw.TextStyle(fontSize: 9, letterSpacing: 0.5),
                  children: [
                    pw.TextSpan(text: 'ICE : ', style: pw.TextStyle(color: gold)),
                    pw.TextSpan(text: '001143477000057', style: pw.TextStyle(color: PdfColors.white)),
                    pw.TextSpan(text: '   -   IF : ', style: pw.TextStyle(color: gold)),
                    pw.TextSpan(text: '59802119', style: pw.TextStyle(color: PdfColors.white)),
                    pw.TextSpan(text: '   -   N° DU REGISTRE DE COMMERCE : ', style: pw.TextStyle(color: gold)),
                    pw.TextSpan(text: '1042/BOUJAAD', style: pw.TextStyle(color: PdfColors.white)),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.RichText(
                textAlign: pw.TextAlign.center,
                text: pw.TextSpan(
                  style: pw.TextStyle(fontSize: 9, letterSpacing: 0.5),
                  children: [
                    pw.TextSpan(text: 'PATENTE : ', style: pw.TextStyle(color: gold)),
                    pw.TextSpan(text: '41218012', style: pw.TextStyle(color: PdfColors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
