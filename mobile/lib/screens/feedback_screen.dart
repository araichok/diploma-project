import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/map_provider.dart';

const _moodEmojis = ['😞', '😕', '😐', '🙂', '😄'];
const _moodLabels = ['Bad', 'Not great', 'Neutral', 'Good', 'Great'];

class FeedbackScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const FeedbackScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int? _beforeMood;
  int? _afterMood;
  int _categoryScore = 2; // 0–4
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final captured =
          Provider.of<MapProvider>(context, listen: false).beforeMood;
      if (captured != null && mounted) {
        setState(() => _beforeMood = captured);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _categoryQuestion(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('relax') || c.contains('calm') || c.contains('спокой')) {
      return 'How well did you manage to unwind?';
    }
    if (c.contains('adventure') || c.contains('active') || c.contains('приключ')) {
      return 'Did you get an energy boost?';
    }
    if (c.contains('cultur') || c.contains('histor') || c.contains('культур')) {
      return 'How much did the route enrich you?';
    }
    if (c.contains('food') || c.contains('gastro') || c.contains('еда')) {
      return 'How tasty was the journey?';
    }
    if (c.contains('nature') || c.contains('park') || c.contains('природ')) {
      return 'Did nature recharge you?';
    }
    if (c.contains('social') || c.contains('социал')) {
      return 'How did the socializing go?';
    }
    return 'Did the route meet your expectations?';
  }

  List<String> _sliderLabels(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('relax') || c.contains('спокой')) return ['Still tense', 'Total zen'];
    if (c.contains('adventure') || c.contains('приключ')) return ['Felt boring', 'Pure adrenaline'];
    if (c.contains('cultur')) return ['Nothing new', 'Learned a lot'];
    if (c.contains('food') || c.contains('еда')) return ['Not impressed', 'Absolutely delicious'];
    if (c.contains('nature') || c.contains('природ')) return ['No recharge', 'Fully recharged'];
    return ['Not at all', 'Absolutely'];
  }

  String _deltaText() {
    if (_beforeMood == null || _afterMood == null) return '';
    final d = _afterMood! - _beforeMood!;
    if (d >= 2) return 'Mood improved a lot! 🚀';
    if (d == 1) return 'Feeling a bit better 😊';
    if (d == 0) return 'About the same 😌';
    if (d == -1) return 'A little tired... 😴';
    return 'Maybe this route wasn\'t the right fit 💭';
  }

  Color _deltaColor() {
    if (_beforeMood == null || _afterMood == null) return Colors.grey;
    final d = _afterMood! - _beforeMood!;
    if (d >= 1) return Colors.green;
    if (d == 0) return Colors.blueGrey;
    return Colors.orange;
  }

  Future<void> _submit(BuildContext context) async {
    if (_afterMood == null) return;
    final feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final category =
        Provider.of<MoodProvider>(context, listen: false).selectedCategory?.displayName ?? '';

    setState(() => _submitting = true);

    final before = _beforeMood != null ? _moodEmojis[_beforeMood!] : '?';
    final after = _moodEmojis[_afterMood!];
    final catQ = _categoryQuestion(category);
    final stars = '⭐' * (_categoryScore + 1);
    var comment = 'Before: $before → After: $after | $catQ $stars';
    if (_commentController.text.trim().isNotEmpty) {
      comment += '\n${_commentController.text.trim()}';
    }

    final success = await feedbackProvider.submitFeedback(
      userId: authProvider.currentUser!.id,
      userName: authProvider.currentUser!.name,
      routeId: widget.routeId,
      routeName: widget.routeName,
      rating: (_afterMood! + 1).toDouble(),
      comment: comment,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Thanks! Your impressions have been saved.'
          : 'Failed to submit. Please try again.'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final color = moodProvider.selectedCategory?.color ?? Colors.blue;
    final category = moodProvider.selectedCategory?.displayName ?? '';
    final catQuestion = _categoryQuestion(category);
    final labels = _sliderLabels(category);
    final beforeCaptured =
        Provider.of<MapProvider>(context, listen: false).beforeMood != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Your Journey Diary'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Route completed ✓',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(widget.routeName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(category,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Before mood
            _SectionLabel(
              beforeCaptured
                  ? 'Your mood at the start of the route'
                  : 'How were you feeling BEFORE the walk?',
            ),
            const SizedBox(height: 12),
            beforeCaptured
                ? _ReadOnlyMood(index: _beforeMood!, color: Colors.blueGrey)
                : _MoodPicker(
                    selected: _beforeMood,
                    onSelect: (i) => setState(() => _beforeMood = i),
                    activeColor: Colors.blueGrey,
                  ),

            const SizedBox(height: 28),

            // After mood
            _SectionLabel('How do you feel NOW, after the route?'),
            const SizedBox(height: 12),
            _MoodPicker(
              selected: _afterMood,
              onSelect: (i) => setState(() => _afterMood = i),
              activeColor: color,
            ),

            // Delta banner
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: (_beforeMood != null && _afterMood != null)
                  ? Container(
                      key: const ValueKey('delta'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _deltaColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _deltaColor().withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_moodEmojis[_beforeMood!]}  →  ${_moodEmojis[_afterMood!]}',
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _deltaText(),
                              style: TextStyle(
                                color: _deltaColor(),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty')),
            ),

            const SizedBox(height: 28),

            // Category question slider
            _SectionLabel(catQuestion),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                    child: Text(labels[0],
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                Expanded(
                    child: Text(labels[1],
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        textAlign: TextAlign.end)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withOpacity(0.2),
                overlayColor: color.withOpacity(0.12),
                trackHeight: 6,
              ),
              child: Slider(
                value: _categoryScore.toDouble(),
                min: 0,
                max: 4,
                divisions: 4,
                onChanged: (v) => setState(() => _categoryScore = v.round()),
              ),
            ),
            Center(
              child: Text(
                _moodEmojis[_categoryScore],
                style: const TextStyle(fontSize: 32),
              ),
            ),

            const SizedBox(height: 28),

            // Optional comment
            _SectionLabel('Want to add anything?', optional: true),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Free thoughts, impressions...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_afterMood != null && !_submitting)
                    ? () => _submit(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Share my impressions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool optional;
  const _SectionLabel(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text('(optional)',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ],
    );
  }
}

class _ReadOnlyMood extends StatelessWidget {
  final int index;
  final Color color;
  const _ReadOnlyMood({required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(_moodEmojis[index], style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Text(
            _moodLabels[index],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _MoodPicker extends StatelessWidget {
  final int? selected;
  final void Function(int) onSelect;
  final Color activeColor;

  const _MoodPicker({
    required this.selected,
    required this.onSelect,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final on = selected == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 58,
            height: 68,
            decoration: BoxDecoration(
              color: on ? activeColor.withOpacity(0.14) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: on ? activeColor : Colors.grey[300]!,
                width: on ? 2 : 1,
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                          color: activeColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_moodEmojis[i], style: TextStyle(fontSize: on ? 28 : 22)),
                const SizedBox(height: 3),
                Text(
                  _moodLabels[i],
                  style: TextStyle(
                    fontSize: 9,
                    color: on ? activeColor : Colors.grey[500],
                    fontWeight: on ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
