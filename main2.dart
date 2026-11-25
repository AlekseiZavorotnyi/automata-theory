import 'dart:io';

// Первый знак правой части читается со входа, остальные идут в стек.
const rules = <String, List<String>>{
  'S': ['aAE'],
  'A': ['cDCD'],
  'B': ['cD'],
  'C': ['dFB', 'hO'],
  'D': ['g'],
  'O': ['i', 'iO'],
  'E': ['b'],
  'F': ['f'],
};

String visible(String word) => word.isEmpty ? 'ε' : word;

String showStacks(Set<String> stacks) {
  if (stacks.isEmpty) return '∅';
  return '{${stacks.map(visible).join(', ')}}';
}

bool accepts(String word, {bool trace = false}) {
  // Вершина каждого стека находится слева.
  var stacks = <String>{'S'};
  if (trace) stdout.writeln('0  начало  ${showStacks(stacks)}');

  for (var pos = 0; pos < word.length; pos++) {
    final symbol = word[pos];
    final next = <String>{};
    for (final stack in stacks) {
      if (stack.isEmpty) continue;
      for (final rhs in rules[stack[0]]!) {
        if (rhs[0] == symbol) {
          next.add(rhs.substring(1) + stack.substring(1));
        }
      }
    }
    stacks = next;
    if (trace) {
      stdout.writeln('${pos + 1}  $symbol  ${showStacks(stacks)}');
    }
    if (stacks.isEmpty) return false;
  }
  return stacks.contains('');
}

String verdict(bool accepted) => accepted ? 'принята' : 'отклонена';

bool checkWord(String word, bool trace) {
  final result = accepts(word, trace: trace);
  stdout.writeln('${visible(word)} — ${verdict(result)}');
  return result;
}

void runTests() {
  const cases = <String, bool>{
    'acgdfcggb': true,
    'acghigb': true,
    'acghiigb': true,
    'acghiiiigb': true,
    '': false,
    'acghgb': false,
    'acgdfcgb': false,
    'acghig': false,
    'acghigbb': false,
    'acgvigb': false,
    'acgh igb': false,
    'ACGHIGB': false,
  };
  var passed = 0;
  for (final test in cases.entries) {
    final result = accepts(test.key);
    final ok = result == test.value;
    if (ok) passed++;
    final status = ok ? 'OK' : 'ОШИБКА';
    stdout.writeln('$status  ${visible(test.key)} — ${verdict(result)}');
  }
  stdout.writeln('Пройдено $passed из ${cases.length}');
  if (passed != cases.length) exitCode = 1;
}

void main(List<String> args) {
  if (args.length == 1 && args.first == '--test') {
    runTests();
    return;
  }
  final trace = args.isNotEmpty && args.first == '--trace';
  final words = trace ? args.skip(1) : args;
  if (words.isNotEmpty) {
    for (final word in words) {
      if (!checkWord(word, trace)) exitCode = 1;
    }
    return;
  }

  stdout.writeln('Введите цепочку и нажмите Enter. Для выхода введите :q');
  while (true) {
    stdout.write('> ');
    final word = stdin.readLineSync();
    if (word == null || word == ':q') return;
    checkWord(word, trace);
  }
}
