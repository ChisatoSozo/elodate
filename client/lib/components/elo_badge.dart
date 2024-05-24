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
    String path = 'images/elo_icons/$baseRank$rankLevel.svg';

    return SimpleShadow(
      opacity: 0.8,
      child: SvgPicture.asset(
        path,
        width: 100.0,
        height: 200.0,
      ),
    );
  }
}
