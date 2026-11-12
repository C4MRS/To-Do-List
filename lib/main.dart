import 'package:flutter/material.dart';

// 1. TASK MODEL
class Task {
  final String title;
  final bool important;
  bool done;

  Task({required this.title, this.important = false, this.done = false});
}

// 2. APPLICATION ENTRY POINT
void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const ListPage(),
    );
  }
}

// 3. MAIN TASK LIST PAGE
class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final List<Task> _tasks = [];

  // R1: Add a new task
  Future<void> _addTask() async {
    final newTask = await Navigator.of(
      context,
    ).push<Task>(MaterialPageRoute(builder: (context) => const NewTaskPage()));

    // Do nothing if the user cancels task creation.
    if (!mounted || newTask == null) return;

    setState(() {
      _tasks.add(newTask);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Task successfully added!')));
  }

  // R3: Update task completion status
  void _changeState(Task task, bool done) {
    setState(() {
      task.done = done;
    });
  }

  // R4: Delete a task after confirmation
  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text('Do you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // Keep the task if the user cancels deletion.
    if (!mounted || confirmed != true) return;

    setState(() {
      _tasks.remove(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Count completed tasks.
    final nDone = _tasks.where((task) => task.done).length;

    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),

      body: Column(
        children: [
          // R2: Completed tasks counter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$nDone of ${_tasks.length} tasks completed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          // R2: Display tasks or an empty list message
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text("You don't have any tasks yet."),
                        SizedBox(height: 4),
                        Text('Tap Add to create a task.'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 88,
                    ),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];

                      return Card(
                        child: ListTile(
                          // Toggle completion using the checkbox.
                          leading: Checkbox(
                            value: task.done,
                            onChanged: (value) {
                              if (value != null) {
                                _changeState(task, value);
                              }
                            },
                          ),

                          // Strike through completed tasks.
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),

                          // Display completion and importance.
                          subtitle: Text(
                            '${task.done ? "Done" : "To do"}'
                            ' • '
                            '${task.important ? "Important" : "Not important"}',
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Show a star for important tasks.
                              if (task.important)
                                const Icon(Icons.star, color: Colors.amber),

                              // Delete task button.
                              IconButton(
                                tooltip: 'Delete task',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  _deleteTask(task);
                                },
                              ),
                            ],
                          ),

                          // Toggle completion by tapping the row.
                          onTap: () {
                            _changeState(task, !task.done);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// 4. NEW TASK PAGE
class NewTaskPage extends StatefulWidget {
  const NewTaskPage({super.key});

  @override
  State<NewTaskPage> createState() => _NewTaskPageState();
}

class _NewTaskPageState extends State<NewTaskPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();

  bool _important = false;

  // S1: Validate the form and create a new task.
  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newTask = Task(
      title: _titleController.text.trim(),
      important: _important,
    );

    // Return the new task to the main page.
    Navigator.of(context).pop(newTask);
  }

  @override
  void dispose() {
    // Release the text controller when leaving the page.
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Task')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task title input field.
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'E.g. Study Flutter',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Reject empty titles or whitespace only.
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Task importance switch.
              SwitchListTile(
                title: const Text('Important'),
                subtitle: const Text('Mark this task as important'),
                value: _important,
                onChanged: (value) {
                  setState(() {
                    _important = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Save task button.
              FilledButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.check),
                label: const Text('Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
