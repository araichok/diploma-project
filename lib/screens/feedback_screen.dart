import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/auth_provider.dart';
import '../models/feedback.dart';

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
  double _rating = 0;
  final _commentController = TextEditingController();
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    final feedbackProvider = Provider.of<FeedbackProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final existingFeedback = feedbackProvider.getUserFeedback(
      authProvider.currentUser!.id,
      widget.routeId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'How was your trip to\n${widget.routeName}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = index + 1;
                      _rating = (index + 1).toDouble();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      size: 50,
                      color: Colors.amber,
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            Text(
              _selectedRating > 0 ? 'You rated: $_selectedRating/5' : 'Tap to rate',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 32),
            
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Share your experience...',
                hintText: 'What did you like? Any suggestions?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (existingFeedback == null)
              ElevatedButton(
                onPressed: _selectedRating == 0 ? null : () {
                  final feedback = RouteFeedback(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: authProvider.currentUser!.id,
                    userName: authProvider.currentUser!.name,
                    routeId: widget.routeId,
                    routeName: widget.routeName,
                    rating: _rating,
                    comment: _commentController.text.isEmpty 
                        ? 'No comment' 
                        : _commentController.text,
                    createdAt: DateTime.now(),
                  );
                  
                  feedbackProvider.addFeedback(feedback);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your feedback!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit Feedback'),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < existingFeedback.rating.toInt() 
                                  ? Icons.star 
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 30,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You already rated: ${existingFeedback.rating}/5',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${existingFeedback.comment}"',
                          style: TextStyle(color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}