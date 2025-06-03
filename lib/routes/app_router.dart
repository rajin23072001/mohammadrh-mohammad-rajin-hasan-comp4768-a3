import 'package:go_router/go_router.dart';
import '../screens/list_screen.dart';
import '../screens/add_edit_screen.dart';
import '../screens/charts_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const ListScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (_, __) => const AddEditScreen(),
        ),
        GoRoute(
          path: 'edit/:index',
          builder: (_, state) {
            final idx = int.tryParse(state.pathParameters['index'] ?? '');
            return AddEditScreen(index: idx);
          },
        ),
        GoRoute(
          path: 'charts',
          builder: (_, __) => const ChartsScreen(),
        ),
      ],
    ),
  ],
);