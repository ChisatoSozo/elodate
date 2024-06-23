import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/settings/prop_pref_components/pref.dart';
import 'package:client/components/settings/prop_pref_components/prop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';

class CategoryPanel extends StatelessWidget {
  final (
    PreferenceConfigPublicCategoryEnum,
    List<(String, List<PreferenceConfigPublic>, int)>
  ) categoryAndGroup;
  final VoidCallback onModified;

  const CategoryPanel({
    super.key,
    required this.categoryAndGroup,
    required this.onModified,
  });

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 20),
        if (configs.first.valueQuestion.isNotEmpty) ...[
          Text(configs.first.valueQuestion),
          Prop(
            configs: configs,
            props: props,
            onUpdated: (updatedProps) {
              final userModel = Provider.of<UserModel>(context, listen: false);
              userModel.setPropertyGroup(updatedProps, prefs, index);
              onModified();
            },
          ),
          const SizedBox(height: 20),
        ],
        Text(configs.first.rangeQuestion),
        Pref(
          configs: configs,
          prefs: prefs,
          onUpdated: (updatedPrefs) {
            final userModel = Provider.of<UserModel>(context, listen: false);
            userModel.setPropertyGroup(props, updatedPrefs, index);
            onModified();
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
