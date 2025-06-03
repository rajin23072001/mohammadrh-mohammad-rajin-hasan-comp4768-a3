import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier();
});

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<Expense>('expensesBox');

  void _load() => state = _box.values.toList();

  Future<void> add(Expense e) async {
    await _box.add(e);
    _load();
  }

  Future<void> update(int index, Expense e) async {
    await _box.putAt(index, e);
    _load();
  }

  Future<void> remove(int index) async {
    await _box.deleteAt(index);
    _load();
  }
}
