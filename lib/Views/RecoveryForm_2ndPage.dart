import 'package:flutter/foundation.dart' show Uint8List, kDebugMode;
import 'package:flutter/material.dart' show Align, Alignment, AppBar, Border, BorderRadius, BorderSide, BoxDecoration, BuildContext, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, ElevatedButton, Expanded, InputBorder, InputDecoration, ListView, MaterialPageRoute, Navigator, RoundedRectangleBorder, Row, Scaffold, SizedBox, StatelessWidget, Text, TextAlign, TextEditingController, TextField, TextStyle, Widget, WillPopScope;
import 'package:flutter/services.dart' show TextAlign, Uint8List, rootBundle;
import 'package:order_booking_shop/API/Globals.dart' show userNames;
import 'package:pdf/pdf.dart' show PdfColors;
import 'package:order_booking_shop/Views/HomePage.dart' show HomePage;
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:share/share.dart' show Share;
import 'package:pdf/pdf.dart' as pw;


class RecoveryForm_2ndPage extends StatelessWidget {
  final Map<String, dynamic> formData;
  const RecoveryForm_2ndPage({super.key, required this.formData});

  @override
  Widget build(BuildContext context) {
    String recoveryId = formData['recoveryId'];
    String date = formData['date'];
    String shopName = formData['shopName'];
    String cashRecovery = formData['cashRecovery'];
    String netBalance = formData['netBalance'];
    if (kDebugMode) {
      print('NetBalance: $netBalance');
      print('cashRecovery: $cashRecovery');
    }

    return WillPopScope(
      onWillPop: () async {
        // Return false to prevent the user from navigating back
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(''),
          automaticallyImplyLeading: false, // Remove back arrow
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  buildTextFieldRow('Receipt:', recoveryId),
                  buildTextFieldRow('Date:', date),
                  buildTextFieldRow('Shop Name:', shopName),
                  buildTextFieldRow('Payment Amount:', cashRecovery),
                  buildTextFieldRow('Net Balance:', netBalance),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      width: 80,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {
                          generateAndSharePDF(
                              recoveryId, date, shopName, cashRecovery, netBalance);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            side: const BorderSide(color: Colors.orange),
                          ),
                          elevation: 8.0,
                        ),
                        child: const Text('PDF', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 100,
                      height: 30,
                      margin: const EdgeInsets.only(right: 16, bottom: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            side: const BorderSide(color: Colors.red),
                          ),
                          elevation: 8.0,
                        ),
                        child: const Text('Close', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildTextFieldRow(String labelText, String text) {
    TextEditingController controller = TextEditingController(text: text);

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the top
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              labelText,
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: Colors.green),
              ),
              child: TextField(
                readOnly: true,
                controller: controller,
                maxLines: null, // Allow multiple lines
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // Adjust padding
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> generateAndSharePDF(String recoveryId, String date, String shopName,
      String cashRecovery, String netBalance) async {
    final pdf = pw.Document();
    final image = pw.Image(pw.MemoryImage(Uint8List.fromList((await rootBundle.load('assets/images/p1.png')).buffer.asUint8List())));

    // Define a custom page format with margins
    const pdfPageFormat = pw.PdfPageFormat(
      350.0, // Width
      680.0, // Height
      marginAll: 20.0, // Add 20px margin on all sides
    );

    // Add content to the PDF document
    pdf.addPage(pw.Page(
      pageFormat: pdfPageFormat, // Use the custom format
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Header with logo and title
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 10.0), // Add top margin
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    child: image,
                    height: 120,
                    width: 120,
                  ),
                  pw.SizedBox(width: 10.0), // Space between logo and title
                  pw.Text('Courage ERP', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                ],
              ),
            ),

            // Page Content
            pw.SizedBox(height: 30), // Spacing after header

            // Invoice Heading
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center, // Align date to bottom
              mainAxisAlignment: pw.MainAxisAlignment.center, // Date on right side
              children: [
                pw.Text('Recovery Slip', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold,))
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              margin: const pw.EdgeInsets.only(top: 20.0, left: 60.0, right: 20.0), // Add top and bottom margin
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text('Date: $date', style: pw.TextStyle(fontSize: 15,fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.Container(
              margin: const pw.EdgeInsets.only(left: 60.0, right: 20.0), // Add top and bottom margin
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text('Receipt#: $recoveryId', style: pw.TextStyle(fontSize: 15,fontWeight: pw.FontWeight.bold)),

                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Details with justified spacing
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch, // Stretch content horizontally
              children: [
                pw.Container( // Add margin around the details
                  margin: const pw.EdgeInsets.only(top: 20.0, left: 60.0, right: 20.0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start, // Start alignment for text labels
                    children: [

                      pw.Row(
                        children: [
                          pw.Text('Booker Name:', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 10.0),
                          pw.Text(userNames, style: const pw.TextStyle(fontSize: 15)),
                        ],
                      ),
                      pw.SizedBox(height: 10.0), // Spacing between rows
                      pw.Row(
                        children: [
                          pw.Text('Shop Name:', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 10.0),
                          pw.Expanded(
                            child: pw.Wrap(
                              children: [
                                pw.Text(
                                  shopName,
                                  style: const pw.TextStyle(fontSize: 15),
                                  softWrap: true, // Enable text wrapping
                                  overflow: pw.TextOverflow.clip, // Clip overflowed text
                                  maxLines: 3, // Adjust as needed
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 20.0),
                      pw.Row(
                        children: [
                          pw.Text('Payment Amount:', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 10.0),
                          pw.Text(cashRecovery, style: const pw.TextStyle(fontSize: 15)),
                        ],
                      ),
                      pw.SizedBox(height: 10.0),
                      pw.Row(
                        children: [
                          pw.Text('Net Balance:', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 10.0),
                          pw.Text(netBalance, style: const pw.TextStyle(fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Footer with margin
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 80.0, bottom: 20.0), // Add top and bottom margin
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Developed by MetaXperts', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    ));

    // Get the directory for temporary files
    final directory = await getTemporaryDirectory();

    // Create a temporary file in the directory
    final output = File('${directory.path}/recovery_form_$recoveryId.pdf');
    await output.writeAsBytes(await pdf.save());

    // Share the PDF
    await Share.shareFiles([output.path], text: 'PDF Document');
  }
}