import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MesmerApp extends StatelessWidget {
  const MesmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: 'MESMER',

      theme: AppTheme.lightTheme,

      routerConfig: AppRouter.router,
    );
  }
}