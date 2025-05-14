import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/all.dart';

const String uploadURL = 'https://hexanetwork.in:3035/upload';
const String checkChunkURL = 'https://hexanetwork.in:3035/check-chunk';

class ChunkUploaderScreen extends StatefulWidget {
  const ChunkUploaderScreen({super.key});

  @override
  State<ChunkUploaderScreen> createState() => _ChunkUploaderScreenState();
}

class _ChunkUploaderScreenState extends State<ChunkUploaderScreen> {
  @override
  void initState() {
    super.initState();
    ChunkedUploader().resumePendingUploads((msg) {
      printSuccess('---RESUMED UPLOAD: $msg');
    });
  }

  Future<void> pickAndUploadFiles() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(allowMultiple: true);
    } catch (e) {
      printError('Error : $e');
    }

    printWarning('-----=== result == null = ${result == null}');

    if (result != null) {
      printAction('---Started file upload---');
      Utils().showToast(message: 'Started file uploading');

      try {
        printWarning('-----=== result.files.length = ${result.files.length}');
        for (final file in result.files) {
          if (file.path == null) continue;

          final f = File(file.path!);
          ChunkedUploader().handleNewUpload(f.path, (msg) {
            printSuccess('---UPLOAD STATUS: $msg');
            // Utils().showToast(message: 'File uploaded');
            Utils().showToast(message: msg);
          });
        }
      } catch (e) {
        printError('--- pickAndUploadFiles catch error = $e  ---');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chunked File Uploader')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndUploadFiles,
              child: const Text('Select & Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChunkedUploader {
  final String uploadUrl;
  final String checkChunkUrl;
  final int chunkSize;
  final int maxConcurrentUploads;

  ChunkedUploader({
    this.uploadUrl = uploadURL,
    this.checkChunkUrl = checkChunkURL,
    this.chunkSize = 1024 * 1024 * 2, // 2MB
    this.maxConcurrentUploads = 5,
  });

  Future<void> uploadFileInChunks(String filePath, void Function(String) onDone) async {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.last;
    final totalSize = await file.length();
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();

    final uploadedChunksKey = 'uploaded_chunks_$fileName';
    Set<int> uploadedChunks = (prefs.getStringList(uploadedChunksKey) ?? []).map(int.parse).toSet();

    int offset = 0;
    int index = 0;
    List<Future> activeUploads = [];

    while (offset < totalSize) {
      final end = (offset + chunkSize > totalSize) ? totalSize : offset + chunkSize;

      if (uploadedChunks.contains(index) || await chunkExistsOnServer(fileName, index)) {
        offset = end;
        index++;
        continue;
      }

      final chunk = await file.openRead(offset, end).reduce((a, b) => a + b);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(chunk, filename: '$fileName.part$index'),
        'originalname': fileName,
        'index': index.toString(),
        'isLast': (end == totalSize).toString(),
      });

      final uploadFuture = dio.post(uploadUrl, data: formData).then((_) {
        uploadedChunks.add(index);
        prefs.setStringList(uploadedChunksKey, uploadedChunks.map((e) => e.toString()).toList());
      });

      activeUploads.add(uploadFuture);

      if (activeUploads.length >= maxConcurrentUploads) {
        await Future.wait(activeUploads);
        activeUploads.clear();
      }

      offset = end;
      index++;
    }

    if (activeUploads.isNotEmpty) {
      await Future.wait(activeUploads);
    }

    await prefs.remove(uploadedChunksKey);
    await removePendingUpload(filePath);

    printWarning('--- uploadFileInChunks done');
    onDone('$fileName uploaded');
  }

  Future<bool> chunkExistsOnServer(String fileName, int index) async {
    try {
      final response = await Dio().get(checkChunkUrl, queryParameters: {
        'originalname': fileName,
        'index': index.toString(),
      });
      printWarning('--- chunkExistsOnServer response = ${response.data}');

      return response.data['exists'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Track pending uploads for app restarts
  Future<void> addPendingUpload(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = prefs.getStringList('pending_uploads') ?? [];
    printWarning('--- addPendingUpload uploads = $uploads');

    if (!uploads.contains(filePath)) {
      uploads.add(filePath);
      await prefs.setStringList('pending_uploads', uploads);
    }
  }

  Future<void> removePendingUpload(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = prefs.getStringList('pending_uploads') ?? [];
    printWarning('--- removePendingUpload uploads = $uploads');

    uploads.remove(filePath);
    await prefs.setStringList('pending_uploads', uploads);
  }

  /// Called when user selects new files
  Future<void> handleNewUpload(String filePath, void Function(String) onDone) async {
    await addPendingUpload(filePath);
    await uploadFileInChunks(filePath, onDone);
  }

  /// Called on app startup to resume previous uploads
  Future<void> resumePendingUploads(void Function(String) onDone) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = prefs.getStringList('pending_uploads') ?? [];
    printWarning('--- resumePendingUploads uploads = ${uploads.length}');

    for (final filePath in uploads) {
      if (await File(filePath).exists()) {
        await uploadFileInChunks(filePath, onDone);
      }
    }
  }
}
