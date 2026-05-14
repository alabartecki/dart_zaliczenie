import 'task_api_service.dart';
import 'task_local_database.dart';



class TaskSyncService {
  static Future<void> loadInitialDataIfNeeded() async {
// jeżeli lokalna baza ma już dane to nie pobieramy niczego
    if (!TaskLocalDatabase.isEmpty()) {
      return;
    }
// jeżeli nie ma to pobierz dane z API i zapisz w bazie
    final tasks = await TaskApiService.fetchTasks();
    await TaskLocalDatabase.saveTasks(tasks);
  }
}