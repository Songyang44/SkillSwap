import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';


class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final color=theme.colorScheme.primary;
    final style=theme.textTheme.displayMedium!.copyWith(color: const Color.fromARGB(255, 247, 243, 243));
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(pair.asLowerCase,style: style,semanticsLabel: "${pair.first}${pair.second}",),
      ),
    );
  }
}