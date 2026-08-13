import 'package:flutter/material.dart';
import 'core/supabase_client.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const SilasLivraisonApp());
}

class SilasLivraisonApp extends StatelessWidget {
  const SilasLivraisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Silas Livraison',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
