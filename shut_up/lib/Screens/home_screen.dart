import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:shut_up/Screens/auth/login_screen.dart';

class Task {
  String id;
  String title;
  String description;
  DateTime date;
  TimeOfDay time;
  bool isCompleted;
  DateTime createdAt;
  DateTime? completedAt;
  String userId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  static Task fromMap(Map<dynamic, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      time: TimeOfDay(
        hour: map['timeHour'] ?? 0,
        minute: map['timeMinute'] ?? 0,
      ),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      userId: map['userId'] ?? '',
    );
  }

  DateTime get fullDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Color get statusColor {
    final now = DateTime.now();
    final taskDateTime = fullDateTime;
    
    if (isCompleted) {
      return Colors.green;
    } else if (taskDateTime.isBefore(now)) {
      return Colors.red;
    } else if (taskDateTime.difference(now).inMinutes <= 30) {
      return Colors.orange;
    } else if (taskDateTime.difference(now).inMinutes <= 60) {
      return Colors.yellow;
    } else {
      return Colors.blue;
    }
  }

  String get statusText {
    final now = DateTime.now();
    final taskDateTime = fullDateTime;
    
    if (isCompleted) {
      return 'Completed';
    } else if (taskDateTime.isBefore(now)) {
      return 'Overdue';
    } else if (taskDateTime.difference(now).inMinutes <= 30) {
      return 'Due soon';
    } else {
      return 'Upcoming';
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  List<Task> _todayTasks = [];
  
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'today'; // today, all, completed, pending
  DateTime? _selectedFilterDate;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _loadTasks();
    _setupRealtimeListener();
  }

  Future<void> _checkAuthStatus() async {
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    }
  }

  void _setupRealtimeListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _database.child('tasks/$userId').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> tasksMap = 
            event.snapshot.value as Map<dynamic, dynamic>;
        _tasks = _convertTasksMapToList(tasksMap);
        _updateFilteredTasks();
      } else {
        _tasks = [];
        _updateFilteredTasks();
      }
      setState(() => _isLoading = false);
    });
  }

  List<Task> _convertTasksMapToList(Map<dynamic, dynamic> tasksMap) {
    List<Task> tasks = [];
    tasksMap.forEach((key, value) {
      try {
        tasks.add(Task.fromMap(Map<String, dynamic>.from(value)));
      } catch (e) {
        print('Error parsing task: $e');
      }
    });
    return tasks;
  }

  void _loadTasks() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _checkAuthStatus();
      return;
    }
    
    _database.child('tasks/$userId').once().then((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> tasksMap = 
            event.snapshot.value as Map<dynamic, dynamic>;
        _tasks = _convertTasksMapToList(tasksMap);
      }
      _updateFilteredTasks();
      setState(() => _isLoading = false);
    }).catchError((error) {
      print('Error loading tasks: $error');
      setState(() => _isLoading = false);
    });
  }

  void _updateFilteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<Task> filtered = List.from(_tasks);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) =>
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    // Apply type filter
    switch (_filterType) {
      case 'today':
        filtered = filtered.where((task) =>
            task.date.year == today.year &&
            task.date.month == today.month &&
            task.date.day == today.day).toList();
        break;
      case 'completed':
        filtered = filtered.where((task) => task.isCompleted).toList();
        break;
      case 'pending':
        filtered = filtered.where((task) => !task.isCompleted).toList();
        break;
      case 'date':
        if (_selectedFilterDate != null) {
          filtered = filtered.where((task) =>
              task.date.year == _selectedFilterDate!.year &&
              task.date.month == _selectedFilterDate!.month &&
              task.date.day == _selectedFilterDate!.day).toList();
        }
        break;
      // 'all' shows all tasks
    }
    
    // Sort by date and time
    filtered.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return a.fullDateTime.compareTo(b.fullDateTime);
    });
    
    // Get today's tasks for the Today tab
    _todayTasks = _tasks.where((task) =>
        task.date.year == today.year &&
        task.date.month == today.month &&
        task.date.day == today.day).toList();
    
    setState(() {
      _filteredTasks = filtered;
    });
  }

  Future<void> _addTask() async {
    await showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: _createTask,
        existingTasks: _tasks,
      ),
    );
  }

  Future<void> _createTask({
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Check if task with same title exists today
    final existingTask = _tasks.firstWhere(
      (task) =>
          task.title.toLowerCase() == title.toLowerCase() &&
          task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day,
      orElse: () => Task(
        id: '',
        title: '',
        description: '',
        date: DateTime.now(),
        time: TimeOfDay.now(),
        createdAt: DateTime.now(),
        userId: '',
      ),
    );

    if (existingTask.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "$title" already exists for today'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check time gap (3 minutes)
    final newTaskTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final conflictingTask = _tasks.firstWhere(
      (task) {
        final taskTime = task.fullDateTime;
        return taskTime.difference(newTaskTime).inMinutes.abs() < 3;
      },
      orElse: () => Task(
        id: '',
        title: '',
        description: '',
        date: DateTime.now(),
        time: TimeOfDay.now(),
        createdAt: DateTime.now(),
        userId: '',
      ),
    );

    if (conflictingTask.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please leave at least 3 minutes gap between tasks'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final taskId = _database.child('tasks/$userId').push().key!;
    final task = Task(
      id: taskId,
      title: title,
      description: description,
      date: date,
      time: time,
      createdAt: DateTime.now(),
      userId: userId,
    );

    await _database.child('tasks/$userId/$taskId').set(task.toMap());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "$title" added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      date: task.date,
      time: task.time,
      isCompleted: !task.isCompleted,
      createdAt: task.createdAt,
      completedAt: !task.isCompleted ? DateTime.now() : null,
      userId: userId,
    );

    await _database.child('tasks/$userId/${task.id}').update({
      'isCompleted': updatedTask.isCompleted,
      'completedAt': updatedTask.completedAt?.millisecondsSinceEpoch,
    });
  }

  Future<void> _editTask(Task task) async {
    await showDialog(
      context: context,
      builder: (context) => EditTaskDialog(
        task: task,
        onTaskUpdated: _updateTask,
        existingTasks: _tasks,
      ),
    );
  }

  Future<void> _updateTask(Task updatedTask) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Check for conflicts
    final existingTask = _tasks.firstWhere(
      (task) =>
          task.id != updatedTask.id &&
          task.title.toLowerCase() == updatedTask.title.toLowerCase() &&
          task.date.year == updatedTask.date.year &&
          task.date.month == updatedTask.date.month &&
          task.date.day == updatedTask.date.day,
      orElse: () => Task(
        id: '',
        title: '',
        description: '',
        date: DateTime.now(),
        time: TimeOfDay.now(),
        createdAt: DateTime.now(),
        userId: '',
      ),
    );

    if (existingTask.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${updatedTask.title}" already exists for this date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check time gap
    final updatedTaskTime = updatedTask.fullDateTime;
    final conflictingTask = _tasks.firstWhere(
      (task) {
        if (task.id == updatedTask.id) return false;
        final taskTime = task.fullDateTime;
        return taskTime.difference(updatedTaskTime).inMinutes.abs() < 3;
      },
      orElse: () => Task(
        id: '',
        title: '',
        description: '',
        date: DateTime.now(),
        time: TimeOfDay.now(),
        createdAt: DateTime.now(),
        userId: '',
      ),
    );

    if (conflictingTask.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please leave at least 3 minutes gap between tasks'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _database.child('tasks/$userId/${updatedTask.id}').update(updatedTask.toMap());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${updatedTask.title}" updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _database.child('tasks/$userId/${task.id}').remove();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task "${task.title}" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter Tasks',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFilterOption('Today', 'today', Icons.today),
            _buildFilterOption('All Tasks', 'all', Icons.list),
            _buildFilterOption('Completed', 'completed', Icons.check_circle),
            _buildFilterOption('Pending', 'pending', Icons.access_time),
            _buildFilterOption('Select Date', 'date', Icons.calendar_today),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _showDatePickerForFilter();
                Navigator.pop(context);
              },
              child: const Text('Pick Custom Date'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String text, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _filterType == value ? Colors.blue : null),
      title: Text(text),
      trailing: _filterType == value ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() {
          _filterType = value;
          _selectedFilterDate = null;
        });
        _updateFilteredTasks();
        Navigator.pop(context);
      },
    );
  }

  Future<void> _showDatePickerForFilter() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        _filterType = 'date';
        _selectedFilterDate = picked;
      });
      _updateFilteredTasks();
    }
  }

  Widget _buildTaskItem(Task task) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return GestureDetector(
      onTap: () => _toggleTaskCompletion(task),
      onLongPress: () => _editTask(task),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: task.statusColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: task.statusColor,
                width: 4,
              ),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: task.statusColor,
              child: Icon(
                task.isCompleted ? Icons.check : Icons.access_time,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(dateFormat.format(task.date), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${task.time.hour.toString().padLeft(2, '0')}:${task.time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(task.statusText),
                  backgroundColor: task.statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: task.statusColor, fontSize: 10),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editTask(task);
                } else if (value == 'delete') {
                  _deleteTask(task);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayTasksSection() {
    if (_todayTasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tasks for today',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              'Add a task using the + button',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final pendingTasks = _todayTasks.where((task) => !task.isCompleted).toList();
    final completedTasks = _todayTasks.where((task) => task.isCompleted).toList();
    final overdueTasks = pendingTasks.where((task) => task.fullDateTime.isBefore(now)).toList();
    final upcomingTasks = pendingTasks.where((task) => !task.fullDateTime.isBefore(now)).toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (overdueTasks.isNotEmpty) ...[
          _buildTaskSection('Overdue', overdueTasks, Colors.red),
        ],
        if (upcomingTasks.isNotEmpty) ...[
          _buildTaskSection('Upcoming', upcomingTasks, Colors.blue),
        ],
        if (completedTasks.isNotEmpty) ...[
          _buildTaskSection('Completed', completedTasks, Colors.green),
        ],
      ],
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(tasks.length.toString()),
                backgroundColor: color.withOpacity(0.1),
                labelStyle: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
        ...tasks.map(_buildTaskItem).toList(),
      ],
    );
  }

  Widget _buildStatsCard() {
    final now = DateTime.now();
    final todayTasks = _tasks.where((task) =>
        task.date.year == now.year &&
        task.date.month == now.month &&
        task.date.day == now.day).toList();
    
    final completedToday = todayTasks.where((task) => task.isCompleted).length;
    final totalTasks = _tasks.length;
    final totalCompleted = _tasks.where((task) => task.isCompleted).length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Today\'s Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', totalTasks.toString(), Icons.list),
                _buildStatItem('Completed', totalCompleted.toString(), Icons.check_circle),
                _buildStatItem('Today', todayTasks.length.toString(), Icons.today),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: todayTasks.isEmpty ? 0 : completedToday / todayTasks.length,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                todayTasks.isEmpty ? Colors.grey : Colors.green,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${((todayTasks.isEmpty ? 0 : completedToday / todayTasks.length) * 100).toStringAsFixed(0)}% of today\'s tasks completed',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(CupertinoIcons.home),
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(_tasks, _editTask, _deleteTask),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Card
                _buildStatsCard(),
                
                // Filter and Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search tasks...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _updateFilteredTasks();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_filterType.toUpperCase()),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filter info
                if (_selectedFilterDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Filtering by: ${DateFormat('MMM dd, yyyy').format(_selectedFilterDate!)}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              _filterType = 'today';
                              _selectedFilterDate = null;
                            });
                            _updateFilteredTasks();
                          },
                        ),
                      ],
                    ),
                  ),
                
                // Tasks List
                Expanded(
                  child: _filterType == 'today'
                      ? _buildTodayTasksSection()
                      : _filteredTasks.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.task, size: 60, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No tasks found',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  Text(
                                    'Add a task using the + button',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredTasks.length,
                              itemBuilder: (context, index) {
                                return _buildTaskItem(_filteredTasks[index]);
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
}

// Add Task Dialog
class AddTaskDialog extends StatefulWidget {
  final Function({
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay time,
  }) onTaskAdded;
  final List<Task> existingTasks;

  const AddTaskDialog({
    super.key,
    required this.onTaskAdded,
    required this.existingTasks,
  });

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter task title';
                  }
                  // Check if task with same title exists today
                  final existingTask = widget.existingTasks.firstWhere(
                    (task) =>
                        task.title.toLowerCase() == value.toLowerCase() &&
                        task.date.year == _selectedDate.year &&
                        task.date.month == _selectedDate.month &&
                        task.date.day == _selectedDate.day,
                    orElse: () => Task(
                      id: '',
                      title: '',
                      description: '',
                      date: DateTime.now(),
                      time: TimeOfDay.now(),
                      createdAt: DateTime.now(),
                      userId: '',
                    ),
                  );
                  if (existingTask.id.isNotEmpty) {
                    return 'Task with this name already exists for today';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (picked != null && picked != _selectedTime) {
                              setState(() => _selectedTime = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Time',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _selectedTime.format(context),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const Icon(Icons.access_time, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                 ], 
              ),
              const SizedBox(height: 16),
              Text(
                'Note: Please leave at least 3 minutes gap between tasks',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onTaskAdded(
                title: _titleController.text,
                description: _descriptionController.text,
                date: _selectedDate,
                time: _selectedTime,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add Task'),
        ),
      ],
    );
  }
}

// Edit Task Dialog
class EditTaskDialog extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskUpdated;
  final List<Task> existingTasks;

  const EditTaskDialog({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    required this.existingTasks,
  });

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.date;
    _selectedTime = widget.task.time;
    _isCompleted = widget.task.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter task title';
                }
                // Check if task with same title exists on same date (excluding current task)
                final existingTask = widget.existingTasks.firstWhere(
                  (task) =>
                      task.id != widget.task.id &&
                      task.title.toLowerCase() == value.toLowerCase() &&
                      task.date.year == _selectedDate.year &&
                      task.date.month == _selectedDate.month &&
                      task.date.day == _selectedDate.day,
                  orElse: () => Task(
                    id: '',
                    title: '',
                    description: '',
                    date: DateTime.now(),
                    time: TimeOfDay.now(),
                    createdAt: DateTime.now(),
                    userId: '',
                  ),
                );
                if (existingTask.id.isNotEmpty) {
                  return 'Task with this name already exists for this date';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (picked != null) {
                        setState(() => _selectedTime = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedTime.format(context)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Mark as completed'),
              value: _isCompleted,
              onChanged: (value) {
                setState(() => _isCompleted = value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Note: Please leave at least 3 minutes gap between tasks',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              final updatedTask = Task(
                id: widget.task.id,
                title: _titleController.text,
                description: _descriptionController.text,
                date: _selectedDate,
                time: _selectedTime,
                isCompleted: _isCompleted,
                createdAt: widget.task.createdAt,
                completedAt: _isCompleted ? DateTime.now() : null,
                userId: widget.task.userId,
              );
              widget.onTaskUpdated(updatedTask);
              Navigator.pop(context);
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

// Search Delegate
class TaskSearchDelegate extends SearchDelegate {
  final List<Task> tasks;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;

  TaskSearchDelegate(this.tasks, this.onEditTask, this.onDeleteTask);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = tasks.where((task) =>
        task.title.toLowerCase().contains(query.toLowerCase()) ||
        task.description.toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('No tasks found'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        final dateFormat = DateFormat('MMM dd, yyyy');
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: task.statusColor,
              child: Icon(
                task.isCompleted ? Icons.check : Icons.access_time,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${dateFormat.format(task.date)} • ${task.statusText}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEditTask(task);
                } else if (value == 'delete') {
                  onDeleteTask(task);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}