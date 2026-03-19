import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String sellPagePrompt = 
"""
Extraia uma lista de objetos em formato JSON a partir do texto abaixo. Cada objeto deve conter:

quantidade: número decimal com ponto (ex: 0.534, 1.5, 20)
nome: nome do item (string)
preço: número decimal com ponto, sem R\$ (ex: 100.0, 7.5)
formato: "kg" se a quantidade for dada em gramas (g/kg) e "un" caso contrário

exemplo:
uma caixa de batata 100
534g batata doce 100 reais
20 abacaxi 5

[
  {"quantidade": 1, "nome": "caixa de batata", "preço": 100, "formato": "un"},
  {"quantidade": 0.534, "nome": "batata doce", "preço": 100, "formato": "kg"},
  {"quantidade": 20, "nome": "abacaxi", "preço": 5, "formato": "un"}
]
NÃO INCLUA COMENTÁRIOS, APENAS O JSON.
""";

enum Prompt {
  sellPagePrompt
}

final Map<Prompt, String> _promptMap = {
  Prompt.sellPagePrompt: sellPagePrompt,
};


Future<String?> sendToGroq(String input, Prompt prompt) async {
  final String apiKey = dotenv.env['GROQ_API_KEY']!;
  final dio = Dio();
  
  try {
    final response = await dio.post(
      'https://api.groq.com/openai/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        "model": "llama-3.1-8b-instant",
        "messages": [
          {
            "role": "system",
            "content":
                _promptMap[prompt]
          },
          {
            "role": "user",
            "content": input
          }
        ]
      },
    );

    final resposta = response.data['choices'][0]['message']['content'];
    return resposta;
  } catch (e) {
    return null;
  }
}