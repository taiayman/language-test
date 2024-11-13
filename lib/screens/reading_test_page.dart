import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:alc_eljadida_tests/screens/home_page.dart';
import 'package:alc_eljadida_tests/services/auth_service.dart';
import 'package:alc_eljadida_tests/services/test_results_service.dart';
import 'package:alc_eljadida_tests/models/test_result.dart';
import 'package:alc_eljadida_tests/services/test_session_service.dart';
import 'package:alc_eljadida_tests/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alc_eljadida_tests/services/score_calculator.dart';

class ReadingTestPage extends StatefulWidget {
  final Duration? remainingTime;
  final String firstName;
  final String lastName;
  final Function(Duration, int)? onTestComplete;
  
  const ReadingTestPage({
    Key? key, 
    this.remainingTime,
    required this.firstName,
    required this.lastName,
    this.onTestComplete,
  }) : super(key: key);

  @override
  _ReadingTestPageState createState() => _ReadingTestPageState();
}

class _ReadingTestPageState extends State<ReadingTestPage> {
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  final int _totalTimeInMinutes = 20;  // Test duration in minutes
  late Timer _timer;
  late Duration _remainingTime;
  double _progress = 1.0;
  final TestSessionService _testSessionService = TestSessionService();
  DateTime _startTime = DateTime.now();

final List<Map<String, dynamic>> _readingTests = [
  {
    'passage': '''Passage 1: An email, Subject: Greetings from Florida!

Hi, Sara.
I'm visiting my sister in Florida. It's very warm and nice here. Every morning, I go to the beach and swim.
Sometimes my sister comes home early, and we play tennis in the afternoon. And we always go for a long
walk after that. I'm having a great time!

Love,
Heather''',
    'questions': [
      {
        'question': 'Heather _____ every day.',
        'options': [
          'a) swims',
          'b) plays tennis',
          'c) comes home early',
          'd) walks with her sister'
        ],
        'correctAnswer': 'a) swims'
      }
    ]
  },
  {
    'passage': '''Passage 2: Helen is getting married and I'm tired.

This has been a crazy week! One of my friends is getting married on Saturday, and I'm helping her with
the reception. It's not going to be a big party, but I still have to do a lot of things. For example, I chose the
songs last week, but the band is playing them for me tonight. I bought the flowers today, but I have to
pick them up on Friday. I'm tired. Can someone help me, please?!''',
    'questions': [
      {
        'question': 'The writer _____.',
        'options': [
          'a) is singing tonight',
          'b) is buying flowers on Friday',
          'c) listened to a band a week ago',
          'd) is going to a party this weekend'
        ],
        'correctAnswer': 'd) is going to a party this weekend'
      }
    ]
  },
  {
    'passage': '''Passage 3: The Whitney Museum of American Art

The Whitney is one of the most famous art museums in New York City. It first opened in 1931 in
Greenwich Village, and then it moved to two different places in 1954 and 1966. Since 2015, this museum
of American art has been in a new building downtown. The new space is larger and more modern, and it
has beautiful views of the Hudson River from its windows and café. Visit it next time you are in the city.''',
    'questions': [
      {
        'question': 'The Whitney Museum _____.',
        'options': [
          'a) shows art from many countries',
          'b) moved to a smaller place in 2015',
          'c) has a place to eat and great views',
          'd) was in the same building since 1931'
        ],
        'correctAnswer': 'c) has a place to eat and great views'
      }
    ]
  },
  {
    'passage': '''Passage 4: Is sitting unhealthy?

If you have been sitting in an office for a long period of time, stand up and move for your health.
Research has shown that too much sitting might cause higher blood pressure, add body fat, and increase
the danger of death from heart disease. Studies have also suggested that moving more has a positive
effect on a person's health. So, what can an office worker do? Experts say that you should take a break
from sitting every 30 minutes, stand more while working, and even walk when meeting with coworkers.
Moving might save your life.''',
    'questions': [
      {
        'question': 'The article suggests that _____.',
        'options': [
          'a) there is very little research about the effects of sitting',
          'b) sitting for a long time might be dangerous for your health',
          'c) office workers live longer than other types of workers',
          'd) people do not usually like to walk and exercise'
        ],
        'correctAnswer': 'b) sitting for a long time might be dangerous for your health'
      },
      {
        'question': 'According to the article, office workers should _____.',
        'options': [
          'a) stop working every half hour',
          'b) not work in an office if possible',
          'c) only stand or walk when you work',
          'd) move more to avoid serious heart problems'
        ],
        'correctAnswer': 'd) move more to avoid serious heart problems'
      }
    ]
  },
  {
    'passage': '''Passage 5: A changing neighborhood – for better or for worse?

Recently, an international online retailer opened an enormous, brand-new office in our neighborhood.
Until then, there hadn't been any major companies or huge buildings like this in the area – just small
family-owned businesses. So, obviously, there has been a lot of discussion about it lately.

Some people say the company is creating jobs and will attract other new businesses, but others
complain that most of the new jobs will be low-paying. These people also believe that rising costs will
push out independent businesses and make the neighborhood too expensive for its current residents.

I can't make up my mind whether the company will be a benefit for the neighborhood or not. It's a
complicated issue, and I'm not sure there is a right or wrong answer. What do you think?''',
    'questions': [
      {
        'question': 'The author of the blog post believes that _____.',
        'options': [
          'a) there may be both positive and negative consequences',
          'b) the changes will be helpful for most workers from the region',
          'c) there will soon be many more big companies in the neighborhood',
          'd) the changes will be mostly harmful for people who live in the area'
        ],
        'correctAnswer': 'a) there may be both positive and negative consequences'
      },
      {
        'question': 'Some people think the company will help the area because it will _____.',
        'options': [
          'a) create a greater number of jobs with excellent salaries',
          'b) make the area more interesting to other companies',
          'c) lower the cost of living in the neighborhood',
          'd) replace smaller stores with larger ones'
        ],
        'correctAnswer': 'b) make the area more interesting to other companies'
      }
    ]
  },
  {
    'passage': '''Passage 6: An inspiring story

When Alex McGovern was in high school, he used to earn money working weekends at a local bakery.
After working there for several months, helping bake fresh bread and cakes, Alex noticed a familiar
pattern: a huge amount of food was thrown away at the end of each day. It was food that the bakery
could no longer sell, but it was still good enough to eat. So Alex began to wonder what he could do with
all of this extra food.

With the bakery owner's permission, he reached out to a local organization that worked with families
who need help with food and housing. The charity was extremely pleased and arranged to pick up the
extra food each day. Now bread was no longer wasted, but generously shared with people in need.

Alex's idea was such a success that he began approaching other local restaurants about joining the
program. Before long, there were over a dozen businesses taking part, and Alex created a website to
grow the program in other cities. Today Alex's "simple" idea is helping feed people all over the country!''',
    'questions': [
      {
        'question': "Alex's original goal at the bakery was to _____.",
        'options': [
          'a) eat free bread and cake',
          'b) learn to be a baker',
          'c) make money',
          'd) help people'
        ],
        'correctAnswer': 'c) make money'
      },
      {
        'question': 'Alex got his idea _____.',
        'options': [
          'a) when he saw how much food was wasted',
          'b) while he was baking some fresh bread',
          'c) from the owner of the bakery',
          'd) from a local organization'
        ],
        'correctAnswer': 'a) when he saw how much food was wasted'
      },
      {
        'question': 'The bakery owner _____.',
        'options': [
          'a) thought that Alex\'s plans wouldn\'t work',
          'b) allowed Alex to give away the extra bread',
          'c) helped Alex create a website for the organization',
          'd) didn\'t care about the families assisted by the charity'
        ],
        'correctAnswer': 'b) allowed Alex to give away the extra bread'
      },
      {
        'question': 'The extra food was _____.',
        'options': [
          'a) sold by Alex',
          'b) bought by the charity',
          'c) delivered by the bakery',
          'd) picked up by the organization'
        ],
        'correctAnswer': 'd) picked up by the organization'
      }
    ]
  },
  {
    'passage': '''Passage 7: Some thoughts on your online profile

In many ways, the internet has made it easier than ever to find out about new job opportunities.
Yet, as companies increasingly examine candidates' social media profiles for information to use in the
selection process, people need to be aware of the risks and rewards of posting online. The views they
express—and the ways they choose to express them—can be a crucial factor in whether or not they
receive an offer of employment.

Many young adults, who have grown up with social media and are comfortable sharing their lives
online, don't realize how employers are using social media in hiring decisions. These companies don't just
consider information about a person's online behavior; they may even gather information about friends
and family. Some fear that employers may judge candidates based on factors such as their medical
history, age, or even beliefs.

While there is currently debate about what information companies are allowed to legally collect or use
for hiring decisions, everyone agrees that people need to be careful about what they post online. Your
behavior on social media could cost you your current position or job opportunities in the future.

So, should job applicants erase their social media accounts completely? According to Professor John
Sacks of the Better Hiring Institute, "It would be better to make sure you have a strong professional profile
that emphasizes your qualifications. Not having any social media might send the message that you
have something to hide." In other words, take the time to create an attractive profile on a career site and
carefully consider everything you post online.''',
    'questions': [
      {
        'question': 'This article is aimed primarily at _____.',
        'options': [
          'a) employers',
          'b) college students',
          'c) potential job candidates',
          'd) social media organizations'
        ],
        'correctAnswer': 'c) potential job candidates'
      },
      {
        'question': 'According to the author, some people may not realize _____.',
        'options': [
          'a) the effect of their online behavior on friends and family',
          'b) how their online profiles can affect hiring decisions',
          'c) what information companies cannot legally collect',
          'd) if their online profile looks professional enough'
        ],
        'correctAnswer': 'b) how their online profiles can affect hiring decisions'
      },
      {
        'question': 'One way of increasing your chances of getting a good job is _____.',
        'options': [
          'a) not keeping a profile online',
          'b) expressing your opinions in a honest way',
          'c) having a profile that clearly shows your skills',
          'd) being secretive about what you share online'
        ],
        'correctAnswer': 'c) having a profile that clearly shows your skills'
      },
      {
        'question': 'The author _____ online personal information to make hiring decisions.',
        'options': [
          'a) is against companies using',
          'b) is in favor of the practice of using',
          'c) believes it does not matter if employers use',
          'd) does not say whether it is good or bad to use'
        ],
        'correctAnswer': 'd) does not say whether it is good or bad to use'
      }
    ]
  },
  {
    'passage': '''Passage 8: Sleep deprivation

If you can sleep well, be grateful. Sleep deprivation is extremely common, and its side effects are both
serious and underappreciated. It is estimated that 50–70 million people in the U.S. suffer from a sleep
disorder, and yet too many of them do not seek medical help. Although occasional sleep interruptions
are generally no more than a nuisance, continuous lack of sleep can lead to excessive daytime sleepiness,
emotional difficulties, poor job performance, and even obesity.

Sleep deprivation also impacts mental well-being. A study done by the U.K. Mental Health Foundation
found that people who didn't get enough sleep were about three times more likely to exhibit poor
concentration and four times more likely to have relationship problems. According to another study, by
the University of Warwick, getting less than six hours of sleep on a continuous basis makes a person 48%
more likely to die of heart disease and 15% more likely to develop a stroke. According to study co-author
Professor Francesco Cappuccio, lack of sleep "is like a ticking time bomb for your health."

If a person is experiencing difficulties falling and staying asleep, there are several effective methods
that can help and do not require medication. These include relaxation techniques, like tightening and
relaxing muscles, breathing slowly, and meditating; stimulation control, which involves controlling
pre-bedtime activities and surroundings; and cognitive behavioral therapy (CBT), designed to help people
understand and change their thought patterns. If sleep deprivation and negative symptoms continue,
however, consultation with a doctor is recommended. It's essential not to underestimate the importance
of adequate sleep to maintaining good mental and physical health.''',
    'questions': [
      {
        'question': 'The main idea of the article is that _____.',
        'options': [
          'a) lack of sleep can have significant health consequences',
          'b) sleeping is not as essential as people used to think',
          'c) people underestimate how much sleep they need',
          'd) relaxation techniques are important for a good night\'s sleep'
        ],
        'correctAnswer': 'a) lack of sleep can have significant health consequences'
      },
      {
        'question': 'According to the article, many people with sleeping disorders _____.',
        'options': [
          'a) breathe more slowly',
          'b) do cognitive behavioral therapy',
          'c) do not speak to their doctor about it',
          'd) usually practice healthy sleeping habits'
        ],
        'correctAnswer': 'c) do not speak to their doctor about it'
      },
      {
        'question': 'The article suggests that good sleepers _____.',
        'options': [
          'a) can focus better',
          'b) often get about eight hours of good sleep',
          'c) are able to sleep during the day',
          'd) do not have heart problems'
        ],
        'correctAnswer': 'a) can focus better'
      },
      {
        'question': 'Professor Cappuccio found that _____.',
        'options': [
          'a) sleep-deprived people have more relationship problems',
          'b) sleep deprivation might make people critically ill',
          'c) research from the Mental Health Foundation was incorrect',
          'd) lack of sleep is just a minor nuisance'
        ],
        'correctAnswer': 'b) sleep deprivation might make people critically ill'
      },
      {
        'question': 'The article says that people experiencing sleep difficulties can _____.',
        'options': [
          'a) lose some weight',
          'b) take some types of medicine',
          'c) immediately find medical help',
          'd) try methods that help them fall and stay asleep'
        ],
        'correctAnswer': 'd) try methods that help them fall and stay asleep'
      }
    ]
  }
];

  int _currentExerciseIndex = 0;
  
  String get _currentPassage => _readingTests[_currentExerciseIndex]['passage'];
  List<Map<String, dynamic>> get _currentQuestions => 
      _readingTests[_currentExerciseIndex]['questions'];

  bool get _isLastExercise => _currentExerciseIndex == _readingTests.length - 1;

  List<String?> _userAnswers = [];

  bool get _isLastQuestion => 
      _currentQuestionIndex == _currentQuestions.length - 1 && 
      _currentExerciseIndex == _readingTests.length - 1;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  void _handleNextExercise() {
    if (_selectedAnswer == null) return;

    setState(() {
      if (_currentExerciseIndex < _readingTests.length - 1) {
        _currentExerciseIndex++;
        _selectedAnswer = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    _userAnswers = List.filled(_getTotalQuestions(), null);
    _startTime = DateTime.now();
  }

  Future<void> _initializeTimer() async {
    final remainingTime = await _testSessionService.getReadingRemainingTime();
    if (remainingTime != null) {
      setState(() {
        _remainingTime = remainingTime;
        _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
      });
    } else {
      setState(() {
        _remainingTime = Duration(minutes: _totalTimeInMinutes);
        _progress = 1.0;
      });
    }
    _startTimer();
  }

  void _startTimer() {
    const oneSecond = Duration(seconds: 1);
    _timer = Timer.periodic(oneSecond, (timer) async {
      final remainingTime = await _testSessionService.getReadingRemainingTime();
      
      if (remainingTime == null || remainingTime.inSeconds <= 0) {
        _timer.cancel();
        _handleTimeUp();
        return;
      }

      setState(() {
        _remainingTime = remainingTime;
        _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
      });
    });
  }

  void _handleTimeUp() async {
    // Cancel timer and update state immediately
    _timer.cancel();
    await _testSessionService.endReadingTest();
    await _testSessionService.markTestAsCompleted('reading');

    // Calculate scores
    int correctAnswers = 0;
    int totalQuestions = 0;
    
    for (int i = 0; i < _readingTests.length; i++) {
      final questions = _readingTests[i]['questions'] as List;
      totalQuestions += questions.length;
      
      for (int j = 0; j < questions.length; j++) {
        final questionIndex = _getQuestionIndex(i, j);
        if (_userAnswers.length > questionIndex && 
            _userAnswers[questionIndex] == questions[j]['correctAnswer']) {
          correctAnswers++;
        }
      }
    }
    
    // Calculate standardized score
    final standardizedScore = ScoreCalculator.calculateReadingScore(
      correctAnswers,
      totalQuestions
    );
    
    final testDuration = DateTime.now().difference(_startTime);
    
    // Store completion status, score and duration
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('reading_test_completed', true),
      prefs.setInt('reading_test_score', standardizedScore),
      prefs.setInt('reading_test_duration', testDuration.inSeconds),
      prefs.setInt('reading_total_questions', totalQuestions),
    ]);
    
    // Notify parent
    widget.onTestComplete?.call(testDuration, standardizedScore);

    try {
      final authService = AuthService();
      final testResultsService = TestResultsService(authService.projectId);
      
      final userId = await authService.getUserId();
      final result = TestResult(
        userId: userId ?? 'anonymous',
        firstName: widget.firstName,
        lastName: widget.lastName,
        testType: 'Reading Test',
        score: standardizedScore,
        totalQuestions: totalQuestions,
        timestamp: DateTime.now(),
      );
      
      await testResultsService.saveTestResult(result);
    } catch (e) {
      print('Error saving test result: $e');
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Icon(
            MaterialCommunityIcons.book_open_variant,
            color: Color(0xFF2193b0),
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'Reading Test',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2193b0),
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.red.shade400),
              ),
            ),
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.red.shade400,
              size: 20,
            ),
            label: Text(
              'Exit Test',
              style: GoogleFonts.poppins(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => _showExitConfirmation(context),
          ),
        ),
      ],
      toolbarHeight: 72,
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            width: 400, // Fixed width for the dialog
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                ),
                SizedBox(height: 24),
                
                Text(
                  'Exit Test?',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2193b0),
                  ),
                ),
                SizedBox(height: 16),
                
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Are you sure you want to exit?',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'This will mark the test as completed with your current progress.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.exit_to_app, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Exit Test',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldExit == true) {
      // Cancel timer and mark test as completed
      _timer.cancel();
      await _testSessionService.endReadingTest();
      await _testSessionService.markTestAsCompleted('reading');

      // Calculate scores based on answered questions
      int correctAnswers = 0;
      int totalQuestions = 0;
      
      for (int i = 0; i < _readingTests.length; i++) {
        final questions = _readingTests[i]['questions'] as List;
        totalQuestions += questions.length;
        
        for (int j = 0; j < questions.length; j++) {
          final questionIndex = _getQuestionIndex(i, j);
          if (_userAnswers.length > questionIndex && 
              _userAnswers[questionIndex] == questions[j]['correctAnswer']) {
            correctAnswers++;
          }
        }
      }
      
      // Calculate standardized score
      final standardizedScore = ScoreCalculator.calculateReadingScore(
        correctAnswers,
        totalQuestions
      );
      
      final testDuration = DateTime.now().difference(_startTime);
      
      // Store completion status, score and duration
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool('reading_test_completed', true),
        prefs.setInt('reading_test_score', standardizedScore),
        prefs.setInt('reading_test_duration', testDuration.inSeconds),
        prefs.setInt('reading_total_questions', totalQuestions),
      ]);
      
      // Notify parent
      widget.onTestComplete?.call(testDuration, standardizedScore);

      try {
        final authService = AuthService();
        final testResultsService = TestResultsService(authService.projectId);
        
        final userId = await authService.getUserId();
        final result = TestResult(
          userId: userId ?? 'anonymous',
          firstName: widget.firstName,
          lastName: widget.lastName,
          testType: 'Reading Test',
          score: standardizedScore,
          totalQuestions: totalQuestions,
          timestamp: DateTime.now(),
        );
        
        await testResultsService.saveTestResult(result);
      } catch (e) {
        print('Error saving test result: $e');
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    }
  }

  // Add this new method to the _ReadingTestPageState class
  String _getButtonText() {
    // Check if we're on the last question of the current exercise
    bool isLastQuestionInExercise = _currentQuestionIndex == _currentQuestions.length - 1;
    
    // If we're on the last exercise and last question
    if (_currentExerciseIndex == _readingTests.length - 1 && isLastQuestionInExercise) {
      return 'Finish Test';
    }
    
    // If we're on the last question of current exercise (but not last exercise)
    if (isLastQuestionInExercise) {
      return 'Next Passage';
    }
    
    // If we're in the middle of questions for current passage
    return 'Next Question';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Card(
                                margin: EdgeInsets.zero,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Reading Passage',
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2193b0),
                                            ),
                                          ),
                                          Text(
                                            'Passage ${_currentExerciseIndex + 1} of ${_readingTests.length}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 24),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            _currentPassage,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              height: 1.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Card(
                              margin: EdgeInsets.zero,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      color: _remainingTime.inMinutes < 5 
                                          ? Colors.red 
                                          : Color(0xFF2193b0),
                                      size: 28,
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Time Remaining',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            _formatTime(_remainingTime),
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: _remainingTime.inMinutes < 5 
                                                  ? Colors.red 
                                                  : Color(0xFF2193b0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: _progress,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _remainingTime.inMinutes < 5 
                                                ? Colors.red 
                                                : Color(0xFF2193b0),
                                          ),
                                          minHeight: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 32),
                      Expanded(
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _currentQuestions[_currentQuestionIndex]['question'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 24),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _currentQuestions[_currentQuestionIndex]['options'].length,
                                    itemBuilder: (context, index) {
                                      return _buildOptionButton(
                                        _currentQuestions[_currentQuestionIndex]['options'][index]
                                      );
                                    },
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: _selectedAnswer != null
                                    ? () async {
                                        if (_currentQuestionIndex < _currentQuestions.length - 1) {
                                          setState(() {
                                            _userAnswers[_getQuestionIndex(_currentExerciseIndex, _currentQuestionIndex)] = _selectedAnswer;
                                            _currentQuestionIndex++;
                                            _selectedAnswer = null;
                                          });
                                        } else if (_currentExerciseIndex < _readingTests.length - 1) {
                                          _userAnswers[_getQuestionIndex(_currentExerciseIndex, _currentQuestionIndex)] = _selectedAnswer;
                                          setState(() {
                                            _currentExerciseIndex++;
                                            _currentQuestionIndex = 0;
                                            _selectedAnswer = null;
                                          });
                                        } else {
                                          // Save final answer before completion
                                          _userAnswers[_getQuestionIndex(_currentExerciseIndex, _currentQuestionIndex)] = _selectedAnswer;
                                          await _handleTestCompletion();
                                        }
                                      }
                                    : null,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: Text(
                                        _getButtonText(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _selectedAnswer == option 
                ? Color(0xFF2193b0) 
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _selectedAnswer = option;
            });
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: _selectedAnswer == option
                  ? LinearGradient(
                      colors: [
                        Color(0xFF2193b0).withOpacity(0.1),
                        Color(0xFF6dd5ed).withOpacity(0.1)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                  )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedAnswer == option 
                          ? Color(0xFF2193b0) 
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: _selectedAnswer == option 
                        ? Color(0xFF2193b0) 
                        : Colors.transparent,
                  ),
                  child: _selectedAnswer == option
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: _selectedAnswer == option 
                          ? Color(0xFF2193b0) 
                          : Colors.black87,
                      fontWeight: _selectedAnswer == option 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  int _getTotalQuestions() {
    return _readingTests.fold<int>(0, (sum, test) => 
        sum + (test['questions'] as List).length);
  }

  int _getCurrentQuestionNumber() {
    int questionNumber = 0;
    for (int i = 0; i < _currentExerciseIndex; i++) {
      questionNumber += (_readingTests[i]['questions'] as List).length;
    }
    return questionNumber + _currentQuestionIndex + 1;
  }

  int _getTotalQuestionsInCurrentExercise() {
    return _readingTests[_currentExerciseIndex]['questions'].length;
  }

  int _getQuestionIndex(int exerciseIndex, int questionIndex) {
    int index = 0;
    for (int i = 0; i < exerciseIndex; i++) {
      index += (_readingTests[i]['questions'] as List).length;
    }
    return index + questionIndex;
  }

  Future<void> _handleTestCompletion() async {
    try {
      // Cancel timer immediately
      _timer.cancel();
      await _testSessionService.endReadingTest();
      await _testSessionService.markTestAsCompleted('reading');
      
      // Calculate raw score
      int correctAnswers = 0;
      int totalQuestions = 0;
      
      // Count total questions and correct answers
      for (int i = 0; i < _readingTests.length; i++) {
        final questions = _readingTests[i]['questions'] as List;
        totalQuestions += questions.length;
        
        for (int j = 0; j < questions.length; j++) {
          final questionIndex = _getQuestionIndex(i, j);
          if (_userAnswers.length > questionIndex && 
              _userAnswers[questionIndex] == questions[j]['correctAnswer']) {
            correctAnswers++;
          }
        }
      }
      
      // Calculate standardized score using ScoreCalculator
      final standardizedScore = ScoreCalculator.calculateReadingScore(
        correctAnswers,
        totalQuestions
      );

      // Calculate test duration
      final testDuration = DateTime.now().difference(_startTime);
      
      // Save test data
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setInt('reading_test_score', standardizedScore),
        prefs.setInt('reading_test_duration', testDuration.inSeconds),
        prefs.setBool('reading_test_completed', true),
        prefs.setInt('reading_total_questions', totalQuestions),
      ]);

      // Save to Firestore
      final authService = AuthService();
      final testResultsService = TestResultsService(authService.projectId);
      
      final userId = await authService.getUserId();
      final result = TestResult(
        userId: userId ?? 'anonymous',
        firstName: widget.firstName,
        lastName: widget.lastName,
        testType: 'Reading Test',
        score: standardizedScore,
        totalQuestions: totalQuestions,
        timestamp: DateTime.now(),
      );
      
      await testResultsService.saveTestResult(result);
      
      // Notify parent
      widget.onTestComplete?.call(testDuration, standardizedScore);
      
      if (!mounted) return;

      // Navigate to home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
      
    } catch (e) {
      print('Error completing reading test: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save test result. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _handleTestCompletion,
          ),
        ),
      );
    }
  }
}
