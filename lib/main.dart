import 'package:file_upload_demo/helpers/all.dart';
import 'package:file_upload_demo/ui/file_upload_screen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Loading();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Subscription Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        builder: EasyLoading.init(),
        home: const ChunkUploaderScreen(),
      ),
    );
  }
}
