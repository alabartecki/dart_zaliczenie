class TaskRepository {
  static List<Task> tasks = [
  Task(
    title: "Przedszkolne zabawy",
    deadline: "za 2 dni",
    done: true,
    priority: "średni",
  ),
  Task(title: "Gra w berka", deadline: "jutro", done: false, priority: "niski"),
  Task(
    title: "Gra w klasy",
    deadline: "pojutrze",
    done: false,
    priority: "średni",
  ),
  Task(
    title: "Zabawa na skakankach",
    deadline: "za tydzien",
    done: false,
    priority: "wysoki",
  ),
];

}
class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  const Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}



