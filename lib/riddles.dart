class Riddle {
  final int id;
  final String question;
  final String answer;
  final String level;

  Riddle({required this.id, required this.question, required this.answer, required this.level});
}

List<Riddle> riddles = [
  Riddle(id: 1, question: "I have a mane but I am not a horse. Who am I?", answer: "lion", level: "easy"),
  Riddle(id: 2, question: "I speak without a mouth and hear without ears. What am I?", answer: "echo", level: "medium"),
  Riddle(id: 3, question: "I have cities but no houses. Rivers but no water. What am I?", answer: "map", level: "hard"),
];
