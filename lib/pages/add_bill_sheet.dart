import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';

class AddBillSheet extends StatefulWidget {
  final Bill? bill;
  const AddBillSheet({super.key, this.bill});

  @override
  State<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<AddBillSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customCtrl = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  late bool _editing;

  @override
  void initState() {
    super.initState();
    _editing = widget.bill != null;
    if (widget.bill != null) {
      _amountCtrl.text = widget.bill!.amount.toStringAsFixed(2);
      _noteCtrl.text = widget.bill!.note;
      _selectedCategory = widget.bill!.category;
      _selectedDate = widget.bill!.date;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cats = context.read<BillProvider>().categories;
      if (_selectedCategory == null && cats.isNotEmpty) {
        setState(() => _selectedCategory = cats.first.name);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose(); _noteCtrl.dispose(); _customCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额'), backgroundColor: Color(0xFFE74C3C)));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择用途'), backgroundColor: Color(0xFFE74C3C)));
      return;
    }
    final provider = context.read<BillProvider>();
    if (_editing && widget.bill != null) {
      provider.updateBill(Bill(id: widget.bill!.id, amount: amt, category: _selectedCategory!, note: _noteCtrl.text.trim(), date: _selectedDate, createdAt: widget.bill!.createdAt));
    } else {
      provider.addBill(Bill(amount: amt, category: _selectedCategory!, note: _noteCtrl.text.trim(), date: _selectedDate));
    }
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now(), locale: const Locale('zh'));
    if (p != null) setState(() => _selectedDate = p);
  }

  void _addCustom() async {
    final name = _customCtrl.text.trim();
    if (name.isEmpty) return;
    final ok = await context.read<BillProvider>().addCategory(name);
    if (!mounted) return;
    if (ok) { _customCtrl.clear(); setState(() => _selectedCategory = name); }
    else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该用途已存在'), backgroundColor: Color(0xFFF39C12))); }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 顶部拖拽条
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            // 标题
            Row(children: [
              Text(_editing ? '编辑账单' : '记一笔', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const Spacer(),
            ]),
            const SizedBox(height: 24),

            // 金额输入
            const Text('金额', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                autofocus: !_editing,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFE67E22)),
                decoration: InputDecoration(
                  prefixIcon: const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('¥', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFE67E22)))),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44),
                  hintText: '0.00',
                  hintStyle: TextStyle(fontSize: 28, color: Colors.grey[300], fontWeight: FontWeight.w700),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 用途选择
            const Text('用途', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Consumer<BillProvider>(
              builder: (_, provider, child) => Wrap(spacing: 10, runSpacing: 10, children: [
                ...provider.categories.map((cat) {
                  final sel = _selectedCategory == cat.name;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFE67E22) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: sel
                            ? [BoxShadow(color: const Color(0xFFE67E22).withAlpha(50), blurRadius: 8, offset: const Offset(0, 3))]
                            : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: Text(cat.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: sel ? Colors.white : const Color(0xFF555555))),
                    ),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 16),

            // 自定义用途
            Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))]),
                  child: TextField(
                    controller: _customCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(hintText: '自定义用途', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: InputBorder.none),
                    onSubmitted: (_) => _addCustom(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE67E22), Color(0xFFD35400)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFFE67E22).withAlpha(40), blurRadius: 8, offset: const Offset(0, 3))]),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _addCustom,
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13), child: Icon(Icons.add, color: Colors.white, size: 22)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // 日期
            const Text('日期', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))]),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 18, color: Color(0xFFE67E22)),
                  const SizedBox(width: 10),
                  Text(DateFormat('yyyy年M月d日').format(_selectedDate), style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // 备注
            const Text('备注', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _noteCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(hintText: '添加备注说明...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 28),

            // 保存
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                child: Text(_editing ? '更新' : '保存', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
