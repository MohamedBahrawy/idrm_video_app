// lib/pdf_viewer_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'custom_appbar.dart';

class PdfViewerPage extends StatelessWidget {
  final File pdfFile;

  const PdfViewerPage({super.key, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(), // أو AppBar(title: Text("عرض الملف")),
      body: SfPdfViewer.file(pdfFile),
    );
  }
}

