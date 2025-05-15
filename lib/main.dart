import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyTodoApp());
}

class MyTodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo List',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(Colors.green),
        ),
      ),
      home: TodoHomePage(),
    );
  }
}

class TodoItem {
  String title;
  bool isDone;

  TodoItem(this.title, this.isDone);

  Map<String, dynamic> toJson() => {
    'title': title,
    'isDone': isDone,
  };

  static TodoItem fromJson(Map<String, dynamic> json) =>
      TodoItem(json['title'], json['isDone']);
}

class TodoHomePage extends StatefulWidget {
  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  List<TodoItem> todos = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  void loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('todos');
    if (jsonData != null) {
      final list = json.decode(jsonData) as List;
      setState(() {
        todos = list.map((item) => TodoItem.fromJson(item)).toList();
      });
    }
  }

  void saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(todos.map((item) => item.toJson()).toList());
    await prefs.setString('todos', jsonData);
  }

  void addTodo() {
    showDialog(
      context: context,
      builder: (context) {
        String newTask = '';
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Add Task'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => newTask = value,
            decoration: InputDecoration(hintText: 'Enter task'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                if (newTask.trim().isNotEmpty) {
                  setState(() {
                    todos.add(TodoItem(newTask.trim(), false));
                  });
                  saveTodos();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void editTodo(int index) {
    String updatedTask = todos[index].title;
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: updatedTask);
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Edit Task'),
          content: TextField(
            controller: controller,
            onChanged: (value) => updatedTask = value,
            decoration: InputDecoration(hintText: 'Update task'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                if (updatedTask.trim().isNotEmpty) {
                  setState(() {
                    todos[index].title = updatedTask.trim();
                  });
                  saveTodos();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void toggleDone(int index) {
    setState(() {
      todos[index].isDone = !todos[index].isDone;
    });
    saveTodos();
  }

  void deleteTodo(int index) {
    setState(() {
      todos.removeAt(index);
    });
    saveTodos();
  }

  void resetCompletionStatus() {
    setState(() {
      for (var item in todos) {
        item.isDone = false;
      }
    });
    saveTodos();
  }

  void sortAlphabetically() {
    setState(() {
      todos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    });
    saveTodos();
  }

  void sortByCompletion() {
    setState(() {
      todos.sort((a, b) => a.isDone.toString().compareTo(b.isDone.toString()));
    });
    saveTodos();
  }

  List<TodoItem> get filteredTodos {
    if (searchQuery.isEmpty) return todos;
    return todos.where((item) => item.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo Checklist'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort_by_alpha),
            tooltip: "Sort A-Z",
            onPressed: sortAlphabetically,
          ),
          IconButton(
            icon: Icon(Icons.filter_alt),
            tooltip: "Sort by status",
            onPressed: sortByCompletion,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Reset completed",
            onPressed: resetCompletionStatus,
          ),
          SizedBox(width: 5),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) {
          final item = filteredTodos[index];
          final actualIndex = todos.indexOf(item);

          return Dismissible(
            key: UniqueKey(),
            onDismissed: (direction) => deleteTodo(actualIndex),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              leading: Checkbox(
                value: item.isDone,
                onChanged: (val) => toggleDone(actualIndex),
              ),
              title: GestureDetector(
                onTap: () => editTodo(actualIndex),
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                    color: item.isDone ? Colors.grey : Colors.white,
                  ),
                ),
              ),
              trailing: Icon(Icons.more_vert, color: Colors.grey),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTodo,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.home, color: Colors.white), onPressed: () {}),
            IconButton(icon: Icon(Icons.folder_open, color: Colors.white), onPressed: () {}),
            SizedBox(width: 40), // Space for FAB
            IconButton(icon: Icon(Icons.check_circle, color: Colors.white), onPressed: () {}),
            IconButton(icon: Icon(Icons.settings, color: Colors.white), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}