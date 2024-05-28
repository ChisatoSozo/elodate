import 'package:client/components/prop_pref_components/gender_prop_pref.dart';
import 'package:flutter/material.dart';

class GenderDisplay extends StatefulWidget {
  final double maleValue;
  final double femaleValue;

  const GenderDisplay(
      {super.key, required this.maleValue, required this.femaleValue});

  @override
  GenderDisplayState createState() => GenderDisplayState();
}

class GenderDisplayState extends State<GenderDisplay> {
  bool _isLabelVisible = false;

  void _toggleLabelVisibility() {
    setState(() {
      _isLabelVisible = !_isLabelVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    String genderLabel = getGenderLabel(widget.maleValue, widget.femaleValue);
    Color genderColor = getGenderColor(widget.maleValue, widget.femaleValue);

    return MouseRegion(
      onEnter: (_) => setState(() => _isLabelVisible = true),
      onExit: (_) => setState(() => _isLabelVisible = false),
      child: GestureDetector(
        onTap: _toggleLabelVisibility,
        child: Tooltip(
          message: genderLabel,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: genderColor,
            ),
          ),
        ),
      ),
    );
  }

  Color getGenderColor(double maleValue, double femaleValue) {
    var femaleColor = HSVColor.fromColor(Colors.pink);
    var maleColor = HSVColor.fromColor(Colors.blue);
    var agenderColor = HSVColor.fromColor(Colors.white);
    double absoluteGender = maleValue > femaleValue ? maleValue : femaleValue;

    if (absoluteGender == 0) {
      return agenderColor.toColor();
    }

    var colorFromRatio = HSVColor.lerp(
        femaleColor, maleColor, maleValue / (maleValue + femaleValue));

    var colorToAgenderLerp =
        HSVColor.lerp(agenderColor, colorFromRatio, absoluteGender);

    return colorToAgenderLerp!.toColor();
  }
}
