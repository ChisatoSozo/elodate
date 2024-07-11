import 'package:flutter/material.dart';

var gradients = [
  ("#cd7f32", "#a97142"),
  ("#c0c0c0", "#808080"),
  ("#ffd700", "#daa520"),
  ("#e5e4e2", "#bcc6cc"),
  ("#50c878", "#2e8b57"),
  ("#0f52ba", "#000080"),
  ("#e0115f", "#8b0000"),
  ("#b9f2ff", "#e0ffff"),
  ("#000000", "#4b0082")
];

// Function to turn hex to Color
Color hexToColor(String code) {
  return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

class EloBadge extends StatelessWidget {
  final String eloLabel;
  final double elo;

  const EloBadge({super.key, required this.eloLabel, required this.elo});

  @override
  Widget build(BuildContext context) {
    String baseRank = eloLabel.split(' ')[0].toLowerCase();
    int rankLevel = int.parse(eloLabel.split(' ')[1]);

    int baseRankIdx = [
      'bronze',
      'silver',
      'gold',
      'platinum',
      'emerald',
      'sapphire',
      'ruby',
      'diamond',
    ].indexOf(baseRank);

    //rankLevel can be 1 or 2
    var isRankLevelTwo = rankLevel == 2;

    var nextGrad = gradients[baseRankIdx + 1];
    var thisGrad = gradients[baseRankIdx];

    var displayNumber = (elo * 1000).toInt();

    return Stack(
      children: [
        // Black outline for the text
        Text(
          displayNumber.toString(),
          style: TextStyle(
            fontSize: 40.0,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = eloLabel == "Diamond 2" ? 2 : 3
              ..color = eloLabel == "Diamond 2"
                  ? hexToColor(thisGrad.$1)
                  : Colors.black,
          ),
        ),
        ShaderMask(
          shaderCallback: (Rect bounds) {
            bounds = Rect.fromLTWH(bounds.left, bounds.top, bounds.width, 20);
            return LinearGradient(
              colors: [
                hexToColor(thisGrad.$1),
                hexToColor(isRankLevelTwo ? nextGrad.$1 : thisGrad.$2),
              ],
              end: Alignment.bottomCenter,
            ).createShader(bounds);
          },
          child: Text(
            displayNumber.toString(),
            style: const TextStyle(
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
              color: Colors.white, // This is necessary to apply the gradient
            ),
          ),
        ),
      ],
    );
  }
}
