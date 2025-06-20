import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:student_planner/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:student_planner/screens/auth/login_screen.dart';
import 'package:student_planner/screens/auth/register_screen.dart';
import 'package:student_planner/screens/calendar/bloc/bloc.dart';
import 'package:student_planner/screens/calendar/create_event_screen.dart';
import 'package:student_planner/screens/calendar/view_event.dart';
import 'package:student_planner/screens/home/home_screen.dart';
import 'package:student_planner/services/event_repo.dart';
import 'screens/auth/bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'screens/profile/bloc/bloc.dart';
import 'services/locale_notification.dart';
import 'services/review_repo.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void onTapLocalNotification(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (payload != null && payload.isNotEmpty) {
    // Переходимо на сторінку деталей події, передаючи ID події
    // navigatorKey.currentState?.push(
    //   MaterialPageRoute(
    //     builder: (context) => ViewEventPage(event: payload),
    //   ),
    // );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LocalNotificationService().initialize();

  // // Ініціалізація для сповіщень
  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('app_icon');
  // const DarwinInitializationSettings initializationSettingsIOS =
  //     DarwinInitializationSettings(
  //         requestAlertPermission: true,
  //         requestBadgePermission: true,
  //         requestSoundPermission: true);

  // const InitializationSettings initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  // await flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  //   onDidReceiveNotificationResponse: onTapLocalNotification,
  //   // onDidReceiveBackgroundNotificationResponse:
  //   //     (NotificationResponse notificationResponse) async {
  //   //   final String? payload = notificationResponse.payload;
  //   //   if (payload != null && payload.isNotEmpty) {
  //   //     // Обробка для фонового режиму (може потребувати окремої логіки для ініціалізації Navigator)
  //   //     // Для більш складних сценаріїв у фоновому режимі може знадобитися flutter_background_service
  //   //     // або спеціалізована обробка в ізоляті.
  //   //     debugPrint('Background Notification tapped with payload: $payload');
  //   //   }
  //   // },
  // );

  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => EventRepository()),
        RepositoryProvider(create: (_) => ReviewRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>(create: (context) => AppBloc()),
          BlocProvider(
            create: (context) => EventBloc(
              eventRepository: RepositoryProvider.of<EventRepository>(context),
              flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
            ),
          ),
          BlocProvider<ReviewBloc>(
            create: (context) => ReviewBloc(
              reviewRepository: context.read<ReviewRepository>(),
            ),
          ),
        ],
        child: InitialPermissionScreen(
          child: BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              if (state.status == "authenticated") {
                return MaterialApp(
                  title: 'Student Events',
                  theme: FlexThemeData.light(
                    scheme: FlexScheme.flutterDash,
                    // useMaterial3: true,
                    fontFamily: GoogleFonts.lato().fontFamily,
                    blendLevel: 7,
                  ),
                  debugShowCheckedModeBanner: false,
                  home: HomeScreen(),
                  routes: {
                    '/register': (context) => const RegisterPage(),
                    '/login': (context) => const LoginScreen(),
                    // '/profile': (context) => const ProfileScreen(),
                    '/home': (context) => const HomeScreen(),
                    '/create_event': (context) => const CreateEventScreen(),
                  },
                );
              } else {
                return MaterialApp(
                  navigatorKey: navigatorKey,
                  title: 'Student Events',
                  theme: FlexThemeData.light(
                    scheme: FlexScheme.flutterDash,
                    // useMaterial3: true,
                    fontFamily: GoogleFonts.lato().fontFamily,
                    blendLevel: 7,
                  ),
                  debugShowCheckedModeBanner: false,
                  home: LoginScreen(),
                  routes: {
                    '/register': (context) => const RegisterPage(),
                    '/login': (context) => const LoginScreen(),
                    '/home': (context) => const HomeScreen(),
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class InitialPermissionScreen extends StatefulWidget {
  final Widget child; // Віджет, який буде показаний після запиту дозволу

  const InitialPermissionScreen({super.key, required this.child});

  @override
  State<InitialPermissionScreen> createState() =>
      _InitialPermissionScreenState();
}

class _InitialPermissionScreenState extends State<InitialPermissionScreen> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    // Викликаємо метод запиту дозволу з BuildContext
    await LocalNotificationService().requestPermissions(context);
  }

  @override
  Widget build(BuildContext context) {
    // Просто показуємо дочірній віджет
    return widget.child;
  }
}
