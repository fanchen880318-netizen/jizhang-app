import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _controller = TextEditingController();

  void _addCategory() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final success = await context.read<BillProvider>().addCategory(name);
    if (!mounted) return;

    if (success) {
      _controller.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该用途已存在'), backgroundColor: Colors.orange),
      );
    }
  }

  void _deleteCategory(int id, String name) {
    final provider = context.read<BillProvider>();
    if (provider.categories.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少保留一个用途'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除用途'),
        content: Text('确定删除「$name」吗？\n该用途下的账单不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCategory(id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用途管理'),
      ),
      body: Column(
        children: [
          // 添加区域
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '输入新用途名称',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: Consumer<BillProvider>(
              builder: (context, provider, _) {
                final cats = provider.categories;

                if (cats.isEmpty) {
                  return const Center(child: Text('暂无用-途'));
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: cats.length,
                  onReorderItem: (oldIndex, newIndex) {
                    provider.reorderCategories(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final cat = cats[index];
                    return Container(
                      key: ValueKey(cat.id),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getColor(index).withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              cat.name[0],
                              style: TextStyle(
                                color: _getColor(index),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        title: Text(cat.name, style: const TextStyle(fontSize: 16)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drag_handle, color: Colors.grey[300]),
                            const SizedBox(width: 8),
                            // 更明显的删除按钮
                            TextButton.icon(
                              onPressed: () => _deleteCategory(cat.id!, cat.name),
                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                              label: const Text('删除', style: TextStyle(fontSize: 13)),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[400],
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(int index) {
    const colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}
