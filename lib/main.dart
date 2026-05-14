import 'package:flutter/material.dart';
import 'models/task.dart';
import 'services/task_api_service.dart';
import 'services/task_sync_service.dart';
import 'services/task_local_database.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:math';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("settings");
  await Hive.openBox("tasks");

  runApp(const MyApp());
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MyHomeScreenState();
}

class TaskListScreen extends StatefulWidget {

  final ValueChanged<List<Task>> onTasksLoaded;

  const TaskListScreen({
    super.key,
    required this.onTasksLoaded,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {

  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = TaskApiService.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(


      future: tasksFuture,
      builder: (context, snapshot) {

        // obsługa loadera
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // obsługa błędu
        if (snapshot.hasError) {
          return Center(
            child: Text("Błąd: ${snapshot.error}"),
          );
        }

        final tasks = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onTasksLoaded(tasks);
        });

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
              // widget TaskCard dla każdego elementu
          },
        );
      },
    );
  }
}

class _MyHomeScreenState extends State<HomeScreen> {

  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  String selectedFilter = "wszystkie";

  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = TaskRepository.tasks;

    if (selectedFilter == "wykonane") {
      filteredTasks = TaskRepository.tasks.where((task) => task.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = TaskRepository.tasks.where((task) => !task.done).toList();
    }

    int completedTasks = TaskRepository.tasks.where((t) => t.done).length;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text("KrakFlow", style: TextStyle(color: Colors.black)),
          iconTheme: IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: Icon(
                Icons.delete_sweep,
                // color: TaskRepository.tasks.isEmpty ? Colors.grey : Colors.red,
                color: Colors.red,

              ),
              onPressed: TaskRepository.tasks.isEmpty
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Brak zadań do usunięcia!")),
                );
              }
                  : () => _showDeleteAllDialog(context),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Masz dziś $allTasksCount zadania",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w100,
                color: Colors.blue,
              ),
            ),
            Text(
              "Wykonano: $doneTasksCount",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w100,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 8),
            FilterBar(
              selectedFilter: selectedFilter,
              onFilterChanged: (newFilter) {
                setState(() {
                  selectedFilter = newFilter;
                });
              },
            ),

            SizedBox(height: 18),
            Text(
              "Dzisiejsze zadania:",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Task>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Błąd: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    // Nawet jeśli jest pusta lista, warto wyczyścić liczniki
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      updateCounters([]);
                    });
                    return const Center(child: Text("Brak zadań"));
                  }

                  // Przypisujemy pobrane zadania do listy do filtrowania
                  final List<Task> tasksFromHive = snapshot.data!;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    updateCounters(tasksFromHive);
                  });

                  // Logika filtrowania (możesz ją zostawić tutaj)
                  List<Task> filteredTasks = tasksFromHive;
                  if (selectedFilter == "wykonane") {
                    filteredTasks = tasksFromHive.where((t) => t.done).toList();
                  } else if (selectedFilter == "do zrobienia") {
                    filteredTasks = tasksFromHive.where((t) => !t.done).toList();
                  }

                  return ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {

                  final task = filteredTasks[index];

                  return Dismissible(
                    key: ObjectKey(task),
                    direction: DismissDirection.endToStart,

                    onDismissed: (direction) async {
                      final String deletedTaskName = task.title;

                      await TaskLocalDatabase.deleteTask(task.id);
                      _refreshTasks(); // To odświeży Future i UI

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Usunięto zadanie: $deletedTaskName")),
                      );

                    },
                    child: TaskCard(
                      title: task.title,
                      subtitle: "Termin: ${task.deadline}",
                      priority: task.priority,
                      done: task.done,
                      onTap: () async {

                        final Task? updatedTaskFromScreen = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)),
                        );

                        if (updatedTaskFromScreen != null) {
                          final finalTask = Task(
                            id: task.id,
                            title: updatedTaskFromScreen.title,
                            deadline: updatedTaskFromScreen.deadline,
                            priority: updatedTaskFromScreen.priority,
                            done: updatedTaskFromScreen.done,
                          );

                          await TaskLocalDatabase.updateTask(finalTask);
                          _refreshTasks();
                        }

                      },

                      onChanged: (bool? value) async {
                        final updatedTask = Task(
                          id: task.id,
                          title: task.title,
                          deadline: task.deadline,
                          priority: task.priority,
                          done: value ?? false,
                        );
                        await TaskLocalDatabase.updateTask(updatedTask);
                        _refreshTasks();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),

        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final Task? newTask = await Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 800), //wolniej sie animuje
                  pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    final offsetAnimation = Tween<Offset>(
                    begin: Offset(1.0, 0.0),
                    end:  Offset.zero,
                    ).animate(CurvedAnimation(  //odbija sie na koncu
                      parent: animation,
                      curve: Curves.easeInOut,
                    ));

                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  }
                ),
            );
            if (newTask != null ){
              await TaskLocalDatabase.addTask(newTask);
              _refreshTasks();
            }
          },
          child: Icon(Icons.add),
        ),
    );
  }


  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Potwierdzenie"),
          content: const Text("Czy na pewno chcesz usunąć WSZYSTKIE zadania?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anuluj"),
            ),
            TextButton(
              onPressed: () async {
                await TaskLocalDatabase.deleteAllTasks();
                _refreshTasks();
                Navigator.pop(context);
              },
              child: const Text("Usuń wszystko", style: TextStyle(color: Colors.red)), // Dodaj ten child!
            ),

          ],
        );
      },
    );
  }

  // tworzymy funkcję aktualizującą
  void updateCounters(List<Task> tasks) {
    setState(() {
      allTasksCount = tasks.length;
      doneTasksCount = tasks.where((task) => task.done).length;
      todoTasksCount = tasks.where((task) => !task.done).length;
    });
  }


  void _refreshTasks() {
    setState(() {
      _tasksFuture = loadTasks();
    });
  }

}



class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String priority;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'wysoki': return Colors.red;
      case 'średni': return Colors.orange;
      case 'niski': return Colors.green;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Card(
        color: done ? Colors.grey[100] : Colors.white,
        child: ListTile(
          onTap: onTap,
          leading: Checkbox(
            value: done,
            onChanged: onChanged,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
              color: done ? Colors.grey : Colors.black,
            ),
          ),
          subtitle:
          Row(
            children: [
              Text(
                subtitle,
                style: TextStyle(color: done ? Colors.grey : Colors.black54),
              ),
              const Text(" | "),
              Text(
                priority,
                style: TextStyle(
                  color: done ? Colors.grey : _getPriorityColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}




//drugi ekran
class AddTaskScreen extends StatelessWidget{

  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();


  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Nowe zadanie:"),
        ),
        body:
            Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Tytuł zadania:",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(20),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: deadlineController,
                      decoration: InputDecoration(
                        labelText: "Termin zadania:",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(20),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: priorityController,
                      decoration: InputDecoration(
                        labelText: "Priorytet:",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(20),

                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () {
                          // sprawdzam czy pola nie są puste lub nie zawierają samych spacji
                          if (titleController.text.trim().isEmpty ||
                              deadlineController.text.trim().isEmpty ||
                              priorityController.text.trim().isEmpty) {

                            // return - Navigator.pop się nie wykona
                            return;
                          }

                          final newTask = Task(
                              id: Random().nextInt(1000000),
                              title: titleController.text,
                              deadline: deadlineController.text,
                              done: false,
                              priority: priorityController.text,
                          );

                          Navigator.pop(context, newTask);
                        },
                        child: Text("Zapisz"),
                    ),
                  ],
                )
            )
      );

  }
}

//trzeci ekran
class EditTaskScreen extends StatelessWidget {
  final Task task;

  final TextEditingController titleController;
  final TextEditingController deadlineController;
  final TextEditingController priorityController;

  EditTaskScreen({super.key, required this.task})
      : titleController = TextEditingController(text: task.title),
        deadlineController = TextEditingController(text: task.deadline),
        priorityController = TextEditingController(text: task.priority);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Tytuł zadania", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(labelText: "Termin", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(labelText: "Priorytet", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;

                final updatedTask = Task(
                  id: task.id,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: task.done,
                  priority: priorityController.text,
                );

                Navigator.pop(context, updatedTask);
              },
              child: const Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}



class FilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _filterButton(context, "wszystkie"),
        _filterButton(context, "do zrobienia"),
        _filterButton(context, "wykonane"),
      ],
    );
  }

  Widget _filterButton(BuildContext context, String label) {
    bool isActive = selectedFilter == label;
    return TextButton(
      onPressed: () => onFilterChanged(label),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.blue : Colors.grey,
      ),
      child: Text(label),
    );
  }
}