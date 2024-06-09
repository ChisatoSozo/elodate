import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_shadow/simple_shadow.dart';

class EloBadge extends StatelessWidget {
  final String eloLabel;

  const EloBadge({super.key, required this.eloLabel});

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

    return Stack(
      alignment: Alignment.center,
      children: [
        SimpleShadow(
          opacity: 0.8,
          child: SvgPicture.string(
            makeSvg(baseRank, rankLevel),
            width: 100.0,
            height: 200.0,
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

String makeSvg(String baseRank, int rankLevel) {
  String grad1 = '';
  String grad2 = '';
  switch (baseRank) {
    case 'bronze':
      grad1 = 'bronzeGradient';
      grad2 = 'silverGradient';
      break;
    case 'silver':
      grad1 = 'silverGradient';
      grad2 = 'goldGradient';
      break;
    case 'gold':
      grad1 = 'goldGradient';
      grad2 = 'platinumGradient';
      break;
    case 'platinum':
      grad1 = 'platinumGradient';
      grad2 = 'emeraldGradient';
      break;
    case 'emerald':
      grad1 = 'emeraldGradient';
      grad2 = 'sapphireGradient';
      break;
    case 'sapphire':
      grad1 = 'sapphireGradient';
      grad2 = 'rubyGradient';
      break;
    case 'ruby':
      grad1 = 'rubyGradient';
      grad2 = 'diamondGradient';
      break;
    case 'diamond':
      grad1 = 'diamondGradient';
      grad2 = 'nextRankGradient';
      break;
    default:
      throw Exception('Invalid baseRank');
  }

  return '''<svg width="100" height="200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bronzeGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#cd7f32;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#a97142;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="silverGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#c0c0c0;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#808080;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="goldGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#ffd700;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#daa520;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="platinumGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#e5e4e2;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#bcc6cc;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="emeraldGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#50c878;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#2e8b57;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="sapphireGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0f52ba;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#000080;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="rubyGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#e0115f;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#8b0000;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="diamondGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#b9f2ff;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#e0ffff;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="nextRankGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#000000;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#4b0082;stop-opacity:1" />
    </linearGradient>
    </defs>

  <path style="fill: url(#$grad1); stroke: black; stroke-width: 2;" d="M 10 -10 L 10 190 L 50 150 L 90 190L 90 -10 Z"/>
  ${rankLevel > 1 ? '<path d="M 10 190 L 50 150 L 90 190L 90 170 L 50 130 L 10 170 Z" fill="url(#$grad2)" stroke="black" stroke-width="2"/>' : ''}
  ${rankLevel > 2 ? '<path d="M 10 160 L 50 120L 90 160 L 90 150 L 50 110 L 10 150 Z" fill="url(#$grad2)" stroke="black" stroke-width="2"/>' : ''}
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
