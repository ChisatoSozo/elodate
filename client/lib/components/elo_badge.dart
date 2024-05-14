import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EloBadge extends StatelessWidget {
  final String eloLabel;

  const EloBadge({super.key, required this.eloLabel});

  @override
  Widget build(BuildContext context) {
    String baseRank = eloLabel.split(' ')[0].toLowerCase();
    int rankLevel = int.parse(eloLabel.split(' ')[1]) - 1;

    // Path to the base rank SVG file
    String baseSvgPath = 'images/elo_icons/$baseRank.svg';

    return Column(
      children: [
        SvgPicture.asset(
          baseSvgPath,
          width: 100.0,
          height: 100.0,
        ),
        if (rankLevel >= 1) _buildChevronLines(rankLevel),
      ],
    );
  }

  Widget _buildChevronLines(int rankLevel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rankLevel,
        (index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2.0),
          width: 60.0,
          height: 6.0,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(3.0),
          ),
        ),
      ),
    );
  }
}
