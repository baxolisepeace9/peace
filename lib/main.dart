
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zmrcfhskmdnxulcqdvnm.supabase.co',
    anonKey: 'sb_publishable_Eq39CiC8BvBIBKbmzTHJLA_1LM0cerW',
  );


  final supabase = Supabase.instance.client;

  if (supabase.auth.currentUser == null) {
    await supabase.auth.signInAnonymously();
  }

  debugPrint(
    'COMMUNITYFIX RESIDENT ID: ${supabase.auth.currentUser?.id}',
  );


  debugPrint(
    'COMMUNITYFIX RESIDENT ID: ${supabase.auth.currentUser?.id}',
  );


  try {
    await Supabase.instance.client
        .from('community_reports')
        .select('id')
        .limit(1);

    debugPrint('COMMUNITYFIX: Supabase connection successful!');
  } catch (error) {
    debugPrint('COMMUNITYFIX: Supabase connection failed: $error');
  }

  runApp(const CommunityFixApp());
}

const Color navy = Color(0xFF12345A);
const Color blue = Color(0xFF246BCE);
const Color pageBg = Color(0xFFF3F6FB);
const Color green = Color(0xFF18864B);

const List<String> categories = [
  'Roads',
  'Water',
  'Electricity',
  'Waste',
  'Safety',
  'Public Facilities',
  'Other',
];

const List<String> statuses = [
  'Submitted',
  'Acknowledged',
  'In Progress',
  'Resolved',
];

// Demo-only account store. Accounts disappear when the app restarts.
// This is not secure authentication and must not be used for real staff data.
final Map<String, String> staffAccounts = {};

String today() {
  final d = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class CommunityReport {
  final String id;
  final String title;
  final String category;
  final String location;
  final String description;
  final String date;
  String status;

  CommunityReport({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    required this.date,
    this.status = 'Submitted',
  });
}

class CommunityFixApp extends StatelessWidget {
  const CommunityFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CommunityFix',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBg,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: navy,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE3EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE3EC)),
          ),
        ),
      ),
      home: const CommunityHome(),
    );
  }
}

class CommunityHome extends StatefulWidget {
  const CommunityHome({super.key});

  @override
  State<CommunityHome> createState() => _CommunityHomeState();
}

class _CommunityHomeState extends State<CommunityHome> {
  int tab = 0;
  int nextNumber = 1046;
  String? loggedInStaff;

  late final List<CommunityReport> reports = [
    CommunityReport(
      id: 'CF-1043',
      title: 'Large pothole on main road',
      category: 'Roads',
      location: 'Duncan Village, East London',
      description:
      'A large pothole is making it difficult for vehicles to pass safely.',
      date: today(),
      status: 'In Progress',
    ),
    CommunityReport(
      id: 'CF-1044',
      title: 'Broken streetlight',
      category: 'Electricity',
      location: 'Mdantsane, Eastern Cape',
      description:
      'The streetlight near the local shops is not working at night.',
      date: today(),
      status: 'Acknowledged',
    ),
    CommunityReport(
      id: 'CF-1045',
      title: 'Illegal dumping near road',
      category: 'Waste',
      location: 'Mthatha, Eastern Cape',
      description:
      'Household rubbish has been dumped beside the public road.',
      date: today(),
      status: 'Resolved',
    ),
  ];

  int get openCount =>
      reports.where((r) => r.status != 'Resolved').length;

  int get resolvedCount =>
      reports.where((r) => r.status == 'Resolved').length;


  Future<void> createReport() async {
    final report = await Navigator.of(context).push<CommunityReport>(
      MaterialPageRoute(
        builder: (_) => ReportFormPage(
          reference: 'CF-${nextNumber}',
        ),
      ),
    );

    if (!mounted || report == null) return;

    final supabase = Supabase.instance.client;
    final residentId = supabase.auth.currentUser?.id;

    if (residentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resident session unavailable. Please reopen the app.'),
        ),
      );
      return;
    }

    try {
      await supabase.from('community_reports').insert({
        'reference': report.id,
        'title': report.title,
        'category': report.category,
        'location': report.location,
        'description': report.description,
        'resident_key': residentId,
        'status': 'Submitted',
      });

      if (!mounted) return;

      setState(() {
        nextNumber++;
        reports.insert(0, report);
        tab = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: green,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Report ${report.id} submitted successfully!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Could not save report: $error'),
        ),
      );
    }
  }

  Future<void> openStaffArea() async {
    if (loggedInStaff != null) {
      setState(() => tab = 2);
      return;
    }

    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const StaffLoginPage()),
    );

    if (!mounted || username == null) return;

    setState(() {
      loggedInStaff = username;
      tab = 2;
    });
  }

  void logoutStaff() {
    setState(() {
      loggedInStaff = null;
      tab = 0;
    });
  }

  void updateStatus(CommunityReport report, String status) {
    setState(() {
      report.status = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${report.id} updated to $status'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        reports: reports,
        openCount: openCount,
        resolvedCount: resolvedCount,
        onCreate: createReport,
        onViewReports: () => setState(() => tab = 1),
      ),
      ReportsPage(reports: reports),
      if (loggedInStaff != null)
        StaffPage(
          reports: reports,
          onUpdate: updateStatus,
          username: loggedInStaff!,
          onLogout: logoutStaff,
        )
      else
        const StaffLockedPage(),
      const AboutPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        backgroundColor: Colors.white,
        indicatorColor: blue.withAlpha(25),
        onDestinationSelected: (index) {
          if (index == 2) {
            openStaffArea();
          } else {
            setState(() => tab = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Staff',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}


// ---------------- STAFF AUTHENTICATION (DEMO) ----------------

class StaffLockedPage extends StatelessWidget {
  const StaffLockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Staff login required.'),
    );
  }
}

class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;
  String? errorMessage;

  void login() {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Enter your username and password.');
      return;
    }

    if (staffAccounts.containsKey(username) &&
        staffAccounts[username] == password) {
      Navigator.of(context).pop(username);
    } else {
      setState(() {
        errorMessage = 'Invalid login. Check your details or register first.';
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(title: const Text('Staff Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: navy,
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'CommunityFix',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Authorised staff access'),
                    const SizedBox(height: 24),
                    TextField(
                      controller: usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      onSubmitted: (_) => login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => hidePassword = !hidePassword);
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: login,
                        icon: const Icon(Icons.login),
                        label: const Text('LOGIN'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StaffRegistrationPage(),
                          ),
                        );
                      },
                      child: const Text('Register staff account'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Demo accounts are stored only while this app is running.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StaffRegistrationPage extends StatefulWidget {
  const StaffRegistrationPage({super.key});

  @override
  State<StaffRegistrationPage> createState() =>
      _StaffRegistrationPageState();
}

class _StaffRegistrationPageState extends State<StaffRegistrationPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool hidePassword = true;
  String? errorMessage;

  void register() {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => errorMessage = 'Complete all fields.');
      return;
    }
    if (username.length < 3) {
      setState(() => errorMessage = 'Username must be at least 3 characters.');
      return;
    }
    if (password.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => errorMessage = 'Passwords do not match.');
      return;
    }
    if (staffAccounts.containsKey(username)) {
      setState(() => errorMessage = 'That username is already registered.');
      return;
    }

    staffAccounts[username] = password;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff account created. Please log in.')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Registration')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 58, color: navy),
                    const SizedBox(height: 12),
                    const Text(
                      'Create staff account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Choose username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Choose password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => hidePassword = !hidePassword);
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: register,
                        child: const Text('CREATE ACCOUNT'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Demo limitation: anyone who can access this screen can register. '
                          'Use an administrator-controlled registration process for a real app.',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- HOME DASHBOARD ----------------

class DashboardPage extends StatelessWidget {
  final List<CommunityReport> reports;
  final int openCount;
  final int resolvedCount;
  final VoidCallback onCreate;
  final VoidCallback onViewReports;

  const DashboardPage({
    super.key,
    required this.reports,
    required this.openCount,
    required this.resolvedCount,
    required this.onCreate,
    required this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.location_city,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CommunityFix',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  Text(
                    'Your community. Your voice.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.notifications_none,
              size: 28,
              color: navy,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [navy, blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let us fix it together! 🇿🇦',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Help make your neighbourhood cleaner, '
                    'safer and better for everyone.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Report a Problem',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Community Overview',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total',
                value: '${reports.length}',
                icon: Icons.assignment_outlined,
                color: blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: 'Open',
                value: '$openCount',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: 'Resolved',
                value: '$resolvedCount',
                icon: Icons.check_circle_outline,
                color: green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 27),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Reports',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            TextButton(
              onPressed: onViewReports,
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...reports.take(3).map(
              (report) => ReportCard(report: report),
        ),
        const SizedBox(height: 18),
        const Text(
          'Small actions. Stronger communities.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- REPORT FORM ----------------

class ReportFormPage extends StatefulWidget {
  final String reference;

  const ReportFormPage({
    super.key,
    required this.reference,
  });

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = 'Roads';

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'What needs fixing?',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Give us the details of the community problem.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            const Text('Problem category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: categories
                  .map(
                    (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => category = value);
                }
              },
            ),
            const SizedBox(height: 18),
            const Text('Problem title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: titleController,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: 'e.g. Broken water pipe',
                prefixIcon: Icon(Icons.edit_outlined),
                counterText: '',
              ),
              validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 18),
            const Text('Location or landmark'),
            const SizedBox(height: 8),
            TextFormField(
              controller: locationController,
              maxLength: 150,
              decoration: const InputDecoration(
                hintText: 'e.g. Duncan Village, near the school',
                prefixIcon: Icon(Icons.location_on_outlined),
                counterText: '',
              ),
              validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Please enter a location'
                  : null,
            ),
            const SizedBox(height: 18),
            const Text('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              maxLength: 1000,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Explain what happened...',
                alignLabelWithHint: true,
                counterText: '',
              ),
              validator: (value) =>
              value == null || value.trim().length < 5
                  ? 'Please describe the problem'
                  : null,
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You will receive a demo reference number '
                          'after submitting your report.',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final report = CommunityReport(
                    id: widget.reference,
                    title: titleController.text.trim(),
                    category: category,
                    location: locationController.text.trim(),
                    description: descriptionController.text.trim(),
                    date: today(),
                  );

                  Navigator.pop(context, report);
                },
                icon: const Icon(Icons.send),
                label: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- REPORT LIST AND SEARCH ----------------

class ReportsPage extends StatefulWidget {
  final List<CommunityReport> reports;

  const ReportsPage({
    super.key,
    required this.reports,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String query = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.reports.where((report) {
      final text =
      '${report.id} ${report.title} ${report.location} '
          '${report.category}'.toLowerCase();

      final matchesText = text.contains(query.toLowerCase());
      final matchesStatus =
          filter == 'All' || report.status == filter;

      return matchesText && matchesStatus;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Community Reports',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${widget.reports.length} reports in the demo',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'Search title, location or ID',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: filter,
                decoration: const InputDecoration(
                  labelText: 'Filter by status',
                ),
                items: [
                  'All',
                  ...statuses,
                ].map(
                      (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  ),
                ).toList(),
                onChanged: (value) {
                  setState(() => filter = value ?? 'All');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
            child: Text('No matching reports found.'),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return ReportCard(report: filtered[index]);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------- MUNICIPAL STAFF DEMO ----------------

class StaffPage extends StatefulWidget {
  final List<CommunityReport> reports;
  final void Function(CommunityReport, String) onUpdate;
  final String username;
  final VoidCallback onLogout;

  const StaffPage({
    super.key,
    required this.reports,
    required this.onUpdate,
    required this.username,
    required this.onLogout,
  });

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final visibleReports = widget.reports.where((r) {
      return filter == 'All' || r.status == filter;
    }).toList();

    final pending = widget.reports
        .where((r) => r.status == 'Submitted')
        .length;

    final working = widget.reports
        .where((r) => r.status == 'In Progress')
        .length;

    final resolved = widget.reports
        .where((r) => r.status == 'Resolved')
        .length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          color: navy,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 35,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Staff Dashboard',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Signed in as ${widget.username}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Demo municipal report management',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Log out',
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: MiniStat(
                  title: 'Submitted',
                  value: '$pending',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MiniStat(
                  title: 'In Progress',
                  value: '$working',
                  color: blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MiniStat(
                  title: 'Resolved',
                  value: '$resolved',
                  color: green,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: filter,
            decoration: const InputDecoration(
              labelText: 'Show reports',
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: [
              'All',
              ...statuses,
            ].map(
                  (s) => DropdownMenuItem(
                value: s,
                child: Text(s),
              ),
            ).toList(),
            onChanged: (value) {
              setState(() => filter = value ?? 'All');
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Manage Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ),
        ),
        Expanded(
          child: visibleReports.isEmpty
              ? const Center(child: Text('No reports in this category.'))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: visibleReports.length,
            itemBuilder: (context, index) {
              final report = visibleReports[index];

              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.id,
                        style: const TextStyle(
                          color: blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        report.location,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Update report status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: report.status,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: statuses.map(
                              (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          if (value != null &&
                              value != report.status) {
                            widget.onUpdate(report, value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const MiniStat({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------------- REUSABLE REPORT CARD ----------------

class ReportCard extends StatelessWidget {
  final CommunityReport report;

  const ReportCard({
    super.key,
    required this.report,
  });

  Color get statusColor {
    switch (report.status) {
      case 'Resolved':
        return green;
      case 'In Progress':
        return Colors.orange.shade800;
      case 'Acknowledged':
        return blue;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData get categoryIcon {
    switch (report.category) {
      case 'Roads':
        return Icons.add_road;
      case 'Water':
        return Icons.water_drop_outlined;
      case 'Electricity':
        return Icons.lightbulb_outline;
      case 'Waste':
        return Icons.delete_outline;
      case 'Safety':
        return Icons.security;
      case 'Public Facilities':
        return Icons.apartment;
      default:
        return Icons.report_problem_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(report.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reference: ${report.id}'),
                  const SizedBox(height: 10),
                  Text('Category: ${report.category}'),
                  const SizedBox(height: 10),
                  Text('Location: ${report.location}'),
                  const SizedBox(height: 10),
                  Text('Description: ${report.description}'),
                  const SizedBox(height: 10),
                  Text('Date: ${report.date}'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Status: '),
                      Flexible(
                        child: Text(
                          report.status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CommunityFix demonstration report. '
                        'No municipality has been contacted.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: blue.withAlpha(22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon, color: blue, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.location,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      report.id,
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ABOUT PAGE ----------------

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [navy, blue],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.location_city,
            size: 65,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'About CommunityFix',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'A South African community reporting demo that helps '
              'residents document local problems and demonstrates '
              'how reports could be managed and resolved.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.7, fontSize: 15),
        ),
        const SizedBox(height: 24),
        const FeatureTile(
          icon: Icons.report_problem_outlined,
          title: 'Report problems',
          detail: 'Document local infrastructure issues.',
        ),
        const FeatureTile(
          icon: Icons.track_changes,
          title: 'Track progress',
          detail: 'Follow a report from submission to resolution.',
        ),
        const FeatureTile(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Staff dashboard',
          detail: 'Demonstrate how staff can update report statuses.',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'DEMO MODE\n\nReports are stored in app memory only. '
                'They are not sent to a municipality and will reset '
                'when the app restarts.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.6),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CommunityFix • South Africa 🇿🇦',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: CircleAvatar(
        backgroundColor: blue.withAlpha(25),
        child: Icon(icon, color: blue),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(detail),
    );
  }
}