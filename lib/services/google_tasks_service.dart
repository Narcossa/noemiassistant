import 'package:googleapis/tasks/v1.dart' as tasks;

class GoogleTasksService {
  final tasks.TasksApi _tasksApi;
  String? _defaultTaskListId;

  GoogleTasksService(this._tasksApi);

  Future<void> _initDefaultList() async {
    if (_defaultTaskListId != null) return;
    
    final lists = await _tasksApi.tasklists.list();
    if (lists.items != null && lists.items!.isNotEmpty) {
      _defaultTaskListId = lists.items!.first.id;
    } else {
      _defaultTaskListId = '@default';
    }
  }

  Future<List<String>> getPendingTasks() async {
    try {
      await _initDefaultList();
      final response = await _tasksApi.tasks.list(
        _defaultTaskListId!,
        showCompleted: false,
        maxResults: 10,
      );

      if (response.items == null || response.items!.isEmpty) {
        return [];
      }

      return response.items!.map((t) => t.title ?? "Tâche sans nom").toList();
    } catch (e) {
      print("Erreur Tasks (lecture) : \$e");
      return [];
    }
  }

  Future<bool> addTask(String title) async {
    try {
      await _initDefaultList();
      final task = tasks.Task()..title = title;
      await _tasksApi.tasks.insert(task, _defaultTaskListId!);
      return true;
    } catch (e) {
      print("Erreur Tasks (création) : \$e");
      return false;
    }
  }
}
