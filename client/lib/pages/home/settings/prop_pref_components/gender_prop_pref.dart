import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/spacer.dart';
import 'package:client/pages/home/settings/labeled_radio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const maxGridSize = 300.0;
const cornerHitRadius = 50.0;

class GenderPicker extends StatefulWidget {
  final List<ApiUserPropsInner> props;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<ApiUserPropsInner>) onUpdated;

  const GenderPicker({
    required this.props,
    required this.preferenceConfigs,
    required this.onUpdated,
    super.key,
  });

  @override
  GenderPickerState createState() => GenderPickerState();
}

class GenderPickerState extends State<GenderPicker> {
  late double percentMale;
  late double percentFemale;
  late PreferenceConfigPublic _preferenceConfig;

  @override
  void initState() {
    super.initState();
    if (widget.props.length != 2) {
      throw Exception('GenderPicker requires exactly two props');
    }
    if (widget.preferenceConfigs.length != 2) {
      throw Exception('GenderPicker requires exactly two preference config');
    }

    percentMale = widget.props[0].value.toDouble();
    percentFemale = widget.props[1].value.toDouble();

    _preferenceConfig = widget.preferenceConfigs.first;
  }

  void _updateGenderValue(Offset newGenderValue) {
    setState(() {
      percentMale = newGenderValue.dx /
              maxGridSize *
              (_preferenceConfig.max - _preferenceConfig.min) +
          _preferenceConfig.min;
      percentFemale = (1 - newGenderValue.dy / maxGridSize) *
              (_preferenceConfig.max - _preferenceConfig.min) +
          _preferenceConfig.min;
    });

    widget.props[0].value = percentMale.round();
    widget.props[1].value = percentFemale.round();
    widget.onUpdated(widget.props);
  }

  void _updateGenderValueByDetails(dynamic details) {
    var x = details.localPosition.dx.clamp(0, maxGridSize).toDouble();
    var y = details.localPosition.dy.clamp(0, maxGridSize).toDouble();
    _updateGenderValue(Offset(x, y));
  }

  Offset getOffset() {
    return Offset(
      (percentMale - _preferenceConfig.min) /
          (_preferenceConfig.max - _preferenceConfig.min) *
          maxGridSize,
      (1 -
              (percentFemale - _preferenceConfig.min) /
                  (_preferenceConfig.max - _preferenceConfig.min)) *
          maxGridSize,
    );
  }

  String getGenderValue() {
    if (percentMale == _preferenceConfig.max &&
        percentFemale == _preferenceConfig.min) {
      return "Male";
    } else if (percentMale == _preferenceConfig.min &&
        percentFemale == _preferenceConfig.max) {
      return "Female";
    } else {
      return "Advanced";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledRadio<String>(
          label: 'Male',
          value: 'Male',
          groupValue: getGenderValue(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                percentMale = _preferenceConfig.max.toDouble();
                percentFemale = _preferenceConfig.min.toDouble();
              });
              widget.props[0].value = _preferenceConfig.max;
              widget.props[1].value = _preferenceConfig.min;
              widget.onUpdated(widget.props);
            }
          },
        ),
        LabeledRadio<String>(
          label: 'Female',
          value: 'Female',
          groupValue: getGenderValue(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                percentMale = _preferenceConfig.min.toDouble();
                percentFemale = _preferenceConfig.max.toDouble();
              });
              widget.props[0].value = _preferenceConfig.min;
              widget.props[1].value = _preferenceConfig.max;
              widget.onUpdated(widget.props);
            }
          },
        ),
        LabeledRadio<String>(
          label: 'Advanced',
          value: 'Advanced',
          groupValue: getGenderValue(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                percentMale = 50;
                percentFemale = 50;
              });
              widget.props[0].value = 50;
              widget.props[1].value = 50;
              widget.onUpdated(widget.props);
            }
          },
        ),
        if (getGenderValue() == "Advanced") ...[
          const VerticalSpacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: _updateGenderValueByDetails,
            onVerticalDragUpdate: _updateGenderValueByDetails,
            onPanDown: _updateGenderValueByDetails,
            onTapDown: _updateGenderValueByDetails,
            child: GenderPainterWidget(
              painter: GridPainter(getOffset()),
              maxGridSize: maxGridSize,
            ),
          ),
          Text(getGenderLabel(
              (percentMale - _preferenceConfig.min) /
                  (_preferenceConfig.max - _preferenceConfig.min),
              (percentFemale - _preferenceConfig.min) /
                  (_preferenceConfig.max - _preferenceConfig.min)))
        ],
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final Offset genderValue;

  GridPainter(this.genderValue);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = Colors.black;
    canvas.drawCircle(genderValue, 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GenderPainterWidget extends StatelessWidget {
  final CustomPainter painter;
  final double maxGridSize;

  const GenderPainterWidget({
    super.key,
    required this.painter,
    required this.maxGridSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: maxGridSize,
          width: maxGridSize,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.pink, Colors.blue],
            ),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Colors.white,
                  Color.fromARGB(127, 255, 255, 255),
                  Color.fromARGB(63, 255, 255, 255),
                  Color.fromARGB(31, 255, 255, 255),
                  Color.fromARGB(0, 255, 255, 255),
                ],
                stops: [0, 0.2, 0.4, 0.6, 0.8],
              ),
            ),
            child: CustomPaint(
              painter: painter,
            ),
          ),
        ),
        const Positioned(
          top: 5,
          left: 5,
          child: Text('Female', style: TextStyle(color: Colors.white)),
        ),
        const Positioned(
          bottom: 5,
          right: 5,
          child: Text('Male', style: TextStyle(color: Colors.white)),
        ),
        const Positioned(
          top: 5,
          right: 5,
          child: Text('Bigender', style: TextStyle(color: Colors.white)),
        ),
        const Positioned(
          bottom: 5,
          left: 5,
          child: Text('Agender', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}

class GenderRangePicker extends StatefulWidget {
  final List<ApiUserPrefsInner> prefs;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<ApiUserPrefsInner>) onUpdated;

  const GenderRangePicker({
    required this.prefs,
    required this.preferenceConfigs,
    required this.onUpdated,
    super.key,
  });

  @override
  GenderRangePickerState createState() => GenderRangePickerState();
}

class GenderRangePickerState extends State<GenderRangePicker> {
  late double maleMin;
  late double maleMax;
  late double femaleMin;
  late double femaleMax;
  late (PreferenceConfigPublic, PreferenceConfigPublic) _preferenceConfig;
  Offset? dragStart;
  bool isDraggingCorner = false;
  int hoveringCornerIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.prefs.length != 2) {
      throw Exception('GenderRangePicker requires exactly two prefs');
    }
    if (widget.preferenceConfigs.length != 2) {
      throw Exception(
          'GenderRangePicker requires exactly two preference configs');
    }

    maleMin = widget.prefs[0].range.min.toDouble();
    maleMax = widget.prefs[0].range.max.toDouble();
    femaleMin = widget.prefs[1].range.min.toDouble();
    femaleMax = widget.prefs[1].range.max.toDouble();

    //coerce to be within the bounds of the preference config, farther than 0.1 apart, and in the correct order

    if (maleMin < 0) {
      maleMin = 0;
    }
    if (maleMax > 100) {
      maleMax = 100.0;
    }
    if (femaleMin < 0) {
      femaleMin = 0;
    }
    if (femaleMax > 100) {
      femaleMax = 100.0;
    }

    if (maleMin > maleMax) {
      var temp = maleMin;
      maleMin = maleMax;
      maleMax = temp;
    }

    if (femaleMin > femaleMax) {
      var temp = femaleMin;
      femaleMin = femaleMax;
      femaleMax = temp;
    }

    //make sure they are more than 0.1 apart
    //first check if there's enough room to move the max up
    if (maleMax - maleMin < 10) {
      if (maleMax + 10 <= 100) {
        maleMax += 10;
      } else {
        maleMin -= 10;
      }
    }

    if (femaleMax - femaleMin < 10) {
      if (femaleMax + 10 <= 100) {
        femaleMax += 10;
      } else {
        femaleMin -= 10;
      }
    }

    _preferenceConfig = (
      widget.preferenceConfigs.first,
      widget.preferenceConfigs.last,
    );
  }

  (Offset, Offset) getRangeBounds() {
    var (maleConfig, femaleConfig) = _preferenceConfig;
    return (
      Offset(
        (maleMin - maleConfig.min) /
            (maleConfig.max - maleConfig.min) *
            maxGridSize,
        (1 -
                (femaleMax - femaleConfig.min) /
                    (femaleConfig.max - femaleConfig.min)) *
            maxGridSize,
      ),
      Offset(
        (maleMax - maleConfig.min) /
            (maleConfig.max - maleConfig.min) *
            maxGridSize,
        (1 -
                (femaleMin - femaleConfig.min) /
                    (femaleConfig.max - femaleConfig.min)) *
            maxGridSize,
      )
    );
  }

  String getGenderValue() {
    if (maleMin == 50 && maleMax == 100 && femaleMin == 0 && femaleMax == 50) {
      return "Male";
    } else if (maleMin == 0 &&
        maleMax == 50 &&
        femaleMin == 50 &&
        femaleMax == 100) {
      return "Female";
    } else if ((maleMin == _preferenceConfig.$1.min || maleMin == -32768) &&
        (maleMax == _preferenceConfig.$1.max || maleMax == 32767) &&
        (femaleMin == _preferenceConfig.$2.min || femaleMin == -32768) &&
        (femaleMax == _preferenceConfig.$2.max || femaleMax == 32767)) {
      return "No Preference";
    } else {
      return "Advanced";
    }
  }

  void _updateRange(Offset start, Offset end) {
    //make sure there's at least 0.1 difference between the start and end on both axes
    if ((start.dx - end.dx).abs() < maxGridSize * 0.1 ||
        (start.dy - end.dy).abs() < maxGridSize * 0.1) {
      return;
    }

    //make sure the start is less than the end on both axes
    if (start.dx > end.dx || start.dy > end.dy) {
      return;
    }

    //make sure the start and end are within the bounds of the grid
    if (start.dx < 0) {
      start = Offset(0, start.dy);
    }
    if (start.dy < 0) {
      start = Offset(start.dx, 0);
    }
    if (end.dx > maxGridSize) {
      end = Offset(maxGridSize, end.dy);
    }
    if (end.dy > maxGridSize) {
      end = Offset(end.dx, maxGridSize);
    }

    var (maleConfig, femaleConfig) = _preferenceConfig;
    setState(() {
      maleMin = start.dx / maxGridSize * (maleConfig.max - maleConfig.min) +
          maleConfig.min;
      maleMax = end.dx / maxGridSize * (maleConfig.max - maleConfig.min) +
          maleConfig.min;
      femaleMin =
          (1 - end.dy / maxGridSize) * (femaleConfig.max - femaleConfig.min) +
              femaleConfig.min;
      femaleMax =
          (1 - start.dy / maxGridSize) * (femaleConfig.max - femaleConfig.min) +
              femaleConfig.min;
    });

    widget.prefs[0].range.min = maleMin.round();
    widget.prefs[0].range.max = maleMax.round();
    widget.prefs[1].range.min = femaleMin.round();
    widget.prefs[1].range.max = femaleMax.round();
    widget.onUpdated(widget.prefs);
  }

  void _updateRangeDrag(Offset position, int cornerIndex) {
    var (start, end) = getRangeBounds();
    switch (cornerIndex) {
      case 0: // Top-left corner
        start = position;
        break;
      case 1: // Top-right corner
        start = Offset(start.dx, position.dy);
        end = Offset(position.dx, end.dy);
        break;
      case 2: // Bottom-right corner
        end = position;
        break;
      case 3: // Bottom-left corner
        start = Offset(position.dx, start.dy);
        end = Offset(end.dx, position.dy);
        break;
    }
    _updateRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledRadio<String>(
          label: 'Male',
          value: 'Male',
          groupValue: getGenderValue(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                maleMin = 50;
                maleMax = 100;
                femaleMin = 0;
                femaleMax = 50;
              });
              widget.prefs[0].range.min = maleMin.round();
              widget.prefs[0].range.max = maleMax.round();
              widget.prefs[1].range.min = femaleMin.round();
              widget.prefs[1].range.max = femaleMax.round();
              widget.onUpdated(widget.prefs);
            }
          },
        ),
        LabeledRadio<String>(
          label: 'Female',
          value: 'Female',
          groupValue: getGenderValue(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                maleMin = 0;
                maleMax = 50;
                femaleMin = 50;
                femaleMax = 100;
              });
              widget.prefs[0].range.min = maleMin.round();
              widget.prefs[0].range.max = maleMax.round();
              widget.prefs[1].range.min = femaleMin.round();
              widget.prefs[1].range.max = femaleMax.round();
              widget.onUpdated(widget.prefs);
            }
          },
        ),
        LabeledRadio<String>(
          label: 'No Preference',
          value: 'No Preference',
          groupValue: getGenderValue(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                maleMin = 0;
                maleMax = 100;
                femaleMin = 0;
                femaleMax = 100;
              });
              widget.prefs[0].range.min = -32768;
              widget.prefs[0].range.max = 32767;
              widget.prefs[1].range.min = -32768;
              widget.prefs[1].range.max = 32767;
              widget.onUpdated(widget.prefs);
            }
          },
        ),
        LabeledRadio<String>(
          label: 'Advanced',
          value: 'Advanced',
          groupValue: getGenderValue(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                maleMin = 25;
                maleMax = 75;
                femaleMin = 25;
                femaleMax = 75;
              });
              widget.prefs[0].range.min = maleMin.round();
              widget.prefs[0].range.max = maleMax.round();
              widget.prefs[1].range.min = femaleMin.round();
              widget.prefs[1].range.max = femaleMax.round();
              widget.onUpdated(widget.prefs);
            }
          },
        ),
        if (getGenderValue() == "Advanced") ...[
          const VerticalSpacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              if (dragStart != null) {
                if (isDraggingCorner) {
                  _updateRangeDrag(details.localPosition, hoveringCornerIndex);
                }
              }
            },
            onVerticalDragUpdate: (details) {
              if (dragStart != null) {
                if (isDraggingCorner) {
                  _updateRangeDrag(details.localPosition, hoveringCornerIndex);
                }
              }
            },
            onTapDown: (details) {
              dragStart = details.localPosition;
              var (start, end) = getRangeBounds();
              isDraggingCorner = true;
              hoveringCornerIndex = -1;

              if ((dragStart! - start).distance < cornerHitRadius) {
                hoveringCornerIndex = 0;
              } else if ((dragStart! - Offset(end.dx, start.dy)).distance <
                  cornerHitRadius) {
                hoveringCornerIndex = 1;
              } else if ((dragStart! - end).distance < cornerHitRadius) {
                hoveringCornerIndex = 2;
              } else if ((dragStart! - Offset(start.dx, end.dy)).distance <
                  cornerHitRadius) {
                hoveringCornerIndex = 3;
              } else {
                isDraggingCorner = false;
              }
              setState(() {
                hoveringCornerIndex = hoveringCornerIndex;
              });
            },
            onPanStart: (details) {
              dragStart = details.localPosition;
              var (start, end) = getRangeBounds();
              isDraggingCorner = true;
              hoveringCornerIndex = -1;

              if ((dragStart! - start).distance < cornerHitRadius) {
                hoveringCornerIndex = 0;
              } else if ((dragStart! - Offset(end.dx, start.dy)).distance <
                  cornerHitRadius) {
                hoveringCornerIndex = 1;
              } else if ((dragStart! - end).distance < cornerHitRadius) {
                hoveringCornerIndex = 2;
              } else if ((dragStart! - Offset(start.dx, end.dy)).distance <
                  cornerHitRadius) {
                hoveringCornerIndex = 3;
              } else {
                isDraggingCorner = false;
              }
              setState(() {
                hoveringCornerIndex = hoveringCornerIndex;
              });
            },
            onPanEnd: (_) {
              dragStart = null;
              isDraggingCorner = false;
              hoveringCornerIndex = -1;
              setState(() {
                hoveringCornerIndex = hoveringCornerIndex;
              });
            },
            child: MouseRegion(
              onHover: (details) {
                var (start, end) = getRangeBounds();
                int newHoveringCornerIndex = -1;

                if ((details.localPosition - start).distance <
                    cornerHitRadius) {
                  newHoveringCornerIndex = 0;
                } else if ((details.localPosition - Offset(end.dx, start.dy))
                        .distance <
                    cornerHitRadius) {
                  newHoveringCornerIndex = 1;
                } else if ((details.localPosition - end).distance <
                    cornerHitRadius) {
                  newHoveringCornerIndex = 2;
                } else if ((details.localPosition - Offset(start.dx, end.dy))
                        .distance <
                    cornerHitRadius) {
                  newHoveringCornerIndex = 3;
                }

                if (hoveringCornerIndex != newHoveringCornerIndex) {
                  setState(() {
                    hoveringCornerIndex = newHoveringCornerIndex;
                  });
                }
              },
              cursor: _getCursorForCorner(hoveringCornerIndex),
              child: GenderPainterWidget(
                painter: RangeGridPainter(getRangeBounds()),
                maxGridSize: maxGridSize,
              ),
            ),
          ),
          Text(getGenderValue())
        ],
      ],
    );
  }

  SystemMouseCursor _getCursorForCorner(int cornerIndex) {
    switch (cornerIndex) {
      case 0:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case 1:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case 2:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case 3:
        return SystemMouseCursors.resizeUpRightDownLeft;
      default:
        return SystemMouseCursors.basic;
    }
  }
}

class RangeGridPainter extends CustomPainter {
  final (Offset, Offset) rangeBounds;

  RangeGridPainter(this.rangeBounds);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromPoints(rangeBounds.$1, rangeBounds.$2), paint);

    // Draw arrows
    _drawArrow(canvas, rangeBounds.$1, const Offset(-1, -1));
    _drawArrow(canvas, Offset(rangeBounds.$2.dx, rangeBounds.$1.dy),
        const Offset(1, -1));
    _drawArrow(canvas, rangeBounds.$2, const Offset(1, 1));
    _drawArrow(canvas, Offset(rangeBounds.$1.dx, rangeBounds.$2.dy),
        const Offset(-1, 1));
  }

  void _drawArrow(Canvas canvas, Offset position, Offset corner) {
    var paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    var path = Path();
    var arrowSize = 10.0;

    var cornerPosition = Offset(
      position.dx - corner.dx * 3,
      position.dy - corner.dy * 3,
    );

    path.moveTo(cornerPosition.dx, cornerPosition.dy);
    path.lineTo(cornerPosition.dx - arrowSize * corner.dx, cornerPosition.dy);
    path.lineTo(cornerPosition.dx, cornerPosition.dy);
    path.lineTo(cornerPosition.dx, cornerPosition.dy - arrowSize * corner.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GenderLabel {
  double maleStart;
  double maleEnd;
  double femaleStart;
  double femaleEnd;
  String label;

  GenderLabel(
      {required this.maleStart,
      required this.maleEnd,
      required this.femaleStart,
      required this.femaleEnd,
      required this.label});
}

var genderLabels = [
  GenderLabel(
      maleStart: 0,
      maleEnd: 0.33,
      femaleStart: 0,
      femaleEnd: 0.33,
      label: "Agender"),
  GenderLabel(
      maleStart: 0,
      maleEnd: 0.33,
      femaleStart: 0.33,
      femaleEnd: 0.66,
      label: "Demigirl"),
  GenderLabel(
      maleStart: 0,
      maleEnd: 0.33,
      femaleStart: 0.66,
      femaleEnd: 1.0,
      label: "Female"),
  GenderLabel(
      maleStart: 0.33,
      maleEnd: 0.66,
      femaleStart: 0.0,
      femaleEnd: 0.33,
      label: "Demiboy"),
  GenderLabel(
      maleStart: 0.33,
      maleEnd: 0.66,
      femaleStart: 0.33,
      femaleEnd: 0.66,
      label: "Nonbinary"),
  GenderLabel(
      maleStart: 0.33,
      maleEnd: 0.66,
      femaleStart: 0.66,
      femaleEnd: 1.0,
      label: "Feminine Nonbinary"),
  GenderLabel(
      maleStart: 0.66,
      maleEnd: 1.0,
      femaleStart: 0.0,
      femaleEnd: 0.33,
      label: "Male"),
  GenderLabel(
      maleStart: 0.66,
      maleEnd: 1.0,
      femaleStart: 0.33,
      femaleEnd: 0.66,
      label: "Masculine Nonbinary"),
  GenderLabel(
      maleStart: 0.66,
      maleEnd: 1.0,
      femaleStart: 0.66,
      femaleEnd: 1.0,
      label: "Bigender"),
];

//getLabel
String getGenderLabel(double maleValue, double femaleValue) {
  for (var label in genderLabels) {
    if (maleValue >= label.maleStart &&
        maleValue <= label.maleEnd &&
        femaleValue >= label.femaleStart &&
        femaleValue <= label.femaleEnd) {
      return label.label;
    }
  }
  return "Unknown";
}
