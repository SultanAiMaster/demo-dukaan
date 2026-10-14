import 'package:flutter/material.dart';
import 'api.dart';

// DESIGN LANGUAGE (product default, see README): Bento Grid + Minimalism.
// Neutral palette, ONE accent (kBrand), 24px rounded cards, hairline borders, no heavy shadows, generous whitespace.
const kBrand = Color(0xFFE85D2A); // the single accent
const kAccent = Color(0xFF111111); // ink
const kBg = Color(0xFFF4F4F1);
const kCard = Colors.white;
const kLine = Color(0xFFE6E6E1);
const kMuted = Color(0xFF6B6B66);
BoxDecoration bento([Color c = kCard]) => BoxDecoration(color: c, borderRadius: BorderRadius.circular(24), border: Border.all(color: kLine));
const List<String> kBuiltInImages = ['atta','rice','tea','ghee','biscuit','soap','oil','spices','tshirt','kurta','saree','jeans','dupatta','tote','sneakers'];

Widget productImage(String img, {BoxFit fit = BoxFit.cover}) {
  if (img.startsWith('http')) {
    return Image.network(img, fit: fit, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined)));
  }
  return Image.asset('assets/img/p_$img.jpg', fit: fit, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_outlined)));
}

String rupee(int n) => '₹$n';

class ProductCard extends StatelessWidget {
  final Product p;
  final VoidCallback onTap;
  const ProductCard(this.p, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: bento(),
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: SizedBox.expand(child: productImage(p.image))),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 6, 8),
              child: Row(children: [
                Text(rupee(p.price), style: const TextStyle(fontWeight: FontWeight.bold, color: kBrand, fontSize: 16)),
                const Spacer(),
                IconButton(
                    tooltip: 'Add to cart',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    onPressed: () {
                      Cart.I.add(p);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} added to cart'), duration: const Duration(seconds: 1)));
                    }),
              ]),
            ),
          ]),
        ),
      );
}

int gridCols(double w) => w >= 1100 ? 5 : w >= 800 ? 4 : w >= 560 ? 3 : 2;

class ProductGrid extends StatelessWidget {
  final List<Product> items;
  const ProductGrid(this.items, {super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridCols(box.maxWidth), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.82),
          itemBuilder: (_, i) => ProductCard(items[i], () => Navigator.pushNamed(c, '/product', arguments: items[i])),
        );
      });
}
