import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // dotenvのためにこの2行を追加
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Weather App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController controller = TextEditingController();
  String areaName = "";
  String weather = "";
  double temperature = 0;
  int humidity = 0;
  double temperatureMax = 0;
  double temperatureMin = 0;
  String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  Future<void> loadWeather(String query) async {

    if (apiKey.isEmpty) {
      print('エラー: APIキーが設定されていません');
      return;
    }

    final url = "https://api.openweathermap.org/data/2.5/weather?APPID=$apiKey&lang=ja&units=metric&q=$query";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('API呼び出しエラー: ${response.statusCode}');
        return;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final main = (body["main"] ?? {}) as Map<String, dynamic>;

      setState(() {
        areaName = body["name"] ?? "";
        weather = (body["weather"]?[0]?["description"] ?? "") as String;
        humidity = (main["humidity"] ?? 0) as int;
        temperature = (main["temp"] ?? 0).toDouble();
        temperatureMax = (main["temp_max"] ?? 0).toDouble(); // as double;だと、取得したデータがdouble以外の場合エラーになる
        temperatureMin = (main["temp_min"] ?? 0).toDouble(); // toDouble();だと、int型データの場合もエラーなく取得できる（例：25 → 25.0）
      });

      print('天気データ更新完了');
    } catch (e) {
      print('例外エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          keyboardType: TextInputType.text, // テキスト入力に変更
          decoration: InputDecoration(
            hintText: '都市名を入力（例: fukuoka, tokyo）',
            // border: InputBorder.none,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && value.length >= 2) { // 2文字以上で検索
              loadWeather(value);
            }
          },
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("地域"),
            subtitle: Text(areaName.isEmpty ? "都市名を入力してください" : areaName),
          ),
          ListTile(
            title: Text("天気"),
            subtitle: Text(weather.isEmpty ? "-" : weather),
          ),
          ListTile(
            title: Text("現在の気温"),
            subtitle: Text(temperature == 0 ? "-" : "${temperature.toStringAsFixed(1)}°C"),
          ),
          ListTile(
            title: Text("最高気温"),
            subtitle: Text(temperatureMax == 0 ? "-" : "${temperatureMax.toStringAsFixed(1)}°C"),
          ),
          ListTile(
            title: Text("最低気温"),
            subtitle: Text(temperatureMin == 0 ? "-" : "${temperatureMin.toStringAsFixed(1)}°C"),
          ),
          ListTile(
            title: Text("湿度"),
            subtitle: Text(humidity == 0 ? "-" : "$humidity%"),
          ),
        ],
      ),
    );
  }
}