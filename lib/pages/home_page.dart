import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';
import '../services/excel_service.dart';
import 'add_bill_sheet.dart';
import 'category_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showAmount = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadData();
    });
  }

  void _showAddBillSheet({Bill? bill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBillSheet(bill: bill),
    );
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<BillProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: provider.dateRange,
      locale: const Locale('zh'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF5B2444))),
        child: child!,
      ),
    );
    if (picked != null) provider.setDateRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1E0D7),
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.account_balance_wallet, size: 22),
          SizedBox(width: 8),
          Text('记账', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: const Color(0xFF5B2444),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.visibility_outlined), tooltip: '隐藏金额', onPressed: () => setState(() => _showAmount = !_showAmount)),
          IconButton(icon: const Icon(Icons.category_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryPage()))),
          IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportPage()))),
        ],
      ),
      body: Consumer<BillProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF5B2444)));
          return Column(children: [
            _buildHeaderCard(provider),
            _buildFilterChips(provider),
            Expanded(child: _buildBillList(provider)),
          ]);
        },
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _showAddBillSheet(),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF5B2444), Color(0xFF3D1529)]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0xFF5B2444).withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BillProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5B2444), Color(0xFF3D1529)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF5B2444).withAlpha(60), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Row(children: [
          const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.savings_outlined, size: 18, color: Colors.white70),
            SizedBox(width: 6),
            Text('支出合计', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  provider.dateRange != null ? '${DateFormat('M.d').format(provider.dateRange!.start)} - ${DateFormat('M.d').format(provider.dateRange!.end)}' : '全部日期',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (provider.dateRange != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(onTap: () => provider.setDateRange(null), child: const Icon(Icons.close, size: 14, color: Colors.white54)),
                ],
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Padding(padding: EdgeInsets.only(bottom: 6, right: 6), child: Icon(Icons.account_balance_wallet, size: 28, color: Colors.white70)),
          Text(_showAmount ? '¥${NumberFormat('#,###.00').format(provider.totalAmount)}' : '¥****', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildBadge(Icons.receipt_long_outlined, '共 ${provider.bills.length} 笔'),
          const SizedBox(width: 12),
          _buildBadge(Icons.trending_down, provider.bills.isNotEmpty ? '日均 ¥${(provider.totalAmount / provider.groupedBills.length).toStringAsFixed(0)}' : '暂无数据'),
        ]),
      ]),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildFilterChips(BillProvider provider) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip('全部', Icons.list_alt, provider.filterCategory == null, () => provider.setFilterCategory(null)),
          ...provider.categories.map((cat) => _buildChip(cat.name, _catIcon(cat.name), provider.filterCategory == cat.name, () => provider.setFilterCategory(cat.name))),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5B2444) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFF5B2444).withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF7B7774)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF7B7774), fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildBillList(BillProvider provider) {
    if (provider.bills.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF5B2444).withAlpha(20), borderRadius: BorderRadius.circular(40)), child: const Icon(Icons.receipt_long, size: 40, color: Color(0xFF5B2444))),
          const SizedBox(height: 20),
          const Text('还没有账单', style: TextStyle(fontSize: 17, color: Color(0xFF7B7774))),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('点击 ', style: TextStyle(fontSize: 14, color: Color(0xFF7B7774))),
            Container(width: 28, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF5B2444), Color(0xFF3D1529)]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.add, size: 18, color: Colors.white)),
            const Text(' 开始记账', style: TextStyle(fontSize: 14, color: Color(0xFF7B7774))),
          ]),
        ]),
      );
    }

    final grouped = provider.groupedBills;
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedKeys.length,
      itemBuilder: (_, index) {
        final dateKey = sortedKeys[index];
        final dayBills = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        final dayTotal = dayBills.fold<double>(0, (s, b) => s + b.amount);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF5B2444), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('${date.month}月${date.day}日', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF211E21))),
              const SizedBox(width: 8),
              Text(_weekday(date), style: const TextStyle(fontSize: 13, color: Color(0xFF7B7774))),
              const Spacer(),
              const Icon(Icons.monetization_on_outlined, size: 14, color: Color(0xFF5B2444)),
              const SizedBox(width: 4),
              Text('¥${dayTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: Color(0xFF5B2444), fontWeight: FontWeight.w500)),
            ]),
          ),
          ...dayBills.map((bill) => _buildBillCard(bill)),
        ]);
      },
    );
  }

  Widget _buildBillCard(Bill bill) {
    final color = _catColor(bill.category);
    return GestureDetector(
      onTap: () => _showAddBillSheet(bill: bill),
      onLongPress: () => _confirmDelete(bill),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))]),
        child: IntrinsicHeight(child: Row(children: [
          Container(width: 4, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: Icon(_catIcon(bill.category), size: 22, color: color)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(bill.category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF211E21))),
                if (bill.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(bill.note, style: const TextStyle(fontSize: 13, color: Color(0xFF7B7774)), overflow: TextOverflow.ellipsis)),
              ])),
              Text(_showAmount ? '¥${NumberFormat('#,###.00').format(bill.amount)}' : '¥****', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF5B2444))),
            ])),
          ),
        ])),
      ),
    );
  }

  IconData _catIcon(String name) {
    const map = {
      '网采': Icons.shopping_cart_outlined, '还款': Icons.credit_card_outlined, '地采': Icons.storefront_outlined,
      '餐饮': Icons.restaurant_outlined, '交通': Icons.directions_car_outlined, '购物': Icons.shopping_bag_outlined,
      '娱乐': Icons.sports_esports_outlined, '医疗': Icons.medication_outlined, '教育': Icons.school_outlined,
      '住房': Icons.home_outlined, '通讯': Icons.phone_android_outlined, '日用': Icons.cleaning_services_outlined,
    };
    return map[name] ?? Icons.label_outline;
  }

  String _weekday(DateTime d) { const w = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']; return w[d.weekday - 1]; }

  Color _catColor(String name) {
    const cs = [Color(0xFF5B2444), Color(0xFF457B9D), Color(0xFF40916C), Color(0xFF9B59B6), Color(0xFF2A9D8F), Color(0xFFC1121F), Color(0xFF5B2444), Color(0xFF1D3557)];
    return cs[name.hashCode.abs() % cs.length];
  }

  void _confirmDelete(Bill bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.delete_outline, color: Color(0xFFC1121F)), SizedBox(width: 8), Text('删除确认')]),
        content: Text('确定删除 ¥${NumberFormat('#,###.00').format(bill.amount)} 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Color(0xFF7B7774)))),
          TextButton(onPressed: () { context.read<BillProvider>().deleteBill(bill.id!); Navigator.pop(ctx); }, child: const Text('删除', style: TextStyle(color: Color(0xFFC1121F)))),
        ],
      ),
    );
  }
}

// ── 导出页（带独立日期选择）──
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});
  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  DateTimeRange? _exportRange;
  List<Bill> _previewBills = [];
  double _previewTotal = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    final provider = context.read<BillProvider>();
    final bills = await provider.getExportBillsForRange(_exportRange);
    final total = await provider.getExportTotalForRange(_exportRange);
    if (mounted) {
      setState(() { _previewBills = bills; _previewTotal = total; _loading = false; });
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _exportRange,
      locale: const Locale('zh'),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF5B2444))), child: child!),
    );
    if (picked != null) {
      setState(() => _exportRange = picked);
      _loadPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1E0D7),
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.file_upload_outlined, size: 22), SizedBox(width: 8), Text('导出账单')]),
        backgroundColor: const Color(0xFF5B2444),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // 日期选择卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(children: [
              // 日期选择按钮
              GestureDetector(
                onTap: _pickRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF5B2444).withAlpha(50)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF5B2444).withAlpha(10),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.date_range, color: Color(0xFF5B2444)),
                    const SizedBox(width: 10),
                    Text(
                      _exportRange != null
                          ? '${DateFormat('yyyy-MM-dd').format(_exportRange!.start)} ~ ${DateFormat('yyyy-MM-dd').format(_exportRange!.end)}'
                          : '点击选择导出日期范围',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _exportRange != null ? const Color(0xFF211E21) : const Color(0xFF7B7774)),
                    ),
                    if (_exportRange != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () { setState(() => _exportRange = null); _loadPreview(); },
                        child: const Icon(Icons.close, size: 18, color: Color(0xFF7B7774)),
                      ),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const CircularProgressIndicator(color: Color(0xFF5B2444))
              else ...[
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF40916C)]), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.table_chart, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text('共 ${_previewBills.length} 笔', style: const TextStyle(fontSize: 14, color: Color(0xFF7B7774))),
                const SizedBox(height: 4),
                Text('¥${NumberFormat('#,###.00').format(_previewTotal)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF211E21))),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading || _previewBills.isEmpty ? null : () => _export(),
              icon: const Icon(Icons.file_download),
              label: const Text('导出为 Excel (.xlsx)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('自动调起分享面板，支持微信/QQ', style: TextStyle(fontSize: 13, color: Color(0xFF7B7774))),
        ]),
      ),
    );
  }

  Future<void> _export() async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF5B2444))));
      await ExcelService.exportAndShare(_previewBills, _previewTotal, '账单_${DateFormat('yyyyMMdd').format(DateTime.now())}');
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red)); }
    }
  }
}
