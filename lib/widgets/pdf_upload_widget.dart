import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class PdfUploadWidget extends StatefulWidget {
  String label;
  File? selectedPdf;
  final Function(File?) onFileSelected;

  PdfUploadWidget({super.key, required this.onFileSelected,required this.label,required this.selectedPdf});

  @override
  State<PdfUploadWidget> createState() => _PdfUploadWidgetState();
}

class _PdfUploadWidgetState extends State<PdfUploadWidget> {
  File? _selectedPdf;
  static const int maxSizeInBytes = 2 * 1024 * 1024; // 2MB

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();

      if (size > maxSizeInBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File must be less than 2 MB')),
        );
        return;
      }

      setState(() {
        _selectedPdf = file;
      });

      widget.onFileSelected(_selectedPdf);
    }
  }

  void _removePdf() {
    setState(() {
      _selectedPdf = null;
    });
    widget.onFileSelected(null);
  }

  Future<void> _uploadPdf() async {
    if (_selectedPdf == null) return;

    // TODO: Implement your upload logic here

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploading: ${_selectedPdf!.path.split('/').last}')),
    );
  }


  @override
  void initState() {
    _selectedPdf = widget.selectedPdf;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // _selectedPdf != null ? _selectedPdf = widget.selectedPdf : "";
    return SizedBox(
      height: 150,
      width: 500,
      child:Card(
      // margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _selectedPdf != null
                ? ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(_selectedPdf!.path.split('/').last),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _removePdf,
              ),
            )
                : const Text('No PDF selected', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file,color: kSecondaryColor,),
                  label: const Text('Choose PDF',style: TextStyle(color: kSecondaryColor),),
                  onPressed: _pickPdf,
                ),
                // ElevatedButton.icon(
                //   onPressed: _selectedPdf != null ? _uploadPdf : null,
                //   icon: const Icon(Icons.cloud_upload),
                //   label: const Text("Upload"),
                // ),
              ],
            ),
          ],
        ),
      ),
    ),
    );

  }

}
