import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';

import '../../helpers/all.dart';

class ChunkUploaderScreen extends StatefulWidget {
  const ChunkUploaderScreen({super.key});

  @override
  State<ChunkUploaderScreen> createState() => _ChunkUploaderScreenState();
}

class _ChunkUploaderScreenState extends State<ChunkUploaderScreen> {
  final String uploadUrl = 'https://hexanetwork.in:3035/upload';

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
          printAction('-----=== 111');
          final f = File(file.path!);
          final receivePort = ReceivePort();
          printAction('-----=== 222');
          await Isolate.spawn(uploadFileInChunks, {
            'sendPort': receivePort.sendPort,
            'filePath': f.path,
            'uploadUrl': uploadUrl,
          });
          printAction('-----=== 333');
          receivePort.listen((msg) {
            printSuccess('---UPLOAD STATUS: $msg');
            Utils().showToast(message: 'File uploaded');
          });
          printAction('-----=== 444');
        }
      } catch (e) {
        printError('--- pickAndUploadFiles catch error = $e  ---');
      }
    }
  }

  static Future<void> uploadFileInChunks(Map<String, dynamic> args) async {
    printAction('-----=== uploadFileInChunks');
    final sendPort = args['sendPort'] as SendPort;
    final filePath = args['filePath'] as String;
    final uploadUrl = args['uploadUrl'] as String;

    final file = File(filePath);
    final fileName = file.uri.pathSegments.last;
    const chunkSize = 1024 * 1024 * 5; // 5MB
    final totalSize = file.lengthSync();
    final dio = Dio();

    var offset = 0;
    var index = 0;
    List<Future> activeUploads = [];
    const int maxConcurrentUploads = 5;

    try {
      while (offset < totalSize) {
        printAction('---offset = $offset < totalSize = $totalSize --- ${offset < totalSize}---');
        printAction('---index = $index---');
        final end = (offset + chunkSize > totalSize) ? totalSize : offset + chunkSize;
        final chunk = file.readAsBytesSync().sublist(offset, end);

        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(chunk, filename: '$fileName.part$index'),
          'originalname': fileName,
          'index': index.toString(),
          'isLast': (end == totalSize).toString(),
        });

        final uploadFuture = dio.post(
          uploadUrl,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
          onSendProgress: (sent, total) {
            printAction("Chunk progress: ${sent / total * 100}%");
          },
        );

        activeUploads.add(uploadFuture);

        printAction('----- activeUploads.length = ${activeUploads.length}');

        // If we hit the maxConcurrentUploads, wait for all to complete
        if (activeUploads.length >= maxConcurrentUploads) {
          await Future.wait(activeUploads);
          activeUploads.clear();
        }

        offset = end;
        index++;
        printAction('---index++ = $index---');
      }

      // Wait for any remaining uploads to complete
      if (activeUploads.isNotEmpty) {
        await Future.wait(activeUploads);
      }

      sendPort.send('$fileName uploaded');
      printAction('--- $fileName uploaded ---');
    } catch (e) {
      printError('--- uploadFileInChunks catch error = $e  ---');
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NextScreen()),
                );
              },
              child: const Text('Next Screen'),
            ),
          ],
        ),
      ),
    );
  }
}

class NextScreen extends StatelessWidget {
  const NextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'First Screen',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
    );
  }
}
