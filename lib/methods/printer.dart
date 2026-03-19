import 'dart:typed_data';
import 'package:market_invoices_app/methods/database.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrintPage extends StatefulWidget {
  const PrintPage(
      {required this.commereceType,
      required this.data,
      required this.tableName,
      this.useProductId = false,
      this.commerceId,
      this.timestamp,
      super.key});
  final List<Item> data;
  final String commereceType;
  final String tableName;
  final bool useProductId;
  final int? commerceId;
  final int? timestamp;

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  double cellFontSize = 8.0;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cellFontSize = prefs.getDouble('pdf_cell_font_size') ?? 8.0;
    });
  }

  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pdf_cell_font_size', size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Listas da Fruteira"),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.text_decrease,
                color: Color(0xFF000000),
              ),
              onPressed: () {
                if (cellFontSize > 4) {
                  final newSize = cellFontSize - 0.5;
                  setState(() {
                    cellFontSize = newSize;
                  });
                  _saveFontSize(newSize);
                }
              },
              tooltip: 'Diminuir fonte',
            ),
            Center(
              child: Text(
                cellFontSize.toStringAsFixed(1),
                style: const TextStyle(color: Color(0xFF000000)),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.text_increase,
                color: Color(0xFF000000),
              ),
              onPressed: () {
                if (cellFontSize < 16) {
                  final newSize = cellFontSize + 0.5;
                  setState(() {
                    cellFontSize = newSize;
                  });
                  _saveFontSize(newSize);
                }
              },
              tooltip: 'Aumentar fonte',
            ),
          ],
        ),
        body: PdfPreview(build: (format) => _generatePdf(format, "Lista")));
  }

  double sumTable(List<Item> items) {
    double total = 0;
    for (Item produto in items) {
      total += produto.price * produto.quantity;
    }
    return total;
  }

  List<List<String>> getData() {
    final int length = widget.data.length;
    final int collumns = length ~/ 58 + 1;
    final List<List<String>> result;
    final NumberFormat f = NumberFormat.currency(symbol: "R\$");
    if (widget.commereceType == "vendas") {
      result = [];
      for (final Item item in widget.data) {
        if (widget.useProductId) {
          result.add([
            item.productId?.toString() ?? '-',
            item.name,
            f.format(item.price),
            "${item.quantity} ${item.type}",
            f.format(item.price * item.quantity)
          ]);
        } else {
          result.add([
            item.name,
            f.format(item.price),
            "${item.quantity} ${item.type}",
            f.format(item.price * item.quantity)
          ]);
        }
      }
      if (widget.useProductId) {
        result.add(["", "Total", "", "", f.format(sumTable(widget.data))]);
      } else {
        result.add(["Total", "", "", f.format(sumTable(widget.data))]);
      }
      return result;
    }
    if (collumns == 1) {
      result = [];
      for (final Item item in widget.data) {
        result.add([item.name, "${f.format(item.price)} / ${item.quantity}"]);
      }
      return result;
    }
    result = List.generate(58, (_) => []);
    int idx = 0;
    for (int i = 0; i <= length - 1; i++) {
      i % 57 == 0 ? idx = 0 : null;
      result[idx].add(widget.data[i].representation());
      idx++;
    }
    return result;
  }

  List<String> getHeaders() {
    if (widget.commereceType == "vendas") {
      if (widget.useProductId) {
        return ['Código', 'Produto', 'Preço', 'Peso / Qtd', 'Valores'];
      } else {
        return ['Produto', 'Preço', 'Peso / Qtd', 'Valores'];
      }
    }
    if (widget.data.length <= 57) {
      return ['Produto', 'Preço'];
    }
    return [];
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final result = getData();
    final headers = getHeaders();

    // Buscar preços anteriores se useProductId está ativado
    Map<int, double> previousPrices = {};
    if (widget.useProductId &&
        widget.commerceId != null &&
        widget.timestamp != null) {
      for (final item in widget.data) {
        if (item.productId != null && item.productId! > 0) {
          final previousPrice = await db.getPreviousPrice(
              widget.commerceId!, item.productId!, widget.timestamp!);
          if (previousPrice != null) {
            previousPrices[item.productId!] = previousPrice;
          }
        }
      }
    }

    // Criar tabela com coloração condicional
    final table = widget.useProductId && previousPrices.isNotEmpty
        ? _createColoredTable(result, headers, cellFontSize, previousPrices)
        : pw.TableHelper.fromTextArray(
            data: result,
            headers: headers,
            headerStyle: pw.TextStyle(
                fontSize: cellFontSize + 1, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(fontSize: cellFontSize),
            cellAlignment: pw.Alignment.centerLeft,
            headerPadding:
                const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          );
    pdf.addPage(pw.Page(
        margin: const pw.EdgeInsets.all(4),
        build: (context) => pw.Column(children: [
              pw.Text(
                widget.tableName,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Divider(),
              pw.SizedBox(height: 2),
              table
            ])));

    return pdf.save();
  }

  /// Cria tabela com linhas coloridas baseado na variação de preço
  pw.Widget _createColoredTable(List<List<String>> result, List<String> headers,
      double cellFontSize, Map<int, double> previousPrices) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map((header) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2, vertical: 3),
                    child: pw.Text(
                      header,
                      style: pw.TextStyle(
                          fontSize: cellFontSize + 1,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ))
              .toList(),
        ),
        // Data rows
        ...result.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;

          // Determinar cor da linha e símbolo baseado na comparação de preço
          PdfColor? backgroundColor;
          String priceSymbol = '  ';
          if (index < widget.data.length &&
              widget.data[index].productId != null) {
            final productId = widget.data[index].productId!;
            if (productId > 0 && previousPrices.containsKey(productId)) {
              final previousPrice = previousPrices[productId]!;
              final currentPrice = widget.data[index].price;

              if (currentPrice < previousPrice) {
                backgroundColor = PdfColors.green100; // Preço reduziu
                priceSymbol = 'v ';
              } else if (currentPrice > previousPrice) {
                backgroundColor = PdfColors.red100; // Preço aumentou
                priceSymbol = '^ ';
              }
            }
          }

          return pw.TableRow(
            decoration: backgroundColor != null
                ? pw.BoxDecoration(color: backgroundColor)
                : null,
            children: row.asMap().entries.map((cellEntry) {
              final cellIndex = cellEntry.key;
              final cell = cellEntry.value;

              // Adicionar símbolo antes do nome do produto (índice 1 quando useProductId, índice 0 quando não)
              final nameColumnIndex = widget.useProductId ? 1 : 0;
              final displayText =
                  (cellIndex == nameColumnIndex && priceSymbol.isNotEmpty)
                      ? '$priceSymbol$cell'
                      : cell;

              return pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: pw.Text(
                  displayText,
                  style: pw.TextStyle(fontSize: cellFontSize),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
