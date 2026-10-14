import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Backend base URL. Empty on web (same origin); set with --dart-define=API_BASE=... for the APK.
const String kApiBase = String.fromEnvironment('API_BASE', defaultValue: '');

/// Demo shop contact details. Placeholders - a real shop gets its own numbers.
const String kShopPhone = '+911234567890';
const String kShopWhatsApp = '911234567890';

class Product {
  final String id, name, category, description, image;
  final int price;
  Product({required this.id, required this.name, required this.category, required this.price, required this.description, required this.image});
  factory Product.fromJson(Map<String, dynamic> j) => Product(
      id: j['id'], name: j['name'], category: j['category'], price: (j['price'] as num).toInt(), description: j['description'] ?? '', image: j['image'] ?? 'tote');
}

class Order {
  final String id, name, phone, status, at;
  final int total;
  final List<Map<String, dynamic>> items;
  Order(this.id, this.name, this.phone, this.status, this.at, this.total, this.items);
  factory Order.fromJson(Map<String, dynamic> j) => Order(j['id'], j['name'], j['phone'], j['status'], j['at'], (j['total'] as num).toInt(),
      (j['items'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
}

class Api {
  static String? adminToken;
  static Uri _u(String p) => Uri.parse('$kApiBase$p');
  static Map<String, String> get _h => {'content-type': 'application/json', if (adminToken != null) 'x-admin-token': adminToken!};

  static dynamic _check(http.Response r) {
    final body = r.body.isEmpty ? {} : jsonDecode(r.body);
    if (r.statusCode >= 300) throw Exception(body is Map && body['error'] != null ? body['error'] : 'Request failed');
    return body;
  }

  static Future<List<Product>> products() async =>
      (_check(await http.get(_u('/api/products'))) as List).map((e) => Product.fromJson(e)).toList();
  static Future<void> login(String u, String p) async {
    final b = _check(await http.post(_u('/api/login'), headers: _h, body: jsonEncode({'user': u, 'pass': p})));
    adminToken = b['token'];
  }
  static Future<void> saveProduct(Map<String, dynamic> p, {String? id}) async {
    final r = id == null ? await http.post(_u('/api/products'), headers: _h, body: jsonEncode(p)) : await http.put(_u('/api/products/$id'), headers: _h, body: jsonEncode(p));
    _check(r);
  }
  static Future<void> deleteProduct(String id) async => _check(await http.delete(_u('/api/products/$id'), headers: _h));
  static Future<List<Order>> orders() async => (_check(await http.get(_u('/api/orders'), headers: _h)) as List).map((e) => Order.fromJson(e)).toList();
  static Future<void> setStatus(String id, String s) async => _check(await http.post(_u('/api/orders/$id/status'), headers: _h, body: jsonEncode({'status': s})));
  static Future<Map<String, dynamic>> placeOrder(String name, String phone, List<Map<String, dynamic>> items) async =>
      Map<String, dynamic>.from(_check(await http.post(_u('/api/orders'), headers: _h, body: jsonEncode({'name': name, 'phone': phone, 'items': items}))));
  static Future<void> demoRequest(String name, String shop, String phone) async =>
      _check(await http.post(_u('/api/demo-request'), headers: _h, body: jsonEncode({'name': name, 'shop': shop, 'phone': phone})));
}

class Cart extends ChangeNotifier {
  static final Cart I = Cart();
  final Map<String, int> qty = {};
  final Map<String, Product> prods = {};
  void add(Product p, [int n = 1]) { prods[p.id] = p; qty[p.id] = (qty[p.id] ?? 0) + n; notifyListeners(); }
  void setQty(String id, int n) { if (n <= 0) { qty.remove(id); prods.remove(id); } else { qty[id] = n; } notifyListeners(); }
  void clear() { qty.clear(); prods.clear(); notifyListeners(); }
  int get count => qty.values.fold(0, (a, b) => a + b);
  int get total => qty.entries.fold(0, (a, e) => a + prods[e.key]!.price * e.value);
  List<Map<String, dynamic>> get lines => qty.entries.map((e) => {'name': prods[e.key]!.name, 'price': prods[e.key]!.price, 'qty': e.value}).toList();
}
