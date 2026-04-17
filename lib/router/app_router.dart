import 'package:go_router/go_router.dart';
import '../screens/main_shell.dart';
import '../screens/my_proxies_screen.dart';
import '../screens/history_screen.dart';
import '../screens/online_screen.dart';
import '../screens/offline_screen.dart';

final router = GoRouter(
  initialLocation: '/proxies',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(
        navigationShell: navigationShell,
      ),
      branches: [
        // Ветка 1: Мои прокси
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/proxies',
              name: 'proxies',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MyProxiesScreen(),
              ),
            ),
          ],
        ),
        // Ветка 2: Вся история
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              name: 'history',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HistoryScreen(),
              ),
            ),
          ],
        ),
        // Ветка 3: Доступные
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/online',
              name: 'online',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: OnlineScreen(),
              ),
            ),
          ],
        ),
        // Ветка 4: Недоступные
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/offline',
              name: 'offline',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: OfflineScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);