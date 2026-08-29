import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../api/repository.dart';
import '../models/category.dart';
import '../models/summary.dart';
import '../models/transaction.dart';

enum LoadState { idle, loading, loaded, error }

enum TypeFilter { all, income, expense }

class FinanceState extends ChangeNotifier {
  final _repo = financeRepository;

  LoadState categoriesState = LoadState.idle;
  LoadState transactionsState = LoadState.idle;
  LoadState summaryState = LoadState.idle;
  String? error;

  List<Category> categories = [];
  List<Transaction> transactions = [];
  Summary? summary;

  TypeFilter typeFilter = TypeFilter.all;
  int? categoryFilter;
  String searchQuery = '';
  bool filtersActive = false;

  DateTime? _monthAnchor;

  DateTime? get monthAnchor => _monthAnchor;

  List<Transaction> get visibleTransactions {
    Iterable<Transaction> result = transactions;
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((t) =>
          t.note.toLowerCase().contains(q) ||
          (t.category?.name.toLowerCase().contains(q) ?? false));
    }
    return result.toList();
  }

  void _fail(Object e) {
    error = e.toString();
  }

  Future<void> loadAll() async {
    await Future.wait([loadCategories(), loadTransactions(), loadSummary()]);
  }

  Future<void> loadCategories() async {
    categoriesState = LoadState.loading;
    notifyListeners();
    try {
      categories = await _repo.listCategories();
      categoriesState = LoadState.loaded;
    } catch (e) {
      categoriesState = LoadState.error;
      _fail(e);
    }
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    transactionsState = LoadState.loading;
    notifyListeners();
    try {
      final anchor = _monthAnchor;
      transactions = await _repo.listTransactions(
        type: typeFilter == TypeFilter.all ? null : typeFilter.toTxnType(),
        categoryId: categoryFilter,
        fromDate: anchor != null ? DateTime(anchor.year, anchor.month, 1) : null,
        toDate: anchor != null
            ? DateTime(anchor.year, anchor.month + 1, 0)
            : null,
      );
      transactionsState = LoadState.loaded;
      error = null;
    } catch (e) {
      transactionsState = LoadState.error;
      _fail(e);
    }
    notifyListeners();
  }

  Future<void> loadSummary() async {
    summaryState = LoadState.loading;
    notifyListeners();
    try {
      summary = await _repo.summary();
      summaryState = LoadState.loaded;
      error = null;
    } catch (e) {
      summaryState = LoadState.error;
      _fail(e);
    }
    notifyListeners();
  }

  Future<bool> saveTransaction(Transaction txn) async {
    try {
      await _repo.createTransaction(txn);
      await Future.wait([loadTransactions(), loadSummary()]);
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> editTransaction(int id, Transaction txn) async {
    try {
      await _repo.updateTransaction(id, txn);
      await Future.wait([loadTransactions(), loadSummary()]);
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> removeTransaction(int id) async {
    try {
      await _repo.deleteTransaction(id);
      await Future.wait([loadTransactions(), loadSummary()]);
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  // ---------- Categories ----------

  Future<bool> createCategory(
      {required String name, required String color, String icon = 'label'}) async {
    try {
      await _repo.createCategory(name: name, color: color, icon: icon);
      await loadCategories();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> updateCategory(int id,
      {required String name, required String color, String icon = 'label'}) async {
    try {
      await _repo.updateCategory(id, name: name, color: color, icon: icon);
      await Future.wait([loadCategories(), loadTransactions()]);
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _repo.deleteCategory(id);
      await Future.wait([loadCategories(), loadTransactions(), loadSummary()]);
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  // ---------- Budgets ----------

  Future<bool> setBudget(int categoryId, double limit) async {
    try {
      await _repo.setBudget(categoryId, limit);
      await loadSummary();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> deleteBudget(int categoryId) async {
    try {
      await _repo.deleteBudget(categoryId);
      await loadSummary();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  // ---------- Filters ----------

  void setTypeFilter(TypeFilter f) {
    typeFilter = f;
    filtersActive = true;
    loadTransactions();
  }

  void setCategoryFilter(int? categoryId) {
    categoryFilter = categoryId;
    filtersActive = true;
    loadTransactions();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setMonth(DateTime? anchor) {
    _monthAnchor = anchor;
    filtersActive = anchor != null;
    loadTransactions();
  }

  void clearFilters() {
    typeFilter = TypeFilter.all;
    categoryFilter = null;
    _monthAnchor = null;
    searchQuery = '';
    filtersActive = false;
    loadTransactions();
  }
}

extension TypeFilterX on TypeFilter {
  TxnType? toTxnType() =>
      this == TypeFilter.all ? null : TxnType.values.byName(name);
}
