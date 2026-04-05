import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekService {
  String get apiKey {
    const fromDefine = String.fromEnvironment('DEEPSEEK_API_KEY');
    final fromEnv = dotenv.env['DEEPSEEK_API_KEY'];

    final key = fromDefine.isNotEmpty ? fromDefine : (fromEnv ?? '');

    if (key.isEmpty) {
      throw Exception("API KEY no encontrada");
    }

    return key;
  }

  Future<String> analizarFinanzas({
    required double ingresos,
    required double gastos,
    required double deudas,
    required double balance,
    required int mes,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception("API KEY no encontrada");
    }

    final url = Uri.parse("https://api.deepseek.com/v1/chat/completions");

    double porcentaje = ingresos > 0 ? (gastos / ingresos) * 100 : 0;

    final nombreMes = _getNombreMes(mes);

    final prompt = """
Eres un asesor financiero experto.

Analiza el comportamiento financiero del usuario en el mes actual.

Datos:
Mes: $nombreMes
Ingresos: $ingresos
Gastos: $gastos
Balance: $balance

Responde en máximo 2 líneas:

1. Explica cómo va este mes (déficit, equilibrio o superávit) usando cifras
2. Da una recomendación clara y práctica para mejorar el próximo mes

Sé directo, profesional y útil.

Ejemplo:
"En abril llevas gastos de 200k frente a ingresos de 300k, tienes un superávit de 100k. Vas bien, pero podrías aumentar tu ahorro reduciendo gastos innecesarios."
""";

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
            },
            body: jsonEncode({
              "model": "deepseek-chat",
              "messages": [
                {
                  "role": "system",
                  "content": "Eres un asesor financiero experto."
                },
                {"role": "user", "content": prompt}
              ]
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"] ?? "Sin respuesta";
      } else {
        print("❌ Error IA: ${response.body}");
        return "No se pudo analizar tu información.";
      }
    } catch (e) {
      print("🔥 Error conexión IA: $e");
      return "Error de conexión con la IA.";
    }
  }

  // 🔥 Helper para nombre del mes
  String _getNombreMes(int mes) {
    const meses = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre"
    ];

    if (mes < 1 || mes > 12) return "Mes inválido";
    return meses[mes - 1];
  }
}
