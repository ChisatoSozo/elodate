import 'package:client/models/gender_model.dart';
import 'package:flutter/material.dart';

const maxGridSize = 300.0;

class GenderPickerController extends ValueNotifier<(double, double)> {
  GenderPickerController(
      {required double percentMale, required double percentFemale})
      : super((percentMale, percentFemale));

  void updateValues(double percentMale, double percentFemale) {
    value = (percentMale, percentFemale);
  }
}

class GenderPickerFormField extends FormField<(double, double)> {
  GenderPickerFormField({
    super.key,
    required GenderPickerController controller,
    required FormFieldSetter<(double, double)> onSaved,
    super.validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          initialValue: controller.value,
          onSaved: onSaved,
          builder: (FormFieldState<(double, double)> state) {
            return Column(
              children: <Widget>[
                GenderPicker(
                  controller: controller,
                  onUpdate: (double newPercentMale, double newPercentFemale) {
                    state.didChange((newPercentMale, newPercentFemale));
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.errorText ?? '',
                      style: TextStyle(
                        color: Theme.of(state.context).colorScheme.error,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}

class GenderPicker extends StatefulWidget {
  final GenderPickerController controller;
  final Function(double, double) onUpdate;

  const GenderPicker({
    super.key,
    required this.controller,
    required this.onUpdate,
  });

  @override
  GenderPickerState createState() => GenderPickerState();
}

class GenderPickerState extends State<GenderPicker> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  Offset getOffset() {
    return Offset(
      widget.controller.value.$1 * maxGridSize,
      (1 - widget.controller.value.$2) * maxGridSize,
    );
  }

  String getGenderValue() {
    if (widget.controller.value.$1 == 1 && widget.controller.value.$2 == 0) {
      return "Male";
    } else if (widget.controller.value.$1 == 0 &&
        widget.controller.value.$2 == 1) {
      return "Female";
    } else {
      return "Advanced";
    }
  }

  void _updateGenderValue(Offset newGenderValue) {
    double percentMale = newGenderValue.dx / maxGridSize;
    double percentFemale = 1 - (newGenderValue.dy / maxGridSize);
    widget.controller.updateValues(percentMale, percentFemale);
    widget.onUpdate(percentMale, percentFemale);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          title: const Text('Male'),
          leading: Radio<String>(
            value: 'Male',
            groupValue: getGenderValue(),
            onChanged: (String? value) {
              if (value != null) {
                widget.controller.updateValues(1.0, 0.0);
                widget.onUpdate(1.0, 0.0);
              }
            },
          ),
        ),
        ListTile(
          title: const Text('Female'),
          leading: Radio<String>(
            value: 'Female',
            groupValue: getGenderValue(),
            onChanged: (String? value) {
              if (value != null) {
                widget.controller.updateValues(0.0, 1.0);
                widget.onUpdate(0.0, 1.0);
              }
            },
          ),
        ),
        ListTile(
          title: const Text('Advanced'),
          leading: Radio<String>(
            value: 'Advanced',
            groupValue: getGenderValue(),
            onChanged: (String? value) {
              if (value != null) {
                widget.controller.updateValues(0.5, 0.5);
                widget.onUpdate(0.5, 0.5);
              }
            },
          ),
        ),
        if (getGenderValue() == "Advanced") ...[
          const SizedBox(height: 20),
          GestureDetector(
            onPanUpdate: (details) {
              var x = details.localPosition.dx.clamp(0, maxGridSize).toDouble();
              var y = details.localPosition.dy.clamp(0, maxGridSize).toDouble();
              _updateGenderValue(Offset(x, y));
            },
            onTapDown: (details) {
              var x = details.localPosition.dx.clamp(0, maxGridSize).toDouble();
              var y = details.localPosition.dy.clamp(0, maxGridSize).toDouble();
              _updateGenderValue(Offset(x, y));
            },
            child: Stack(
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
                          Color.fromARGB(0, 255, 255, 255)
                        ],
                        stops: [0, 0.2, 0.4, 0.6, 0.8],
                      ),
                    ),
                    child: CustomPaint(
                      painter: GridPainter(getOffset()),
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
                  child:
                      Text('Bigender', style: TextStyle(color: Colors.white)),
                ),
                const Positioned(
                  bottom: 5,
                  left: 5,
                  child: Text('Agender', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
          Text(getGenderLabel(
              widget.controller.value.$1, widget.controller.value.$2)),
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
