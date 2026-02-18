import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'riddles.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Far&Near',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FarNearGame(),
    );
  }
}

class FarNearGame extends StatefulWidget {
  const FarNearGame({super.key});

  @override
  State<FarNearGame> createState() => _FarNearGameState();
}

class _FarNearGameState extends State<FarNearGame>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  List<Riddle> currentRiddles = [];
  int currentIndex = 0;
  final TextEditingController guessController = TextEditingController();

  List<Map<String, dynamic>> guessHistory = []; // Stores guesses + percent
  bool revealAnswer = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      switchLevel(tabController.index);
    });
    switchLevel(0); // default Easy
  }

  void switchLevel(int index) {
    setState(() {
      currentIndex = 0;
      guessHistory.clear();
      revealAnswer = false;
      String level = index == 0
          ? "easy"
          : index == 1
              ? "medium"
              : "hard";
      currentRiddles = riddles.where((r) => r.level == level).toList();
    });
  }

  Riddle get currentRiddle => currentRiddles.isEmpty
      ? Riddle(id: 0, question: "No riddles available", answer: "", level: "")
      : currentRiddles[currentIndex];

  Future<void> checkGuess() async {
    String userGuess = guessController.text.trim();
    if (userGuess.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/similarity"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "main_word": currentRiddle.answer,
          "guess_word": userGuess,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double percent = data["similarity_percentage"];

        setState(() {
          guessHistory.insert(0, {
            "guess": userGuess,
            "percent": percent,
            "isCorrect": percent >= 95
          });
          guessController.clear();
        });

        // If correct, show congrats popup
        if (percent >= 95) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🎉 Congratulations!"),
              content: Text(
                  "Your guess '${userGuess}' is correct!\nSimilarity: ${percent.toStringAsFixed(0)}%"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Continue"))
              ],
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error connecting to backend: $e")));
    }
  }

  void reveal() {
    setState(() {
      revealAnswer = true;
      guessHistory.insert(0, {
        "guess": currentRiddle.answer,
        "percent": 100,
        "isCorrect": true
      });
    });
  }

  void nextRiddle() {
    if (currentIndex + 1 < currentRiddles.length) {
      setState(() {
        currentIndex++;
        guessHistory.clear();
        revealAnswer = false;
        guessController.clear();
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No more riddles!")));
    }
  }

  void showHelp() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("How to play"),
              content: const Text(
                  "1. Read the riddle.\n"
                  "2. Type your guess in the bottom box.\n"
                  "3. Press Enter icon to submit.\n"
                  "4. A bar shows how near your guess is to the answer.\n"
                  "5. You can Reveal the answer if stuck.\n"
                  "6. Switch difficulty using tabs."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Far&Near",
          style: GoogleFonts.greatVibes( // curvy, elegant font
            fontSize: 40,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: Colors.black,
            shadows: [
              const Shadow(
                blurRadius: 4,
                color: Colors.black45,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: showHelp, icon: const Icon(Icons.help_outline))
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: "Easy"),
            Tab(text: "Medium"),
            Tab(text: "Hard"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Question text
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            width: double.infinity,
            child: Text(
              currentRiddle.question,
              style:
                  GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Answer history list
          Expanded(
            child: ListView.builder(
              itemCount: guessHistory.length,
              itemBuilder: (context, index) {
                final item = guessHistory[index];
                double percent = item["percent"];
                String guess = item["guess"];
                bool isCorrect = item["isCorrect"];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[300],
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percent / 100,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isCorrect ? Colors.green : Colors.blue,
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  guess,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("${percent.toStringAsFixed(0)}%"),
                    ],
                  ),
                );
              },
            ),
          ),

          // Reveal answer
          if (revealAnswer)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[100],
              width: double.infinity,
              child: Text(
                "Answer: ${currentRiddle.answer}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

          // Bottom floating input box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: guessController,
                      decoration: const InputDecoration(
                        hintText: "Type your guess...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => checkGuess(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: checkGuess,
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.red),
                    tooltip: "Reveal Answer",
                    onPressed: reveal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.green),
                    tooltip: "Next Riddle",
                    onPressed: nextRiddle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
