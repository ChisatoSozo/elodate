import 'package:client/api/pkg/lib/api.dart';

List<
        (
          PreferenceConfigPublicCategoryEnum,
          List<(String, List<PreferenceConfigPublic>, int)>
        )>
    preferenceConfigsToCategoriesAndGroups(
        List<PreferenceConfigPublic> preferenceConfigs) {
  var categories = <(
    PreferenceConfigPublicCategoryEnum,
    List<(String, List<PreferenceConfigPublic>, int)>
  )>[];
  var index = 0;
  for (var config in preferenceConfigs) {
    var category = categories.firstWhere(
        (element) => element.$1 == config.category,
        orElse: () => (config.category, []));
    if (!categories.contains(category)) {
      categories.add(category);
    }
    var group = category.$2.firstWhere((element) => element.$1 == config.group,
        orElse: () => (config.group, [], index));
    if (!category.$2.contains(group)) {
      category.$2.add(group);
    }
    group.$2.add(config);
    index++;
  }
  return categories;
}
