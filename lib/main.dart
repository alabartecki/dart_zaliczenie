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
  @override
  Widget build(BuildContext context) {
    int completedTasks = TaskRepository.tasks.where((t) => t.done).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("KrakFlow")),
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
                itemCount: TaskRepository.tasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(task: TaskRepository.tasks[index]);
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
      ),
    );
  }
}



class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Card(
        child: ListTile(
          leading: Icon(
            task.done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.done ? Colors.green : Colors.grey,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.done ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Termin: ${task.deadline} | priorytet: ${task.priority}",
          ),
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


