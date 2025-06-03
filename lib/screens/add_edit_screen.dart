import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

class AddEditScreen extends ConsumerStatefulWidget {
  final int? index;
  const AddEditScreen({super.key, this.index});

  @override
  ConsumerState<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends ConsumerState<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descCtrl;
  late TextEditingController _amountCtrl;
  DateTime _date = DateTime.now();
  String _category = 'General';

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      final e = ref.read(expensesProvider)[widget.index!];
      _descCtrl = TextEditingController(text: e.description);
      _amountCtrl = TextEditingController(text: e.amount.toString());
      _date = e.date;
      _category = e.category;
    } else {
      _descCtrl = TextEditingController();
      _amountCtrl = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.index == null ? 'Add Expense' : 'Edit Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /* ---- Description ---- */
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter description' : null,
              ),

              /* ---- Amount ---- */
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Amount must be > 0';
                  }
                  return null;
                },
              ),

              /* ---- Date picker ---- */
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat.yMd().format(_date)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _date,
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),

              /* ---- Category dropdown (updated) ---- */
              DropdownButtonFormField<String>(
                value: _category,
                items: [
                  'General',
                  'Food',
                  'Transport',
                  'Bills',
                  'Entertainment',
                  'Utility',
                  'Shopping',
                  'Education',
                ]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'General'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),

              const SizedBox(height: 24),

              /* ---- Save button ---- */
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final expense = Expense(
                      description: _descCtrl.text,
                      amount: double.parse(_amountCtrl.text),
                      date: _date,
                      category: _category,
                    );
                    if (widget.index == null) {
                      ref.read(expensesProvider.notifier).add(expense);
                    } else {
                      ref
                          .read(expensesProvider.notifier)
                          .update(widget.index!, expense);
                    }
                    context.pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
