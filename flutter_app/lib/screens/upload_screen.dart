import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _uploading = false;
  String? _statusMessage;
  bool _success = false;
  final List<Map<String, dynamic>> _uploadedFiles = [];

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() { _uploading = true; _statusMessage = 'Uploading...'; _success = false; });
    int totalChunks = 0;
    try {
      for (final picked in result.files) {
        final bytes = picked.bytes!;
        final uploadResult = await ApiService.uploadPdfBytes(bytes, picked.name);
        totalChunks += uploadResult.chunksStored;
        setState(() { _uploadedFiles.insert(0, {'name': uploadResult.filename, 'chunks': uploadResult.chunksStored}); });
      }
      setState(() { _success = true; _statusMessage = '${result.files.length} file(s) uploaded — $totalChunks chunks indexed!'; });
    } catch (e) {
      setState(() { _success = false; _statusMessage = 'Error: $e'; });
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.upload_file, size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('Upload Course PDFs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _pickAndUpload,
                      icon: _uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                      label: Text(_uploading ? 'Processing...' : 'Select PDF Files'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_statusMessage!, style: TextStyle(color: _success ? Colors.green : Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_uploadedFiles.isNotEmpty) ...[
            const Text('Indexed Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _uploadedFiles.length,
                itemBuilder: (_, i) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(_uploadedFiles[i]['name']),
                    trailing: Chip(label: Text('${_uploadedFiles[i]['chunks']} chunks')),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}