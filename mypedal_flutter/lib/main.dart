
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:mypedal_flutter/screens/pedal_screen.dart';
import 'package:mypedal_flutter/services/pedal_network.dart';
import 'package:mypedal_flutter/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Keep the screen on: the pedal must not sleep while it is being sustained.
  WakelockPlus.enable();

  runApp(const MyPedalApp());
}

class MyPedalApp extends StatelessWidget {
  const MyPedalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PedalNetwork>(
      create: (_) => PedalNetwork(),
      child: MaterialApp(
        title: 'My Pedal',
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        home: const PedalScreen(),
      ),
    );
  }
}
