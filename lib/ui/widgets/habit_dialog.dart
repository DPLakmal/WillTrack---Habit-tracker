import 'package:flutter/material.dart';
import 'habit_symbol_icon.dart';

class HabitDialog extends StatefulWidget {
  final String? initialName;
  final String? initialCategory;
  final String? initialSymbol;
  final int? initialColor;
  final String title;
  final String confirmLabel;

  const HabitDialog({
    super.key,
    this.initialName,
    this.initialCategory,
    this.initialSymbol,
    this.initialColor,
    required this.title,
    this.confirmLabel = 'Save',
  });

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class HabitDialogResult {
  final String name;
  final String category;
  final String symbol;
  final int colorValue;

  HabitDialogResult({
    required this.name,
    required this.category,
    required this.symbol,
    required this.colorValue,
  });
}

class _HabitDialogState extends State<HabitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  late String _selectedSymbol;
  late int _selectedColor;

  final List<String> _suggestedCategories = [
    'General',
    'Fitness',
    'Health',
    'Learning',
    'Mindfulness',
    'Work',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedCategory = widget.initialCategory ?? 'General';
    _categoryController = TextEditingController(text: _selectedCategory);
    _selectedSymbol = widget.initialSymbol ?? 'check';
    _selectedColor = widget.initialColor ?? HabitColors.palette[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final category = _categoryController.text.trim().isEmpty
          ? _selectedCategory
          : _categoryController.text.trim();

      Navigator.of(context, rootNavigator: true).pop(
        HabitDialogResult(
          name: name,
          category: category,
          symbol: _selectedSymbol,
          colorValue: _selectedColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Habit Name input
                const Text(
                  'Habit Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  autofocus: widget.initialName == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'e.g. Daily Swimming, Read 20 mins',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a habit name';
                    }
                    if (value.trim().length > 100) {
                      return 'Habit name is too long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category selector
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _suggestedCategories.map((cat) {
                    final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                            _categoryController.text = cat;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Or enter custom category',
                    isDense: true,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                ),
                const SizedBox(height: 18),

                // Symbol picker
                const Text(
                  'Completion Symbol',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HabitSymbols.options.map((opt) {
                    final isSelected = _selectedSymbol == opt.key;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedSymbol = opt.key;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(_selectedColor).withValues(alpha: 0.2)
                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Color(_selectedColor)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          opt.icon,
                          size: 22,
                          color: isSelected
                              ? Color(_selectedColor)
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Color palette
                const Text(
                  'Color Theme',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: HabitColors.palette.map((colorVal) {
                    final isSelected = _selectedColor == colorVal;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorVal;
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(colorVal).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Color(_selectedColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
