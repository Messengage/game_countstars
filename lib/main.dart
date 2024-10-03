// ignore_for_file: avoid_print, deprecated_member_use, unused_field

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
  String _responseMessage = 'Awaiting response...';
  String _userId = '';

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
      }, onError: (err) {
        print('Erro ao escutar deep links: $err');
      });
    } catch (e) {
      print('Erro ao inicializar deep links: $e');
    }
  }

  Future<void> _initUserId() async {
    _userId = await _getDeviceIdentifier();
  }

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
    print('Deep link recebido: $uri');
    try {
      final id = uri.queryParameters['id'];
      final lives = uri.queryParameters['lives']; // Captura o número de vidas
      if (id != null) {
        print('ID do jogo: $id');
        if (lives != null) {
          // Processa a quantidade de vidas e atualiza o estado da aplicação
          int livesCount = int.parse(lives);
          print('Quantidade de vidas recebida: $livesCount');
          // Atualiza a quantidade de vidas no app, por exemplo:
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
  }

  Future<void> startFlow() async {
    const String url =
        'https://game.api.messengage.ai/game/entrypoint/GQjXS7Uz/pQjXS7Up/ios?custom_user_id=1234';

    const headers = {
      'api-key': 'j84iC6GWSWFTOH5F4EUxVW5kf4dz6AGA',
    };

    setState(() {
      _isLoading = true;
    });

    final response = await _makeGetRequest(url, headers);

    if (response != null && response.containsKey('deepLink')) {
      final String deepLink = response['deepLink'];

      // Extraia o valor do destinationUrl
      Uri parsedUri = Uri.parse(deepLink);
      String destinationUrl = parsedUri.queryParameters['destinationUrl'] ?? '';

      // Decodifica a URL, pois está codificada em URL encoding
      destinationUrl = Uri.decodeFull(destinationUrl);

      print('Deep link decodificado: $destinationUrl');

      // Agora, tenta abrir o link do WhatsApp
      if (await canLaunch(destinationUrl)) {
        await launch(destinationUrl, forceSafariVC: false);
      } else {
        print('Não foi possível abrir o WhatsApp com o link: $destinationUrl');
      }

      setState(() {
        _responseMessage = deepLink;
      });
    } else {
      setState(() {
        _responseMessage = 'Failed to get deep link';
      });
      print('Falha ao obter o deep link: $response');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _makeGetRequest(
      String url, Map<String, String> headers) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Erro na resposta: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao fazer a requisição GET: $e');
    }
    return null;
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
      // Em seguida, realizar o POST para obter o deep link e abrir o WhatsApp
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Verifica se a resposta contém o deepLink
        if (responseBody != null && responseBody.containsKey('deepLink')) {
          final String deepLink = responseBody['deepLink'];

          print('Deep link decodificado: $deepLink');

          // Agora, tenta abrir o link do WhatsApp
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
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Star Game'),
      ),
      body: Center(
        child: _starCount > 0
            ? ElevatedButton(
                onPressed: _decrementStar,
                child: Text('Play ($_starCount)'),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : startFlow,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Go to WhatsApp (GET)'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : fetchAndOpenWhatsApp,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Go to WhatsApp (POST)'),
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
      appBar: AppBar(title: Text('Playing Game $gameId')),
      body: Center(child: Text('Playing Game $gameId')),
    );
  }
}
