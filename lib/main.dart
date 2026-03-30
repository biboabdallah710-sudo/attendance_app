import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

// --- إدارة الحالة العالمية ---
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
ValueNotifier<Locale> languageNotifier = ValueNotifier(const Locale('en'));

String tr(String en, String ar) =>
    languageNotifier.value.languageCode == 'ar' ? ar : en;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://iblehykhqdwmisxknqda.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlibGVoeWtocWR3bWlzeGtucWRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2MjExODUsImV4cCI6MjA4OTE5NzE4NX0.P8N43s5QLEX5-an84ZveY8tps_7EinQknJz5334smQY',
  );
  runApp(const AttendanceProApp());
}

class AttendanceProApp extends StatelessWidget {
  const AttendanceProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => ValueListenableBuilder<Locale>(
        valueListenable: languageNotifier,
        builder: (___, locale, ____) => MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
          darkTheme: ThemeData.dark(useMaterial3: true),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}

// --- شاشة الدخول ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.school, size: 80, color: Colors.indigo),
          const SizedBox(height: 20),
          TextField(
              controller: _email,
              decoration: InputDecoration(
                  labelText: tr("Email", "البريد الإلكتروني"),
                  border: const OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(
              controller: _pass,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: tr("Password", "كلمة المرور"),
                  border: const OutlineInputBorder())),
          const SizedBox(height: 30),
          SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await Supabase.instance.client.auth.signInWithPassword(
                        email: _email.text.trim(), password: _pass.text.trim());
                    if (!mounted) return;
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MainNavigation()));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: Text(tr("Login", "تسجيل الدخول")),
              )),
          TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen())),
              child: Text(tr("Create Account", "إنشاء حساب جديد"))),
        ]),
      ),
    );
  }
}

// --- شاشة التسجيل ---
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _role = 'student';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Sign Up", "إنشاء حساب"))),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            TextField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: tr("Full Name", "الاسم بالكامل"),
                    border: const OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
                controller: _email,
                decoration: InputDecoration(
                    labelText: tr("Email", "البريد الإلكتروني"),
                    border: const OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
                controller: _pass,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: tr("Password", "كلمة المرور"),
                    border: const OutlineInputBorder())),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(
                  labelText: tr("Role", "الدور"),
                  border: const OutlineInputBorder()),
              items: [
                DropdownMenuItem(
                    value: 'student', child: Text(tr("Student", "طالب"))),
                DropdownMenuItem(
                    value: 'instructor',
                    child: Text(tr("Instructor", "محاضر"))),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 30),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final auth = await Supabase.instance.client.auth.signUp(
                          email: _email.text.trim(),
                          password: _pass.text.trim(),
                          data: {'full_name': _name.text, 'role': _role});
                      if (auth.user != null) {
                        await Supabase.instance.client.from('profiles').insert({
                          'id': auth.user!.id,
                          'full_name': _name.text,
                          'role': _role
                        });
                      }
                      if (!mounted) return;
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainNavigation()));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: Text(tr("Register & Start", "تسجيل وابدأ")),
                )),
          ])),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  final _screens = [
    const HomeScreen(),
    const AttendanceScanScreen(),
    const HistoryScreen(),
    const AlertsScreen(),
    const SettingsScreen()
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        body: _screens[_idx],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _idx,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _idx = i),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home), label: tr("Home", "الرئيسية")),
            BottomNavigationBarItem(
                icon: const Icon(Icons.fingerprint),
                label: tr("Scan", "البصمة")),
            BottomNavigationBarItem(
                icon: const Icon(Icons.analytics), label: tr("Rate", "النسبة")),
            BottomNavigationBarItem(
                icon: const Icon(Icons.notifications),
                label: tr("Alerts", "التنبيهات")),
            BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: tr("Settings", "الإعدادات")),
          ],
        ),
      );
}

// --- شاشة الـ HomeScreen ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get isInstructor =>
      Supabase.instance.client.auth.currentUser?.userMetadata?['role'] ==
      'instructor';

  void _addCourse() {
    final nameC = TextEditingController();
    final codeC = TextEditingController();
    final levelC = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(tr("Add New Course", "إضافة كورس جديد")),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: nameC,
                      decoration: InputDecoration(
                          labelText: tr("Course Name", "اسم الكورس"))),
                  TextField(
                      controller: codeC,
                      decoration: InputDecoration(
                          labelText: tr("Course Code", "كود الكورس"))),
                  TextField(
                      controller: levelC,
                      decoration: InputDecoration(
                          labelText:
                              tr("Level/Class", "الفرقة / الفصل الدراسي"))),
                ]),
              ),
              actions: [
                TextButton(
                    onPressed: () async {
                      if (nameC.text.isNotEmpty && codeC.text.isNotEmpty) {
                        await Supabase.instance.client.from('courses').insert({
                          'name': nameC.text,
                          'code': codeC.text.toUpperCase(),
                          'level': levelC.text,
                          'created_by':
                              Supabase.instance.client.auth.currentUser!.id
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(tr("Add", "إضافة")))
              ],
            ));
  }

  void _addLecture(String courseId) async {
    final titleC = TextEditingController();
    PlatformFile? pickedFile;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  title: Text(tr("Add New Lecture", "إضافة محاضرة جديدة")),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: titleC,
                        decoration: InputDecoration(
                            labelText: tr("Lecture Title", "عنوان المحاضرة"))),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'pdf',
                              'jpg',
                              'png',
                              'doc',
                              'docx',
                              'ppt',
                              'pptx'
                            ],
                            withData: true);
                        if (result != null) {
                          setDialogState(() => pickedFile = result.files.first);
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(pickedFile == null
                          ? tr("Pick Material", "اختر الملف")
                          : pickedFile!.name),
                    ),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () async {
                          if (titleC.text.isNotEmpty && pickedFile != null) {
                            try {
                              final fileName =
                                  "${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}";
                              if (kIsWeb) {
                                await Supabase.instance.client.storage
                                    .from('lecture_materials')
                                    .uploadBinary(fileName, pickedFile!.bytes!);
                              } else {
                                await Supabase.instance.client.storage
                                    .from('lecture_materials')
                                    .upload(fileName, File(pickedFile!.path!));
                              }
                              final fileUrl = Supabase.instance.client.storage
                                  .from('lecture_materials')
                                  .getPublicUrl(fileName);
                              await Supabase.instance.client
                                  .from('lectures')
                                  .insert({
                                'course_id': courseId,
                                'title': titleC.text,
                                'file_url': fileUrl
                              });
                              if (!mounted) return;
                              Navigator.pop(ctx);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())));
                            }
                          }
                        },
                        child: Text(tr("Save", "حفظ")))
                  ],
                )));
  }

  Future<void> _viewFile(String url, String title) async {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.pdf') ||
        lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.png')) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => Scaffold(
                    appBar: AppBar(title: Text(title)),
                    body: lowerUrl.contains('.pdf')
                        ? SfPdfViewer.network(url)
                        : Center(
                            child:
                                InteractiveViewer(child: Image.network(url))),
                  )));
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: Text(tr("Study Courses", "المواد الدراسية"))),
      floatingActionButton: isInstructor
          ? FloatingActionButton(
              onPressed: _addCourse, child: const Icon(Icons.add))
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: isInstructor
            ? Supabase.instance.client
                .from('courses')
                .stream(primaryKey: ['id']).eq('created_by', userId ?? '')
            : Supabase.instance.client
                .from('courses')
                .stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data!;
          return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (ctx, i) => Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: ExpansionTile(
                      title: Text(courses[i]['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "${tr("Code", "الكود")}: ${courses[i]['code']} - ${courses[i]['level'] ?? ''}"),
                      trailing: isInstructor
                          ? IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  _addLecture(courses[i]['id'].toString()))
                          : null,
                      children: [
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: Supabase.instance.client
                              .from('lectures')
                              .stream(primaryKey: ['id']).eq(
                                  'course_id', courses[i]['id']),
                          builder: (ctx, lSnap) {
                            if (!lSnap.hasData || lSnap.data!.isEmpty) {
                              return Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Text(tr("No lectures yet.",
                                      "لا توجد محاضرات بعد.")));
                            }
                            return Column(
                                children: lSnap.data!
                                    .map((l) => ListTile(
                                          leading: Icon(
                                              l['file_url']?.contains('.pdf') ==
                                                      true
                                                  ? Icons.picture_as_pdf
                                                  : Icons.description,
                                              color: Colors.indigo),
                                          title: Text(l['title']),
                                          onTap: () => l['file_url'] != null
                                              ? _viewFile(
                                                  l['file_url'], l['title'])
                                              : null,
                                        ))
                                    .toList());
                          },
                        )
                      ],
                    ),
                  ));
        },
      ),
    );
  }
}

// --- شاشة تعديل الملف الشخصي ---
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameC = TextEditingController();
  final _bioC = TextEditingController();
  final _emailC = TextEditingController();
  String? _gender;
  DateTime? _selectedDate;
  String? _avatarUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailC.text = user.email ?? "";
      _nameC.text = user.userMetadata?['full_name'] ?? "";
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) {
        setState(() {
          _bioC.text = data['bio'] ?? "";
          _gender = data['gender'];
          _avatarUrl = data['avatar_url'];
          if (data['birth_date'] != null) {
            _selectedDate = DateTime.parse(data['birth_date']);
          }
        });
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      setState(() => _loading = true);
      try {
        final file = result.files.first;
        final fileName =
            "${Supabase.instance.client.auth.currentUser!.id}_avatar.jpg";
        if (kIsWeb) {
          await Supabase.instance.client.storage.from('avatars').uploadBinary(
              fileName, file.bytes!,
              fileOptions: const FileOptions(upsert: true));
        } else {
          await Supabase.instance.client.storage.from('avatars').upload(
              fileName, File(file.path!),
              fileOptions: const FileOptions(upsert: true));
        }
        setState(() => _avatarUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(fileName));
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  void _saveProfile() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameC.text,
        'bio': _bioC.text,
        'gender': _gender,
        'birth_date': _selectedDate?.toIso8601String().split('T')[0],
        'avatar_url': _avatarUrl,
      }).eq('id', user!.id);

      if (_emailC.text != user.email) {
        await Supabase.instance.client.auth
            .updateUser(UserAttributes(email: _emailC.text));
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Edit Profile", "تعديل الملف الشخصي"))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                GestureDetector(
                    onTap: _uploadAvatar,
                    child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null
                            ? const Icon(Icons.camera_alt)
                            : null)),
                const SizedBox(height: 20),
                TextField(
                    controller: _nameC,
                    decoration:
                        InputDecoration(labelText: tr("Full Name", "الاسم"))),
                TextField(
                    controller: _emailC,
                    decoration: InputDecoration(
                        labelText: tr("Email", "البريد الإلكتروني"),
                        helperText: tr("Requires verification",
                            "يحتاج لتأكيد من الإيميل الجديد"))),
                TextField(
                    controller: _bioC,
                    decoration:
                        InputDecoration(labelText: tr("Bio", "نبذة عنك"))),
                DropdownButtonFormField<String>(
                    initialValue: _gender,
                    items: [
                      DropdownMenuItem(
                          value: 'Male', child: Text(tr("Male", "ذكر"))),
                      DropdownMenuItem(
                          value: 'Female', child: Text(tr("Female", "أنثى")))
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                    decoration:
                        InputDecoration(labelText: tr("Gender", "النوع"))),
                ListTile(
                  title: Text(_selectedDate == null
                      ? tr("Birth Date", "الميلاد")
                      : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
                  onTap: () async {
                    DateTime? p = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now());
                    if (p != null) setState(() => _selectedDate = p);
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                    onPressed: _saveProfile, child: Text(tr("Save", "حفظ"))),
              ]),
            ),
    );
  }
}

// --- شاشة الأمان ---
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPass = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();
  bool _isVerified = false;
  bool _loading = false;

  void _verifyOldPassword() async {
    setState(() => _loading = true);
    try {
      final email = Supabase.instance.client.auth.currentUser!.email!;
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: _currentPass.text);
      setState(() => _isVerified = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(tr("Incorrect password", "كلمة المرور الحالية خاطئة"))));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updatePassword() async {
    if (_newPass.text != _confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("Mismatch", "كلمات المرور غير متطابقة"))));
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: _newPass.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr("Done", "تم التحديث"))));
      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Security", "الأمان"))),
      body: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  if (!_isVerified) ...[
                    TextField(
                        controller: _currentPass,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText:
                                tr("Current Password", "كلمة المرور الحالية"))),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _verifyOldPassword,
                        child: Text(tr("Verify", "تأكيد"))),
                  ] else ...[
                    TextField(
                        controller: _newPass,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText:
                                tr("New Password", "كلمة المرور الجديدة"))),
                    TextField(
                        controller: _confirmPass,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: tr(
                                "Confirm New Password", "تأكيد كلمة المرور"))),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _updatePassword,
                        child: Text(tr("Update", "تحديث"))),
                  ]
                ])),
    );
  }
}

// --- شاشة الإعدادات ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(tr("Settings", "الإعدادات"))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('profiles')
            .stream(primaryKey: ['id']).eq('id', user?.id ?? ''),
        builder: (context, snapshot) {
          final data = (snapshot.hasData && snapshot.data!.isNotEmpty)
              ? snapshot.data!.first
              : null;
          final name =
              data?['full_name'] ?? user?.userMetadata?['full_name'] ?? "User";
          final avatarUrl = data?['avatar_url'];
          final role = data?['role'] ?? user?.userMetadata?['role'] ?? "";

          return ListView(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(
                    "${user?.email} (${tr(role, role == 'instructor' ? "محاضر" : "طالب")})"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                decoration: const BoxDecoration(color: Colors.indigo),
              ),
              ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(tr("Edit Profile", "تعديل الملف الشخصي")),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()))),
              ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.orange),
                  title: Text(tr("Security & Password", "الأمان وكلمة المرور")),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SecurityScreen()))),
              const Divider(),

              // --- قائمة اختيار اللغة (Dropdown) ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.grey),
                    const SizedBox(width: 15),
                    Expanded(
                        child: Text(tr("App Language", "لغة التطبيق"),
                            style: const TextStyle(fontSize: 16))),
                    ValueListenableBuilder<Locale>(
                      valueListenable: languageNotifier,
                      builder: (context, currentLocale, _) {
                        return DropdownButton<String>(
                          value: currentLocale.languageCode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                                value: 'en', child: Text("English")),
                            DropdownMenuItem(
                                value: 'ar', child: Text("العربية")),
                          ],
                          onChanged: (String? newLang) {
                            if (newLang != null) {
                              languageNotifier.value = Locale(newLang);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (_, mode, __) => ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: Text(tr("Dark Mode", "الوضع الليلي")),
                      trailing: Switch(
                          value: mode == ThemeMode.dark,
                          onChanged: (v) => themeNotifier.value =
                              v ? ThemeMode.dark : ThemeMode.light))),
              const Divider(),
              ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(tr("Logout", "خروج")),
                  onTap: () =>
                      Supabase.instance.client.auth.signOut().then((_) {
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()));
                      })),
            ],
          );
        },
      ),
    );
  }
}

// --- شاشات للتكملة ---
class AttendanceScanScreen extends StatelessWidget {
  const AttendanceScanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(tr("Scan", "البصمة"))),
        body: const Center(child: Icon(Icons.qr_code_scanner, size: 100)));
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(tr("Rate", "النسبة"))),
        body: const Center(child: Icon(Icons.bar_chart, size: 100)));
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(tr("Alerts", "التنبيهات"))),
        body: const Center(child: Icon(Icons.notifications, size: 100)));
  }
}
