import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TaskManagerApp());
}

// ================= API SERVICE =================

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Map<String, String> _headers(String token, {bool json = false}) {
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  static String getError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          return data['errors'][0]['msg'].toString();
        }
      }
    } catch (_) {}
    return 'Yeu cau that bai: ${response.statusCode}';
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<void> register(String fullName, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );
    if (response.statusCode != 201) throw Exception(getError(response));
  }

  static Future<List<Map<String, dynamic>>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['tasks'] as List? ?? [];
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<Map<String, dynamic>> getTaskDetail(String token, String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    final task = Map<String, dynamic>.from(data['task'] as Map);
    task['_permissions'] = Map<String, dynamic>.from(
      (data['permissions'] as Map?) ?? const {},
    );
    return task;
  }

  static Future<void> createTask(String token, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers(token, json: true),
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) throw Exception(getError(response));
  }

  static Future<void> updateTask(String token, String id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers(token, json: true),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
  }

  static Future<void> deleteTask(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String token, String query) async {
    final uri = Uri.parse('$baseUrl/users/search').replace(
      queryParameters: {'q': query.trim()},
    );
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode != 200) throw Exception(getError(response));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['users'] as List? ?? [];
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<Map<String, dynamic>> getAssignees(String token, String taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId/assignees'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<void> addAssignees(
    String token,
    String taskId,
    List<String> userIds, {
    String? primaryAssigneeId,
  }) async {
    final body = <String, dynamic>{'userIds': userIds};
    if (primaryAssigneeId != null) body['primaryAssigneeId'] = primaryAssigneeId;
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/assignees'),
      headers: _headers(token, json: true),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
  }

  static Future<void> setPrimaryAssignee(
    String token,
    String taskId,
    String userId,
    bool isPrimary,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/assignees/$userId'),
      headers: _headers(token, json: true),
      body: jsonEncode({'isPrimary': isPrimary}),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
  }

  static Future<void> removeAssignee(String token, String taskId, String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId/assignees/$userId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
  }

  static Future<List<Map<String, dynamic>>> getShares(String token, String taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId/shares'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['shares'] as List? ?? [];
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<void> addShares(
    String token,
    String taskId,
    List<String> userIds,
    String permission,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/shares'),
      headers: _headers(token, json: true),
      body: jsonEncode({'userIds': userIds, 'permission': permission}),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
  }

  static Future<void> updateSharePermission(
    String token,
    String taskId,
    String shareId,
    String permission,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/shares/$shareId'),
      headers: _headers(token, json: true),
      body: jsonEncode({'permission': permission}),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
  }

  static Future<void> removeShare(String token, String taskId, String shareId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId/shares/$shareId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) throw Exception(getError(response));
  }
}

// ================= APPLICATION =================

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
          throw Exception('Khong nhan duoc JWT');
        }

        final newUser = Map<String, dynamic>.from(
          result['user'] as Map,
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
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                            return 'Email khong hop le';
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

                          if (password.isEmpty) {
                            return 'Vui long nhap mat khau';
                          }

                          if (isRegister &&
                              (password.length < 8 ||
                                  password.length > 72)) {
                            return 'Mat khau phai tu 8 den 72 ky tu';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
const SizedBox(height: 24),

                      FilledButton(
                        onPressed: isLoading ? null : submit,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                isRegister ? 'DANG KY' : 'DANG NHAP',
                              ),
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
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String? error;
  String statusFilter = 'all';
  String priorityFilter = 'all';
  String sortBy = 'createdAt';
  String sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  Future<void> openCreateTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(token: widget.token)),
    );
    if (result == true) await loadTasks();
  }

  Future<void> openTaskDetail(String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          token: widget.token,
          taskId: id,
          onChanged: loadTasks,
        ),
      ),
    );
  }

  Future<void> openFilterDialog() async {
    final searchTemp = TextEditingController(text: searchController.text);
    String tempStatus = statusFilter;
    String tempPriority = priorityFilter;
    String tempSortBy = sortBy;
    String tempSortOrder = sortOrder;

    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Tìm kiếm và lọc công việc'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchTemp,
                    decoration: const InputDecoration(
                      labelText: 'Tên công việc',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tempStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Trạng thái'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
                      DropdownMenuItem(value: 'in_progress', child: Text('Đang thực hiện')),
                      DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => tempStatus = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tempPriority,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Mức ưu tiên'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'low', child: Text('Thấp')),
                      DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                      DropdownMenuItem(value: 'high', child: Text('Cao')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => tempPriority = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tempSortBy,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sắp xếp theo'),
                    items: const [
                      DropdownMenuItem(value: 'createdAt', child: Text('Ngày tạo')),
                      DropdownMenuItem(value: 'dueDate', child: Text('Hạn hoàn thành')),
                      DropdownMenuItem(value: 'priority', child: Text('Mức ưu tiên')),
                      DropdownMenuItem(value: 'title', child: Text('Tên công việc')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => tempSortBy = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tempSortOrder,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Thứ tự'),
                    items: const [
                      DropdownMenuItem(value: 'desc', child: Text('Mới trước')),
                      DropdownMenuItem(value: 'asc', child: Text('Cũ trước')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => tempSortOrder = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                searchTemp.clear();
                setDialogState(() {
                  tempStatus = 'all';
                  tempPriority = 'all';
                  tempSortBy = 'createdAt';
                  tempSortOrder = 'desc';
                });
              },
              child: const Text('Xóa lọc'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );

    if (apply == true && mounted) {
      setState(() {
        searchController.text = searchTemp.text;
        statusFilter = tempStatus;
        priorityFilter = tempPriority;
        sortBy = tempSortBy;
        sortOrder = tempSortOrder;
      });
    }
    searchTemp.dispose();
  }

  List<Map<String, dynamic>> get visibleTasks {
    final query = searchController.text.trim().toLowerCase();
    final result = tasks.where((task) {
      final title = task['title']?.toString().toLowerCase() ?? '';
      final matchesQuery = query.isEmpty || title.contains(query);
      final matchesStatus = statusFilter == 'all' || task['status'] == statusFilter;
      final matchesPriority = priorityFilter == 'all' || task['priority'] == priorityFilter;
      return matchesQuery && matchesStatus && matchesPriority;
    }).toList();

    int priorityRank(dynamic value) {
      switch (value?.toString()) {
        case 'high': return 3;
        case 'medium': return 2;
        case 'low': return 1;
        default: return 0;
      }
    }

    result.sort((a, b) {
      int compare;
      switch (sortBy) {
        case 'title':
          compare = (a['title']?.toString() ?? '').compareTo(b['title']?.toString() ?? '');
          break;
        case 'priority':
          compare = priorityRank(a['priority']).compareTo(priorityRank(b['priority']));
          break;
        case 'dueDate':
          compare = (DateTime.tryParse(a['dueDate']?.toString() ?? '') ?? DateTime(9999))
              .compareTo(DateTime.tryParse(b['dueDate']?.toString() ?? '') ?? DateTime(9999));
          break;
        default:
          compare = (DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970))
              .compareTo(DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970));
      }
      return sortOrder == 'asc' ? compare : -compare;
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['fullName']?.toString() ?? 'Người dùng';
    final email = widget.user['email']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc của tôi'),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm và lọc',
            onPressed: openFilterDialog,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateTask,
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('Xin chào, $name'),
                subtitle: Text(email),
              ),
              const Divider(height: 1),
              Expanded(child: buildTaskBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTaskBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: loadTasks, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final shownTasks = visibleTasks;
    if (shownTasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('Chưa có công việc phù hợp')),
            SizedBox(height: 8),
            Center(child: Text('Nhấn Thêm công việc để bắt đầu')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadTasks,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: shownTasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = shownTasks[index];
          final assigneeCount = (task['assigneeIds'] as List?)?.length ?? 0;
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.task_alt)),
              title: Text(
                task['title']?.toString() ?? 'Công việc',
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
                      children: [
                        Chip(label: Text(statusLabel(task['status']?.toString()))),
                        Chip(label: Text('Ưu tiên: ${priorityLabel(task['priority']?.toString())}')),
                        if (assigneeCount > 0)
                          Chip(
                            avatar: const Icon(Icons.people, size: 16),
                            label: Text('$assigneeCount người được giao'),
                          ),
                      ],
                    ),
                    Text('Hạn: ${formatDate(task['dueDate'])}'),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final id = task['_id']?.toString() ?? '';
                if (id.isNotEmpty) openTaskDetail(id);
              },
            ),
          );
        },
      ),
    );
  }
}

// ================= CREATE / EDIT TASK =================

class TaskFormScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? task;

  const TaskFormScreen({
    super.key,
    required this.token,
    this.task,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  late String priority;
  late String status;

  DateTime? startDate;
  DateTime? dueDate;

  bool isSaving = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    titleController = TextEditingController(
      text: task?['title']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: task?['description']?.toString() ?? '',
    );

    priority = task?['priority']?.toString() ?? 'medium';
    status = task?['status']?.toString() ?? 'todo';

    startDate = parseDate(task?['startDate']);
    dueDate = parseDate(task?['dueDate']);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> chooseDate(bool isStart) async {
    final initialDate = isStart ? startDate : dueDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        startDate = selected;
      } else {
dueDate = selected;
      }
    });
  }

  Future<void> saveTask() async {
    if (!formKey.currentState!.validate()) return;

    if (startDate != null &&
        dueDate != null &&
        dueDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Han hoan thanh khong duoc truoc ngay bat dau'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    final body = <String, dynamic>{
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'startDate': startDate?.toUtc().toIso8601String(),
      'dueDate': dueDate?.toUtc().toIso8601String(),
      'priority': priority,
      'status': status,
    };

    try {
      if (isEditing) {
        await ApiService.updateTask(
          widget.token,
          widget.task!['_id'].toString(),
          body,
        );
      } else {
        await ApiService.createTask(widget.token, body);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Cap nhat cong viec thanh cong'
                : 'Tao cong viec thanh cong',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Chinh sua cong viec' : 'Them cong viec',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: titleController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Ten cong viec',
                    prefixIcon: Icon(Icons.task_alt),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui long nhap ten cong viec';
                    }
                    if (value.trim().length > 200) {
                      return 'Ten cong viec toi da 200 ky tu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
decoration: const InputDecoration(
                    labelText: 'Mo ta cong viec',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Ngay bat dau',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    startDate == null
                        ? 'Chua chon ngay bat dau'
                        : formatDate(startDate!.toIso8601String()),
                  ),
                  trailing: IconButton(
                    onPressed: () => chooseDate(true),
                    icon: const Icon(Icons.edit_calendar),
                  ),
                  onTap: () => chooseDate(true),
                ),

                const Divider(),

                const Text(
                  'Han hoan thanh',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(
                    dueDate == null
                        ? 'Chua chon han hoan thanh'
                        : formatDate(dueDate!.toIso8601String()),
                  ),
                  trailing: IconButton(
                    onPressed: () => chooseDate(false),
                    icon: const Icon(Icons.edit_calendar),
                  ),
                  onTap: () => chooseDate(false),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Muc do uu tien',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'low',
                      child: Text('Thap'),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text('Trung binh'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('Cao'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => priority = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Trang thai',
prefixIcon: Icon(Icons.sync),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'todo',
                      child: Text('Chua thuc hien'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('Dang thuc hien'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Da hoan thanh'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => status = value);
                    }
                  },
                ),

                const SizedBox(height: 28),

                FilledButton.icon(
                  onPressed: isSaving ? null : saveTask,
                  icon: const Icon(Icons.save),
                  label: isSaving
                      ? const CircularProgressIndicator()
                      : Text(
                          isEditing ? 'Luu thay doi' : 'Tao cong viec',
                        ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= TASK DETAIL =================

class TaskDetailScreen extends StatefulWidget {
  final String token;
  final String taskId;
  final Future<void> Function() onChanged;

  const TaskDetailScreen({
    super.key,
    required this.token,
    required this.taskId,
    required this.onChanged,
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

  Map<String, dynamic> get permissions =>
      Map<String, dynamic>.from((task?['_permissions'] as Map?) ?? const {});

  bool get canEdit => permissions['canEdit'] == true;
  bool get canManage => permissions['canManage'] == true;
  bool get canUpdateStatus => permissions['canUpdateStatus'] == true;

  Future<void> openAssignments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentManagementScreen(
          token: widget.token,
          taskId: widget.taskId,
        ),
      ),
    );
    await loadDetail();
    await widget.onChanged();
  }

  Future<void> openSharing() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskSharingScreen(
          token: widget.token,
          taskId: widget.taskId,
        ),
      ),
    );
    await loadDetail();
    await widget.onChanged();
  }

  Future<void> changeStatus() async {
    if (task == null || !canUpdateStatus) return;
    final current = task!['status']?.toString() ?? 'todo';
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String value = current;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Cap nhat trang thai'),
            content: DropdownButtonFormField<String>(
              value: value,
              decoration: const InputDecoration(labelText: 'Trang thai'),
              items: const [
                DropdownMenuItem(value: 'todo', child: Text('Chua thuc hien')),
                DropdownMenuItem(value: 'in_progress', child: Text('Dang thuc hien')),
                DropdownMenuItem(value: 'completed', child: Text('Da hoan thanh')),
              ],
              onChanged: (next) {
                if (next != null) setDialogState(() => value = next);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Huy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, value),
                child: const Text('Luu'),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == current) return;
    try {
      await ApiService.updateTask(widget.token, widget.taskId, {'status': selected});
      await loadDetail();
      await widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cap nhat trang thai thanh cong')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> editTask() async {
    if (task == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(
          token: widget.token,
          task: task,
        ),
      ),
    );

    if (result == true) {
      await loadDetail();
      await widget.onChanged();
    }
  }

  Future<void> deleteTask() async {
    final confirmed = await showDialog<bool>(
context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xac nhan xoa'),
          content: const Text(
            'Ban co chac chan muon xoa cong viec nay khong?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Huy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xoa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteTask(widget.token, widget.taskId);

      if (!mounted) return;

      await widget.onChanged();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiet cong viec'),
        actions: [
          if (task != null && canEdit)
            IconButton(
              tooltip: 'Chinh sua',
              onPressed: editTask,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (task != null && canManage)
            IconButton(
              tooltip: 'Xoa cong viec',
              onPressed: deleteTask,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
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

        const SizedBox(height: 16),
        if (canManage) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment_ind_outlined),
              title: const Text('Giao viec'),
              subtitle: const Text('Them nguoi phu trach va chon nguoi phu trach chinh'),
              trailing: const Icon(Icons.chevron_right),
              onTap: openAssignments,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Chia se va phan quyen'),
              subtitle: const Text('Cap quyen viewer hoac editor, thay doi va thu hoi quyen'),
              trailing: const Icon(Icons.chevron_right),
              onTap: openSharing,
            ),
          ),
        ],
        if (canUpdateStatus) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: changeStatus,
            icon: const Icon(Icons.sync),
            label: const Text('Cap nhat trang thai'),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: editTask,
            icon: const Icon(Icons.edit),
            label: const Text('Chinh sua cong viec'),
          ),
        ],
        if (canManage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: deleteTask,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xoa cong viec'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
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

// ================= ASSIGNEE MANAGEMENT =================

class AssignmentManagementScreen extends StatefulWidget {
  final String token;
  final String taskId;

  const AssignmentManagementScreen({
    super.key,
    required this.token,
    required this.taskId,
  });

  @override
  State<AssignmentManagementScreen> createState() => _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState extends State<AssignmentManagementScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> assignees = [];
  List<Map<String, dynamic>> results = [];
  String? primaryAssigneeId;
  bool isLoading = true;
  bool isSearching = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadAssignees();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadAssignees() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ApiService.getAssignees(widget.token, widget.taskId);
      if (!mounted) return;
      setState(() {
        assignees = (data['assignees'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        primaryAssigneeId = data['primaryAssigneeId']?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> search() async {
    final query = searchController.text.trim();
    if (query.length < 2) {
      setState(() => results = []);
      return;
    }
    setState(() => isSearching = true);
    try {
      final data = await ApiService.searchUsers(widget.token, query);
      if (mounted) setState(() => results = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isSearching = false);
    }
  }

  Future<void> addAssignee(Map<String, dynamic> user) async {
    final id = user['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      await ApiService.addAssignees(widget.token, widget.taskId, [id]);
      await loadAssignees();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Da giao viec cho ${user['fullName']}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> togglePrimary(String userId) async {
    final makePrimary = primaryAssigneeId != userId;
    try {
      await ApiService.setPrimaryAssignee(
        widget.token,
        widget.taskId,
        userId,
        makePrimary,
      );
      await loadAssignees();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> remove(String userId) async {
    try {
      await ApiService.removeAssignee(widget.token, widget.taskId, userId);
      await loadAssignees();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedIds = assignees.map((user) => user['_id']?.toString()).toSet();
    return Scaffold(
      appBar: AppBar(title: const Text('Giao viec')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Tim nguoi dung theo ten hoac email',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (_) => search(),
                      decoration: const InputDecoration(
                        hintText: 'Nhap ten hoac email (it nhat 2 ky tu)',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: isSearching ? null : search,
                    child: isSearching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Tim'),
                  ),
                ],
              ),
              if (results.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Ket qua tim kiem', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...results.map((user) {
                  final id = user['_id']?.toString() ?? '';
                  final alreadyAssigned = assignedIds.contains(id);
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(user['fullName']?.toString() ?? 'Nguoi dung'),
                      subtitle: Text(user['email']?.toString() ?? ''),
                      trailing: alreadyAssigned
                          ? const Chip(label: Text('Da giao'))
                          : FilledButton.tonal(
                              onPressed: () => addAssignee(user),
                              child: const Text('Giao viec'),
                            ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              const Text('Danh sach nguoi duoc giao', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red))
              else if (assignees.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Chua giao cong viec cho ai')))
              else
                ...assignees.map((user) {
                  final id = user['_id']?.toString() ?? '';
                  final isPrimary = primaryAssigneeId == id;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPrimary ? const Color(0xFF287D5A) : null,
                        child: const Icon(Icons.person),
                      ),
                      title: Text(user['fullName']?.toString() ?? 'Nguoi dung'),
                      subtitle: Text('${user['email'] ?? ''}${isPrimary ? ' • Nguoi phu trach chinh' : ''}'),
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: isPrimary ? 'Bo chon phu trach chinh' : 'Chon phu trach chinh',
                            onPressed: () => togglePrimary(id),
                            icon: Icon(isPrimary ? Icons.star : Icons.star_border, color: isPrimary ? Colors.amber[800] : null),
                          ),
                          IconButton(
                            tooltip: 'Huy giao viec',
                            onPressed: () => remove(id),
                            icon: const Icon(Icons.person_remove_outlined),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= TASK SHARING MANAGEMENT =================

class TaskSharingScreen extends StatefulWidget {
  final String token;
  final String taskId;

  const TaskSharingScreen({
    super.key,
    required this.token,
    required this.taskId,
  });

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> shares = [];
  List<Map<String, dynamic>> results = [];
  String selectedPermission = 'viewer';
  bool isLoading = true;
  bool isSearching = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadShares();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadShares() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ApiService.getShares(widget.token, widget.taskId);
      if (mounted) setState(() => shares = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> search() async {
    final query = searchController.text.trim();
    if (query.length < 2) {
      setState(() => results = []);
      return;
    }
    setState(() => isSearching = true);
    try {
      final data = await ApiService.searchUsers(widget.token, query);
      if (mounted) setState(() => results = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isSearching = false);
    }
  }

  Future<void> shareWith(Map<String, dynamic> user) async {
    final id = user['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      await ApiService.addShares(widget.token, widget.taskId, [id], selectedPermission);
      await loadShares();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Da chia se voi ${user['fullName']}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> changePermission(String shareId, String permission) async {
    try {
      await ApiService.updateSharePermission(widget.token, widget.taskId, shareId, permission);
      await loadShares();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> revoke(String shareId) async {
    try {
      await ApiService.removeShare(widget.token, widget.taskId, shareId);
      await loadShares();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharedIds = shares.map((share) {
      final user = share['userId'];
      return user is Map ? user['_id']?.toString() : user?.toString();
    }).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Chia se va phan quyen')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Tim nguoi dung theo ten hoac email', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (_) => search(),
                      decoration: const InputDecoration(
                        hintText: 'Nhap ten hoac email (it nhat 2 ky tu)',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: isSearching ? null : search,
                    child: isSearching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Tim'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPermission,
                decoration: const InputDecoration(labelText: 'Quyen mac dinh khi chia se'),
                items: const [
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer - Chi xem')),
                  DropdownMenuItem(value: 'editor', child: Text('Editor - Duoc chinh sua')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => selectedPermission = value);
                },
              ),
              if (results.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Ket qua tim kiem', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...results.map((user) {
                  final id = user['_id']?.toString() ?? '';
                  final alreadyShared = sharedIds.contains(id);
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(user['fullName']?.toString() ?? 'Nguoi dung'),
                      subtitle: Text(user['email']?.toString() ?? ''),
                      trailing: alreadyShared
                          ? const Chip(label: Text('Da chia se'))
                          : FilledButton.tonal(
                              onPressed: () => shareWith(user),
                              child: const Text('Chia se'),
                            ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              const Text('Nguoi dang duoc chia se', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red))
              else if (shares.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Chua chia se cong viec nay')))
              else
                ...shares.map((share) {
                  final user = share['userId'];
                  final userMap = user is Map ? Map<String, dynamic>.from(user) : <String, dynamic>{};
                  final shareId = share['_id']?.toString() ?? '';
                  final permission = share['permission']?.toString() ?? 'viewer';
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(userMap['fullName']?.toString() ?? 'Nguoi dung'),
                      subtitle: Text(userMap['email']?.toString() ?? ''),
                      trailing: Wrap(
                        spacing: 0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 142,
                            child: DropdownButton<String>(
                              value: permission,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                                DropdownMenuItem(value: 'editor', child: Text('Editor')),
                              ],
                              onChanged: (value) {
                                if (value != null && value != permission) {
                                  changePermission(shareId, value);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Thu hoi quyen',
                            onPressed: () => revoke(shareId),
                            icon: const Icon(Icons.link_off),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= HELPER FUNCTIONS =================

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
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