import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  // 🔥 URL de tu API en Vercel
  final String baseUrl = "https://bfinanzas-kw8e.vercel.app/api/deepseek";

  /// ==============================
  /// 💬 Chat simple
  /// ==============================
  Future<String> sendMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "message": message,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? "Sin respuesta";
      } else {
        print("❌ Error IA: ${response.body}");
        return "No se pudo obtener respuesta.";
      }
    } catch (e) {
      print("🔥 Error conexión IA: $e");
      return "Error de conexión con la IA.";
    }
  }

  /// ==============================
  /// 📊 Análisis financiero
  /// ==============================
  Future<String> analizarFinanzas({
    required double ingresos,
    required double gastos,
    required double deudas,
    required double balance,
    required int mes,
  }) async {
    double porcentaje = ingresos > 0 ? (gastos / ingresos) * 100 : 0;
    final nombreMes = _getNombreMes(mes);

    final prompt = """
Eres un asesor financiero experto.

Analiza el comportamiento financiero del usuario en el mes actual.

Datos:
Mes: $nombreMes
Ingresos: $ingresos
Gastos: $gastos
Deudas: $deudas
Balance: $balance
Porcentaje de gasto: ${porcentaje.toStringAsFixed(1)}%

Responde en máximo 2 líneas:

1. Explica cómo va este mes (déficit, equilibrio o superávit) usando cifras
2. Da una recomendación clara y práctica para mejorar el próximo mes

Sé directo, profesional y útil.
Importante no pongas asteriscos ni emojis, solo texto claro y directo.
""";

    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "message": prompt,
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

  /// ==============================
  /// 📅 Helper mes
  /// ==============================
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
