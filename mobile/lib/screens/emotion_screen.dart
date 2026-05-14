import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/mood_provider.dart';

class BreathingExerciseScreen extends StatefulWidget {
  final TravelCategory category;
  final String location;

  const BreathingExerciseScreen({
    super.key,
    required this.category,
    required this.location,
  });

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  Timer? _timer;
  int _currentStep = 0;
  int _secondsRemaining = 0;
  bool _isActive = false;
  bool _isPaused = false;
  
  late List<BreathStep> _breathSteps;
  
  String _currentInstruction = '';
  String _currentAction = '';
  Color _currentColor = Colors.blue;
  
  @override
  void initState() {
    super.initState();
    _initBreathingPattern();
    _initAnimations();
  }
  
  void _initBreathingPattern() {
    switch (widget.category) {
      case TravelCategory.romantic:
        _breathSteps = [
          BreathStep('Inhale', 'Feel the love', 4, Colors.pink),
          BreathStep('Hold', 'Embrace the warmth', 4, Colors.redAccent),
          BreathStep('Exhale', 'Release with love', 6, Colors.purple),
        ];
        _currentColor = Colors.pink;
        break;
        
      case TravelCategory.active:
        _breathSteps = [
          BreathStep('Inhale', 'Prepare for adventure', 3, Colors.green),
          BreathStep('Hold', 'Feel the excitement', 2, Colors.lightGreen),
          BreathStep('Exhale', 'Release hesitation', 4, Colors.teal),
        ];
        _currentColor = Colors.green;
        break;
        
      case TravelCategory.calm:
        _breathSteps = [
          BreathStep('Inhale', 'Peace flows in', 6, Colors.blue),
          BreathStep('Hold', 'Stillness', 4, Colors.lightBlue),
          BreathStep('Exhale', 'Tension melts away', 8, Colors.cyan),
        ];
        _currentColor = Colors.blue;
        break;
        
      case TravelCategory.cultural:
        _breathSteps = [
          BreathStep('Inhale', 'Open to discovery', 5, Colors.purple),
          BreathStep('Hold', 'Embrace the wonder', 3, Colors.deepPurple),
          BreathStep('Exhale', 'Let curiosity flow', 5, Colors.indigo),
        ];
        _currentColor = Colors.purple;
        break;
        
      case TravelCategory.happy:
        _breathSteps = [
          BreathStep('Inhale', 'Joy fills your heart', 4, Colors.amber),
          BreathStep('Hold', 'Smile', 2, Colors.yellow),
          BreathStep('Exhale', 'Spread happiness', 4, Colors.orange),
        ];
        _currentColor = Colors.amber;
        break;
        
      case TravelCategory.food:
        _breathSteps = [
          BreathStep('Inhale', 'Enjoy the aroma', 4, Colors.deepOrange),
          BreathStep('Hold', 'Savor the moment', 3, Colors.orange),
          BreathStep('Exhale', 'Release satisfaction', 5, Colors.brown),
        ];
        _currentColor = Colors.deepOrange;
        break;
        
      case TravelCategory.shopping:
        _breathSteps = [
          BreathStep('Inhale', 'Energy builds', 3, Colors.pink),
          BreathStep('Hold', 'Excitement peaks', 2, Colors.pinkAccent),
          BreathStep('Exhale', 'Calm down', 5, Colors.purple),
        ];
        _currentColor = Colors.pink;
        break;
    }
    
    _currentInstruction = _breathSteps[0].instruction;
    _currentAction = _breathSteps[0].action;
    _secondsRemaining = _breathSteps[0].duration;
  }
  
  void _initAnimations() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    
    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _breathController.forward();
      }
    });
  }
  
  void _startExercise() {
    setState(() {
      _isActive = true;
      _isPaused = false;
      _currentStep = 0;
      _secondsRemaining = _breathSteps[0].duration;
      _currentInstruction = _breathSteps[0].instruction;
      _currentAction = _breathSteps[0].action;
      _currentColor = _breathSteps[0].color;
    });
    
    _breathController.forward();
    _startTimer();
  }
  
  void _pauseExercise() {
    setState(() {
      _isPaused = true;
      _isActive = false;
    });
    _timer?.cancel();
    _breathController.stop();
  }
  
  void _resumeExercise() {
    setState(() {
      _isPaused = false;
      _isActive = true;
    });
    _startTimer();
    _breathController.forward();
  }
  
  void _stopExercise() {
    setState(() {
      _isActive = false;
      _isPaused = false;
      _currentStep = 0;
      _secondsRemaining = _breathSteps[0].duration;
      _currentInstruction = _breathSteps[0].instruction;
      _currentAction = _breathSteps[0].action;
      _currentColor = _breathSteps[0].color;
    });
    _timer?.cancel();
    _breathController.stop();
    _breathController.reset();
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isActive || _isPaused) return;
      
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          if (_currentStep < _breathSteps.length - 1) {
            _currentStep++;
            _secondsRemaining = _breathSteps[_currentStep].duration;
            _currentInstruction = _breathSteps[_currentStep].instruction;
            _currentAction = _breathSteps[_currentStep].action;
            _currentColor = _breathSteps[_currentStep].color;
          } else {
            _currentStep = 0;
            _secondsRemaining = _breathSteps[0].duration;
            _currentInstruction = _breathSteps[0].instruction;
            _currentAction = _breathSteps[0].action;
            _currentColor = _breathSteps[0].color;
          }
        }
      });
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.displayName} Breathing'),
        backgroundColor: _currentColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _currentColor.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'In ${widget.location}',
                  style: TextStyle(
                    fontSize: 16,
                    color: _currentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _breathController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _isActive ? _opacityAnimation.value : 1.0,
                        child: Transform.scale(
                          scale: _isActive ? _scaleAnimation.value : 1.0,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _currentColor,
                                  _currentColor.withOpacity(0.5),
                                  _currentColor.withOpacity(0.2),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _currentColor.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentInstruction,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _currentAction,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '$_secondsRemaining',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'seconds',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_breathSteps.length, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index == _currentStep
                              ? _currentColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isActive && !_isPaused)
                      FloatingActionButton.extended(
                        onPressed: _startExercise,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        backgroundColor: _currentColor,
                      ),
                    
                    if (_isActive && !_isPaused)
                      FloatingActionButton.extended(
                        onPressed: _pauseExercise,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                        backgroundColor: _currentColor,
                      ),
                    
                    if (_isPaused)
                      FloatingActionButton.extended(
                        onPressed: _resumeExercise,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                        backgroundColor: _currentColor,
                      ),
                    
                    const SizedBox(width: 16),
                    
                    if (_isActive || _isPaused)
                      FloatingActionButton.extended(
                        onPressed: _stopExercise,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                        backgroundColor: Colors.grey,
                      ),
                  ],
                ),
              ),
              
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: _currentColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Sit comfortably with your back straight\n'
                      '• Close your eyes if you feel comfortable\n'
                      '• Focus on the sensation of your breath\n'
                      '• Let thoughts come and go without judgment',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BreathStep {
  final String instruction;
  final String action;
  final int duration;
  final Color color;
  
  BreathStep(this.instruction, this.action, this.duration, this.color);
}
