import 'dart:collection';
import 'dart:io';

const q0 = 'q₀';
const q = 'q';
const epsilon = '';

class Rule {
  final String from, input, top, to;
  final List<String> replacements;

  const Rule(this.from, this.input, this.top, this.to, this.replacements);
}

const delta = <Rule>[
  Rule(q0, epsilon, 'S', q, ['aAE']),
  Rule(q, epsilon, 'A', q, ['cDCD']),
  Rule(q, epsilon, 'B', q, ['cD']),
  Rule(q, epsilon, 'C', q, ['dFB', 'hO']),
  Rule(q, epsilon, 'D', q, ['g']),
  Rule(q, epsilon, 'O', q, ['i', 'iO']),
  Rule(q, epsilon, 'E', q, ['b']),
  Rule(q, epsilon, 'F', q, ['f']),
  Rule(q, 'a', 'a', q, [epsilon]),
  Rule(q, 'b', 'b', q, [epsilon]),
  Rule(q, 'c', 'c', q, [epsilon]),
  Rule(q, 'd', 'd', q, [epsilon]),
  Rule(q, 'f', 'f', q, [epsilon]),
  Rule(q, 'g', 'g', q, [epsilon]),
  Rule(q, 'h', 'h', q, [epsilon]),
  Rule(q, 'i', 'i', q, [epsilon]),
];

class Stack {
  final List<String> _symbols;
  Stack.initial() : _symbols = ['S'];
  Stack.copy(Stack other) : _symbols = List.of(other._symbols);

  bool get isEmpty => _symbols.isEmpty;
  String get top => _symbols.last;
  String pop() => _symbols.removeLast();
  void push(String symbol) => _symbols.add(symbol);
}

class Configuration {
  final String state;
  final int position;
  final Stack stack;

  Configuration(this.state, this.position, this.stack);

  Configuration move(Rule rule, String replacement) {
    final nextStack = Stack.copy(stack);
    nextStack.pop();
    for (var i = replacement.length - 1; i >= 0; i--) {
      nextStack.push(replacement[i]);
    }
    return Configuration(rule.to, position + rule.input.length, nextStack);
  }
}

bool accepts(String word) {
  final initial = Configuration(q0, 0, Stack.initial());
  final pending = Queue<Configuration>()..addLast(initial);

  while (pending.isNotEmpty) {
    final current = pending.removeFirst();

    if (current.stack.isEmpty) {
      if (current.state == q && current.position == word.length) {
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
        pending.addLast(current.move(rule, replacement));
      }
    }
  }

  return false;
}

void main() {
  stdout.writeln('Введите цепочку и нажмите Enter. Для выхода введите :q');
  while (true) {
    stdout.write('> ');
    final word = stdin.readLineSync();
    if (word == null || word == ':q') return;
    print(accepts(word) ? 'принята' : 'отклонена');
  }
  /*'acgdfcggb': true,
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
  'ACGHIGB': false*/
}
