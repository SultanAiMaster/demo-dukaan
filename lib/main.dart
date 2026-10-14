import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'ui.dart';
import 'admin.dart';

void main() => runApp(const DukaanApp());

class DukaanApp extends StatelessWidget {
  const DukaanApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Demo Dukaan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: kBrand, surface: kBg), useMaterial3: true, scaffoldBackgroundColor: kBg, cardTheme: CardThemeData(color: kCard, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: kLine))), chipTheme: ChipThemeData(shape: const StadiumBorder(), side: const BorderSide(color: kLine)), filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14)))),
        initialRoute: '/',
        onGenerateRoute: (s) {
          Widget page;
          switch (s.name) {
            case '/products': page = Shell(title: 'Products', child: ProductsPage(initialCategory: s.arguments as String?)); break;
            case '/product': page = Shell(title: 'Product', child: ProductPage(s.arguments as Product)); break;
            case '/about': page = const Shell(title: 'About', child: AboutPage()); break;
            case '/cart': page = const Shell(title: 'Cart', child: CartPage()); break;
            case '/admin': page = const AdminPage(); break;
            default: page = const Shell(title: 'Home', child: HomePage());
          }
          return PageRouteBuilder(settings: s, pageBuilder: (_, __, ___) => page, transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero);
        },
      );
}

Future<void> openUrl(String u) async => launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);

class Shell extends StatelessWidget {
  final String title;
  final Widget child;
  const Shell({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    final nav = <MapEntry<String, String>>[const MapEntry('Home', '/'), const MapEntry('Products', '/products'), const MapEntry('About & Contact', '/about')];
    void go(String r) => Navigator.pushReplacementNamed(context, r);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kAccent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: InkWell(onTap: () => go('/'), child: const Text('Demo Dukaan', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5))),
        actions: [
          if (wide) ...nav.map((e) => TextButton(onPressed: () => go(e.value), child: Text(e.key, style: const TextStyle(color: kAccent)))),
          AnimatedBuilder(
            animation: Cart.I,
            builder: (_, __) => IconButton(
              tooltip: 'Cart',
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              icon: Badge(isLabelVisible: Cart.I.count > 0, label: Text('${Cart.I.count}'), child: const Icon(Icons.shopping_cart_outlined)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: ListView(children: [
              const DrawerHeader(decoration: BoxDecoration(color: kAccent), child: Align(alignment: Alignment.bottomLeft, child: Text('Demo Dukaan', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))),
              ...nav.map((e) => ListTile(title: Text(e.key), onTap: () => go(e.value))),
              ListTile(leading: const Icon(Icons.admin_panel_settings_outlined), title: const Text('Admin demo'), onTap: () => Navigator.pushNamed(context, '/admin')),
            ])),
      body: SingleChildScrollView(
        child: Column(children: [
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), child: child))),
          Container(
            width: double.infinity,
            color: kAccent,
            padding: const EdgeInsets.all(20),
            child: Wrap(alignment: WrapAlignment.spaceBetween, spacing: 20, runSpacing: 8, children: [
              const Text('Demo Dukaan - a sample shop built by WorkChain AI. Products and orders are demo data.', style: TextStyle(color: Colors.white70)),
              InkWell(onTap: () => Navigator.pushNamed(context, '/admin'), child: const Text('Admin panel demo', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline))),
            ]),
          ),
        ]),
      ),
    );
  }
}

mixin LoadProducts<T extends StatefulWidget> on State<T> {
  List<Product>? products;
  String? err;
  Future<void> loadProducts() async {
    try { final p = await Api.products(); if (mounted) setState(() { products = p; err = null; }); } catch (e) { if (mounted) setState(() => err = 'Could not load products. Please retry.'); }
  }
  Widget? stateWidget() {
    if (err != null) return Center(child: Column(children: [Text(err!), TextButton(onPressed: loadProducts, child: const Text('Retry'))]));
    if (products == null) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    return null;
  }
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomeState(); }
class _HomeState extends State<HomePage> with LoadProducts {
  @override void initState() { super.initState(); loadProducts(); }
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    final s = stateWidget();
    Widget tile({required Widget child, Color? color, EdgeInsets pad = const EdgeInsets.all(24), VoidCallback? onTap}) => InkWell(
        borderRadius: BorderRadius.circular(24), onTap: onTap,
        child: Container(width: double.infinity, padding: pad, decoration: bento(color ?? kCard), child: child));
    final hero = tile(
      pad: EdgeInsets.all(wide ? 44 : 26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('GROCERY + FASHION', style: TextStyle(color: kBrand, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12)),
        const SizedBox(height: 14),
        Text('Everyday things,\nsimply ordered.', style: TextStyle(fontSize: wide ? 54 : 34, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
        const SizedBox(height: 14),
        const Text('Pick from the shelf, add to cart, send the order on WhatsApp.', style: TextStyle(fontSize: 16, color: kMuted)),
        const SizedBox(height: 22),
        Wrap(spacing: 10, runSpacing: 8, children: [
          FilledButton(style: FilledButton.styleFrom(backgroundColor: kAccent), onPressed: () => Navigator.pushReplacementNamed(context, '/products'), child: const Text('Shop now')),
          OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: kAccent, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), side: const BorderSide(color: kLine)), onPressed: () => Navigator.pushNamed(context, '/admin'), child: const Text('See the admin panel')),
        ]),
      ]));
    final grocery = tile(color: kBrand, onTap: () => Navigator.pushReplacementNamed(context, '/products', arguments: 'Grocery'),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.local_grocery_store_outlined, color: Colors.white), SizedBox(height: 40), Text('Grocery', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)), Text('Staples, tea, ghee', style: TextStyle(color: Colors.white70))]));
    final fashion = tile(onTap: () => Navigator.pushReplacementNamed(context, '/products', arguments: 'Fashion'),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.checkroom_outlined), SizedBox(height: 40), Text('Fashion', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), Text('Kurta, saree, denim', style: TextStyle(color: kMuted))]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (wide) IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 3, child: hero), const SizedBox(width: 16), Expanded(child: Column(children: [Expanded(child: grocery), const SizedBox(height: 16), Expanded(child: fashion)]))]))
      else ...[hero, const SizedBox(height: 16), IntrinsicHeight(child: Row(children: [Expanded(child: grocery), const SizedBox(width: 16), Expanded(child: fashion)]))],
      const SizedBox(height: 40),
      const Text('Popular right now', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
      const SizedBox(height: 16),
      s ?? ProductGrid(products!.take(8).toList()),
      const SizedBox(height: 40),
      const DemoRequestCard(),
    ]);
  }
  Widget _cat(BuildContext c, IconData i, String n) => Expanded(
      child: Card(child: InkWell(onTap: () => Navigator.pushReplacementNamed(c, '/products', arguments: n), child: Padding(padding: const EdgeInsets.all(18), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: kBrand), const SizedBox(width: 8), Text(n, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))])))));
}

class ProductsPage extends StatefulWidget { final String? initialCategory; const ProductsPage({super.key, this.initialCategory}); @override State<ProductsPage> createState() => _ProductsState(); }
class _ProductsState extends State<ProductsPage> with LoadProducts {
  String cat = 'All';
  String q = '';
  @override void initState() { super.initState(); cat = widget.initialCategory ?? 'All'; loadProducts(); }
  @override
  Widget build(BuildContext context) {
    final s = stateWidget();
    List<Product> list = [];
    var cats = <String>['All'];
    if (products != null) {
      cats = ['All', ...{...products!.map((e) => e.category)}];
      list = products!.where((p) => (cat == 'All' || p.category == cat) && p.name.toLowerCase().contains(q.toLowerCase())).toList();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Search products', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v) => setState(() => q = v)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: cats.map((c) => ChoiceChip(label: Text(c), selected: cat == c, onSelected: (_) => setState(() => cat = c))).toList()),
      const SizedBox(height: 12),
      s ?? (list.isEmpty ? const Padding(padding: EdgeInsets.all(30), child: Text('No products found.')) : ProductGrid(list)),
    ]);
  }
}

class ProductPage extends StatefulWidget { final Product p; const ProductPage(this.p, {super.key}); @override State<ProductPage> createState() => _ProductState(); }
class _ProductState extends State<ProductPage> {
  int n = 1;
  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final wide = MediaQuery.of(context).size.width >= 800;
    final img = ClipRRect(borderRadius: BorderRadius.circular(14), child: AspectRatio(aspectRatio: 1, child: productImage(p.image)));
    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Chip(label: Text(p.category)),
      Text(p.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(rupee(p.price), style: const TextStyle(fontSize: 24, color: kBrand, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Text(p.description, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 16),
      Row(children: [
        IconButton.outlined(onPressed: () => setState(() => n = n > 1 ? n - 1 : 1), icon: const Icon(Icons.remove)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$n', style: const TextStyle(fontSize: 18))),
        IconButton.outlined(onPressed: () => setState(() => n++), icon: const Icon(Icons.add)),
      ]),
      const SizedBox(height: 14),
      FilledButton.icon(
          onPressed: () { Cart.I.add(p, n); Navigator.pushNamed(context, '/cart'); },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Add to cart')),
    ]);
    return wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: img), const SizedBox(width: 30), Expanded(child: info)]) : Column(children: [img, const SizedBox(height: 16), Align(alignment: Alignment.centerLeft, child: info)]);
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('About Demo Dukaan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('This is a sample neighbourhood shop that sells groceries and everyday clothes. It shows how your own shop would look: a website, an Android app and an admin panel from one codebase. The name, products and contact details here are placeholders.', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () => openUrl('tel:$kShopPhone'), icon: const Icon(Icons.call), label: const Text('Call the shop')),
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: kAccent), onPressed: () => openUrl('https://wa.me/$kShopWhatsApp?text=Hello'), icon: const Icon(Icons.chat), label: const Text('WhatsApp')),
        ]),
        const SizedBox(height: 8),
        const Text('Phone and WhatsApp numbers shown here are demo placeholders.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(14)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.location_on_outlined, size: 40), SizedBox(height: 6), Text('Map placeholder - your shop location goes here'), Text('Main Market Road, Your Town', style: TextStyle(color: Colors.black54))]),
        ),
        const SizedBox(height: 16),
        const Text('Shop hours: 9 AM - 9 PM (sample)', style: TextStyle(fontSize: 16)),
      ]);
}

class CartPage extends StatefulWidget { const CartPage({super.key}); @override State<CartPage> createState() => _CartState(); }
class _CartState extends State<CartPage> {
  final name = TextEditingController(), phone = TextEditingController();
  bool busy = false;
  @override void initState() { super.initState(); Cart.I.addListener(_r); }
  @override void dispose() { Cart.I.removeListener(_r); super.dispose(); }
  void _r() => setState(() {});

  Future<void> order() async {
    if (name.text.trim().isEmpty || phone.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name and phone number')));
      return;
    }
    setState(() => busy = true);
    try {
      final lines = Cart.I.lines;
      final total = Cart.I.total;
      final o = await Api.placeOrder(name.text.trim(), phone.text.trim(), lines);
      final msg = StringBuffer('Hello, I want to order (#${o['id']}):\n');
      for (final l in lines) { msg.writeln('- ${l['name']} x ${l['qty']} = ₹${l['price'] * l['qty']}'); }
      msg.writeln('Total: ₹$total\nName: ${name.text.trim()}\nPhone: ${phone.text.trim()}');
      Cart.I.clear();
      if (!mounted) return;
      await showDialog(context: context, builder: (c) => AlertDialog(
        title: const Text('Order placed'),
        content: Text('Your order #${o['id']} is saved in the shop admin. Tap below to also send it on WhatsApp.'),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')), FilledButton(onPressed: () { openUrl('https://wa.me/$kShopWhatsApp?text=${Uri.encodeComponent(msg.toString())}'); Navigator.pop(c); }, child: const Text('Open WhatsApp'))],
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ids = Cart.I.qty.keys.toList();
    if (ids.isEmpty) return Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(children: [const Icon(Icons.shopping_cart_outlined, size: 48), const SizedBox(height: 8), const Text('Your cart is empty'), TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/products'), child: const Text('Browse products'))])));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your cart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ...ids.map((id) {
        final p = Cart.I.prods[id]!;
        final n = Cart.I.qty[id]!;
        return Card(child: ListTile(
          leading: SizedBox(width: 52, height: 52, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: productImage(p.image))),
          title: Text(p.name), subtitle: Text('${rupee(p.price)} each'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: () => Cart.I.setQty(id, n - 1), icon: const Icon(Icons.remove_circle_outline)),
            Text('$n'),
            IconButton(onPressed: () => Cart.I.setQty(id, n + 1), icon: const Icon(Icons.add_circle_outline)),
          ]),
        ));
      }),
      const SizedBox(height: 8),
      Text('Total: ${rupee(Cart.I.total)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrand)),
      const SizedBox(height: 12),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
      const SizedBox(height: 10),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: kAccent, padding: const EdgeInsets.all(16)),
        onPressed: busy ? null : order, icon: const Icon(Icons.chat), label: Text(busy ? 'Placing...' : 'Order on WhatsApp'))),
      const SizedBox(height: 6),
      const Text('The order is also saved in the shop admin panel. No payment is taken in this demo.', style: TextStyle(color: Colors.black54)),
    ]);
  }
}

class DemoRequestCard extends StatefulWidget { const DemoRequestCard({super.key}); @override State<DemoRequestCard> createState() => _DRState(); }
class _DRState extends State<DemoRequestCard> {
  final n = TextEditingController(), s = TextEditingController(), p = TextEditingController();
  bool busy = false, done = false;
  Future<void> send() async {
    if (n.text.trim().isEmpty || p.text.trim().length < 6) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name and phone number'))); return; }
    setState(() => busy = true);
    try { await Api.demoRequest(n.text.trim(), s.text.trim(), p.text.trim()); setState(() => done = true); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext context) => Card(
        color: kCard,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: done
              ? const Text('Thanks! Your request is saved. WorkChain AI will contact you on the number you gave.', style: TextStyle(fontSize: 16))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Want a shop like this for your business?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Leave your details and WorkChain AI will get in touch.'),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    SizedBox(width: 220, child: TextField(controller: n, decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder(), filled: true, fillColor: Colors.white))),
                    SizedBox(width: 220, child: TextField(controller: s, decoration: const InputDecoration(labelText: 'Shop name', border: OutlineInputBorder(), filled: true, fillColor: Colors.white))),
                    SizedBox(width: 220, child: TextField(controller: p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder(), filled: true, fillColor: Colors.white))),
                  ]),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: busy ? null : send, child: Text(busy ? 'Sending...' : 'Request a demo')),
                ]),
        ),
      );
}
