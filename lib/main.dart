import 'package:flutter/material.dart';
import 'task_repository.dart';

void main() {
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



class _MyHomeScreenState extends State<HomeScreen> {

  String selectedFilter = "wszystkie";

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
              "Masz dziś ${TaskRepository.tasks.length} zadania",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w100,
                color: Colors.blue,
              ),
            ),
            Text(
              "Wykonano: $completedTasks",
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
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];

                  return Dismissible(
                    key: ObjectKey(task),
                    direction: DismissDirection.endToStart,

                    onDismissed: (direction) {
                      final String deletedTaskName = task.title;
                      setState(() {
                        TaskRepository.tasks.remove(task);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Usunieto zadanie: $deletedTaskName"),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: "OK",
                            onPressed: () {},
                          ),
                        ),
                      );
                    },
                    child: TaskCard(
                      title: task.title,
                      subtitle: "Termin: ${task.deadline}",
                      priority: task.priority,
                      done: task.done,
                      onTap: () async {
                        final Task? updatedTask = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskScreen(task: task),
                          ),
                        );

                        if (updatedTask != null) {
                          setState(() {
                            int originalIndex = TaskRepository.tasks.indexOf(task);
                            TaskRepository.tasks[originalIndex] = updatedTask;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("zaktualizowano zadanie")),
                          );
                        }
                      },
                      onChanged: (bool? value) {
                        setState(() {
                          int originalIndex = TaskRepository.tasks.indexOf(task);
                          TaskRepository.tasks[originalIndex] = Task(
                            title: task.title,
                            deadline: task.deadline,
                            priority: task.priority,
                            done: value ?? false,
                          );
                        });
                      },
                    ),
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
              setState(() {
                TaskRepository.tasks.add(newTask);
              });
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
              onPressed: () {
                setState(() {
                  TaskRepository.tasks.clear();
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Wszystkie zadania zostały usunięte"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              child: const Text(
                "Usuń wszystko",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
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