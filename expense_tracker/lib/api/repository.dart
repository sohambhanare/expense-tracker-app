import '../config.dart';
import '../models/category.dart';
import '../models/summary.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import 'api_client.dart';

class FinanceRepository {
  final ApiClient client;

  FinanceRepository(this.client);

  // ---------- Auth ----------

  Future<({String token, AppUser user})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    return _tokenResult(data);
  }

  Future<({String token, AppUser user})> login({
    required String email,
    required String password,
  }) async {
    final data = await client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _tokenResult(data);
  }

  Future<AppUser> me() async =>
      AppUser.fromJson(await client.get('/auth/me') as Map<String, dynamic>);

  ({String token, AppUser user}) _tokenResult(dynamic data) {
    final map = data as Map<String, dynamic>;
    return (
      token: map['access_token'] as String,
      user: AppUser.fromJson(map['user'] as Map<String, dynamic>),
    );
  }

  // ---------- Transactions ----------

  Future<List<Transaction>> listTransactions({
    TxnType? type,
    int? categoryId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 500,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      if (type != null) 'type': type.name,
      if (categoryId != null) 'category_id': '$categoryId',
      if (fromDate != null) 'from_date': _date(fromDate),
      if (toDate != null) 'to_date': _date(toDate),
    };
    final data = await client.get('/transactions', query: query) as List<dynamic>;
    return data.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Transaction> createTransaction(Transaction t) async =>
      Transaction.fromJson(await client.post('/transactions', body: t.toRequestJson())
          as Map<String, dynamic>);

  Future<Transaction> updateTransaction(int id, Transaction t) async =>
      Transaction.fromJson(
          await client.put('/transactions/$id', body: t.toRequestJson())
              as Map<String, dynamic>);

  Future<void> deleteTransaction(int id) => client.delete('/transactions/$id');

  // ---------- Categories ----------

  Future<List<Category>> listCategories() async {
    final data = await client.get('/categories') as List<dynamic>;
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Category> createCategory({
    required String name,
    required String color,
    String icon = 'label',
  }) async =>
      Category.fromJson(await client.post('/categories', body: {
        'name': name,
        'color': color,
        'icon': icon,
      }) as Map<String, dynamic>);

  Future<Category> updateCategory(int id,
          {required String name, required String color, String icon = 'label'}) async =>
      Category.fromJson(await client.put('/categories/$id', body: {
        'name': name,
        'color': color,
        'icon': icon,
      }) as Map<String, dynamic>);

  Future<void> deleteCategory(int id) => client.delete('/categories/$id');

  // ---------- Budgets ----------

  Future<List<Budget>> listBudgets() async {
    final data = await client.get('/budgets') as List<dynamic>;
    return data.map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Budget> setBudget(int categoryId, double monthlyLimit) async =>
      Budget.fromJson(await client.put('/budgets/$categoryId',
          body: {'monthly_limit': monthlyLimit}) as Map<String, dynamic>);

  Future<void> deleteBudget(int categoryId) =>
      client.delete('/budgets/$categoryId');

  // ---------- Stats ----------

  Future<Summary> summary({int months = 6}) async =>
      Summary.fromJson(await client.get('/stats/summary', query: {'months': '$months'})
          as Map<String, dynamic>);

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final financeRepository = FinanceRepository(ApiClient(baseUrl: Config.apiBaseUrl));
