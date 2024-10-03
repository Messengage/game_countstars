import 'dart:convert';
import 'package:http/http.dart' as http;

class InventoryAPI {
  final String accountId = '12f7256d-690c-4032-a78d-2c7687755964';
  final String gameId = 'AGQ94k7X';
  final String userId = '1234test';
  final String secretKey = '46645132-b558-41e0-9412-13ce9e6878d7';

  Future<void> addBalance(String type, int value) async {
    final url = Uri.parse(
      'https://messengage-inventory-ohymxcqbya-uc.a.run.app/inventory/12f7256d-690c-4032-a78d-2c7687755964/add/AGQ94k7X/1234test',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': secretKey,
    };
    final body = jsonEncode({
      'type': type,
      'value': value,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Saldo adicionado com sucesso');
      } else {
        print('Erro ao adicionar saldo: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

  Future<void> checkBalance(String type) async {
    final url = Uri.parse(
      'https://messengage-inventory-ohymxcqbya-uc.a.run.app/inventory/12f7256d-690c-4032-a78d-2c7687755964/balance/AGQ94k7X/1234test',
    );
    final headers = {
      'Authorization': secretKey,
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        print('Saldo verificado: ${response.body}');
      } else {
        print('Erro ao verificar saldo: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

  Future<void> withdrawBalance(String type, double value) async {
    final url = Uri.parse(
      'https://messengage-inventory-ohymxcqbya-uc.a.run.app/inventory/12f7256d-690c-4032-a78d-2c7687755964/withdraw/AGQ94k7X/1234test',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': secretKey,
    };
    final body = jsonEncode({
      'type': type,
      'value': value,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Saldo retirado com sucesso');
      } else {
        print('Erro ao retirar saldo: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    }
  }
}
