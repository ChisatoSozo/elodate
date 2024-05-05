import 'package:client/models/gender_model.dart';
import 'package:client/models/register_model.dart';
import 'package:client/pages/register_username.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterGenderPage extends StatefulWidget {
  const RegisterGenderPage({super.key});

  @override
  RegisterGenderPageState createState() => RegisterGenderPageState();
}

const maxGridSize = 300.0;

class RegisterGenderPageState extends State<RegisterGenderPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String gender = 'Male';
  bool showAdvanced = false;
  Offset gridValue = const Offset(maxGridSize, maxGridSize);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text("Select your gender:",
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Male'),
                  leading: Radio<String>(
                    value: 'Male',
                    groupValue: gender,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          gender = value;
                          showAdvanced = false;
                          gridValue = const Offset(maxGridSize, maxGridSize);
                        });
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Female'),
                  leading: Radio<String>(
                    value: 'Female',
                    groupValue: gender,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          gender = value;
                          showAdvanced = false;
                          gridValue = const Offset(0, 0);
                        });
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Advanced'),
                  leading: Radio<String>(
                    value: 'Advanced',
                    groupValue: gender,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          gender = value;
                          showAdvanced = true;
                          gridValue =
                              const Offset(maxGridSize / 2, maxGridSize / 2);
                        });
                      }
                    },
                  ),
                ),
                if (showAdvanced) ...[
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onPanUpdate: (details) {
                          var x = details.localPosition.dx
                              .clamp(0, maxGridSize)
                              .toDouble();
                          var y = details.localPosition.dy
                              .clamp(0, maxGridSize)
                              .toDouble();
                          setState(() {
                            gridValue = Offset(x, y);
                          });
                        },
                        child: Container(
                          height: maxGridSize,
                          width: maxGridSize,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.pink,
                                Colors.blue
                              ], // Top to bottom gradient
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
                                  stops: [
                                    0,
                                    0.2,
                                    0.4,
                                    0.6,
                                    0.8
                                  ]),
                            ),
                            child: CustomPaint(
                              painter: GridPainter(gridValue),
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 5,
                        left: 5,
                        child: Text('Female',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const Positioned(
                        bottom: 5,
                        right: 5,
                        child:
                            Text('Male', style: TextStyle(color: Colors.white)),
                      ),
                      const Positioned(
                        top: 5,
                        right: 5,
                        child: Text('Bigender',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const Positioned(
                        bottom: 5,
                        left: 5,
                        child: Text('Agender',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                  Text(getGenderLabel((gridValue.dx / maxGridSize),
                      1 - (gridValue.dy / maxGridSize))),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveGenderAndProceed,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next'),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveGenderAndProceed() {
    Provider.of<RegisterModel>(context, listen: false).setGenderPercentages(
        (gridValue.dx / maxGridSize), 1 - (gridValue.dy / maxGridSize));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterUsernamePage(),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Offset gridValue;

  GridPainter(this.gridValue);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = Colors.black;
    canvas.drawCircle(gridValue, 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
