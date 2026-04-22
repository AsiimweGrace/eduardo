import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../theme.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runyankole Dictionary'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: 'assets/dictionary.pdf',
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
              });
            },
            onViewCreated: (PDFViewController controller) {
              _pdfController = controller;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page ?? 0;
                if (total != null) _totalPages = total;
              });
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading PDF: $error')),
              );
            },
          ),
          if (_totalPages == 0)
            const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            ),
        ],
      ),
      floatingActionButton: _totalPages > 1
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentPage > 0)
                  FloatingActionButton(
                    heroTag: 'prev',
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      _pdfController?.setPage(_currentPage - 1);
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                const SizedBox(width: 16),
                if (_currentPage < _totalPages - 1)
                  FloatingActionButton(
                    heroTag: 'next',
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      _pdfController?.setPage(_currentPage + 1);
                    },
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
              ],
            )
          : null,
    );
  }
}
