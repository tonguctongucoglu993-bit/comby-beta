import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

const combyTeal = Color(0xFF11C2C0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.create();
  runApp(CombyApp(store: store));
}

class CombyApp extends StatelessWidget {
  final Store store;
  const CombyApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comby Beta',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: combyTeal),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
      ),
      home: Splash(store: store),
    );
  }
}

/// ----------------------
/// DATA / STORAGE (local)
/// ----------------------
enum Cat { ust, alt, ayakkabi, aksesuar }

String catLabel(Cat c) {
  switch (c) {
    case Cat.ust:
      return 'Üst Giyim';
    case Cat.alt:
      return 'Alt Giyim';
    case Cat.ayakkabi:
      return 'Ayakkabı';
    case Cat.aksesuar:
      return 'Aksesuar';
  }
}

class ClothingItem {
  final String id;
  final String name;
  final Cat cat;
  ClothingItem({required this.id, required this.name, required this.cat});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'cat': cat.name};

  static ClothingItem fromJson(Map<String, dynamic> j) => ClothingItem(
        id: j['id'],
        name: j['name'],
        cat: Cat.values.firstWhere((e) => e.name == j['cat']),
      );
}

class Outfit {
  final String id;
  final String title;
  final List<String> itemIds;
  Outfit({required this.id, required this.title, required this.itemIds});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'itemIds': itemIds};

  static Outfit fromJson(Map<String, dynamic> j) => Outfit(
        id: j['id'],
        title: j['title'],
        itemIds: List<String>.from(j['itemIds'] ?? const []),
      );
}

class TrendProduct {
  final String brand;
  final String name;
  final String url;
  TrendProduct({required this.brand, required this.name, required this.url});
}

class TrendOutfit {
  final String id;
  final String title;
  final String subtitle;
  final List<TrendProduct> products;
  TrendOutfit({required this.id, required this.title, required this.subtitle, required this.products});
}

class Store {
  static const _kClothes = 'comby_clothes_v1';
  static const _kOutfits = 'comby_outfits_v1';

  final SharedPreferences prefs;
  final List<ClothingItem> clothes;
  final List<Outfit> outfits;
  final List<TrendOutfit> trends;

  Store._(this.prefs, this.clothes, this.outfits, this.trends);

  static Future<Store> create() async {
    final prefs = await SharedPreferences.getInstance();

    List<ClothingItem> clothes = [];
    List<Outfit> outfits = [];

    final cj = prefs.getString(_kClothes);
    final oj = prefs.getString(_kOutfits);

    if (cj != null) {
      clothes = (jsonDecode(cj) as List).map((e) => ClothingItem.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    if (oj != null) {
      outfits = (jsonDecode(oj) as List).map((e) => Outfit.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    // Seed if empty
    if (clothes.isEmpty) {
      clothes = [
        ClothingItem(id: 'c1', name: 'Kazak', cat: Cat.ust),
        ClothingItem(id: 'c2', name: 'Tişört', cat: Cat.ust),
        ClothingItem(id: 'c3', name: 'Gömlek', cat: Cat.ust),
        ClothingItem(id: 'c4', name: 'Pantolon', cat: Cat.alt),
        ClothingItem(id: 'c5', name: 'Kot Pantolon', cat: Cat.alt),
        ClothingItem(id: 'c6', name: 'Spor Ayakkabı', cat: Cat.ayakkabi),
        ClothingItem(id: 'c7', name: 'Sneakers', cat: Cat.ayakkabi),
        ClothingItem(id: 'c8', name: 'Kemer', cat: Cat.aksesuar),
      ];
      await prefs.setString(_kClothes, jsonEncode(clothes.map((e) => e.toJson()).toList()));
    }

    final trends = <TrendOutfit>[
      TrendOutfit(
        id: 't1',
        title: 'Trend Kombin • Minimal',
        subtitle: 'Temiz, günlük ve ofise uygun.',
        products: [
          TrendProduct(brand: 'LC Waikiki', name: 'Krem Ceket', url: 'https://www.lcwaikiki.com/tr-TR/TR'),
          TrendProduct(brand: 'ZARA', name: 'Bej Kazak', url: 'https://www.zara.com/tr/'),
          TrendProduct(brand: 'MANGO', name: 'Kahverengi Pantolon', url: 'https://shop.mango.com/tr'),
          TrendProduct(brand: 'Nike', name: 'Beyaz Sneaker', url: 'https://www.nike.com/tr/'),
        ],
      ),
      TrendOutfit(
        id: 't2',
        title: 'Trend Kombin • Street',
        subtitle: 'Genç, rahat, şehir stili.',
        products: [
          TrendProduct(brand: 'H&M', name: 'Oversize Hoodie', url: 'https://www2.hm.com/tr_tr/index.html'),
          TrendProduct(brand: 'Pull&Bear', name: 'Baggy Pantolon', url: 'https://www.pullandbear.com/tr/'),
          TrendProduct(brand: 'adidas', name: 'Sneakers', url: 'https://www.adidas.com.tr/'),
        ],
      ),
    ];

    return Store._(prefs, clothes, outfits, trends);
  }

  Future<void> _save() async {
    await prefs.setString(_kClothes, jsonEncode(clothes.map((e) => e.toJson()).toList()));
    await prefs.setString(_kOutfits, jsonEncode(outfits.map((e) => e.toJson()).toList()));
  }

  Future<void> addClothing(String name, Cat cat) async {
    clothes.insert(0, ClothingItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, cat: cat));
    await _save();
  }

  Future<void> addOutfit(String title, List<String> itemIds) async {
    outfits.insert(0, Outfit(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, itemIds: itemIds));
    await _save();
  }

  Future<void> deleteOutfit(String id) async {
    outfits.removeWhere((o) => o.id == id);
    await _save();
  }

  ClothingItem? byId(String id) {
    for (final c in clothes) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// ---------
/// SCREENS
/// ---------
class Splash extends StatefulWidget {
  final Store store;
  const Splash({super.key, required this.store});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Shell(store: widget.store)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ColoredBox(
        color: combyTeal,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checkroom, color: Colors.white, size: 42),
              SizedBox(width: 10),
              Text('Comby', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  final Store store;
  const Shell({super.key, required this.store});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int idx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      Home(store: widget.store),
      Wardrobe(store: widget.store),
      Outfits(store: widget.store),
    ];

    return Scaffold(
      body: pages[idx],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateOutfit(store: widget.store)));
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Keşfet'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Dolabım'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_mosaic), label: 'Kombinlerim'),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget {
  final Store store;
  const Home({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comby', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Keşfet', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text('Trend kombinleri gör ve parçaları satın al.', style: TextStyle(color: Color(0xFF666666))),
          const SizedBox(height: 16),
          for (final t in store.trends) ...[
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrendDetail(trend: t))),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(t.subtitle, style: const TextStyle(color: Color(0xFF6B6B6B))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class Wardrobe extends StatefulWidget {
  final Store store;
  const Wardrobe({super.key, required this.store});

  @override
  State<Wardrobe> createState() => _WardrobeState();
}

class _WardrobeState extends State<Wardrobe> {
  Cat? filter;

  @override
  Widget build(BuildContext context) {
    final items = filter == null ? widget.store.clothes : widget.store.clothes.where((e) => e.cat == filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dolabım', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => AddClothing(store: widget.store)));
              setState(() {});
            },
            icon: const Icon(Icons.add_circle_outline),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _Pill(text: 'Dolabım', selected: true, onTap: () {}),
              const SizedBox(width: 10),
              _Pill(
                text: 'Kombinlerim',
                selected: false,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alt menüden Kombinlerim’e geç.')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Chip(label: 'Tümü', selected: filter == null, onTap: () => setState(() => filter = null)),
                _Chip(label: 'Üst', selected: filter == Cat.ust, onTap: () => setState(() => filter = Cat.ust)),
                _Chip(label: 'Alt', selected: filter == Cat.alt, onTap: () => setState(() => filter = Cat.alt)),
                _Chip(label: 'Ayakkabı', selected: filter == Cat.ayakkabi, onTap: () => setState(() => filter = Cat.ayakkabi)),
                _Chip(label: 'Aksesuar', selected: filter == Cat.aksesuar, onTap: () => setState(() => filter = Cat.aksesuar)),
              ].expand((w) => [w, const SizedBox(width: 10)]).toList()..removeLast(),
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (_, i) => _ClothingTile(item: items[i]),
          )
        ],
      ),
    );
  }
}

class Outfits extends StatefulWidget {
  final Store store;
  const Outfits({super.key, required this.store});

  @override
  State<Outfits> createState() => _OutfitsState();
}

class _OutfitsState extends State<Outfits> {
  @override
  Widget build(BuildContext context) {
    final outfits = widget.store.outfits;

    return Scaffold(
      appBar: AppBar(title: const Text('Kombinlerim', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Kombinlerim', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (outfits.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('Henüz kombin yok. + ile ekle.', style: TextStyle(color: Color(0xFF666666))),
            ),
          for (final o in outfits) ...[
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Column(
                      children: [
                        IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                          onPressed: () async {
                            await widget.store.deleteOutfit(o.id);
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(o.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class AddClothing extends StatefulWidget {
  final Store store;
  const AddClothing({super.key, required this.store});

  @override
  State<AddClothing> createState() => _AddClothingState();
}

class _AddClothingState extends State<AddClothing> {
  final ctrl = TextEditingController();
  Cat cat = Cat.ust;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kıyafet Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'İsim',
                hintText: 'Örn: Siyah hoodie',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Cat>(
              value: cat,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Kategori'),
              items: Cat.values.map((c) => DropdownMenuItem(value: c, child: Text(catLabel(c)))).toList(),
              onChanged: (v) => setState(() => cat = v ?? Cat.ust),
            ),
            const Spacer(),
            _Primary(
              text: 'Ekle',
              onTap: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                await widget.store.addClothing(name, cat);
                if (!mounted) return;
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}

class CreateOutfit extends StatefulWidget {
  final Store store;
  const CreateOutfit({super.key, required this.store});

  @override
  State<CreateOutfit> createState() => _CreateOutfitState();
}

class _CreateOutfitState extends State<CreateOutfit> {
  final titleCtrl = TextEditingController(text: 'Yeni Kombin');
  String? ust, alt, ayk, aks;

  @override
  void dispose() {
    titleCtrl.dispose();
    super.dispose();
  }

  void openAiModal() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checkroom, color: combyTeal, size: 32),
            const SizedBox(height: 10),
            const Text('Nasıl kombin istersin?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            _AiRow(
              icon: Icons.inventory_2,
              title: 'Dolabımdan kombin yap',
              subtitle: 'Sadece dolabımdaki parçaları kullan',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo: Dolabımdan kombin (beta).')));
              },
            ),
            const SizedBox(height: 10),
            _AiRow(
              icon: Icons.add_circle_outline,
              title: 'Eksik parça öner',
              subtitle: 'Dolabı baz alıp 1 parça öner',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo: Eksik parça öner (beta).')));
              },
            ),
            const SizedBox(height: 10),
            _AiRow(
              icon: Icons.local_fire_department,
              title: 'Trend kombin göster',
              subtitle: 'Trend kombinlere git',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => TrendList(store: widget.store)));
              },
            ),
            const SizedBox(height: 12),
            _Secondary(text: 'Vazgeç', onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ustList = widget.store.clothes.where((e) => e.cat == Cat.ust).to
