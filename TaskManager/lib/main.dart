import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TaskManagerApp());
}

// ================= API =================

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static String errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        if (data['message'] != null) {
          return data['message'].toString();
        }

        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first['msg']?.toString() ?? 'Du lieu khong hop le';
        }
      }
    } catch (_) {
      // Phan hoi khong phai JSON.
    }

    return 'Yeu cau that bai (${response.statusCode})';
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(errorMessage(response));
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<void> register(
    String fullName,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(errorMessage(response));
    }
  }

  static Future<List<Map<String, dynamic>>> getTasks(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(errorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['tasks'] as List? ?? [];

    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> getTaskDetail(
    String token,
    String id,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(errorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(data['task'] as Map);
  }
}

// ================= APP =================

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}
class _TaskManagerAppState extends State<TaskManagerApp> {
  String? token;
  Map<String, dynamic> user = {};

  void onLoginSuccess(
    String newToken,
    Map<String, dynamic> newUser,
  ) {
    setState(() {
      token = newToken;
      user = newUser;
    });
  }

  void logout() {
    setState(() {
      token = null;
      user = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF287D5A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: token == null
          ? AuthScreen(onLoginSuccess: onLoginSuccess)
          : TaskListScreen(
              token: token!,
              user: user,
              onLogout: logout,
            ),
    );
  }
}

// ================= LOGIN / REGISTER =================

class AuthScreen extends StatefulWidget {
  final void Function(String, Map<String, dynamic>) onLoginSuccess;

  const AuthScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegister = false;
  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isRegister) {
        await ApiService.register(
          nameController.text,
          emailController.text,
          passwordController.text,
        );

        if (!mounted) return;

        setState(() {
          isRegister = false;
          nameController.clear();
          passwordController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dang ky thanh cong. Hay dang nhap.'),
          ),
        );
      } else {
        final result = await ApiService.login(
          emailController.text,
          passwordController.text,
        );

        final newToken = result['token']?.toString();
        if (newToken == null || newToken.isEmpty) {
          throw Exception('May chu khong tra ve token');
        }

        final newUser = Map<String, dynamic>.from(
          (result['user'] as Map?) ?? {},
        );

        if (!mounted) return;
        widget.onLoginSuccess(newToken, newUser);
      }
} catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Color(0xFF287D5A),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'TASK MANAGER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegister
                            ? 'Tao tai khoan moi'
                            : 'Dang nhap de xem cong viec',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      if (isRegister) ...[
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ho va ten',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().length < 2) {
                              return 'Nhap ho ten it nhat 2 ky tu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!email.contains('@') ||
                              !email.contains('.')) {
                            return 'Vui long nhap email hop le';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Mat khau',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = value ?? '';

                          if (isRegister &&
                              (password.length < 8 ||
                                  password.length > 72)) {
                            return 'Mat khau phai tu 8 den 72 ky tu';
                          }

                          if (password.isEmpty) {
                            return 'Vui long nhap mat khau';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: isLoading ? null : submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isRegister ? 'DANG KY' : 'DANG NHAP'),
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
isRegister = !isRegister;
                                });
                              },
                        child: Text(
                          isRegister
                              ? 'Da co tai khoan? Dang nhap'
                              : 'Chua co tai khoan? Dang ky',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= TASK LIST =================

class TaskListScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const TaskListScreen({
    super.key,
    required this.token,
    required this.user,
    required this.onLogout,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await ApiService.getTasks(widget.token);
      if (!mounted) return;
      setState(() => tasks = result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['fullName']?.toString() ?? 'Nguoi dung';
    final email = widget.user['email']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cong viec cua toi'),
        actions: [
          IconButton(
            tooltip: 'Dang xuat',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text('Xin chao, $name'),
                subtitle: Text(email),
              ),
              const Divider(height: 1),
              Expanded(
                child: buildTaskBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTaskBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: loadTasks,
                child: const Text('Thu lai'),
              ),
            ],
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('Chua co cong viec nao')),
            SizedBox(height: 8),
            Center(child: Text('Keo xuong de tai lai')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadTasks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = tasks[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.task_alt),
              ),
              title: Text(
                task['title']?.toString() ?? 'Cong viec',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['description']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(statusLabel(task['status']?.toString())),
                        ),
                        Chip(
                          label: Text(
                            'Uu tien: ${priorityLabel(task['priority']?.toString())}',
                          ),
                        ),
                      ],
                    ),
                    Text('Han: ${formatDate(task['dueDate'])}'),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final id = task['_id']?.toString() ?? '';
                if (id.isEmpty) return;

                Navigator.of(context).push(
                  MaterialPageRoute(
builder: (_) => TaskDetailScreen(
                      token: widget.token,
                      taskId: id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ================= TASK DETAIL =================

class TaskDetailScreen extends StatefulWidget {
  final String token;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.token,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? task;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await ApiService.getTaskDetail(
        widget.token,
        widget.taskId,
      );

      if (!mounted) return;
      setState(() => task = result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiet cong viec')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: buildBody(),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: loadDetail,
                child: const Text('Thu lai'),
              ),
            ],
          ),
        ),
      );
    }

    if (task == null) {
      return const Center(child: Text('Khong tim thay cong viec'));
    }

    final data = task!;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(
          Icons.task_alt,
          size: 64,
          color: Color(0xFF287D5A),
        ),
        const SizedBox(height: 16),
        Text(
          data['title']?.toString() ?? 'Cong viec',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        detailRow(
          Icons.description_outlined,
          'Mo ta',
          data['description']?.toString().isNotEmpty == true
? data['description'].toString()
              : 'Khong co mo ta',
        ),
        detailRow(
          Icons.flag_outlined,
          'Trang thai',
          statusLabel(data['status']?.toString()),
        ),
        detailRow(
          Icons.priority_high,
          'Muc do uu tien',
          priorityLabel(data['priority']?.toString()),
        ),
        detailRow(
          Icons.calendar_today_outlined,
          'Ngay bat dau',
          formatDate(data['startDate']),
        ),
        detailRow(
          Icons.event_outlined,
          'Han hoan thanh',
          formatDate(data['dueDate']),
        ),
        detailRow(
          Icons.person_outline,
          'Ma nguoi tao',
          data['createdBy']?.toString() ?? '',
        ),
        detailRow(
          Icons.people_outline,
          'So nguoi duoc giao',
          ((data['assigneeIds'] as List?) ?? []).length.toString(),
        ),
      ],
    );
  }

  Widget detailRow(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value),
        ),
      ),
    );
  }
}

// ================= HELPERS =================

String statusLabel(String? status) {
  switch (status) {
    case 'todo':
      return 'Chua thuc hien';
    case 'in_progress':
      return 'Dang thuc hien';
    case 'completed':
      return 'Da hoan thanh';
    default:
      return status ?? 'Chua ro';
  }
}

String priorityLabel(String? priority) {
  switch (priority) {
    case 'low':
      return 'Thap';
    case 'medium':
      return 'Trung binh';
    case 'high':
      return 'Cao';
    default:
      return priority ?? 'Chua ro';
  }
}

String formatDate(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return 'Chua thiet lap';
  }

  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();

  final localDate = date.toLocal();

  return '${localDate.day.toString().padLeft(2, '0')}/'
      '${localDate.month.toString().padLeft(2, '0')}/'
      '${localDate.year}';
}