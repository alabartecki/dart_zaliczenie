import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_repository.dart';
import 'dart:math';


final random = Random();
final priorities = ["niski", "średni", "wysoki"];
final priority = priorities[random.nextInt(priorities.length)];

class TaskApiService {

  static const String baseUrl = "https://dummyjson.com";
  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/todos"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];
      return todos.map((todo) {
        return Task(
          title: todo["todo"],
          deadline: "brak", done: todo["completed"],
          priority: priority,
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych");
    }
  }
}