import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/spacer.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/pages/home/settings/prop_pref_components/pref.dart';
import 'package:client/pages/home/settings/prop_pref_components/prop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';

class SettingsCategory extends StatefulWidget {
  final String category;

  const SettingsCategory({
    super.key,
    required this.category,
  });
  @override
  SettingsCategoryState createState() => SettingsCategoryState();
}

class SettingsCategoryState extends State<SettingsCategory> {
  late List<
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      )> categoriesAndGroups;

  @override
  //init
  void initState() {
    super.initState();
    final userModel = Provider.of<UserModel>(context, listen: false);
    categoriesAndGroups =
        preferenceConfigsToCategoriesAndGroups(userModel.preferenceConfigs!);
  }

  @override
  Widget build(BuildContext context) {
    var categoryAndGroupExists = categoriesAndGroups
        .any((element) => element.$1.toString() == widget.category);
    if (!categoryAndGroupExists) {
      return const Text('No data found');
    }
    var categoryAndGroup = categoriesAndGroups
        .firstWhere((element) => element.$1.toString() == widget.category);
    return Column(
      children: categoryAndGroup.$2.map((group) {
        final userModel = Provider.of<UserModel>(context, listen: false);
        final (props, prefs) = userModel.getPropertyGroup(group.$2);
        final configs = group.$2;
        final index = group.$3;
        return _buildCategoryGroup(context, configs, props, prefs, index);
      }).toList(),
    );
  }

  Widget _buildCategoryGroup(
    BuildContext context,
    List<PreferenceConfigPublic> configs,
    List<ApiUserPropsInner> props,
    List<ApiUserPrefsInner> prefs,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(configs.first.display,
            style: Theme.of(context).textTheme.titleMedium),
        const VerticalSpacer(),
        if (configs.first.valueQuestion.isNotEmpty) ...[
          Text(configs.first.valueQuestion),
          Prop(
            configs: configs,
            props: props,
            onUpdated: (updatedProps) {
              final userModel = Provider.of<UserModel>(context, listen: false);
              userModel.setPropertyGroup(updatedProps, prefs, index);
            },
          ),
          const VerticalSpacer(),
        ],
        Text(configs.first.rangeQuestion),
        Pref(
          configs: configs,
          prefs: prefs,
          onUpdated: (updatedPrefs) {
            final userModel = Provider.of<UserModel>(context, listen: false);
            userModel.setPropertyGroup(props, updatedPrefs, index);
          },
        ),
        const VerticalSpacer(size: SpacerSize.large)
      ],
    );
  }
}
