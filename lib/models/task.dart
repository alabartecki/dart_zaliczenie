class TaskRepository {

  static List<Task> tasks = [
  Task(
    id: 103,
    title: "Przedszkolne zabawy",
    deadline: "za 2 dni",
    done: true,
    priority: "średni",
  ),
  Task(id: 102, title: "Gra w berka", deadline: "jutro", done: false, priority: "niski"),
  Task(
    id: 100,
    title: "Gra w klasy",
    deadline: "pojutrze",
    done: false,
    priority: "średni",
  ),
  Task(
    id: 101,
    title: "Zabawa na skakankach",
    deadline: "za tydzien",
    done: false,
    priority: "wysoki",
  ),
];

}
class Task {
  final int id;
  final String title;
  final String deadline;
  final String priority;
  final bool done;
  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.done,
  });
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "deadline": deadline,
      "priority": priority,
      "done": done,
    };
  }
  factory Task.fromMap(Map map) {
    return Task(
      id: map["id"],
      title: map["title"],
      deadline: map["deadline"],
      priority: map["priority"],
      done: map["done"],
    );
  }
}


