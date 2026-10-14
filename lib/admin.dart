import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';

class AdminPage extends StatefulWidget { const AdminPage({super.key}); @override State<AdminPage> createState() => _AdminState(); }
class _AdminState extends State<AdminPage> {
  final u = TextEditingController(text: ''), pw = TextEditingController(text: '');
  String? err;
  bool busy = false;

  Future<void> login() async {
    setState(() { busy = true; err = null; });
    try { await Api.login(u.text.trim(), pw.text.trim()); } catch (e) { err = 'Wrong username or password'; }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (Api.adminToken != null) return AdminDash(onLogout: () => setState(() => Api.adminToken = null));
    return Scaffold(
      appBar: AppBar(title: const Text('Shop admin'), backgroundColor: kBg, foregroundColor: kAccent, elevation: 0, leading: BackButton(onPressed: () => Navigator.pushReplacementNamed(context, '/'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(children: [
              Card(color: kCard, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Demo login', style: TextStyle(fontWeight: FontWeight.bold)),
                const SelectableText('Username: demo\nPassword: demo123'),
                const SizedBox(height: 6),
                const Text('Demo data resets every day (IST). Anyone can try it.', style: TextStyle(color: Colors.black54)),
                TextButton(onPressed: () { u.text = 'demo'; pw.text = 'demo123'; }, child: const Text('Fill demo login')),
              ]))),
              const SizedBox(height: 12),
              TextField(controller: u, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: pw, obscureText: true, onSubmitted: (_) => login(), decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : login, child: const Text('Log in'))),
            ]),
          ),
        ),
      ),
    );
  }
}

class AdminDash extends StatefulWidget { final VoidCallback onLogout; const AdminDash({super.key, required this.onLogout}); @override State<AdminDash> createState() => _DashState(); }
class _DashState extends State<AdminDash> {
  List<Product> products = [];
  List<Order> orders = [];
  bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { final p = await Api.products(); final o = await Api.orders(); if (mounted) setState(() { products = p; orders = o; loading = false; }); } catch (e) { if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }
  }

  Future<void> edit([Product? p]) async {
    final name = TextEditingController(text: p?.name), price = TextEditingController(text: p?.price.toString()), desc = TextEditingController(text: p?.description), imgUrl = TextEditingController(text: (p != null && p.image.startsWith('http')) ? p.image : '');
    String cat = p?.category ?? 'Grocery';
    String img = (p != null && !p.image.startsWith('http')) ? p.image : 'tote';
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, set) => AlertDialog(
      title: Text(p == null ? 'Add product' : 'Edit product'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Product name')),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)')),
        DropdownButtonFormField<String>(value: cat, items: ['Grocery', 'Fashion'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => set(() => cat = v!), decoration: const InputDecoration(labelText: 'Category')),
        TextField(controller: desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 10),
        const Align(alignment: Alignment.centerLeft, child: Text('Pick a picture')),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: kBuiltInImages.map((e) => InkWell(onTap: () => set(() { img = e; imgUrl.clear(); }), child: Container(width: 48, height: 48, decoration: BoxDecoration(border: Border.all(color: img == e && imgUrl.text.isEmpty ? kBrand : Colors.transparent, width: 3), borderRadius: BorderRadius.circular(6)), child: productImage(e)))).toList()),
        TextField(controller: imgUrl, decoration: const InputDecoration(labelText: 'or image link (https://...)')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))],
    )));
    if (ok != true) return;
    try {
      await Api.saveProduct({'name': name.text, 'price': int.tryParse(price.text) ?? 0, 'category': cat, 'description': desc.text, 'image': imgUrl.text.trim().startsWith('http') ? imgUrl.text.trim() : img}, id: p?.id);
      await load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  @override
  Widget build(BuildContext context) {
    final newCount = orders.where((o) => o.status == 'New').length;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kBg, foregroundColor: kAccent, elevation: 0,
          title: const Text('Shop admin'),
          leading: BackButton(onPressed: () => Navigator.pushReplacementNamed(context, '/')),
          actions: [IconButton(onPressed: load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)), TextButton(onPressed: widget.onLogout, child: const Text('Log out', style: TextStyle(color: kAccent)))],
          bottom: TabBar(labelColor: kAccent, unselectedLabelColor: kMuted, indicatorColor: kBrand, tabs: [Tab(text: 'Products (${products.length})'), Tab(text: 'Orders ($newCount new)')]),
        ),
        body: loading ? const Center(child: CircularProgressIndicator()) : TabBarView(children: [_productsTab(), _ordersTab()]),
      ),
    );
  }

  Widget _productsTab() => Stack(children: [
        ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), children: products.map((p) => Card(child: ListTile(
          leading: SizedBox(width: 52, height: 52, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: productImage(p.image))),
          title: Text(p.name), subtitle: Text('${p.category} - ${rupee(p.price)}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined), onPressed: () => edit(p)),
            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () async { await Api.deleteProduct(p.id); await load(); }),
          ]),
        ))).toList()),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton.extended(onPressed: () => edit(), icon: const Icon(Icons.add), label: const Text('Add product'))),
      ]);

  Widget _ordersTab() => orders.isEmpty
      ? const Center(child: Text('No orders yet today. Place one from the shop and it shows up here.'))
      : ListView(padding: const EdgeInsets.all(12), children: orders.map((o) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Chip(label: Text(o.status), backgroundColor: o.status == 'New' ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5), visualDensity: VisualDensity.compact),
            const Spacer(),
            Text(rupee(o.total), style: const TextStyle(fontWeight: FontWeight.bold, color: kBrand)),
          ]),
          Text('${o.name} - ${o.phone}'),
          const SizedBox(height: 4),
          ...o.items.map((i) => Text('${i['name']} x ${i['qty']}')),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () async { await Api.setStatus(o.id, o.status == 'New' ? 'Done' : 'New'); await load(); }, child: Text(o.status == 'New' ? 'Mark Done' : 'Mark New'))),
        ])))).toList());
}
