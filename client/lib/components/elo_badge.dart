import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_shadow/simple_shadow.dart';

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

    var textGrad = gradients[baseRankIdx + 1];

    var displayNumber = (elo * 1000).toInt();

    return Stack(
      alignment: Alignment.center,
      children: [
        SimpleShadow(
          opacity: 0.8,
          child: SvgPicture.string(
            makeSvg(baseRankIdx, rankLevel),
            width: 100.0,
            height: 200.0,
          ),
        ),
        Positioned(
          top: 5.0,
          child: Stack(
            children: [
              // Black outline for the text
              Text(
                displayNumber.toString(),
                style: TextStyle(
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Colors.black,
                ),
              ),
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  bounds = Rect.fromLTWH(bounds.left, bounds.top, bounds.width,
                      bounds.height + 100);
                  return LinearGradient(
                    colors: [
                      hexToColor(textGrad.$1),
                      hexToColor(textGrad.$2),
                    ],
                    end: Alignment.bottomCenter,
                  ).createShader(bounds);
                },
                child: Text(
                  displayNumber.toString(),
                  style: const TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                    color:
                        Colors.white, // This is necessary to apply the gradient
                  ),
                ),
              ),
            ],
          ),
        ),
        ClipPath(
          clipper: BannerClipper(),
          child: Opacity(
            opacity: 0.1 * (8 - baseRankIdx),
            child: Image.asset(
              'images/elo_icons/clothxsm.png',
              width: 100.0,
              height: 200.0,
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ],
    );
  }
}

String makeSvg(int gradIdx, int rankLevel) {
  var grad11 = gradients[gradIdx].$1;
  var grad12 = gradients[gradIdx].$2;
  var grad21 = gradients[gradIdx + 1].$1;
  var grad22 = gradients[gradIdx + 1].$2;

  return '''<svg width="100" height="200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:$grad11;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$grad12;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:$grad21;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$grad22;stop-opacity:1" />
    </linearGradient>
  </defs>
  <path style="fill: url(#grad1); stroke: black; stroke-width: 2;" d="M 10 -10 L 10 190 L 50 150 L 90 190L 90 -10 Z"/>
  ${rankLevel > 1 ? '<path d="M 10 190 L 50 150 L 90 190L 90 170 L 50 130 L 10 170 Z" fill="url(#grad2)" stroke="black" stroke-width="2"/>' : ''}
  ${rankLevel > 2 ? '<path d="M 10 160 L 50 120L 90 160 L 90 150 L 50 110 L 10 150 Z" fill="url(#grad2)" stroke="black" stroke-width="2"/>' : ''}
</svg>
''';
}

class BannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(10, -10)
      ..lineTo(10, 190)
      ..lineTo(50, 150)
      ..lineTo(90, 190)
      ..lineTo(90, -10)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
