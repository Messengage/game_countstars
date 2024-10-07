// ignore_for_file: avoid_print, prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:star_plus_game/cloud_clipper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const StarGameApp());
}

class StarGameApp extends StatelessWidget {
  const StarGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Star Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StarGamePage(),
    );
  }
}

class StarGamePage extends StatefulWidget {
  const StarGamePage({super.key});

  @override
  State<StarGamePage> createState() => _StarGamePageState();
}

class _StarGamePageState extends State<StarGamePage>
    with TickerProviderStateMixin {
  StreamSubscription<Uri?>? _sub;
  String? gameId;
  int _starCount = 0;
  bool _isLoading = false;
  late Database _database;
  late AnimationController _bounceController; // Controlador para o salto
  late AnimationController _sparkleController; // Controlador para o brilho

  @override
  void initState() {
    super.initState();
    // Controlador para a animação de salto
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    // Controlador para o brilho
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sparkleController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initDatabase(); // Aguarda a inicialização do banco de dados
      await _initStarCount(); // Só inicializa o contador após a inicialização do banco de dados
      _getDeviceIdentifier().then((value) {
        gameId = value;
      });
      _initDeepLink(); // Inicializa deep links depois
    });
    FlutterNativeSplash.remove();
  }

  Future<void> _initDeepLink() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      _sub = uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      }, onError: (err) {});
    } catch (e) {
      print('Erro ao inicializar deep links: $e');
    }
  }

  Future<void> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = "${documentsDirectory.path}/game_data.db";

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE StarCount (id INTEGER PRIMARY KEY, lives INTEGER)");
      },
    );

    // Check if table is empty before inserting default values
    List<Map<String, dynamic>> result =
        await _database.query("StarCount", where: "id = ?", whereArgs: [1]);
    if (result.isEmpty) {
      await _database
          .insert("StarCount", {"id": 1, "lives": 5}); // Insert only if empty
    }
  }

  Future<void> _initStarCount() async {
    List<Map<String, dynamic>> result =
        await _database.query("StarCount", where: "id = ?", whereArgs: [1]);
    if (result.isNotEmpty) {
      setState(() {
        _starCount = result.first["lives"] ?? 0;
      });
    }
  }

  Future<void> _updateStarCount(int newStars) async {
    await _database.update("StarCount", {"lives": newStars},
        where: "id = ?", whereArgs: [1]);
    setState(() {
      _starCount = newStars;
    });
  }

  Future<void> _incrementLives(int lives) async {
    List<Map<String, dynamic>> result =
        await _database.query("StarCount", where: "id = ?", whereArgs: [1]);
    if (result.isNotEmpty) {
      int currentLives = result.first["lives"] ?? 0;
      await _database.update("StarCount", {"lives": currentLives + lives},
          where: "id = ?", whereArgs: [1]);

      // Atualiza a variável local e o estado do widget
      setState(() {
        _starCount = currentLives + lives;
      });
    }
  }

  // ignore: unused_element
  Future<String> _getDeviceIdentifier() async {
    if (Platform.isIOS) {
      return (await _getDeviceInfo()).identifierForVendor!;
    } else {
      return (await _getDeviceInfoAndroid()).id;
    }
  }

  Future<IosDeviceInfo> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    return deviceInfo.iosInfo;
  }

  Future<AndroidDeviceInfo> _getDeviceInfoAndroid() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    return deviceInfo.androidInfo;
  }

  void _handleDeepLink(Uri uri) async {
    print(uri);
    try {
      final livesParam = uri.queryParameters['lives'];

      if (livesParam != null) {
        int lives = int.tryParse(livesParam) ?? 0;
        await _incrementLives(lives);

        print('Quantidade de vidas recebida: $lives');
      }
    } catch (e) {
      print('Erro ao processar deep link: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _bounceController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _decrementStar() async {
    setState(() {
      if (_starCount > 0) {
        _starCount--;
        _updateStarCount(_starCount);
        _sparkleController.forward(from: 0.0);
      }
    });

    if (_starCount == 0) {
      _showNoLivesDialog();
    }
  }

  Future<void> _showNoLivesDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEEF0F2),
          title: const Text('Out of Stars? '),
          content: const Text(
              'No worries! 🌟 Get more lives now and keep the adventure going. You\'re just one step away from shining bright again.'),
          actions: <Widget>[
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      fetchAndOpenWhatsAppPOST();
                    },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Ask for more stars',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF372755),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchAndOpenWhatsAppPOST() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        'https://game-api-ohymxcqbya-uc.a.run.app/game/entrypoint/GQjXS7Uz/pQjXS7Up/ios');
    final headers = {
      'api-key': 'j84iC6GWSWFTOH5F4EUxVW5kf4dz6AGA',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'custom_user_id': 'KELVENGLINDO1',
      'custom_data1': 'jhown Wekler',
      'custom_data2': 'jhown.wekler@jet.com',
      'custom_data3': 'Sao Paulo',
      'country': 'BR',
      'language': 'PT-BR',
      'idfv_or_app_set_id': gameId ?? 'D2A7C-321232-9K73230'
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody != null && responseBody.containsKey('deepLink')) {
          final String deepLink = responseBody['deepLink'];
          print('Deep link decodificado: $deepLink');
          if (await canLaunchUrl(Uri.parse(deepLink))) {
            await launchUrl(Uri.parse(deepLink));
          } else {
            print('Não foi possível abrir o WhatsApp com o link: $deepLink');
          }
        }
      }
    } catch (e) {
      print('Erro: $e');
    }

    setState(() {
      _isLoading = false;
    });

    // Atualiza a contagem de vidas com os valores mais recentes do banco de dados
  }

  Future<void> fetchAndOpenWhatsAppGET() async {
    final url = Uri.parse(
        'https://game.api.messengage.ai/game/entrypoint/GQjXS7Uz/pQjXS7Up/ios?custom_user_id=${gameId ?? "12345"}');
    final headers = {
      'api-key': 'j84iC6GWSWFTOH5F4EUxVW5kf4dz6AGA',
    };

    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody != null && responseBody.containsKey('deepLink')) {
          final String deepLink = responseBody['deepLink'];
          print('Deep link decodificado: $deepLink');
          if (await canLaunchUrl(Uri.parse(deepLink))) {
            await launchUrl(Uri.parse(deepLink));
          } else {
            print('Não foi possível abrir o WhatsApp com o link: $deepLink');
          }
        }
      }
    } catch (e) {
      print('Erro: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF81D4FA), // Azul céu claro
      // AppBar com formato de nuvem
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(150.0), // Definir a altura da AppBar
        child: ClipPath(
          clipper: CloudClipper(),
          child: Container(
            color: const Color(0xFFEEF0F2), // Cor de fundo da nuvem
            child: Center(
              child: Text(
                'Star Game',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color:
                      const Color(0xFFFFD700), // Amarelo escuro para o título
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: fetchAndOpenWhatsAppGET, // Chama a função ao clicar
        child: Container(
          height: 50,
          width: double.infinity,
          color: Colors.transparent, // Transparente acinzentado
          child: Center(
            child: Text(
              '',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container para exibir a animação de estrela feliz/triste
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animação combinada de salto e brilho
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Brilho ao redor da estrela feliz
                    if (_starCount > 0)
                      ...List.generate(10, (index) {
                        final angle = (index / 10) *
                            2 *
                            pi; // Ângulo para distribuir as partículas
                        const radius = 70.0;
                        return Positioned(
                          left: radius * cos(angle) + 60, // Posição horizontal
                          top: radius * sin(angle) + 60, // Posição vertical
                          child: Opacity(
                            opacity: 1.0 -
                                _sparkleController
                                    .value, // Reduzir opacidade ao longo do tempo
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.yellow.withOpacity(0.8),
                              ),
                            ),
                          ),
                        );
                      }),
                    // Animação de salto
                    Transform.translate(
                      offset: Offset(
                          0, -10 * sin(_bounceController.value * 2 * pi)),
                      child: _starCount > 0
                          ? Image.asset(
                              'assets/happy_star.png',
                              width: 150,
                              height: 150,
                            )
                          : Image.asset(
                              'assets/sad_star.png',
                              width: 150,
                              height: 150,
                            ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Text(
                  '$_starCount',
                  style: const TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _decrementStar,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 15),
                minimumSize: const Size(100, 40),
              ),
              child: const Text(
                'PLAY',
                style: TextStyle(
                  color: Color(0xFF372755),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Definir um CustomClipper para recortar a forma de nuvem

