import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/mood_provider.dart';
import '../providers/map_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_logo.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final List<String> cities = ['Астана', 'Алматы'];

  final List<int> hourOptions = List.generate(24, (i) => i + 1);
  final List<int> dayOptions = List.generate(30, (i) => i + 1);

  void _showDurationPicker(BuildContext context, MoodProvider mp) {
    final color = mp.selectedCategory?.color ?? Colors.blue;
    final isHours = mp.durationUnit == DurationUnit.hours;

    int currentVal = isHours
        ? mp.durationHours.clamp(1, 24)
        : (mp.durationHours / 24).round().clamp(1, 30);
    int currentUnitIndex = isHours ? 0 : 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DurationPickerSheet(
          color: color,
          initialUnit: mp.durationUnit,
          initialHours: mp.durationHours,
          hourOptions: hourOptions,
          dayOptions: dayOptions,
          onConfirm: (DurationUnit unit, int value) {
            if (unit == DurationUnit.hours) {
              mp.setDurationUnit(DurationUnit.hours);
              mp.setDurationHours(value);
            } else {
              mp.setDurationUnit(DurationUnit.days);
              mp.setDurationHours(value * 24);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);
    final accentColor = moodProvider.selectedCategory?.color ?? Colors.blue;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const CustomLogo(size: 40),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(moodProvider.selectedCategory?.icon ?? Icons.emoji_emotions, color: Colors.white, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You choose: ${moodProvider.selectedCategory?.displayName ?? ''}",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "We'll create the perfect route for you",
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),

            const SizedBox(height: 30),

            const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.white),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: moodProvider.selectedCity.isEmpty ? null : moodProvider.selectedCity,
                  hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Select a city')),
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: cities.map((city) => DropdownMenuItem<String>(value: city, child: Text(city))).toList(),
                  onChanged: (value) => moodProvider.setCity(value!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: moodProvider.selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) moodProvider.setDate(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.white),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd.MM.yyyy').format(moodProvider.selectedDate), style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text('Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showDurationPicker(context, moodProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      moodProvider.durationUnit == DurationUnit.hours
                          ? Icons.schedule
                          : Icons.calendar_month,
                      color: accentColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      moodProvider.durationDisplay,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: accentColor),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Budget
            Text('Budget: \$${moodProvider.budget.round()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('\$50', style: TextStyle(color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: moodProvider.budget,
                    min: 50,
                    max: 5000,
                    divisions: 99,
                    activeColor: accentColor,
                    onChanged: (value) => moodProvider.setBudget(value),
                  ),
                ),
                const Text('\$5000', style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 30),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back', style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (moodProvider.selectedCity.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a city'), backgroundColor: Colors.red));
                      } else if (moodProvider.selectedCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a travel style'), backgroundColor: Colors.red));
                      } else {
                        final mapProvider = Provider.of<MapProvider>(context, listen: false);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final color = moodProvider.selectedCategory!.color;
                        final hex = '#${color.value.toRadixString(16).substring(2)}';
                        Navigator.pushNamed(context, '/map');
                        mapProvider.generateRoute(
                          userId: authProvider.currentUser?.id ?? '',
                          city: moodProvider.selectedCity,
                          category: moodProvider.selectedCategory!.displayName,
                          duration: moodProvider.duration,
                          budget: moodProvider.budget,
                          markerColor: hex,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Show Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationPickerSheet extends StatefulWidget {
  final Color color;
  final DurationUnit initialUnit;
  final int initialHours;
  final List<int> hourOptions;
  final List<int> dayOptions;
  final void Function(DurationUnit unit, int value) onConfirm;

  const _DurationPickerSheet({
    required this.color,
    required this.initialUnit,
    required this.initialHours,
    required this.hourOptions,
    required this.dayOptions,
    required this.onConfirm,
  });

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  late DurationUnit _unit;
  late int _selectedValue; // hours or days depending on _unit
  late FixedExtentScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialUnit;
    if (_unit == DurationUnit.hours) {
      _selectedValue = widget.initialHours.clamp(1, 24);
    } else {
      _selectedValue = (widget.initialHours / 24).round().clamp(1, 30);
    }
    _scrollCtrl = FixedExtentScrollController(initialItem: _selectedValue - 1);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<int> get _options => _unit == DurationUnit.hours ? widget.hourOptions : widget.dayOptions;

  void _switchUnit(DurationUnit unit) {
    if (_unit == unit) return;
    setState(() {
      _unit = unit;
      if (unit == DurationUnit.days) {
        _selectedValue = ((_selectedValue / 24).ceil()).clamp(1, 30);
      } else {
        _selectedValue = (_selectedValue * 24).clamp(1, 24);
      }
      _selectedValue = _selectedValue.clamp(1, _options.length);
      _scrollCtrl.jumpToItem(_selectedValue - 1);
    });
  }

  String _hoursLabel(int n) {
    if (n == 1) return 'час';
    if (n >= 2 && n <= 4) return 'часа';
    return 'часов';
  }

  String _daysLabel(int n) {
    if (n == 1) return 'день';
    if (n >= 2 && n <= 4) return 'дня';
    return 'дней';
  }

  String _label(int val) => _unit == DurationUnit.hours
      ? '$val ${_hoursLabel(val)}'
      : '$val ${_daysLabel(val)}';

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Выберите длительность',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 20),

          // Unit toggle (Часы / Дни)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _UnitTab(
                  label: 'Часы',
                  icon: Icons.schedule,
                  selected: _unit == DurationUnit.hours,
                  color: color,
                  onTap: () => _switchUnit(DurationUnit.hours),
                ),
                _UnitTab(
                  label: 'Дни',
                  icon: Icons.calendar_month,
                  selected: _unit == DurationUnit.days,
                  color: color,
                  onTap: () => _switchUnit(DurationUnit.days),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Drum roller (CupertinoPicker style)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection highlight
                Positioned(
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _scrollCtrl,
                  itemExtent: 48,
                  perspective: 0.003,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() => _selectedValue = _options[index]);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _options.length,
                    builder: (context, index) {
                      final val = _options[index];
                      final isSelected = val == _selectedValue;
                      return AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 17,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? color : Colors.grey.shade500,
                        ),
                        child: Center(child: Text(_label(val))),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(_unit, _selectedValue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'Выбрать: ${_label(_selectedValue)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _UnitTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
