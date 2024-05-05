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
