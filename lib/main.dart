import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'firebase_options_ios.dart' as ios_options;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:video_player/video_player.dart';
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
Future<void> showTestNotification() async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'kantorfit_channel',
    'KantorFit',
    channelDescription: 'Notifikasi KantorFit',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: 'KantorFit',
    body: 'Waktunya bergerak! 💪',
    notificationDetails: notificationDetails,
  );
}
Future<void> scheduleWorkoutReminder() async {
  final now = tz.TZDateTime.now(tz.local);

  final schedules = [
    {
      'id': 10,
      'hour': 10,
      'minute': 0,
      'title': 'Waktunya Senam Pagi 🏃',
      'body': 'Yuk lakukan senam pagi bersama KantorFit.',
    },
    {
      'id': 14,
      'hour': 14,
      'minute': 0,
      'title': 'Waktunya Senam Siang 🏃',
      'body': 'Yuk lakukan senam siang bersama KantorFit.',
    },
  ];

  for (final schedule in schedules) {
    var scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      schedule['hour'] as int,
      schedule['minute'] as int,
    );

    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(
        const Duration(days: 1),
      );
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: schedule['id'] as int,
      title: schedule['title'] as String,
      body: schedule['body'] as String,
      scheduledDate: scheduleDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'kantorfit_channel',
          'KantorFit',
          channelDescription: 'Pengingat aktivitas fisik KantorFit',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode:
    AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
} 
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();   
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp(
  options: defaultTargetPlatform == TargetPlatform.iOS
      ? ios_options.DefaultFirebaseOptions.ios
      : DefaultFirebaseOptions.currentPlatform,
);
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
  settings: initializationSettings,
  onDidReceiveNotificationResponse: (response) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const BasicSportPage(),
      ),
    );
  },
);
final androidImplementation =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

await androidImplementation?.requestNotificationsPermission();
await scheduleWorkoutReminder();
  runApp(const KantorFitApp());
}
Future<bool> checkAdmin() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return false;
  }

  final adminDoc = await FirebaseFirestore.instance
      .collection('admins')
      .doc(user.uid)
      .get();

  return adminDoc.exists;
}

class KantorFitApp extends StatelessWidget {
  const KantorFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  navigatorKey: navigatorKey,
      title: 'KantorFit',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8FC), 
      ),
    
    home: FirebaseAuth.instance.currentUser == null
    ? const LoginPage()
    : FutureBuilder<bool>(
        future: checkAdmin(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
  return Scaffold(
    body: Center(
      child: Text(
        'Gagal memeriksa akun admin:\n${snapshot.error}',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

if (!snapshot.hasData) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}

          if (FirebaseAuth.instance.currentUser?.uid ==
    'nNvJ2ANDdaOOx6iGla37DkcBuNk2') {
  return const AdminPage();
}
return const HomePage();

  
        },
      ),
    );
  }
}
class WeeklyRecapPage extends StatelessWidget {
  const WeeklyRecapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1));

    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    final end = start.add(const Duration(days: 7));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Mingguan'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workout_history')
            .where(
              'tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where(
              'tanggal',
              isLessThan: Timestamp.fromDate(end),
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada aktivitas minggu ini',
              ),
            );
          }

          final docs = snapshot.data!.docs;

          final Map<String, int> totalPerUser = {};

          for (final doc in docs) {
            final data =
                doc.data() as Map<String, dynamic>;

            final uid = data['uid']?.toString() ?? '';
            final durasi =
                (data['durasi'] ?? 0) as int;

            totalPerUser[uid] =
                (totalPerUser[uid] ?? 0) + durasi;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: totalPerUser.length,
            itemBuilder: (context, index) {
              final uid =
                  totalPerUser.keys.elementAt(index);

              final totalDetik =
                  totalPerUser[uid] ?? 0;

              final menit = totalDetik ~/ 60;
              final detik = totalDetik % 60;

              final targetMingguanDetik = 150 * 60;
              final persen = ((totalDetik / targetMingguanDetik) * 100)
                  .clamp(0, 100)
                  .toStringAsFixed(0);

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const Text('Memuat...');
                      }

                      final userData =
                          userSnapshot.data!.data()
                              as Map<String, dynamic>?;

                      return Text(
                        userData?['nama']?.toString() ??
                            uid,
                      );
                    },
                  ),
               subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Total aktivitas: ${docs.where((doc) => (doc.data() as Map<String, dynamic>)['uid'] == uid).length}\n'
      'Total durasi: $menit menit ${detik.toString().padLeft(2, '0')} detik\n'
      'Target mingguan: 150 menit\n'
      'Pencapaian: $persen%',
    ),
    const SizedBox(height: 8),
    LinearProgressIndicator(
      value: (totalDetik / targetMingguanDetik).clamp(0.0, 1.0),
    ),
  ],
),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String filterAktivitas = 'Semua';
  DateTime? filterTanggal;
 Future<void> verifikasiAktivitas(String docId) async {
  final docRef = FirebaseFirestore.instance
      .collection('workout_history')
      .doc(docId);

  final docSnap = await docRef.get();

  if (!docSnap.exists) {
    throw Exception('Data aktivitas tidak ditemukan');
  }

  final data = docSnap.data();
  final publicId = data?['fotoPublicId']?.toString();

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('Admin belum login');
  }

  final idToken = await user.getIdToken();

  if (idToken == null) {
    throw Exception('Token Firebase tidak tersedia');
  }

  if (publicId != null && publicId.isNotEmpty) {
    final response = await http.post(
      Uri.parse(
        'https://sweet-dew-f06f.zebuacharles738.workers.dev',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idToken': idToken,
        'publicId': publicId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghapus foto dari Cloudinary: ${response.body}',
      );
    }
  }

 await docRef.update({
  'verifikasi': 'terverifikasi',
  'fotoBukti': null,
  'fotoPublicId': null,
});
}

  Future<void> exportCSV([String? selectedUid]) async {
    debugPrint('EXPORT CSV DIMULAI');
  final snapshot = await FirebaseFirestore.instance
      .collection('workout_history')
      .orderBy('tanggal', descending: true)
      .get();

  List<List<dynamic>> rows = [
    [
      'Pengguna',
      'Aktivitas',
      'Durasi',
      'Status',
      'Jarak (km)',
      'Tanggal',
    ],
  ];

  for (var doc in snapshot.docs) {
  final item = doc.data();

  final uid = item['uid']?.toString() ?? '';

  if (selectedUid != null && uid != selectedUid) {
    continue;
  }
    

String nama = '-';

if (uid.isNotEmpty) {
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();

  nama = userDoc.data()?['nama']?.toString() ?? uid;
}


    final durasiDetik = (item['durasi'] ?? 0) as int;
    final menit = durasiDetik ~/ 60;
    final detik = durasiDetik % 60;

    final durasi = '$menit:${detik.toString().padLeft(2, '0')}';

    final jarak = item['jarak'] != null
        ? (item['jarak'] / 1000).toStringAsFixed(2)
        : '-';

    final tanggal = item['tanggal'] != null
    ? '${(item['tanggal'] as Timestamp).toDate().day.toString().padLeft(2, '0')}/'
      '${(item['tanggal'] as Timestamp).toDate().month.toString().padLeft(2, '0')}/'
      '${(item['tanggal'] as Timestamp).toDate().year}'
    : '-';

    rows.add([
      nama,
      item['program'] ?? '-',
      durasi,
      item['status'] ?? '-',
      jarak,
      tanggal,
    ]);
      }

  final csvData = const ListToCsvConverter().convert(rows);

  final directory = Directory('/storage/emulated/0/Download');

if (!await directory.exists()) {
  await directory.create(recursive: true);
}

final file = File(
  '${directory.path}/kantorfit_rekap_${DateTime.now().millisecondsSinceEpoch}.csv',
);

await file.writeAsString(csvData);
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'CSV berhasil disimpan di Download:\n${file.path}',
    ),
  ),
);
}


  
  Future<String> getUserName(String uid) async {
  if (uid.isEmpty) return '-';

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();

  return userDoc.data()?['nama']?.toString() ?? uid;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
  title: const Text('Admin KantorFit'),
  leading: IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () async {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    },
  ),
  actions: [
  IconButton(
    icon: const Icon(Icons.bar_chart),
    tooltip: 'Rekap Mingguan',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WeeklyRecapPage(),
        ),
      );
    },
  ),

  IconButton(
  icon: const Icon(Icons.download),
  tooltip: 'Export CSV',
  onPressed: () async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    if (!context.mounted) return;

    final selectedUid = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export CSV'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
  tileColor: Colors.transparent,
 splashColor: Colors.blue.withValues(alpha: 0.15),
  title: const Text('Semua Pengguna'),
  onTap: () {
    Navigator.pop(context, null);
  },
),
                ...usersSnapshot.docs.map((doc) {
                  final nama =
                      doc.data()['nama']?.toString() ?? doc.id;

                 return ListTile(
  
  title: Text(nama),
  onTap: () {
    Navigator.pop(context, doc.id);
  },
);
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    await exportCSV(selectedUid);
  },
),
    PopupMenuButton<String>(
      initialValue: filterAktivitas,
      onSelected: (value) {
        setState(() {
          filterAktivitas = value;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'Semua',
          child: Text('Semua'),
        ),
        PopupMenuItem(
          value: 'Lari',
          child: Text('Lari'),
        ),
        PopupMenuItem(
          value: 'Senam Jam 10',
          child: Text('Senam Jam 10'),
        ),
        PopupMenuItem(
          value: 'Senam Jam 14',
          child: Text('Senam Jam 14'),
        ),
        PopupMenuItem(
          value: 'Badminton',
          child: Text('Badminton'),
        ),
        PopupMenuItem(
          value: 'Voli',
          child: Text('Voli'),
        ),
        PopupMenuItem(
          value: 'Futsal',
          child: Text('Futsal'),
        ),
      ],
          ),

    IconButton(
      icon: const Icon(Icons.calendar_month),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: filterTanggal ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );

        if (picked != null) {
          setState(() {
            filterTanggal = picked;
          });
        }
      },
    ),
  ],
),
     body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('workout_history')
      .orderBy('tanggal', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Text('Error: ${snapshot.error}'),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text('Belum ada aktivitas'),
      );
    }

    final data = snapshot.data!.docs;
   final filteredData = data.where((doc) {
  final item = doc.data() as Map<String, dynamic>;

  final cocokAktivitas =
      filterAktivitas == 'Semua' ||
      item['program'] == filterAktivitas;

  final cocokTanggal =
      filterTanggal == null ||
      (item['tanggal'] as Timestamp)
              .toDate()
              .year ==
          filterTanggal!.year &&
      (item['tanggal'] as Timestamp)
              .toDate()
              .month ==
          filterTanggal!.month &&
      (item['tanggal'] as Timestamp)
              .toDate()
              .day ==
          filterTanggal!.day;

  return cocokAktivitas && cocokTanggal;
}).toList();
    return ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: filteredData.length + 1,
      itemBuilder: (context, index) {
  if (index == 0) {
  final menunggu = filteredData.where((doc) {
    final item = doc.data() as Map<String, dynamic>;
    return (item['verifikasi'] ?? 'menunggu') == 'menunggu';
  }).length;

  final terverifikasi = filteredData.where((doc) {
    final item = doc.data() as Map<String, dynamic>;
    return item['verifikasi'] == 'terverifikasi';
  }).length;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Aktivitas',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('Total Aktivitas: ${filteredData.length}'),
          Text('Menunggu Verifikasi: $menunggu'),
          Text('Terverifikasi: $terverifikasi'),
        ],
      ),
    ),
  );
}
        final item =
    filteredData[index].data() as Map<String, dynamic>;
    final uid = item['uid'] ?? '';
            final durasiDetik = (item['durasi'] ?? 0) as int;
final menit = durasiDetik ~/ 60;
final detik = durasiDetik % 60;

final durasiText =
    '$menit:${detik.toString().padLeft(2, '0')}';    

        return Card(
          child: ListTile(
           leading: item['fotoBukti'] != null &&
        item['fotoBukti'].toString().isNotEmpty
    ? GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: InteractiveViewer(
                  child: Image.network(
                    item['fotoBukti'],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          );
        },
        child: Image.network(
          item['fotoBukti'],
          width: 55,
          height: 55,
          fit: BoxFit.cover,
        ),
      )
    : const Icon(Icons.fitness_center),
            title: Text(
              item['program'] ?? '-',
            ),
        subtitle: FutureBuilder<String>(
  future: getUserName(uid),
  builder: (context, userSnapshot) {
    final nama = userSnapshot.data ?? 'Memuat...';

    return Text(
      'Durasi: $durasiText\n'
      'Status: ${item['status'] ?? '-'}\n'
      'Jarak: ${item['jarak'] != null ? '${(item['jarak'] / 1000).toStringAsFixed(2)} km' : '-'}\n'
      'Tanggal: ${item['tanggal'] != null ? (item['tanggal'] as Timestamp).toDate().toString().substring(0, 16) : '-'}\n'
      'Pengguna: $nama\n'
      'Verifikasi: ${item['verifikasi'] ?? 'menunggu'}',
    );
  },
),
trailing: item['verifikasi'] == 'terverifikasi'
    ? const Icon(
        Icons.check_circle,
        color: Colors.green,
      )
    : ElevatedButton(
       onPressed: () async {
  try {
    await verifikasiAktivitas(filteredData[index - 1].id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aktivitas berhasil diverifikasi'),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal verifikasi: $e'),
      ),
    );
  }
},
        child: const Text('Verifikasi'),
      ),
          ),
        );
      },
    );
  },
),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
   return Scaffold(
  body: Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/background.jpg'),
        fit: BoxFit.cover,
        opacity: 0.12,
      ),
    ),
    child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             // Header
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo! 👋',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Siap bergerak hari ini?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
    Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Color(0xFF1976D2),
        size: 28,
      ),
    ),
  ],
),
              const SizedBox(height: 24),

              // Banner utama
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                gradient: const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF1976D2),
    Color(0xFF42A5F5),
  ],
),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
  BoxShadow(
   color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 15,
    offset: Offset(0, 8),
  ),
],                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 55,
                    ),
                   const SizedBox(height: 14),
const Text(
  'AKTIVITAS HARI INI',
  style: TextStyle(
    color: Colors.white70,
    fontSize: 13,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  ),
),
const SizedBox(height: 6),
const Text(
                      'Aktif di Tengah Kesibukan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Luangkan beberapa menit untuk menjaga tubuh tetap aktif.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const WorkoutPage(),
    ),
  );
},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1976D2),
                      ),
                      child: const Text('Mulai Aktivitas'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const SizedBox(height: 28),

              // Progress
              const Text(
                'Progress Kamu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProgressPage(),
      ),
    );
  },
  child:
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 7),
    ),
  ],
),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 44,
                      color: Color(0xFF1976D2),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                     FutureBuilder<int>(
  future: FirebaseFirestore.instance
      .collection('workout_history')
      .where(
        'uid',
        isEqualTo: FirebaseAuth.instance.currentUser?.uid,
      )
      .get()
      .then((snapshot) {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    int totalSeconds = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final tanggal = data['tanggal'];

      if (tanggal is Timestamp) {
        final date = tanggal.toDate();

        if (!date.isBefore(startOfDay) &&
            date.isBefore(endOfDay)) {
          final durasi = data['durasi'];

          if (durasi is num) {
            totalSeconds += durasi.toInt();
          }
        }
      }
    }

    return totalSeconds;
  }),
  builder: (context, snapshot) {
    final seconds = snapshot.data ?? 0;
    final minutes = seconds ~/ 60;

    return Text(
      '$minutes Menit Aktivitas',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  },
),
                        SizedBox(height: 4),
                        Text(
                        'Yuk, tetap aktif hari ini!',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                 ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    ),

      // Navigasi bawah
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
       onDestinationSelected: (index) {
  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutPage(),
      ),
    );
  }

  if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProgressPage(),
      ),
    );
  }

 if (index == 3) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const ProfilePage(),
    ),
  );
}
},
        indicatorColor: const Color(0xFFE3F2FD),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
         
_workoutCard(
  context,
  'Olahraga di Rumah',
  'Latihan ringan untuk membantu pengelolaan berat badan',
  Icons.home,
),
const SizedBox(height: 14),
_workoutCard(
  context,
  'Lari',
  'Catat aktivitas lari',
  Icons.directions_run,
),

const SizedBox(height: 14),
_workoutCard(
  context,
  'Senam Peregangan',
  'Senam ringan di sela pekerjaan',
  Icons.accessibility_new,
),
const SizedBox(height: 14),
_workoutCard(
  context,
  'Senam Bersama',
  'Senam bersama di lokasi kantor',
  Icons.groups,
),
        ],
      ),
    );
  }

  Widget _workoutCard(
    BuildContext context,
    String title,
    String duration,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          icon,
          size: 38,
          color: const Color(0xFF1976D2),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(duration),
      onTap: () {
 if (title == 'Lari') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const RunPage(),
    ),
  );
} else if (title == 'Senam Peregangan') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SenamPage(),
    ),
  );
  } else if (title == 'Senam Bersama') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SenamBersamaPage(),
    ),
  );

  } else if (title == 'Olahraga di Rumah') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BasicSportPage(),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutDetailPage(),
      ),
    );
  }
},
      ),
    );
  }
}
class SenamPage extends StatelessWidget {
  const SenamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senam Kantor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Sesi Senam',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lakukan senam di sela kesibukan kerja.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            _senamCard(
              context,
              'Senam Jam 10',
              'Senam pagi • Video panduan',
              Icons.accessibility_new,
            ),

            const SizedBox(height: 16),

            _senamCard(
              context,
              'Senam Jam 14',
              'Senam siang • Video panduan',
              Icons.accessibility_new,
            ),
          ],
        ),
      ),
    );
  }

  Widget _senamCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SenamVideoPage(
        title: title,
      ),
    ),
  );
},
        contentPadding: const EdgeInsets.all(18),
        leading: Icon(
          icon,
          size: 42,
          color: const Color(0xFF1976D2),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
class SenamVideoPage extends StatefulWidget {
  const SenamVideoPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<SenamVideoPage> createState() => _SenamVideoPageState();
}

class _SenamVideoPageState extends State<SenamVideoPage> {
  late VideoPlayerController controller;
  bool videoFinished = false;

  @override
  void initState() {
    super.initState();

  final videoPath = widget.title == 'Senam Jam 10'
    ? 'assets/senam_jam_10.mp4.mp4'
    : 'assets/senam_jam_14.mp4.mp4';

controller = VideoPlayerController.asset(videoPath)
  ..initialize().then((_) {
    controller.addListener(() {
      if (controller.value.position >= controller.value.duration &&
          !videoFinished) {
        setState(() {
          videoFinished = true;
        });
      }
    });

    setState(() {});
  });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
  child: Center(
        child: controller.value.isInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        controller.value.isPlaying
                            ? controller.pause()
                            : controller.play();
                      });
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      controller.value.isPlaying
                          ? 'Pause'
                          : 'Mulai Senam',
                    ),
                  ),
                  const SizedBox(height: 12),
                if (videoFinished) ...[
  ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutCompletePage(
            activityName: widget.title,
          durasiMenit: 0,
durasiDetik:
    controller.value.duration.inSeconds,
          ),
        ),
      );
    },
    icon: const Icon(Icons.check),
    label: const Text('Selesai Senam'),
  ),
                  ],
                ],
              )
            : const CircularProgressIndicator(),
      ),
    ),
  );
  }
}
class WorkoutDetailPage extends StatelessWidget {
  const WorkoutDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stretch',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Peregangan • Tanpa Alat',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gerakan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Neck Stretch\n'
              '2. Shoulder Rotation\n'
              '3. Wrist Stretch\n'
              '4. Torso Rotation',
              style: TextStyle(
                fontSize: 17,
                height: 1.8,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutTimerPage(
  activityName: 'Quick Stretch',
)
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Mulai Aktivitas',
                    style: TextStyle(fontSize: 18),
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
class OfficeWorkoutPage extends StatelessWidget {
  const OfficeWorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Office Workout',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '10 Menit • Tanpa Alat',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Latihan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Chair Squat\n'
              '2. Wall Push Up\n'
              '3. Standing Leg Raise\n'
              '4. Calf Raise\n'
              '5. Torso Rotation',
              style: TextStyle(
                fontSize: 17,
                height: 1.8,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                     builder: (context) => WorkoutTimerPage(
  activityName: 'Quick Stretch',
),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Mulai Latihan',
                    style: TextStyle(fontSize: 18),
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
class SquatAnimationWidget extends StatefulWidget {
  const SquatAnimationWidget({super.key});

  @override
  State<SquatAnimationWidget> createState() =>
      _SquatAnimationWidgetState();
}

class _SquatAnimationWidgetState
    extends State<SquatAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return CustomPaint(
            painter: SquatPainter(progress),
          );
        },
      ),
    );
  }
}

class SquatPainter extends CustomPainter {
  final double progress;

  SquatPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1976D2)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;

    // Gerakan turun-naik squat
    final squatAmount = Curves.easeInOut.transform(progress);

    final bodyY = 65 + (squatAmount * 35);
    final hipY = 120 + (squatAmount * 25);
    final kneeY = 165 + (squatAmount * 5);

    // Kepala
    canvas.drawCircle(
      Offset(centerX, bodyY - 25),
      18,
      paint,
    );

    // Badan
    canvas.drawLine(
      Offset(centerX, bodyY - 7),
      Offset(centerX, hipY),
      paint,
    );

    // Lengan kiri
    canvas.drawLine(
      Offset(centerX, bodyY + 5),
      Offset(centerX - 35, bodyY + 25),
      paint,
    );

    // Lengan kanan
    canvas.drawLine(
      Offset(centerX, bodyY + 5),
      Offset(centerX + 35, bodyY + 25),
      paint,
    );

    // Paha kiri
    canvas.drawLine(
      Offset(centerX, hipY),
      Offset(centerX - 30, kneeY),
      paint,
    );

    // Paha kanan
    canvas.drawLine(
      Offset(centerX, hipY),
      Offset(centerX + 30, kneeY),
      paint,
    );

    // Betis kiri
    canvas.drawLine(
      Offset(centerX - 30, kneeY),
      Offset(centerX - 35, 195),
      paint,
    );

    // Betis kanan
    canvas.drawLine(
      Offset(centerX + 30, kneeY),
      Offset(centerX + 35, 195),
      paint,
    );

    // Garis lantai
    final floorPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(centerX - 70, 198),
      Offset(centerX + 70, 198),
      floorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SquatPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class HomeWorkoutAnimation extends StatefulWidget {
  final String exerciseName;

  const HomeWorkoutAnimation({
    super.key,
    required this.exerciseName,
  });

  @override
  State<HomeWorkoutAnimation> createState() =>
      _HomeWorkoutAnimationState();
}

class _HomeWorkoutAnimationState
    extends State<HomeWorkoutAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: HomeWorkoutPainter(
              progress: _controller.value,
              exerciseName: widget.exerciseName,
            ),
          );
        },
      ),
    );
  }
}



class HomeWorkoutPainter extends CustomPainter {
  final double progress;
  final String exerciseName;

  HomeWorkoutPainter({required this.progress, required this.exerciseName});

  @override
  void paint(Canvas canvas, Size size) {
    // Koordinat tetap membuat proporsi figur konsisten pada ukuran layar berbeda.
    canvas.save();
    final scale = math.min(size.width / 320, size.height / 220);
    canvas.translate((size.width - 320 * scale) / 2, (size.height - 220 * scale) / 2);
    canvas.scale(scale);

    final ink = Paint()
      ..color = const Color(0xFF1976D2)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final floorPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;
    

    final name = exerciseName.toLowerCase();
    final wave = math.sin(progress * math.pi * 2);
    final pulse = (1 - math.cos(progress * math.pi * 2)) / 2;
    const floorY = 190.0;
    const cx = 160.0;

    void line(Offset a, Offset b, [double width = 6]) {
      ink.strokeWidth = width;
      canvas.drawLine(a, b, ink);
    }
    void head(Offset p) => canvas.drawCircle(p, 13, ink);
    void ground() => canvas.drawLine(const Offset(18, floorY), const Offset(302, floorY), floorPaint);
    void standing({double x = cx, double y = 45, double lean = 0}) {
      final headP = Offset(x + lean, y);
      final shoulder = Offset(x, y + 31);
      final hip = Offset(x, y + 78);
      head(headP);
      line(Offset(headP.dx, headP.dy + 13), hip);
      line(shoulder, Offset(x - 27, y + 51));
      line(Offset(x - 27, y + 51), Offset(x - 34, y + 67));
      line(shoulder, Offset(x + 27, y + 51));
      line(Offset(x + 27, y + 51), Offset(x + 34, y + 67));
      line(hip, Offset(x - 19, y + 112));
      line(Offset(x - 19, y + 112), Offset(x - 22, floorY));
      line(hip, Offset(x + 19, y + 112));
      line(Offset(x + 19, y + 112), Offset(x + 22, floorY));
    }

    ground();
    // Gerakan berdiri dengan pose yang berbeda untuk setiap jenis latihan.
    if (name == 'step touch cepat') {
      final lead = wave >= 0 ? 1.0 : -1.0;
      final shift = 18 * pulse;
      final shoulder = Offset(cx + lead * shift * .35, 76);
      final hip = Offset(cx + lead * shift * .45, 120);
      head(Offset(cx + lead * shift * .35, 45));
      line(Offset(cx + lead * shift * .35, 58), hip);
      line(shoulder, Offset(shoulder.dx - 25, 93));
      line(Offset(shoulder.dx - 25, 93), Offset(shoulder.dx - 30, 109));
      line(shoulder, Offset(shoulder.dx + 25, 93));
      line(Offset(shoulder.dx + 25, 93), Offset(shoulder.dx + 30, 109));
      final leadFoot = Offset(cx + lead * 48 * pulse, floorY);
      final trailFoot = Offset(cx + lead * (48 * pulse - 12), floorY);
      final leadKnee = Offset(leadFoot.dx - lead * 8, 151 - 8 * pulse);
      final trailKnee = Offset(trailFoot.dx + lead * 10, 151);
      line(hip, leadKnee); line(leadKnee, leadFoot);
      line(hip, trailKnee); line(trailKnee, trailFoot);
    } else if (name == 'squat ke kursi' || name == 'bodyweight squat' || name == 'squat jump') {
      final down = pulse * (name == 'squat jump' ? 20 : 24);
      final jump = name == 'squat jump' ? math.max(0.0, wave) * 24 : 0.0;
      final y = 45 + down - jump;
      head(Offset(cx, y));
      final shoulder = Offset(cx, y + 31), hip = Offset(cx, y + 78);
      line(Offset(cx, y + 13), hip);
      line(shoulder, Offset(cx - 25, y + 42)); line(Offset(cx - 25, y + 42), Offset(cx - 32, y + 57));
      line(shoulder, Offset(cx + 25, y + 42)); line(Offset(cx + 25, y + 42), Offset(cx + 32, y + 57));
      final kneeL = Offset(cx - 30, 151 - down * .25), kneeR = Offset(cx + 30, 151 - down * .25);
      line(hip, kneeL); line(kneeL, Offset(cx - 36, floorY));
      line(hip, kneeR); line(kneeR, Offset(cx + 36, floorY));
      if (name == 'squat ke kursi') {
        final chair = Paint()..color = Colors.brown.shade400..strokeWidth = 4..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(205, 132), const Offset(205, 174), chair);
        canvas.drawLine(const Offset(188, 132), const Offset(220, 132), chair);
        canvas.drawLine(const Offset(205, 174), const Offset(220, 190), chair);
      }
    } else if (name == 'marching high knee' || name == 'high knee' || name == 'squat + knee drive') {
      final leftLift = math.max(0.0, wave) * 42;
      final rightLift = math.max(0.0, -wave) * 42;
      head(const Offset(cx, 45));
      line(const Offset(cx, 58), const Offset(cx, 120));
      line(const Offset(cx, 76), Offset(cx - 25, 95 - leftLift * .25));
      line(Offset(cx - 25, 95 - leftLift * .25), Offset(cx - 28, 110 - leftLift * .25));
      line(const Offset(cx, 76), Offset(cx + 25, 95 - rightLift * .25));
      line(Offset(cx + 25, 95 - rightLift * .25), Offset(cx + 28, 110 - rightLift * .25));
      line(const Offset(cx, 120), Offset(cx - 19, 151 - leftLift));
      line(Offset(cx - 19, 151 - leftLift), Offset(cx - 20, floorY - leftLift));
      line(const Offset(cx, 120), Offset(cx + 19, 151 - rightLift));
      line(Offset(cx + 19, 151 - rightLift), Offset(cx + 20, floorY - rightLift));
      if (name == 'squat + knee drive') {
        line(const Offset(cx, 76), Offset(cx - 34, 98));
        line(Offset(cx - 34, 98), Offset(cx - 45, 90));
      }
    } else if (name == 'standing punch') {
      standing(y: 45);
      line(const Offset(cx - 30, 96), Offset(cx - 56 - wave * 18, 91));
      line(const Offset(cx + 30, 96), Offset(cx + 56 + wave * 18, 91));
    } else if (name == 'reverse lunge' || name == 'jumping lunge') {
      final jump = name == 'jumping lunge' ? math.max(0.0, wave) * 22 : 0.0;
      final y = 45 - jump;
      head(Offset(cx, y)); line(Offset(cx, y + 13), Offset(cx, y + 78));
      line(Offset(cx, y + 31), Offset(cx - 28, y + 50)); line(Offset(cx, y + 31), Offset(cx + 28, y + 50));
      final frontKnee = Offset(cx - 32, 148 - pulse * 12);
      final backKnee = Offset(cx + 34, 151);
      line(Offset(cx, y + 78), frontKnee); line(frontKnee, Offset(cx - 40, floorY - jump));
      line(Offset(cx, y + 78), backKnee); line(backKnee, Offset(cx + 58, floorY - jump));
    } else if (name == 'wall push-up' || name == 'incline push-up') {
      // Pose miring, tangan menumpu pada dinding/meja, bukan berbaring di lantai.
      final wallX = name == 'wall push-up' ? 274.0 : 286.0;
      final wall = Paint()..color = Colors.grey.shade400..strokeWidth = 4;
      canvas.drawLine(Offset(wallX, 42), Offset(wallX, floorY), wall);
      final dip = pulse * 9;
      head(Offset(92, 67 + dip));
      line(Offset(105, 75 + dip), Offset(185, 112 + dip));
      line(Offset(185, 112 + dip), Offset(239, 125 + dip));
      line(Offset(120, 83 + dip), Offset(185, 100 + dip));
      line(Offset(185, 100 + dip), Offset(wallX, 94 + dip));
      line(Offset(130, 88 + dip), Offset(190, 124 + dip));
      line(Offset(190, 124 + dip), Offset(wallX, 118 + dip));
      line(Offset(239, 125 + dip), Offset(238, floorY));
      line(Offset(239, 125 + dip), Offset(265, floorY));
    } else if (name == 'glute bridge') {
      head(const Offset(68, 159));
      line(const Offset(81, 158), Offset(132, 160 - pulse * 28));
      line(Offset(132, 160 - pulse * 28), const Offset(191, 169));
      line(const Offset(191, 169), const Offset(214, 190));
      line(Offset(132, 160 - pulse * 28), const Offset(126, 184));
      line(const Offset(126, 184), const Offset(151, 190));
      line(const Offset(100, 160), const Offset(114, 183));
    } else if (name == 'push-up') {
      final dip = pulse * 10;
      head(Offset(68, 125 + dip));
      line(Offset(81, 127 + dip), Offset(155, 137 + dip));
      line(Offset(155, 137 + dip), const Offset(225, 145));
      line(Offset(100, 130 + dip), Offset(119, 165)); line(Offset(119, 165), Offset(142, 166));
      line(Offset(225, 145), Offset(244, 171));
      line(Offset(244, 171), Offset(269, 171));
    } else if (name == 'burpee') {
      // Satu siklus burpee: berdiri/squat, plank, kembali jongkok, lalu melompat.
      final phase = progress % 1.0;
      if (phase < .25) {
        final t = phase / .25;
        final y = 45 + t * 22;
        head(Offset(cx, y));
        line(Offset(cx, y + 13), Offset(cx, y + 69));
        line(Offset(cx, y + 31), Offset(cx - 29, y + 45));
        line(Offset(cx, y + 31), Offset(cx + 29, y + 45));
        line(Offset(cx, y + 69), Offset(cx - 29, 151));
        line(Offset(cx - 29, 151), Offset(cx - 39, floorY));
        line(Offset(cx, y + 69), Offset(cx + 29, 151));
        line(Offset(cx + 29, 151), Offset(cx + 39, floorY));
      } else if (phase < .5) {
        final t = (phase - .25) / .25;
        head(Offset(70 + t * 10, 112 + t * 8));
        line(Offset(83 + t * 10, 118 + t * 8), Offset(157, 140));
        line(const Offset(157, 140), const Offset(231, 151));
        line(Offset(96 + t * 8, 124 + t * 8), const Offset(111, 164));
        line(const Offset(111, 164), const Offset(132, 165));
        line(const Offset(231, 151), const Offset(214, 174));
        line(const Offset(214, 174), const Offset(239, 176));
      } else if (phase < .75) {
        final t = (phase - .5) / .25;
        head(Offset(80 + t * 60, 120 - t * 48));
        line(Offset(92 + t * 60, 126 - t * 48), Offset(157, 143 - t * 22));
        line(Offset(157, 143 - t * 22), Offset(220, 151 - t * 18));
        line(Offset(104 + t * 30, 130 - t * 35), Offset(117, 164));
        line(Offset(117, 164), Offset(138, 165));
        line(Offset(220, 151 - t * 18), Offset(211, 173));
        line(Offset(211, 173), Offset(237, 175));
      } else {
        final t = (phase - .75) / .25;
        final hop = math.sin(t * math.pi) * 24;
        head(Offset(cx, 45 - hop));
        line(Offset(cx, 58 - hop), Offset(cx, 120 - hop));
        line(Offset(cx, 76 - hop), Offset(cx - 27, 94 - hop));
        line(Offset(cx, 76 - hop), Offset(cx + 27, 94 - hop));
        line(Offset(cx, 120 - hop), Offset(cx - 23, 151 - hop));
        line(Offset(cx - 23, 151 - hop), Offset(cx - 34, floorY - hop));
        line(Offset(cx, 120 - hop), Offset(cx + 23, 151 - hop));
        line(Offset(cx + 23, 151 - hop), Offset(cx + 34, floorY - hop));
      }
    } else if (name == 'mountain climber' || name == 'mountain climber cepat') {
      final knee = wave * 18;
      head(const Offset(64, 116));
      line(const Offset(77, 120), const Offset(155, 139));
      line(const Offset(155, 139), const Offset(231, 150));
      line(const Offset(93, 124), const Offset(111, 164));
      line(const Offset(111, 164), const Offset(132, 165));
      line(const Offset(231, 150), Offset(203 + knee, 151));
      line(Offset(203 + knee, 151), Offset(181 + knee, 179));
    } else if (name == 'skater jump') {
      final shift = wave * 26;
      head(Offset(cx + shift, 48 - math.max(0.0, wave) * 12));
      line(Offset(cx + shift, 61), Offset(cx + shift - 5, 116));
      line(Offset(cx + shift - 5, 78), Offset(cx + shift - 35, 95));
      line(Offset(cx + shift - 5, 78), Offset(cx + shift + 29, 92));
      line(Offset(cx + shift - 5, 116), Offset(cx + shift - 28, 145));
      line(Offset(cx + shift - 28, 145), Offset(cx + shift - 43, floorY));
      line(Offset(cx + shift - 5, 116), Offset(cx + shift + 27, 143));
      line(Offset(cx + shift + 27, 143), Offset(cx + shift + 48, floorY));
    } else {
      // Fallback untuk gerakan berdiri yang belum memiliki pose khusus.
      standing();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HomeWorkoutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.exerciseName != exerciseName;
}

class WorkoutTimerPage extends StatefulWidget {
  const WorkoutTimerPage({
    super.key,
    required this.activityName,
    this.exercises,
    this.currentIndex = 0,
    this.targetSeconds = 60,
    this.level = 'Pemula',
  });

  final String activityName;
  final List<HomeWorkoutExercise>? exercises;
  final int currentIndex;
  final int targetSeconds;
  final String level;

  @override
  State<WorkoutTimerPage> createState() => _WorkoutTimerPageState();
}

class _WorkoutTimerPageState extends State<WorkoutTimerPage> {
  int seconds = 0;
  bool isRunning = false;
  bool isResting = false;

  Timer? timer;

  late List<HomeWorkoutExercise> exercises;
  late int currentIndex;
  late HomeWorkoutExercise currentExercise;

  @override
  void initState() {
    super.initState();

    exercises =
        widget.exercises ?? getHomeWorkoutProgram(widget.level);

    currentIndex = widget.currentIndex;

    if (exercises.isNotEmpty &&
        currentIndex >= 0 &&
        currentIndex < exercises.length) {
      currentExercise = exercises[currentIndex];
    } else {
      currentExercise = const HomeWorkoutExercise(
        name: 'Latihan',
        description: 'Lakukan latihan dengan nyaman.',
        benefit: 'Membantu menjaga kebugaran dan aktivitas fisik tubuh.',
        repetitions: 10,
        durationSeconds: 60,
        restSeconds: 20,
      );
    }
    if (widget.currentIndex > 0) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      startTimer();
    }
  });
}
  }

  Future<void> startTimer() async {
    if (isRunning) return;

    setState(() {
      isRunning = true;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (seconds >= currentExercise.durationSeconds) {
          timer.cancel();

          setState(() {
            isRunning = false;
          });

          startRest();
          return;
        }

        setState(() {
          seconds++;
        });
      },
    );
  }

  Future<void> startRest() async {
    if (!mounted) return;

    setState(() {
      isResting = true;
      seconds = 0;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (seconds >= currentExercise.restSeconds) {
          timer.cancel();

          setState(() {
            isResting = false;
          });

          nextExercise();
          return;
        }

        setState(() {
          seconds++;
        });
      },
    );
  }

  Future<void> nextExercise() async {
    if (currentIndex < exercises.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutTimerPage(
            activityName: exercises[currentIndex + 1].name,
            exercises: exercises,
            currentIndex: currentIndex + 1,
            level: widget.level,
          ),
        ),
      );
    } else {
      await finishWorkout();
    }
  }

  Future<void> finishWorkout() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();

    final todayKey =
        '${today.year}-${today.month}-${today.day}';

    final currentSeconds =
        prefs.getInt('dailyActivitySeconds_$todayKey') ?? 0;

    int totalWorkoutSeconds = 0;

    for (final exercise in exercises) {
      totalWorkoutSeconds += exercise.durationSeconds;
    }

    await prefs.setInt(
      'dailyActivitySeconds_$todayKey',
      currentSeconds + totalWorkoutSeconds,
    );

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('workout_history')
            .add({
          'uid': user.uid,
          'tanggal': Timestamp.now(),
          'program': 'Olahraga di Rumah',
          'level': widget.level,
          'durasi': totalWorkoutSeconds,
          'status': 'selesai',
        });
      }
    } catch (e) {
      // Abaikan error Firebase.
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutCompletePage(
          activityName: 'Olahraga di Rumah - ${widget.level}',
          durasiMenit: (totalWorkoutSeconds / 60).ceil(),
        ),
      ),
    );
  }

  Future<void> stopTimer() async {
    timer?.cancel();
    timer = null;

    if (!mounted) return;

    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    timer?.cancel();

    setState(() {
      seconds = 0;
      isRunning = false;
      isResting = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  List<String> getInstructions() {
    switch (currentExercise.name) {
      case 'Squat ke Kursi':
        return [
          'Berdiri di depan kursi.',
          'Buka kaki selebar bahu.',
          'Turunkan tubuh perlahan hingga menyentuh kursi.',
          'Dorong tubuh kembali hingga berdiri.',
        ];

      case 'Step Touch Cepat':
        return [
          'Berdiri tegak dengan kaki rapat.',
          'Langkahkan kaki ke kanan.',
          'Rapatkan kaki kiri.',
          'Lakukan gerakan yang sama ke kiri secara berulang.',
        ];

      case 'Wall Push-Up':
        return [
          'Berdiri menghadap dinding.',
          'Letakkan kedua telapak tangan pada dinding.',
          'Tekuk siku dan dekatkan tubuh.',
          'Dorong tubuh kembali hingga lengan lurus.',
        ];

      case 'Marching High Knee':
        return [
          'Berdiri tegak.',
          'Angkat lutut kanan.',
          'Turunkan dan angkat lutut kiri.',
          'Lakukan secara bergantian.',
        ];

      case 'Glute Bridge':
        return [
          'Berbaring dengan lutut ditekuk.',
          'Letakkan kedua kaki di lantai.',
          'Angkat pinggul secara perlahan.',
          'Turunkan kembali dengan terkontrol.',
        ];

      case 'Standing Punch':
        return [
          'Berdiri dengan posisi kaki nyaman.',
          'Tekuk sedikit kedua siku.',
          'Dorong satu tangan ke depan.',
          'Ganti tangan secara bergantian.',
        ];

      case 'Bodyweight Squat':
        return [
          'Berdiri dengan kaki selebar bahu.',
          'Tekuk lutut dan dorong pinggul ke belakang.',
          'Turunkan tubuh dengan kontrol.',
          'Dorong tubuh kembali berdiri.',
        ];

      case 'Reverse Lunge':
        return [
          'Berdiri tegak.',
          'Langkahkan satu kaki ke belakang.',
          'Turunkan tubuh dengan kedua lutut terkontrol.',
          'Kembali berdiri dan ganti kaki.',
        ];

      case 'Incline Push-Up':
        return [
          'Letakkan tangan pada permukaan yang kokoh.',
          'Posisikan tubuh lurus.',
          'Tekuk siku dan turunkan dada.',
          'Dorong tubuh kembali ke posisi awal.',
        ];

      case 'High Knee':
        return [
          'Berdiri tegak.',
          'Angkat lutut kanan.',
          'Turunkan dan segera angkat lutut kiri.',
          'Pertahankan ritme secara terkontrol.',
        ];

      case 'Mountain Climber':
        return [
          'Mulai dari posisi plank.',
          'Bawa lutut kanan ke arah dada.',
          'Kembalikan kaki ke belakang.',
          'Ganti dengan lutut kiri.',
        ];

      case 'Squat + Knee Drive':
        return [
          'Lakukan squat dengan kontrol.',
          'Berdiri kembali.',
          'Angkat satu lutut ke arah dada.',
          'Ulangi dengan sisi lainnya.',
        ];

      case 'Squat Jump':
        return [
          'Mulai dari posisi squat.',
          'Dorong tubuh ke atas.',
          'Mendarat dengan lutut sedikit ditekuk.',
          'Kembali ke posisi squat.',
        ];

      case 'Jumping Lunge':
        return [
          'Mulai dari posisi lunge.',
          'Dorong tubuh ke atas.',
          'Ganti posisi kaki saat di udara.',
          'Mendarat dengan kontrol.',
        ];

      case 'Push-Up':
        return [
          'Mulai dari posisi plank.',
          'Letakkan tangan sedikit lebih lebar dari bahu.',
          'Turunkan dada dengan kontrol.',
          'Dorong tubuh kembali ke atas.',
        ];

      case 'Burpee':
        return [
          'Berdiri tegak.',
          'Turunkan tubuh menuju posisi squat.',
          'Letakkan tangan dan bawa kaki ke belakang.',
          'Kembali berdiri dengan kontrol.',
        ];

      case 'Mountain Climber Cepat':
        return [
          'Mulai dari posisi plank.',
          'Gerakkan lutut kanan ke arah dada.',
          'Ganti dengan lutut kiri.',
          'Pertahankan ritme secara cepat dan terkontrol.',
        ];

      case 'Skater Jump':
        return [
          'Berdiri dengan lutut sedikit ditekuk.',
          'Lompat ke arah kanan.',
          'Mendarat pada kaki kanan.',
          'Lompat ke arah kiri dan ulangi.',
        ];

      default:
        return [
          'Lakukan gerakan sesuai contoh.',
          'Pertahankan posisi tubuh yang baik.',
          'Bernapas secara teratur.',
          'Berhenti jika merasa tidak nyaman.',
        ];
    }
  }

  Widget buildInstructions() {
  final instructions = getInstructions();

  if (instructions.isEmpty) {
    return const SizedBox.shrink();
  }

  final totalRepetitions = currentExercise.repetitions;

  final currentRep = seconds == 0
      ? 1
      : (((seconds * totalRepetitions) /
                      currentExercise.durationSeconds)
                  .floor() +
              1)
          .clamp(1, totalRepetitions);
  


 final instructionIndex =
    ((seconds / 3).floor() % instructions.length);

  final instruction = instructions[instructionIndex];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        const Text(
          'Ikuti gerakan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
       const SizedBox(height: 10),
HomeWorkoutAnimation(
  exerciseName: currentExercise.name,
),
const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.92,
                  end: 1.0,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey('$currentRep-$instructionIndex'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '$currentRep / $totalRepetitions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    if (isResting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Istirahat'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Istirahat',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                '${currentExercise.restSeconds - seconds}',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Bersiap untuk latihan berikutnya',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Olahraga'),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(
              'Level ${widget.level}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Latihan ${currentIndex + 1} dari ${exercises.length}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              currentExercise.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

           Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Column(
    children: [
      Text(
        currentExercise.description,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.grey,
        ),
      ),

      const SizedBox(height: 12),

      Text(
        'Manfaat: ${currentExercise.benefit}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.green,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
),

            const SizedBox(height: 20),

            Text(
              '${currentExercise.repetitions} repetisi',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

           buildInstructions(),

            const SizedBox(height: 25),

            Text(
              '$seconds',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              'detik',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed:
                  isRunning ? stopTimer : startTimer,
              child: Text(
                isRunning ? 'Berhenti' : 'Mulai',
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: resetTimer,
              child: const Text('Reset'),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
class WalkingAnimation extends StatefulWidget {
  const WalkingAnimation({super.key});

  @override
  State<WalkingAnimation> createState() => _WalkingAnimationState();
}

class _WalkingAnimationState extends State<WalkingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final phase = controller.value * 2 * 3.14159;

        return SizedBox(
          height: 220,
          child: CustomPaint(
            painter: WalkingPainter(phase),
            size: const Size(180, 220),
          ),
        );
      },
    );
  }
}

class WalkingPainter extends CustomPainter {
  final double phase;

  WalkingPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1976D2)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final headY = 35.0;
    final bodyTop = 65.0;
    final bodyBottom = 125.0;

    // Kepala
    canvas.drawCircle(
      Offset(centerX, headY),
      18,
      paint,
    );

    // Badan
    canvas.drawLine(
      Offset(centerX, bodyTop),
      Offset(centerX, bodyBottom),
      paint,
    );

    // Gerakan tangan
    final armMovement = 25 * sin(phase);

    canvas.drawLine(
      Offset(centerX, 75),
      Offset(centerX - 35, 105 + armMovement),
      paint,
    );

    canvas.drawLine(
      Offset(centerX, 75),
      Offset(centerX + 35, 105 - armMovement),
      paint,
    );

    // Gerakan kaki
    final legMovement = 30 * sin(phase);

    canvas.drawLine(
      Offset(centerX, bodyBottom),
      Offset(centerX - 25 + legMovement, 175),
      paint,
    );

    canvas.drawLine(
      Offset(centerX, bodyBottom),
      Offset(centerX + 25 - legMovement, 175),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant WalkingPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
class WorkoutCompletePage extends StatefulWidget {
 const WorkoutCompletePage({
  super.key,
  required this.activityName,
  required this.durasiMenit,
  this.durasiDetik,
  this.fotoBukti,
});

final String activityName;
final int durasiMenit;
final int? durasiDetik;
final String? fotoBukti;
  @override
  State<WorkoutCompletePage> createState() => _WorkoutCompletePageState();
}

class _WorkoutCompletePageState extends State<WorkoutCompletePage> {
  bool isSaving = false;
  XFile? proofPhoto;
Future<void> pickProofPhoto(ImageSource source) async {
  final picker = ImagePicker();

  final photo = await picker.pickImage(
    source: source,
    imageQuality: 80,
  );

  if (photo != null) {
    setState(() {
      proofPhoto = photo;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Workout Selesai! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keren! Kamu sudah menyelesaikan latihan hari ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Durasi latihan',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
               Text(
  widget.durasiDetik != null
      ? '${widget.durasiDetik! ~/ 60}:${(widget.durasiDetik! % 60).toString().padLeft(2, '0')}'
      : '${widget.durasiMenit} Menit',
  style: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
),
                const SizedBox(height: 40),
                OutlinedButton.icon(
  onPressed: () {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil Foto dengan Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  pickProofPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  pickProofPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  },
  icon: const Icon(Icons.camera_alt),
  label: const Text('Tambah Foto Bukti'),
),
const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
           onPressed: isSaving
    ? null
    : () async {
        setState(() {
          isSaving = true;
        });

      String? fotoUrl;
String? fotoPublicId;

if (proofPhoto != null) {
  final uploadResult = await uploadProofToCloudinary(
    proofPhoto!.path,
  );

  if (uploadResult != null) {
    fotoUrl = uploadResult['secure_url'];
    fotoPublicId = uploadResult['public_id'];
  }
}
       await saveWorkout(
  durasiMenit: widget.durasiMenit,
  durasiDetik: widget.durasiDetik,
  activityName: widget.activityName,
  fotoBukti: fotoUrl,
    fotoPublicId: fotoPublicId,
);

        if (!context.mounted) return;

        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        );
      },
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Kembali ke Home',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
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
Future<Map<String, String>?> uploadProofToCloudinary(String filePath) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.cloudinary.com/v1_1/wft8wofy/image/upload',
      ),
    );

    request.fields['upload_preset'] = 'kantorfit_bukti';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
      ),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody =
          await response.stream.bytesToString();

      final data = jsonDecode(responseBody);

return {
  'secure_url': data['secure_url'].toString(),
  'public_id': data['public_id'].toString(),
};
    }

    return null;
  } catch (e) {
    return null;
  }
}
Future<void> saveWorkout({
  int durasiMenit = 0,
  int? durasiDetik,
  String activityName = 'Quick Stretch',
  String? fotoBukti,
  String? fotoPublicId,
}) async {
  final prefs = await SharedPreferences.getInstance();

  final today = DateTime.now();
  final todayKey =
    '${today.year}-${today.month}-${today.day}';

final currentSeconds =
    prefs.getInt('dailyActivitySeconds_$todayKey') ?? 0;

await prefs.setInt(
  'dailyActivitySeconds_$todayKey',
  currentSeconds + (durasiDetik ?? (durasiMenit * 60))
);

  // Simpan total workout
  final currentWorkout =
      prefs.getInt('totalWorkout') ?? 0;

  await prefs.setInt(
    'totalWorkout',
    currentWorkout + 1,
  );

  // Simpan riwayat workout di HP
  final history =
      prefs.getStringList('workoutHistory') ?? [];

  final date =
      '${today.day.toString().padLeft(2, '0')}/'
      '${today.month.toString().padLeft(2, '0')}/'
      '${today.year}';

  history.add(
    '$activityName selesai - $date',
  );

  await prefs.setStringList(
    'workoutHistory',
    history,
  );

  // Simpan ke Firestore
  try {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
     FirebaseFirestore.instance
    .collection('workout_history')
    .add({
        'uid': user.uid,
        'nama': user.displayName ?? user.email ?? 'Pengguna',
        'tanggal': Timestamp.fromDate(today),
        'program': activityName,
        'durasi': durasiDetik ?? (durasiMenit * 60),
        'status': 'selesai',
        'fotoBukti': fotoBukti,
        'fotoPublicId': fotoPublicId,
        'verifikasi': 'menunggu',
      });
    }
  } catch (e) {
    // Aktivitas tetap tersimpan di HP
  }
}
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
Future<int> getWeeklyActivitySeconds() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return 0;
  }

  final now = DateTime.now();

  final startOfWeek =
      now.subtract(Duration(days: now.weekday - 1));

  final startDate = DateTime(
    startOfWeek.year,
    startOfWeek.month,
    startOfWeek.day,
  );

  final endDate = startDate.add(
    const Duration(days: 7),
  );

  final snapshot = await FirebaseFirestore.instance
      .collection('workout_history')
      .where('uid', isEqualTo: user.uid)
      .get();

  int totalSeconds = 0;

  for (final doc in snapshot.docs) {
    final data = doc.data();

    final tanggal = data['tanggal'];
    final durasi = data['durasi'];
    final status = data['status'];

    if (tanggal is Timestamp &&
        durasi is num &&
        status == 'selesai') {
      final date = tanggal.toDate();

      if (!date.isBefore(startDate) &&
          date.isBefore(endDate)) {
        totalSeconds += durasi.toInt();
      }
    }
  }

  return totalSeconds;
}
Future<Map<String, int>> getWeeklyActivityByDay() async {
  final user = FirebaseAuth.instance.currentUser;

  final result = {
    'Senin': 0,
    'Selasa': 0,
    'Rabu': 0,
    'Kamis': 0,
    'Jumat': 0,
    'Sabtu': 0,
    'Minggu': 0,
  };

  if (user == null) {
    return result;
  }

  final now = DateTime.now();

  final startOfWeek =
      now.subtract(Duration(days: now.weekday - 1));

  final startDate = DateTime(
    startOfWeek.year,
    startOfWeek.month,
    startOfWeek.day,
  );

  final endDate = startDate.add(
    const Duration(days: 7),
  );

  final snapshot = await FirebaseFirestore.instance
      .collection('workout_history')
      .where('uid', isEqualTo: user.uid)
      .get();

  final namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  for (final doc in snapshot.docs) {
    final data = doc.data();

    final tanggal = data['tanggal'];
    final durasi = data['durasi'];
    final status = data['status'];

    if (tanggal is Timestamp &&
        durasi is num &&
        status == 'selesai') {
      final date = tanggal.toDate();

      if (!date.isBefore(startDate) &&
          date.isBefore(endDate)) {
        final hari = namaHari[date.weekday - 1];

        result[hari] =
            result[hari]! + (durasi.toInt() ~/ 60);
      }
    }
  }

  return result;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Progress Aktivitas'),
      ),
body: SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Progress Aktivitas',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 6),

      const Text(
        'Pantau aktivitas fisikmu',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),

      const SizedBox(height: 20),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.directions_run,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  'Aktivitas Minggu Ini',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

         FutureBuilder<int>(
 future: getWeeklyActivitySeconds(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
  return Text(
    'Error: ${snapshot.error}',
    style: const TextStyle(color: Colors.red),
  );
}
    final seconds = snapshot.data ?? 0;
    final minutes = seconds ~/ 60;

    return Text(
     minutes >= 150
    ? 'Target tercapai 🎉'
    : '$minutes / 150 Menit',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  },
),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
             child: FutureBuilder<int>(
 future: getWeeklyActivitySeconds(),
  builder: (context, snapshot) {
    final seconds = snapshot.data ?? 0;
    final minutes = seconds / 60;

    return LinearProgressIndicator(
      value: (minutes / 150).clamp(0.0, 1.0),
      minHeight: 10,
      backgroundColor: Colors.white30,
      valueColor: const AlwaysStoppedAnimation<Color>(
        Colors.white,
      ),
    );
  },
),
            ),

            const SizedBox(height: 12),

          const Text(
  'Target mingguan: 150 menit aktivitas 🎯',
  style: TextStyle(
    color: Colors.white,
    fontSize: 14,
  ),
),
          ],
        ),
      ),

      const SizedBox(height: 20),
FutureBuilder<Map<String, int>>(
  future: getWeeklyActivityByDay(),
  builder: (context, snapshot) {
    final data = snapshot.data ??
        {
          'Senin': 0,
          'Selasa': 0,
          'Rabu': 0,
          'Kamis': 0,
          'Jumat': 0,
          'Sabtu': 0,
          'Minggu': 0,
        };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas per Hari',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...data.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 65,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (entry.value / 30)
                            .clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1976D2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 55,
                    child: Text(
                      '${entry.value} m',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  },
),

const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.timer,
                    color: Color(0xFF1976D2),
                    size: 30,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Durasi',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                 FutureBuilder<int>(
 future: getWeeklyActivitySeconds(),
  builder: (context, snapshot) {
    final seconds = snapshot.data ?? 0;
    final minutes = seconds ~/ 60;

    return Text(
      '$minutes menit',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  },
),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),


          const SizedBox(width: 12),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.flag,
                    color: Color(0xFF1976D2),
                    size: 30,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Target',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '150 menit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),
    );
  }
}
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(
                Icons.person,
                size: 55,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 20),
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
  future: FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .get(),
  builder: (context, snapshot) {
    String nama = 'Pengguna KantorFit';

    if (snapshot.hasData && snapshot.data!.exists) {
      final data = snapshot.data!.data();
      nama = data?['nama']?.toString() ?? 'Pengguna KantorFit';
    }

    return Text(
      nama,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  },
),
            const SizedBox(height: 8),
            const Text(
              'Sehat di Tengah Kesibukan',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ListTile(
  leading: const Icon(Icons.fitness_center),
  title: const Text('Total Workout'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('workout_history')
      .where('uid', isEqualTo: user.uid)
      .get();

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Total Workout'),
        content: Text(
          'Kamu sudah melakukan ${snapshot.docs.length} aktivitas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
},
),
            ListTile(
  leading: const Icon(Icons.history),
  title: const Text('Riwayat Workout'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutHistoryPage(),
      ),
    );
  },
),
          
 ListTile(
  leading: const Icon(Icons.settings),
  title: const Text('Pengaturan'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
 },
),
ListTile(
  leading: const Icon(Icons.logout),
  title: const Text('Keluar'),
  onTap: () async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  },
),
              
          ],
        ),
      ),
    );
  }
}
class WorkoutHistoryPage extends StatelessWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Silakan login terlebih dahulu.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
  title: const Text('Riwayat Aktivitas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workout_history')
           .where('uid', isEqualTo: user.uid)
.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat riwayat: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat aktivitas',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final data =
                  documents[index].data() as Map<String, dynamic>;

              final tanggal = data['tanggal'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                 leading: CircleAvatar(
  backgroundColor: data['verifikasi'] == 'terverifikasi'
      ? Colors.green.shade100
      : Colors.orange.shade100,
  child: Icon(
    data['verifikasi'] == 'terverifikasi'
        ? Icons.check
        : Icons.hourglass_empty,
    color: data['verifikasi'] == 'terverifikasi'
        ? Colors.green
        : Colors.orange,
  ),
),
                  title: Text(
                    data['program'] ?? 'Workout KantorFit',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Status: ${data['status'] ?? 'selesai'}\n'
                    'Durasi: ${data['durasi'] ?? 0} detik\n'
                    'Tanggal: ${tanggal is Timestamp ? tanggal.toDate() : '-'}',
                  ),
                  onTap: () {
 Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HistoryDetailPage(
      program: data['program'] ?? 'Workout KantorFit',
      status: data['status'] ?? 'selesai',
      durasi: data['durasi'] ?? 0,
      tanggal: tanggal is Timestamp ? tanggal.toDate() : null,
      jarak: data['jarak'] != null
          ? (data['jarak'] as num).toDouble()
          : null,
     routePoints: data['routePoints'] != null
    ? (data['routePoints'] as List)
        .map(
          (point) => LatLng(
            (point['latitude'] as num).toDouble(),
            (point['longitude'] as num).toDouble(),
          ),
        )
      .toList()
    : null,
    ),
),
);
              },
            ),
          );
            },
          );
        },
      ),
    );
  }
}
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool reminderEnabled = true;
  TimeOfDay? reminderTime;
  @override
void initState() {
  super.initState();
  loadReminderSetting();
}

Future<void> loadReminderSetting() async {
  final prefs = await SharedPreferences.getInstance();

  final saved = prefs.getBool('reminderEnabled');
  final hour = prefs.getInt('reminderHour');
  final minute = prefs.getInt('reminderMinute');

  if (!mounted) return;

  setState(() {
    if (saved != null) {
      reminderEnabled = saved;
    }

    if (hour != null && minute != null) {
      reminderTime = TimeOfDay(
        hour: hour,
        minute: minute,
      );
    }
  });
}
Future<void> pilihJamSenam() async {
  int selectedHour = reminderTime?.hour ?? TimeOfDay.now().hour;
  int selectedMinute = reminderTime?.minute ?? TimeOfDay.now().minute;

  final result = await showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Pilih Waktu Alarm Senam'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: selectedHour,
                  items: List.generate(
                    24,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(
                        index.toString().padLeft(2, '0'),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;

                    setDialogState(() {
                      selectedHour = value;
                    });
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: selectedMinute,
                  items: List.generate(
                    60,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(
                        index.toString().padLeft(2, '0'),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;

                    setDialogState(() {
                      selectedMinute = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    TimeOfDay(
                      hour: selectedHour,
                      minute: selectedMinute,
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == null) return;

  setState(() {
    reminderTime = result;
  });

  final prefs = await SharedPreferences.getInstance();

  await prefs.setInt('reminderHour', result.hour);
  await prefs.setInt('reminderMinute', result.minute);

 if (reminderEnabled) {
  await scheduleWorkoutReminder();
  final pending =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();

if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Alarm terdaftar: ${pending.length}',
      ),
    ),
  );
}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm Senam berhasil dijadwalkan'),
        ),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Pengingat Workout'),
            value: reminderEnabled,
          onChanged: (value) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool('reminderEnabled', value);

  setState(() {
    reminderEnabled = value;
  });

if (value && reminderTime != null) {
  await scheduleWorkoutReminder();
}
},
          ),
          ListTile(
  leading: const Icon(Icons.access_time),
  title: const Text('Waktu Alarm Senam'),
  subtitle: Text(
    reminderTime == null
        ? 'Pilih waktu alarm'
        : reminderTime!.format(context),
  ),
  trailing: const Icon(Icons.chevron_right),
  onTap: pilihJamSenam,
),
          ListTile(
  leading: const Icon(Icons.notifications_active),
  title: const Text('Tes Notifikasi'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
showTestNotification();
  },
),
          const Divider(),
          ListTile(
  leading: const Icon(Icons.info_outline),
  title: const Text('Tentang KantorFit'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    showAboutDialog(
      context: context,
      applicationName: 'KantorFit',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Sehat di Tengah Kesibukan',
    );
  },
),
        ],
      ),
    );
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  

  bool isLoading = false;

  Future<void> login() async {
    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

     if (!mounted) return;

final user = FirebaseAuth.instance.currentUser;

if (user?.uid == 'nNvJ2ANDdaOOx6iGla37DkcBuNk2') {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const AdminPage(),
    ),
  );
} else {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const HomePage(),
    ),
  );
} 
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Login gagal',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login KantorFit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
  controller: namaController,
  decoration: const InputDecoration(
    labelText: 'Nama Pengguna',
    prefixIcon: Icon(Icons.person),
  ),
),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Masuk'),
              ),
            ),
            const SizedBox(height: 12),

TextButton(
  onPressed: () async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({
    'nama': namaController.text.trim(),
    'email': emailController.text.trim(),
  });
}

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat! Silakan masuk.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Gagal membuat akun'),
        ),
      );
    }
  },
  child: const Text('Belum punya akun? Daftar'),
),
          ],
        ),
      ),
    );
  }
}
class HistoryDetailPage extends StatelessWidget {
  final String program;
  final String status;
  final dynamic durasi;
  final DateTime? tanggal;
  final double? jarak;
  final List<LatLng>? routePoints;

  const HistoryDetailPage({
    super.key,
    required this.program,
    required this.status,
    required this.durasi,
    required this.tanggal,
    this.jarak,
    this.routePoints,
  });

  String formatDistance() {
    if (jarak == null) {
      return '-';
    }

    if (jarak! < 1000) {
      return '${jarak!.toStringAsFixed(0)} m';
    }

    return '${(jarak! / 1000).toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute =
        routePoints != null && routePoints!.isNotEmpty;

    final mapCenter = hasRoute
        ? routePoints!.first
        : const LatLng(-0.9471, 100.4172);

    return Scaffold(
      appBar: AppBar(
   title: const Text('Detail Aktivitas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 60,
              color: Color(0xFF1976D2),
            ),

            const SizedBox(height: 24),

            const Text(
              'Program',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              program,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Status',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              status,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Durasi',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 4),

            Text(
  '${(durasi as int) ~/ 60}:${((durasi as int) % 60).toString().padLeft(2, '0')}',  
  style: const TextStyle(
    fontSize: 18,
  ),
),
            const SizedBox(height: 24),

            const Text(
              'Jarak',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              formatDistance(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Tanggal',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              tanggal != null
                  ? '${tanggal!.day}/${tanggal!.month}/${tanggal!.year}'
                  : '-',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            if (hasRoute) ...[
              const SizedBox(height: 30),

              const Text(
                'Peta Rute',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 350,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 17,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.flutter_application_1',
                      ),

                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints!,
                            strokeWidth: 5,
                          ),
                        ],
                      ),

                      MarkerLayer(
                        markers: [
                          Marker(
                            point: routePoints!.first,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.green,
                            ),
                          ),
                          Marker(
                            point: routePoints!.last,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class RunPage extends StatefulWidget {
  const RunPage({super.key});

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  final MapController mapController = MapController();

  Position? currentPosition;
  StreamSubscription<Position>? positionSubscription;

  bool isRunning = false;
  File? proofPhoto;
  Future<void> takeProofPhoto() async {
  final picker = ImagePicker();

  final photo = await picker.pickImage(
    source: ImageSource.camera,
  );

  if (photo == null) return;

  setState(() {
    proofPhoto = File(photo.path);
  });
}
  int seconds = 0;
  double distanceMeters = 0;
  List<Position> routePoints = [];

  Timer? timer;

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aktifkan GPS/lokasi di HP terlebih dahulu.',
            ),
          ),
        );
      }
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak.'),
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi ditolak permanen. Aktifkan melalui Pengaturan HP.',
            ),
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> startRun() async {
    final permissionGranted =
        await checkLocationPermission();

    if (!permissionGranted) return;

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    setState(() {
      currentPosition = position;
      routePoints = [position];
      isRunning = true;
      seconds = 0;
      distanceMeters = 0;
    });

    mapController.move(
      LatLng(
        position.latitude,
        position.longitude,
      ),
      17,
    );

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || !isRunning) return;

        setState(() {
          seconds++;
        });
      },
    );

    positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted || !isRunning) return;

 if (position.accuracy > 50) {
  return;
}
      if (currentPosition != null) {
        final distance =
            Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );

       if (distance >= 10) {
          distanceMeters += distance;
          routePoints.add(position);

          setState(() {
            currentPosition = position;
          });

          mapController.move(
            LatLng(
              position.latitude,
              position.longitude,
            ),
            17,
          );
        }
      } else {
        setState(() {
          currentPosition = position;
          routePoints.add(position);
        });
      }
    });
  }

Future<void> stopRun() async {
  timer?.cancel();
  timer = null;

  positionSubscription?.cancel();
  positionSubscription = null;

  setState(() {
    isRunning = false;
  });

  try {
    String? fotoUrl;
String? fotoPublicId;

if (proofPhoto != null) {
  final uploadResult = await uploadProofToCloudinary(
    proofPhoto!.path,
  );

  if (uploadResult != null) {
    fotoUrl = uploadResult['secure_url'];
    fotoPublicId = uploadResult['public_id'];
  }
}
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final route = routePoints.map((point) {
        return {
          'latitude': point.latitude,
          'longitude': point.longitude,
        };
      }).toList();

     await FirebaseFirestore.instance
    .collection('workout_history')
    .add({
  'uid': user.uid,
  'fotoBukti': fotoUrl,
  'fotoPublicId': fotoPublicId,
        'tanggal': Timestamp.now(),
        'program': 'Lari',
        'durasi': seconds,
        'jarak': distanceMeters,
        'status': 'selesai',
        'verifikasi': 'menunggu',
        'routePoints': route,
      });
    }
  } catch (e) {
    // Abaikan error penyimpanan agar aktivitas tetap bisa berhenti.
  }
final prefs = await SharedPreferences.getInstance();

  final today = DateTime.now();
  final todayKey =
      '${today.year}-${today.month}-${today.day}';

  final currentSeconds =
      prefs.getInt('dailyActivitySeconds_$todayKey') ?? 0;

  await prefs.setInt(
    'dailyActivitySeconds_$todayKey',
    currentSeconds + seconds,
  );
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Lari selesai • ${formatTime(seconds)} • ${formatDistance()}',
      ),
    ),
  );
}
  String formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes =
        (totalSeconds % 3600) ~/ 60;
    final remainingSeconds =
        totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String formatDistance() {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }
  String formatPace() {
  if (distanceMeters < 10) {
    return '-';
  }

  final distanceKm = distanceMeters / 1000;
  final paceSeconds = seconds / distanceKm;

  final minutes = paceSeconds ~/ 60;
  final remainingSeconds = paceSeconds.round() % 60;

  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainingSeconds.toString().padLeft(2, '0')} /km';
}

  @override
  void dispose() {
    timer?.cancel();
    positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = currentPosition != null
        ? LatLng(
            currentPosition!.latitude,
            currentPosition!.longitude,
          )
        : const LatLng(-0.9471, 100.4172);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lari'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 17,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.flutter_application_1',
                ),
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints
                            .map(
                              (point) => LatLng(
                                point.latitude,
                                point.longitude,
                              ),
                            )
                            .toList(),
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                if (currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        ),
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          size: 45,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
             padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'Aktivitas Lari',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatTime(seconds),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatDistance(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Jarak'),
                  const SizedBox(height: 12),
Text(
  formatPace(),
  style: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 4),
const Text('Pace'),
                  const SizedBox(height: 16),
                  if (isRunning && seconds >= 600)
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: takeProofPhoto,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Ambil Foto Bukti'),
    ),
  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isRunning ? stopRun : startRun,
                      child: Text(
                        isRunning
                            ? 'Berhenti'
                            : 'Mulai Lari',
                      ),
                    ),
                  ), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class WalkingPage extends StatefulWidget {
  const WalkingPage({super.key});

  @override
  State<WalkingPage> createState() => _WalkingPageState();
}

class _WalkingPageState extends State<WalkingPage> {
  int seconds = 0;
  Timer? timer;
  bool isRunning = false;
  Position? currentPosition;
  Position? previousPosition;
StreamSubscription<Position>? positionSubscription;
double distanceMeters = 0;
  

 Future<void> startTimer() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

if (!serviceEnabled) {
  return;
}

LocationPermission permission =
    await Geolocator.checkPermission();

if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}

if (permission == LocationPermission.denied ||
    permission == LocationPermission.deniedForever) {
  return;
}
previousPosition = null;
distanceMeters = 0;
    timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        seconds++;
      });
    });
positionSubscription = Geolocator.getPositionStream(
 locationSettings: const LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 1,
),
).listen((position) {

 if (position.accuracy > 20) {
  return;
}

  if (previousPosition != null) {
    final distance = Geolocator.distanceBetween(
      previousPosition!.latitude,
      previousPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    if (distance >= 10) {
      distanceMeters += distance;
    }
  }

  previousPosition = position;

  setState(() {
    currentPosition = position;
  });
});
    setState(() {
      isRunning = true;
    });
  }

 Future<void> stopTimer() async {
  timer?.cancel();
  timer = null;

  setState(() {
    isRunning = false;
  });

  final prefs = await SharedPreferences.getInstance();

  final today = DateTime.now();
  final todayKey =
      '${today.year}-${today.month}-${today.day}';

  final currentSeconds =
      prefs.getInt('dailyActivitySeconds_$todayKey') ?? 0;

  await prefs.setInt(
    'dailyActivitySeconds_$todayKey',
    currentSeconds + seconds,
  );
  if (!mounted) return;

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WorkoutCompletePage(
  activityName: 'Quick Stretch',
  durasiMenit: 5,
) 
  ),
);
}

  String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jalan Santai'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_walk,
              size: 80,
              color: Color(0xFF1976D2),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aktivitas Jalan Santai',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Target aktivitas minimal 30 menit per hari',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Text(
              formatTime(seconds),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

Text(
  '${distanceMeters.toStringAsFixed(0)} m',
  style: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isRunning ? stopTimer : startTimer,
                child: Text(
                  isRunning ? 'Berhenti' : 'Mulai Jalan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class BasicSportPage extends StatelessWidget {
  const BasicSportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olahraga di Rumah'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Olahraga di Rumah',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Latihan sederhana tanpa alat yang dapat membantu '
            'meningkatkan aktivitas fisik dan mendukung pengelolaan berat badan.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Pilih Level',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          // PEMULA
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(
                Icons.directions_walk,
                size: 40,
                color: Color(0xFF1976D2),
              ),
              title: const Text(
                'Pemula',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Latihan ringan selama 10 menit',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeWorkoutProgramPage(
                      level: 'Pemula',
                      targetMinutes: 10,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // MENENGAH
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(
                Icons.fitness_center,
                size: 40,
                color: Color(0xFF1976D2),
              ),
              title: const Text(
                'Menengah',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Latihan dengan intensitas sedang selama 15 menit',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeWorkoutProgramPage(
                      level: 'Menengah',
                      targetMinutes: 15,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // LANJUTAN
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(
                Icons.directions_run,
                size: 40,
                color: Color(0xFF1976D2),
              ),
              title: const Text(
                'Lanjutan',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Latihan lebih menantang selama 20 menit',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeWorkoutProgramPage(
                      level: 'Lanjutan',
                      targetMinutes: 20,
                    ),
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
class HomeWorkoutProgramPage extends StatefulWidget {
  const HomeWorkoutProgramPage({
    super.key,
    required this.level,
    required this.targetMinutes,
  });

  final String level;
  final int targetMinutes;

  @override
  State<HomeWorkoutProgramPage> createState() =>
      _HomeWorkoutProgramPageState();
}

class _HomeWorkoutProgramPageState
    extends State<HomeWorkoutProgramPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final program = getHomeWorkoutProgram(widget.level);

      if (program.isEmpty) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutTimerPage(
            activityName: program.first.name,
            exercises: program,
            currentIndex: 0,
            level: widget.level,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.level}'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
class HomeWorkoutExercise {
  final String name;
  final String description;
  final String benefit;
  final int repetitions;
  final int durationSeconds;
  final int restSeconds;

  const HomeWorkoutExercise({
    required this.name,
    required this.description,
    required this.benefit,
    required this.repetitions,
    required this.durationSeconds,
    required this.restSeconds,
  });
}

List<HomeWorkoutExercise> getHomeWorkoutProgram(String level) {
  switch (level) {
    case 'Pemula':
      return const [
        HomeWorkoutExercise(
          name: 'Squat ke Kursi',
          description:
              'Turunkan tubuh perlahan hingga menyentuh kursi, lalu berdiri kembali.',
          benefit:
              'Melatih kekuatan otot paha dan bokong serta membantu meningkatkan kekuatan tubuh bagian bawah.',
          repetitions: 10,
          durationSeconds: 60,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Step Touch Cepat',
          description:
              'Langkahkan kaki ke kanan dan kiri dengan tempo teratur.',
          benefit:
              'Meningkatkan aktivitas aerobik ringan serta melatih koordinasi dan kemampuan bergerak.',
          repetitions: 20,
          durationSeconds: 60,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Wall Push-Up',
          description:
              'Dorong tubuh ke arah dinding lalu kembali ke posisi awal.',
          benefit:
              'Melatih kekuatan otot dada, bahu, dan lengan dengan beban tubuh yang relatif ringan.',
          repetitions: 10,
          durationSeconds: 60,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Marching High Knee',
          description:
              'Angkat lutut secara bergantian dengan tempo yang nyaman.',
          benefit:
              'Meningkatkan aktivitas aerobik serta melatih koordinasi dan kekuatan otot tungkai.',
          repetitions: 20,
          durationSeconds: 60,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Glute Bridge',
          description:
              'Berbaring, tekuk lutut, lalu angkat pinggul secara perlahan.',
          benefit:
              'Melatih otot bokong dan otot belakang paha serta membantu meningkatkan kekuatan tubuh bagian bawah.',
          repetitions: 10,
          durationSeconds: 60,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Standing Punch',
          description:
              'Lakukan pukulan bergantian ke depan sambil menjaga posisi tubuh.',
          benefit:
              'Melatih koordinasi gerak serta melibatkan otot bahu dan lengan dalam aktivitas berulang.',
          repetitions: 20,
          durationSeconds: 60,
          restSeconds: 20,
        ),
      ];

    case 'Menengah':
      return const [
        HomeWorkoutExercise(
          name: 'Bodyweight Squat',
          description:
              'Lakukan squat dengan kontrol dan rentang gerak yang nyaman.',
          benefit:
              'Meningkatkan kekuatan otot paha dan bokong serta mendukung kemampuan melakukan aktivitas fungsional.',
          repetitions: 12,
          durationSeconds: 90,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Reverse Lunge',
          description:
              'Langkahkan satu kaki ke belakang lalu kembali berdiri.',
          benefit:
              'Melatih kekuatan otot tungkai dan bokong serta membantu melatih keseimbangan dan koordinasi.',
          repetitions: 10,
          durationSeconds: 90,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Incline Push-Up',
          description:
              'Lakukan push-up dengan tangan bertumpu pada permukaan yang kokoh.',
          benefit:
              'Melatih kekuatan otot dada, bahu, dan lengan dengan intensitas yang dapat disesuaikan melalui ketinggian tumpuan.',
          repetitions: 10,
          durationSeconds: 90,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'High Knee',
          description:
              'Angkat lutut secara bergantian dengan tempo lebih cepat.',
          benefit:
              'Meningkatkan aktivitas kardiorespirasi serta melatih koordinasi dan kekuatan otot tungkai.',
          repetitions: 24,
          durationSeconds: 90,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Mountain Climber',
          description:
              'Dari posisi plank, gerakkan lutut bergantian ke arah dada.',
          benefit:
              'Melatih otot inti, bahu, dan tungkai sekaligus meningkatkan tuntutan kardiorespirasi.',
          repetitions: 20,
          durationSeconds: 90,
          restSeconds: 20,
        ),
        HomeWorkoutExercise(
          name: 'Squat + Knee Drive',
          description:
              'Lakukan squat kemudian angkat lutut secara bergantian.',
          benefit:
              'Menggabungkan latihan kekuatan tungkai dengan gerakan dinamis untuk melatih koordinasi dan kebugaran kardiorespirasi.',
          repetitions: 10,
          durationSeconds: 90,
          restSeconds: 20,
        ),
      ];

    case 'Lanjutan':
      return const [
        HomeWorkoutExercise(
          name: 'Squat Jump',
          description:
              'Lakukan squat kemudian dorong tubuh ke atas dengan lompatan.',
          benefit:
              'Melatih kekuatan dan daya ledak otot tungkai serta meningkatkan tuntutan kardiorespirasi.',
          repetitions: 12,
          durationSeconds: 120,
          restSeconds: 30,
        ),
        HomeWorkoutExercise(
          name: 'Jumping Lunge',
          description:
              'Lakukan lunge dengan pergantian kaki melalui lompatan.',
          benefit:
              'Melatih kekuatan dan daya ledak otot tungkai serta koordinasi gerakan.',
          repetitions: 12,
          durationSeconds: 120,
          restSeconds: 30,
        ),
        HomeWorkoutExercise(
          name: 'Push-Up',
          description:
              'Turunkan dada dengan kontrol lalu dorong tubuh kembali.',
          benefit:
              'Melatih kekuatan otot dada, bahu, lengan, dan otot inti untuk mempertahankan posisi tubuh.',
          repetitions: 12,
          durationSeconds: 120,
          restSeconds: 30,
        ),
        HomeWorkoutExercise(
          name: 'Burpee',
          description:
              'Lakukan rangkaian turun ke posisi plank, kembali berdiri, lalu dorong tubuh ke atas.',
          benefit:
              'Melibatkan banyak kelompok otot sekaligus dan meningkatkan tuntutan kardiorespirasi serta kemampuan tubuh bergerak secara dinamis.',
          repetitions: 8,
          durationSeconds: 120,
          restSeconds: 30,
        ),
        HomeWorkoutExercise(
          name: 'Mountain Climber Cepat',
          description:
              'Gerakkan lutut bergantian ke arah dada dengan tempo cepat.',
          benefit:
              'Melatih otot inti dan tungkai sekaligus memberikan tuntutan kardiorespirasi yang lebih tinggi.',
          repetitions: 30,
          durationSeconds: 120,
          restSeconds: 30,
        ),
        HomeWorkoutExercise(
          name: 'Skater Jump',
          description:
              'Lakukan lompatan menyamping secara bergantian dengan kontrol.',
          benefit:
              'Melatih kekuatan dan daya ledak tungkai serta koordinasi dan kemampuan bergerak ke arah samping.',
          repetitions: 16,
          durationSeconds: 120,
          restSeconds: 30,
        ),
      ];

    default:
      return const [];
  }
}
class SenamBersamaPage extends StatefulWidget {
  const SenamBersamaPage({super.key});

  @override
  State<SenamBersamaPage> createState() =>
      _SenamBersamaPageState();
}

class _SenamBersamaPageState
    extends State<SenamBersamaPage> {
static const double kantorLatitude = -0.939224;
static const double kantorLongitude = 100.365859;
static const double radiusMeter = 50;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senam Bersama Kantor'),
      ),
     body: Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.groups,
          size: 80,
          color: Color(0xFF1976D2),
        ),
        const SizedBox(height: 20),
        const Text(
          'Senam Bersama Kantor',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Pastikan kamu berada di area senam kantor.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () async {
            final valid = await cekLokasiKantor();

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  valid
                      ? 'Lokasi valid. Kamu bisa memulai senam.'
                      : 'Lokasi tidak valid atau izin GPS belum tersedia.',
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Mulai Senam'),
        ),
      ],
    ),
  ),
),
    );
  }
  Future<bool> cekLokasiKantor() async {
  final izin = await Geolocator.checkPermission();

  if (izin == LocationPermission.denied ||
      izin == LocationPermission.deniedForever) {
    return false;
  }

  final posisi = await Geolocator.getCurrentPosition();

  final jarak = Geolocator.distanceBetween(
    posisi.latitude,
    posisi.longitude,
    kantorLatitude,
    kantorLongitude,
  );

  return jarak <= radiusMeter;
}
}