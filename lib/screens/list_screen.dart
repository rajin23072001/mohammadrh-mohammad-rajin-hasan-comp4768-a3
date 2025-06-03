// ===== imports (MUST be at the very top) =========================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ===== widget =====================================================
class ListScreen extends ConsumerWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () => context.push('/charts'),
          ),
        ],
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No expenses yet'))
          : ListView.separated(
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = expenses[index];
                return ListTile(
                  title: Text(e.description),
                  subtitle: Text(
                    '${DateFormat.yMMMd().format(e.date)} • ${e.category}',
                  ),
                  trailing: Text(currency.format(e.amount)),
                  onTap: () => context.push('/edit/$index'),
                  onLongPress: () =>
                      ref.read(expensesProvider.notifier).remove(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
