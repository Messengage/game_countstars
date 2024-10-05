import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';

void main() {
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

class _StarGamePageState extends State<StarGamePage> {
  StreamSubscription<Uri?>? _sub;
  String? gameId;
  int _starCount = 5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
    _initUserId();
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

  Future<void> _initUserId() async {}

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

  void _handleDeepLink(Uri uri) {
    try {
      final id = uri.queryParameters['id'];
      final lives = uri.queryParameters['lives'];
      if (id != null) {
        print('ID do jogo: $id');
        if (lives != null) {
          int livesCount = int.parse(lives);
          print('Quantidade de vidas recebida: $livesCount');
          setState(() {
            _starCount = livesCount;
          });
        }
        setState(() {
          gameId = id;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GameScreen(gameId: id)),
        );
      } else {
        print('ID não encontrado nos parâmetros do link');
      }
    } catch (e) {
      print('Erro ao processar deep link: $e');
    }
  }

  void _decrementStar() async {
    setState(() {
      if (_starCount > 0) {
        _starCount--;
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
              onPressed: _isLoading ? null : fetchAndOpenWhatsApp,
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

  Future<void> fetchAndOpenWhatsApp() async {
    final url = Uri.parse(
        'https://game-api-ohymxcqbya-uc.a.run.app/game/entrypoint/fjkdyqS0/dQciY5l2o');

    final headers = {
      'api-key': 'TwjHo7lWBTfpIgzAVV3WItKe0dheKLIT',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'custom_user_id': 'D2A4B-321232-9K73212',
      'custom_data1': '1',
      'custom_data2': '1',
      'custom_data3': '1',
      'country': 'BR',
      'language': 'PT-BR',
      'idfv_or_app_set_id': 'D2A4B-321232-9K73212',
    });

    setState(() {
      _isLoading = true;
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
          if (await canLaunch(deepLink)) {
            await launch(deepLink);
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

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEF0F2),
        title: const Text('Star Game'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: _starCount > 0 ? const Color(0xFFFFD600) : Colors.red,
                  size: 150,
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

class GameScreen extends StatelessWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF372755),
      appBar: AppBar(title: Text('Playing Game $gameId')),
      body: Center(child: Text('Playing Game $gameId')),
    );
  }
}
