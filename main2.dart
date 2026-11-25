import 'dart:collection';
import 'dart:io';

const q0 = 'q₀';
const q = 'q';
const epsilon = '';

String visible(String word) => word.isEmpty ? 'ε' : word;

class Rule {
  final int number;
  final String from, input, top, to;
  final List<String> replacements;

  const Rule(
    this.number,
    this.from,
    this.input,
    this.top,
    this.to,
    this.replacements,
  );

  String describe(String replacement) {
    if (input == epsilon) return '($number) Раскрытие $top → $replacement';
    return '($number) Чтение $input, снять $top';
  }
}

const delta = <Rule>[
  Rule(1, q0, epsilon, 'S', q, ['aAE']),
  Rule(2, q, epsilon, 'A', q, ['cDCD']),
  Rule(3, q, epsilon, 'B', q, ['cD']),
  Rule(4, q, epsilon, 'C', q, ['dFB', 'hO']),
  Rule(5, q, epsilon, 'D', q, ['g']),
  Rule(6, q, epsilon, 'O', q, ['i', 'iO']),
  Rule(7, q, epsilon, 'E', q, ['b']),
  Rule(8, q, epsilon, 'F', q, ['f']),
  Rule(9, q, 'a', 'a', q, [epsilon]),
  Rule(10, q, 'b', 'b', q, [epsilon]),
  Rule(11, q, 'c', 'c', q, [epsilon]),
  Rule(12, q, 'd', 'd', q, [epsilon]),
  Rule(13, q, 'f', 'f', q, [epsilon]),
  Rule(14, q, 'g', 'g', q, [epsilon]),
  Rule(15, q, 'h', 'h', q, [epsilon]),
  Rule(16, q, 'i', 'i', q, [epsilon]),
];

class Stack {
  final List<String> _symbols;
  Stack.initial() : _symbols = ['S'];
  Stack.copy(Stack other) : _symbols = List.of(other._symbols);

  bool get isEmpty => _symbols.isEmpty;
  String get top => _symbols.last;
  String pop() => _symbols.removeLast();
  void push(String symbol) => _symbols.add(symbol);

  @override
  String toString() => visible(_symbols.reversed.join());
}

class Configuration {
  final String state;
  final int position;
  final Stack stack;
  final Configuration? previous;
  final String action;

  Configuration(
    this.state,
    this.position,
    this.stack, {
    this.previous,
    this.action = 'Начало',
  });

  Configuration move(Rule rule, String replacement, bool trace) {
    final nextStack = Stack.copy(stack);
    nextStack.pop();
    for (var i = replacement.length - 1; i >= 0; i--) {
      nextStack.push(replacement[i]);
    }
    return Configuration(
      rule.to,
      position + rule.input.length,
      nextStack,
      previous: trace ? this : null,
      action: trace ? rule.describe(replacement) : '',
    );
  }

  String remainingInput(String word) {
    if (word.length - position > 32) {
      return '${word.substring(position, position + 32)}…';
    }
    return visible(word.substring(position));
  }
}

class PushdownAutomaton {
  const PushdownAutomaton();

  bool run(String word, {bool trace = false}) {
    final initial = Configuration(q0, 0, Stack.initial());
    final pending = Queue<Configuration>()..addLast(initial);
    var last = initial;
    while (pending.isNotEmpty) {
      final current = pending.removeFirst();
      last = current;
      if (current.stack.isEmpty) {
        if (current.state == q && current.position == word.length) {
          if (trace) printTrace(word, current, true);
          return true;
        }
        continue;
      }
      final pos = current.position;
      final letter = pos < word.length ? word[pos] : null;
      for (final rule in delta) {
        if (current.state != rule.from || current.stack.top != rule.top) {
          continue;
        }
        if (rule.input != epsilon && rule.input != letter) continue;
        for (final replacement in rule.replacements) {
          pending.addLast(current.move(rule, replacement, trace));
        }
      }
    }
    if (trace) printTrace(word, last, false);
    return false;
  }
}

bool accepts(String word, {bool trace = false}) =>
    const PushdownAutomaton().run(word, trace: trace);

void printTrace(String word, Configuration end, bool accepted) {
  final path = <Configuration>[];
  for (Configuration? c = end; c != null; c = c.previous) {
    path.add(c);
  }
  stdout.writeln(accepted ? 'Принимающая ветвь.' : 'Одна из ветвей отказа.');
  stdout.writeln('Такт  (состояние, остаток входа, магазин)  Переход δ');
  var step = 0;
  for (final c in path.reversed) {
    final rest = c.remainingInput(word);
    stdout.writeln('$step  (${c.state}, $rest, ${c.stack})  ${c.action}');
    step++;
  }
  if (!accepted) stdout.writeln('Все ветви остановились без допуска.');
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
