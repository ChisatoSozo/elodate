// import 'package:client/api/pkg/lib/api.dart';
// import 'package:client/components/distance_slider.dart';
// import 'package:client/components/range_slider.dart';
// import 'package:client/models/home_model.dart';
// import 'package:client/utils/preference_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class UserPreferenceForm extends StatefulWidget {
//   final UserWithImagesUserPreferenceController preferencesController;

//   const UserPreferenceForm({
//     super.key,
//     required this.preferencesController,
//   });

//   @override
//   UserPreferenceFormState createState() => UserPreferenceFormState();
// }

// class UserPreferenceFormState extends State<UserPreferenceForm> {
//   static const List<int> presetDistances = [
//     1,
//     2,
//     5,
//     10,
//     20,
//     50,
//     100,
//     250,
//     500,
//     25000
//   ];

//   late List<RangeSliderFormFieldController> _additionalPreferencesControllers;
//   late RangeSliderFormFieldController _ageController;
//   late RangeSliderFormFieldController _percentMaleController;
//   late RangeSliderFormFieldController _percentFemaleController;

//   late List<void Function(ApiUserPreferencesAdditionalPreferencesInnerRange)>
//       _additionalPreferenceUpdaters;

//   int _distanceIndex = 5;
//   Map<String, bool> _expandedCategories = {};
//   bool _basicIsExpanded = true;

//   @override
//   void initState() {
//     super.initState();
//     _initializeDistanceIndex();
//     _initControllers();
//     _initializeExpandedCategories();
//   }

//   void _initializeDistanceIndex() {
//     int initialDistance = calculateInitialDistance(
//         Provider.of<HomeModel>(context, listen: false).me);
//     _distanceIndex = findClosestDistanceIndex(initialDistance, presetDistances);
//   }

//   void _initControllers() {
//     var homeModel = Provider.of<HomeModel>(context, listen: false);
//     _ageController = RangeSliderFormFieldController(
//       homeModel.me.preferences.age,
//     );
//     _percentMaleController = RangeSliderFormFieldController(
//       homeModel.me.preferences.percentMale,
//     );
//     _percentFemaleController = RangeSliderFormFieldController(
//       homeModel.me.preferences.percentFemale,
//     );

//     _additionalPreferencesControllers = homeModel.preferenceConfigs.additional
//         .map((pref) => RangeSliderFormFieldController(homeModel
//             .me
//             .preferences
//             .additionalPreferences[
//                 homeModel.preferenceConfigs.additional.indexOf(pref)]
//             .range))
//         .toList();

//     _additionalPreferenceUpdaters = homeModel.preferenceConfigs.additional
//         .map((pref) =>
//             (ApiUserPreferencesAdditionalPreferencesInnerRange value) {
//               widget.preferencesController
//                   .updateAdditionalPreference(pref.name, value);
//             })
//         .toList();
//   }

//   void _initializeExpandedCategories() {
//     var homeModel = Provider.of<HomeModel>(context, listen: false);
//     _expandedCategories = {
//       for (var pref in homeModel.preferenceConfigs.additional)
//         pref.category: false
//     };
//   }

//   void _closeAllCategories() {
//     setState(() {
//       _basicIsExpanded = false;
//       _expandedCategories = {
//         for (var key in _expandedCategories.keys) key: false
//       };
//     });
//   }

//   void _toggleCategoryExpansion(String category) {
//     setState(() {
//       var previousState = _expandedCategories[category]!;
//       _closeAllCategories();
//       _expandedCategories[category] = !previousState;
//     });
//   }

//   void _toggleBasicExpansion() {
//     setState(() {
//       var previousState = _basicIsExpanded;
//       _closeAllCategories();
//       _basicIsExpanded = !previousState;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     var homeModel = Provider.of<HomeModel>(context);
//     final categorizedPreferences =
//         homeModel.preferenceConfigs.additional.fold<Map<String, List<int>>>(
//       {},
//       (map, pref) {
//         final index = homeModel.preferenceConfigs.additional.indexOf(pref);
//         map.putIfAbsent(pref.category, () => []).add(index);
//         return map;
//       },
//     );

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             ExpansionPanelList(
//               expansionCallback: (int index, bool isExpanded) {
//                 if (index == 0) {
//                   _toggleBasicExpansion();
//                   return;
//                 }

//                 final category =
//                     categorizedPreferences.keys.elementAt(index - 1);
//                 _toggleCategoryExpansion(category);
//               },
//               children: [
//                 ExpansionPanel(
//                   headerBuilder: (BuildContext context, bool isExpanded) {
//                     return const ListTile(
//                       title: Text('Basic Preferences'),
//                     );
//                   },
//                   body: _basicIsExpanded
//                       ? Column(
//                           children: [
//                             RangeSliderFormField(
//                               title: 'Age Range',
//                               controller: _ageController,
//                               onUpdate: widget.preferencesController.updateAge,
//                               config: homeModel.preferenceConfigs.mandatory.age,
//                             ),
//                             DistanceSliderWidget(
//                               title: 'Distance Range (km)',
//                               distanceIndex: _distanceIndex,
//                               presetDistances: presetDistances,
//                               onChanged: (index) =>
//                                   setState(() => _distanceIndex = index),
//                             ),
//                             RangeSliderFormField(
//                               title: 'Percent Male',
//                               controller: _percentMaleController,
//                               onUpdate: widget
//                                   .preferencesController.updatePercentMale,
//                               config: homeModel
//                                   .preferenceConfigs.mandatory.percentMale,
//                             ),
//                             RangeSliderFormField(
//                               title: 'Percent Female',
//                               controller: _percentFemaleController,
//                               onUpdate: widget
//                                   .preferencesController.updatePercentFemale,
//                               config: homeModel
//                                   .preferenceConfigs.mandatory.percentFemale,
//                             ),
//                           ],
//                         )
//                       : const Text("loading..."),
//                   isExpanded: _basicIsExpanded,
//                   canTapOnHeader: true,
//                 ),
//                 ...categorizedPreferences.entries.map((entry) {
//                   final category = entry.key;
//                   final indices = entry.value;

//                   return ExpansionPanel(
//                     canTapOnHeader: true,
//                     headerBuilder: (BuildContext context, bool isExpanded) {
//                       return ListTile(
//                         title: Text(
//                           category[0].toUpperCase() + category.substring(1),
//                         ),
//                       );
//                     },
//                     body: _expandedCategories[category]!
//                         ? Column(
//                             children: indices.map((index) {
//                               final pref =
//                                   homeModel.preferenceConfigs.additional[index];
//                               return RangeSliderFormField(
//                                 title: pref.display,
//                                 controller:
//                                     _additionalPreferencesControllers[index],
//                                 onUpdate: _additionalPreferenceUpdaters[index],
//                                 config: pref,
//                               );
//                             }).toList(),
//                           )
//                         : const Text("loading..."),
//                     isExpanded: _expandedCategories[category]!,
//                   );
//                 })
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class UserWithImagesUserPreferenceController {
//   ApiUserPreferences value;
//   void Function(ApiUserPreferences) onUpdate;

//   UserWithImagesUserPreferenceController(
//       {required this.value, required this.onUpdate});

//   void updateValue(ApiUserPreferences newValue) {
//     value = newValue;
//     onUpdate(newValue);
//   }

//   void updateAge(ApiUserPreferencesAdditionalPreferencesInnerRange age) {
//     value = ApiUserPreferences(
//       additionalPreferences: value.additionalPreferences,
//       age: age,
//       latitude: value.latitude,
//       longitude: value.longitude,
//       percentFemale: value.percentFemale,
//       percentMale: value.percentMale,
//     );
//     onUpdate(value);
//   }

//   void updateLatitude(
//       ApiUserPreferencesAdditionalPreferencesInnerRange latitude) {
//     value = ApiUserPreferences(
//       additionalPreferences: value.additionalPreferences,
//       age: value.age,
//       latitude: latitude,
//       longitude: value.longitude,
//       percentFemale: value.percentFemale,
//       percentMale: value.percentMale,
//     );
//     onUpdate(value);
//   }

//   void updateLongitude(
//       ApiUserPreferencesAdditionalPreferencesInnerRange longitude) {
//     value = ApiUserPreferences(
//       additionalPreferences: value.additionalPreferences,
//       age: value.age,
//       latitude: value.latitude,
//       longitude: longitude,
//       percentFemale: value.percentFemale,
//       percentMale: value.percentMale,
//     );
//     onUpdate(value);
//   }

//   void updatePercentFemale(
//       ApiUserPreferencesAdditionalPreferencesInnerRange percentFemale) {
//     value = ApiUserPreferences(
//       additionalPreferences: value.additionalPreferences,
//       age: value.age,
//       latitude: value.latitude,
//       longitude: value.longitude,
//       percentFemale: percentFemale,
//       percentMale: value.percentMale,
//     );
//     onUpdate(value);
//   }

//   void updatePercentMale(
//       ApiUserPreferencesAdditionalPreferencesInnerRange percentMale) {
//     value = ApiUserPreferences(
//       additionalPreferences: value.additionalPreferences,
//       age: value.age,
//       latitude: value.latitude,
//       longitude: value.longitude,
//       percentFemale: value.percentFemale,
//       percentMale: percentMale,
//     );
//     onUpdate(value);
//   }

//   void updateAdditionalPreference(String name,
//       ApiUserPreferencesAdditionalPreferencesInnerRange additionalPreference) {
//     final updatedPreferences = value.additionalPreferences;
//     value = ApiUserPreferences(
//       additionalPreferences: updatedPreferences,
//       age: value.age,
//       latitude: value.latitude,
//       longitude: value.longitude,
//       percentFemale: value.percentFemale,
//       percentMale: value.percentMale,
//     );
//     onUpdate(value);
//   }
// }
