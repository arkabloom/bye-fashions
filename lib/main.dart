import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const gold = Color(0xFFD6B36A);
const ink = Color(0xFF101010);
const panel = Color(0xFF1B1B1B);
final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final dateFmt = DateFormat('dd MMM yyyy');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  for (final name in ['products', 'sales', 'expenses', 'customers', 'settings']) {
    await Hive.openBox(name);
  }
  runApp(const ByeFashionsApp());
}

class ByeFashionsApp extends StatelessWidget {
  const ByeFashionsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BYE FASHIONS',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(primary: gold, secondary: gold, surface: panel),
      appBarTheme: const AppBarTheme(backgroundColor: ink, foregroundColor: Colors.white, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold)),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: gold, foregroundColor: ink, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.bold))),
      cardTheme: CardThemeData(color: panel, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: panel, indicatorColor: Color(0xFF4A3C22), labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11))),
    ),
    home: const HomeShell(),
  );
}

Box get products => Hive.box('products');
Box get sales => Hive.box('sales');
Box get expenses => Hive.box('expenses');
Box get customers => Hive.box('customers');
Box get settings => Hive.box('settings');
String id() => const Uuid().v4();
double numVal(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [DashboardPage(), ProductsPage(), BillingPage(), ExpensesPage(), ReportsPage()];
  final labels = const ['Home', 'Stock', 'Billing', 'Expenses', 'Reports'];
  final icons = const [Icons.dashboard_outlined, Icons.inventory_2_outlined, Icons.receipt_long, Icons.payments_outlined, Icons.bar_chart];
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(border: Border.all(color: gold, width: 1.4), shape: BoxShape.circle),
        child: const Center(child: Text('BF', style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 12)))),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BYE FASHIONS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 16)),
        Text('BEYOND YOUR EXPECTATIONS', style: TextStyle(color: gold, fontSize: 8, letterSpacing: 1.2)),
      ]),
      const Spacer(),
      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), icon: const Icon(Icons.settings_outlined))
    ])),
    body: IndexedStack(index: index, children: pages),
    floatingActionButton: index == 1 ? FloatingActionButton(backgroundColor: gold, foregroundColor: ink, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormPage())), child: const Icon(Icons.add)) : null,
    bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v),
      destinations: List.generate(labels.length, (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i]))),
  );
}

Widget sectionTitle(String title, {String? subtitle}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
]));
Widget statCard(String title, String value, IconData icon, {Color color = gold}) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
  const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)), const SizedBox(height: 5),
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
  ]))
])));
double todaySales() {
  final now = DateTime.now();
  return sales.values.where((e) { final d = DateTime.tryParse(e['createdAt'] ?? '') ?? DateTime(2000); return d.year == now.year && d.month == now.month && d.day == now.day; })
    .fold(0.0, (s, e) => s + numVal(e['total']));
}
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Hive.box('sales').listenable(),
    builder: (_, __, ___) => ValueListenableBuilder(valueListenable: products.listenable(), builder: (_, __, ___) {
      final totalStock = products.values.fold<int>(0, (s, e) => s + ((e['qty'] as num?)?.toInt() ?? 0));
      final low = products.values.where((e) => ((e['qty'] as num?)?.toInt() ?? 0) <= 3).length;
      return ListView(padding: const EdgeInsets.all(16), children: [
        sectionTitle('Business overview', subtitle: DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())),
        GridView.count(crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.75, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
          statCard("Today's sales", money.format(todaySales()), Icons.trending_up),
          statCard('Total bills', '${sales.length}', Icons.receipt_long),
          statCard('Stock units', '$totalStock', Icons.inventory_2_outlined),
          statCard('Low stock items', '$low', Icons.warning_amber_rounded, color: low > 0 ? Colors.orange : gold),
        ]),
        const SizedBox(height: 22), sectionTitle('Quick actions'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          actionChip(context, 'Create bill', Icons.add_shopping_cart, const BillingPage()),
          actionChip(context, 'Add product', Icons.add_box_outlined, const ProductsPage(), openForm: true),
          actionChip(context, 'Add expense', Icons.payments_outlined, const ExpensesPage(), openExpense: true),
        ]),
        const SizedBox(height: 22), sectionTitle('Recent bills'),
        if (sales.isEmpty) const EmptyState(text: 'No bills yet. Create your first sale to see it here.')
        else ...sales.values.toList().reversed.take(5).map((s) => SaleTile(data: Map<String,dynamic>.from(s))),
        const SizedBox(height: 18),
        const Text('Your data is stored locally on this device/browser. Export backups regularly from Settings.', style: TextStyle(color: Colors.white38, fontSize: 11)),
      ]);
    }));
}
Widget actionChip(BuildContext context, String label, IconData icon, Widget page, {bool openForm = false, bool openExpense = false}) => ActionChip(
  backgroundColor: panel, avatar: Icon(icon, color: gold, size: 18), label: Text(label),
  onPressed: () { if (openForm) { Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormPage())); } else if (openExpense) { Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseFormPage())); } else { Navigator.push(context, MaterialPageRoute(builder: (_) => page)); } });

class EmptyState extends StatelessWidget {
  final String text; const EmptyState({super.key, required this.text});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14)), child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54))));
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});
  @override Widget build(BuildContext context) => ValueListenableBuilder(valueListenable: products.listenable(), builder: (_, box, __) {
    final items = box.values.map((e) => Map<String,dynamic>.from(e)).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      sectionTitle('Inventory', subtitle: '${items.length} products • Manage stock and pricing'),
      if (items.isEmpty) const EmptyState(text: 'No products added. Tap + to add your first product.'),
      ...items.map((p) => Card(child: ListTile(
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF332A1A), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.checkroom, color: gold)),
        title: Text(p['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${p['category'] ?? 'Uncategorised'} • SKU ${p['sku'] ?? '-'}\nStock: ${p['qty']}  |  Cost: ${money.format(numVal(p['cost']))}', style: const TextStyle(color: Colors.white60, height: 1.5)),
        isThreeLine: true, trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(money.format(numVal(p['price'])), style: const TextStyle(color: gold, fontWeight: FontWeight.bold)), IconButton(visualDensity: VisualDensity.compact, onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Delete product?'), content: Text('Remove ${p['name']} from inventory?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { products.delete(p['id']); Navigator.pop(context); }, child: const Text('Delete'))])), icon: const Icon(Icons.delete_outline, size: 18))]),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormPage(existing: p))),
      ))),
    ]);
  });
}

class ProductFormPage extends StatefulWidget {
  final Map<String,dynamic>? existing; const ProductFormPage({super.key, this.existing});
  @override State<ProductFormPage> createState() => _ProductFormPageState();
}
class _ProductFormPageState extends State<ProductFormPage> {
  final name = TextEditingController(), sku = TextEditingController(), category = TextEditingController(text: 'Shirts');
  final cost = TextEditingController(), price = TextEditingController(), qty = TextEditingController(text: '0');
  @override void initState() { super.initState(); final p = widget.existing; if (p != null) { name.text=p['name']??''; sku.text=p['sku']??''; category.text=p['category']??''; cost.text='${p['cost']}'; price.text='${p['price']}'; qty.text='${p['qty']}'; } }
  @override void dispose() { for(final c in [name,sku,category,cost,price,qty]) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.existing == null ? 'Add product' : 'Edit product')), body: ListView(padding: const EdgeInsets.all(16), children: [
    field(name,'Product name'), field(sku,'SKU / Barcode'), field(category,'Category (Shirts, Pants, Jeans...)'),
    Row(children: [Expanded(child: field(cost,'Purchase cost',number:true)), const SizedBox(width:10), Expanded(child: field(price,'Selling price',number:true))]),
    field(qty,'Opening stock quantity',number:true),
    const SizedBox(height: 18), ElevatedButton(onPressed: save, child: const Text('SAVE PRODUCT')),
  ]));
  Widget field(TextEditingController c,String label,{bool number=false}) => Padding(padding: const EdgeInsets.only(bottom:12), child: TextField(controller:c, keyboardType:number?const TextInputType.numberWithOptions(decimal:true):TextInputType.text, decoration:InputDecoration(labelText:label)));
  void save() {
    if(name.text.trim().isEmpty || price.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product name and selling price are required'))); return; }
    final key = widget.existing?['id'] ?? id();
    products.put(key, {'id':key,'name':name.text.trim(),'sku':sku.text.trim(),'category':category.text.trim(),'cost':numVal(cost.text),'price':numVal(price.text),'qty':int.tryParse(qty.text)??0});
    Navigator.pop(context);
  }
}

class BillingPage extends StatefulWidget { const BillingPage({super.key}); @override State<BillingPage> createState()=>_BillingPageState(); }
class _BillingPageState extends State<BillingPage> {
  String? selected; int quantity=1; final customer=TextEditingController(); final phone=TextEditingController(); final discount=TextEditingController(text:'0'); String payment='Cash';
  @override Widget build(BuildContext context) => ValueListenableBuilder(valueListenable: products.listenable(), builder: (_, box, __) {
    final list=box.values.map((e)=>Map<String,dynamic>.from(e)).toList();
    final matches=list.where((e)=>e['id']==selected).toList(); final p=matches.isEmpty?null:matches.first;
    final subtotal=p==null?0.0:numVal(p['price'])*quantity;
    final total=(subtotal-numVal(discount.text)).clamp(0,double.infinity).toDouble();
    return ListView(padding: const EdgeInsets.all(16), children:[
      sectionTitle('Create a bill',subtitle:'Record a sale and automatically reduce stock'),
      TextField(controller:customer,decoration:const InputDecoration(labelText:'Customer name (optional)')),
      const SizedBox(height:10), TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Mobile number (optional)')),
      const SizedBox(height:14),
      DropdownButtonFormField<String>(value:selected, isExpanded:true, decoration:const InputDecoration(labelText:'Select product'), items:list.map((e)=>DropdownMenuItem(value:e['id'] as String,child:Text('${e['name']} • ${money.format(numVal(e['price']))} • Stock ${e['qty']}'))).toList(), onChanged:(v)=>setState(()=>selected=v)),
      const SizedBox(height:10),
      Row(children:[Expanded(child:TextFormField(initialValue:'1',keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity'),onChanged:(v)=>setState(()=>quantity=int.tryParse(v)??1))), const SizedBox(width:10), Expanded(child:TextField(controller:discount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Discount ₹'),onChanged:(_)=>setState((){})))]),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:payment,decoration:const InputDecoration(labelText:'Payment mode'),items:['Cash','UPI','Card','Bank transfer','Credit'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>payment=v??'Cash')),
      const SizedBox(height:18), Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        line('Subtotal',money.format(subtotal)),line('Discount',money.format(numVal(discount.text))),const Divider(),line('Total',money.format(total),strong:true),
      ]))),
      const SizedBox(height:14), ElevatedButton.icon(onPressed:()=>saveBill(p,total,quantity),icon:const Icon(Icons.check),label:const Text('SAVE BILL & UPDATE STOCK')),
      const SizedBox(height:20), sectionTitle('Recent bills'),
      if(sales.isEmpty) const EmptyState(text:'No sales recorded yet.') else ...sales.values.toList().reversed.take(10).map((s)=>SaleTile(data:Map<String,dynamic>.from(s))),
    ]);
  });
  Widget line(String a,String b,{bool strong=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Text(a,style:TextStyle(color:strong?gold:Colors.white70,fontWeight:strong?FontWeight.bold:FontWeight.normal)),const Spacer(),Text(b,style:TextStyle(color:strong?gold:Colors.white,fontWeight:FontWeight.bold,fontSize:strong?18:14))]));
  void saveBill(Map<String,dynamic>? p,double total,int q) {
    if(p==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Select a product')));return;}
    if(q<1 || q>(p['qty'] as num).toInt()){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Check quantity and available stock')));return;}
    final key=id(); final now=DateTime.now();
    final bill={'id':key,'invoice':'BF-${DateFormat('yyMMdd').format(now)}-${(sales.length+1).toString().padLeft(3,'0')}','createdAt':now.toIso8601String(),'customer':customer.text.trim().isEmpty?'Walk-in Customer':customer.text.trim(),'phone':phone.text.trim(),'product':p['name'],'productId':p['id'],'qty':q,'unitPrice':numVal(p['price']),'discount':numVal(discount.text),'total':total,'payment':payment};
    sales.put(key,bill); products.put(p['id'],{...p,'qty':(p['qty'] as num).toInt()-q});
    customer.clear();phone.clear();discount.text='0';setState(()=>selected=null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Bill saved and stock updated')));
  }
}

class SaleTile extends StatelessWidget {
  final Map<String,dynamic> data; const SaleTile({super.key,required this.data});
  @override Widget build(BuildContext context)=>Card(child:ListTile(
    leading:const CircleAvatar(backgroundColor:Color(0xFF332A1A),child:Icon(Icons.receipt,color:gold)),
    title:Text(data['customer']??'Customer',style:const TextStyle(fontWeight:FontWeight.w600)),
    subtitle:Text('${data['invoice']??''} • ${data['product']??''} × ${data['qty']??1}\n${dateFmt.format(DateTime.tryParse(data['createdAt']??'')??DateTime.now())} • ${data['payment']??'Cash'}',style:const TextStyle(color:Colors.white54,height:1.5)),
    isThreeLine:true,trailing:Text(money.format(numVal(data['total'])),style:const TextStyle(color:gold,fontWeight:FontWeight.bold)),
    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>InvoicePage(data:data))),
  ));
}
class InvoicePage extends StatelessWidget {
  final Map<String,dynamic> data; const InvoicePage({super.key,required this.data});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Invoice'),actions:[IconButton(onPressed:()=>printInvoice(data),icon:const Icon(Icons.picture_as_pdf))]),body:ListView(padding:const EdgeInsets.all(18),children:[
    const Center(child:Text('BYE FASHIONS',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,letterSpacing:2,color:gold))),
    const Center(child:Text('BEYOND YOUR EXPECTATIONS',style:TextStyle(color:Colors.white54,fontSize:10))),
    const SizedBox(height:24),line('Invoice',data['invoice']??''),line('Date',DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.tryParse(data['createdAt']??'')??DateTime.now())),
    line('Customer',data['customer']??''),if((data['phone']??'').toString().isNotEmpty)line('Mobile',data['phone']),
    const Divider(height:30),line('Item',data['product']??''),line('Quantity','${data['qty']}'),line('Unit price',money.format(numVal(data['unitPrice']))),line('Discount',money.format(numVal(data['discount']))),
    const Divider(height:30),line('TOTAL',money.format(numVal(data['total'])),bold:true),line('Payment',data['payment']??'Cash'),
    const SizedBox(height:24),ElevatedButton.icon(onPressed:()=>printInvoice(data),icon:const Icon(Icons.share),label:const Text('PRINT / SAVE PDF')),
    const SizedBox(height:12),const Center(child:Text('Thank you for shopping with us!',style:TextStyle(color:gold))),
  ]));
  Widget line(String a,String b,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[Text(a,style:TextStyle(color:bold?gold:Colors.white70,fontWeight:bold?FontWeight.bold:FontWeight.normal)),const Spacer(),Flexible(child:Text(b,textAlign:TextAlign.right,style:TextStyle(fontWeight:FontWeight.bold,color:bold?gold:Colors.white)))]));
}
Future<void> printInvoice(Map<String,dynamic> d) async {
  final doc=pw.Document();
  doc.addPage(pw.Page(build:(ctx)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
    pw.Center(child:pw.Text('BYE FASHIONS',style:pw.TextStyle(fontSize:24,fontWeight:pw.FontWeight.bold))),
    pw.Center(child:pw.Text('BEYOND YOUR EXPECTATIONS')),pw.SizedBox(height:25),
    pdfLine('Invoice',d['invoice']),pdfLine('Date',DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.tryParse(d['createdAt']??'')??DateTime.now())),
    pdfLine('Customer',d['customer']),pdfLine('Mobile',d['phone']??''),pw.Divider(),
    pdfLine('Product',d['product']),pdfLine('Quantity','${d['qty']}'),pdfLine('Unit price',money.format(numVal(d['unitPrice']))),
    pdfLine('Discount',money.format(numVal(d['discount']))),pw.Divider(),
    pdfLine('TOTAL',money.format(numVal(d['total']))),pdfLine('Payment',d['payment']),
    pw.SizedBox(height:30),pw.Center(child:pw.Text('Thank you for shopping with us!')),
  ])));
  await Printing.layoutPdf(onLayout:(format)=>doc.save());
}
pw.Widget pdfLine(String a,String b)=>pw.Padding(padding:const pw.EdgeInsets.symmetric(vertical:5),child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text(a),pw.Text(b)]));

class ExpensesPage extends StatelessWidget { const ExpensesPage({super.key});
  @override Widget build(BuildContext context)=>ValueListenableBuilder(valueListenable:expenses.listenable(),builder:(_,box,__) {
    final list=box.values.map((e)=>Map<String,dynamic>.from(e)).toList().reversed.toList();
    final total=list.fold(0.0,(s,e)=>s+numVal(e['amount']));
    return ListView(padding:const EdgeInsets.all(16),children:[
      sectionTitle('Expenses',subtitle:'Track rent, utilities, purchases and other costs'),
      statCard('Recorded expenses',money.format(total),Icons.account_balance_wallet_outlined),
      const SizedBox(height:14),ElevatedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ExpenseFormPage())),icon:const Icon(Icons.add),label:const Text('ADD EXPENSE')),
      const SizedBox(height:12),if(list.isEmpty)const EmptyState(text:'No expenses added yet.'),
      ...list.map((e)=>Card(child:ListTile(leading:const Icon(Icons.payments_outlined,color:gold),title:Text(e['title']??'Expense'),subtitle:Text('${e['category']} • ${dateFmt.format(DateTime.tryParse(e['date']??'')??DateTime.now())}'),trailing:Text(money.format(numVal(e['amount'])),style:const TextStyle(color:gold,fontWeight:FontWeight.bold)),onLongPress:()=>expenses.delete(e['id'])))),
    ]);
  });
}
class ExpenseFormPage extends StatefulWidget { const ExpenseFormPage({super.key}); @override State<ExpenseFormPage> createState()=>_ExpenseFormPageState(); }
class _ExpenseFormPageState extends State<ExpenseFormPage>{
  final title=TextEditingController(),amount=TextEditingController();String category='General';
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Add expense')),body:ListView(padding:const EdgeInsets.all(16),children:[
    TextField(controller:title,decoration:const InputDecoration(labelText:'Expense description')),
    const SizedBox(height:12),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount ₹')),
    const SizedBox(height:12),DropdownButtonFormField(value:category,decoration:const InputDecoration(labelText:'Category'),items:['General','Rent','Electricity','Internet','Transport','Stock purchase','Salary','Other'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>category=v??'General')),
    const SizedBox(height:18),ElevatedButton(onPressed:(){if(title.text.trim().isEmpty||numVal(amount.text)<=0)return;final k=id();expenses.put(k,{'id':k,'title':title.text.trim(),'amount':numVal(amount.text),'category':category,'date':DateTime.now().toIso8601String()});Navigator.pop(context);},child:const Text('SAVE EXPENSE')),
  ]));
}

class ReportsPage extends StatelessWidget { const ReportsPage({super.key});
  @override Widget build(BuildContext context)=>ValueListenableBuilder(valueListenable:sales.listenable(),builder:(_,box,__) {
    final all=box.values.toList();final revenue=all.fold(0.0,(s,e)=>s+numVal(e['total']));
    final cost=all.fold(0.0,(s,e)=>s+numVal(e['unitPrice'])*numVal(e['qty']));
    final expenseTotal=expenses.values.fold(0.0,(s,e)=>s+numVal(e['amount']));
    final gross=revenue-cost; final net=gross-expenseTotal;
    return ListView(padding:const EdgeInsets.all(16),children:[
      sectionTitle('Reports & analytics',subtitle:'Summary based on locally recorded transactions'),
      statCard('Total revenue',money.format(revenue),Icons.currency_rupee),
      const SizedBox(height:10),statCard('Estimated gross profit',money.format(gross),Icons.show_chart),
      const SizedBox(height:10),statCard('Total expenses',money.format(expenseTotal),Icons.money_off),
      const SizedBox(height:10),statCard('Estimated net',money.format(net),Icons.account_balance,color:net>=0?gold:Colors.orange),
      const SizedBox(height:18),sectionTitle('Sales by payment mode'),
      ...['Cash','UPI','Card','Bank transfer','Credit'].map((mode){final v=all.where((e)=>e['payment']==mode).fold(0.0,(s,e)=>s+numVal(e['total']));return Card(child:ListTile(title:Text(mode),trailing:Text(money.format(v),style:const TextStyle(color:gold))));}),
      const SizedBox(height:12),const Text('Profit is an estimate using current product purchase cost. Historical cost changes and tax treatment are not accounted for.',style:TextStyle(color:Colors.white38,fontSize:11)),
    ]);
  });
}

class SettingsPage extends StatelessWidget { const SettingsPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Settings & backup')),body:ListView(padding:const EdgeInsets.all(16),children:[
    sectionTitle('Business profile'),const Card(child:ListTile(leading:Icon(Icons.store,color:gold),title:Text('BYE FASHIONS'),subtitle:Text('Beyond Your Expectations'))),
    const SizedBox(height:18),sectionTitle('Data management'),
    Card(child:Column(children:[
      ListTile(leading:const Icon(Icons.download,color:gold),title:const Text('Export backup (JSON)'),subtitle:const Text('Save a copy of products, bills and expenses'),onTap:()=>exportBackup(context)),
      const Divider(height:1),
      ListTile(leading:const Icon(Icons.info_outline,color:gold),title:const Text('About this app'),subtitle:const Text('BYE FASHIONS Shop Management • v1.0.0')),
    ])),
    const SizedBox(height:16),const Text('Important: This first version stores data on this device/browser only. It does not sync automatically between Android and the website. Keep backup files safe. GST invoice configuration, barcode scanning, multi-item cart, customer ledger and cloud sync are not included in this starter release.',style:TextStyle(color:Colors.white54,height:1.5)),
  ]));
}
Future<void> exportBackup(BuildContext context) async {
  final data={'exportedAt':DateTime.now().toIso8601String(),'products':products.values.toList(),'sales':sales.values.toList(),'expenses':expenses.values.toList(),'customers':customers.values.toList()};
  final text=const JsonEncoder.withIndent('  ').convert(data);
  await Clipboard.setData(ClipboardData(text:text));
  if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Backup JSON copied to clipboard. Paste it into a file and save it safely.')));
}
