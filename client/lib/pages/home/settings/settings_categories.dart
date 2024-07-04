import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/elo_badge.dart';
import 'package:client/main.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const categoryOrdering = [
  PreferenceConfigPublicCategoryEnum.background,
  PreferenceConfigPublicCategoryEnum.beliefs,
  PreferenceConfigPublicCategoryEnum.diet,
  PreferenceConfigPublicCategoryEnum.financial,
  PreferenceConfigPublicCategoryEnum.future,
  PreferenceConfigPublicCategoryEnum.hobbies,
  PreferenceConfigPublicCategoryEnum.lgbt,
  PreferenceConfigPublicCategoryEnum.lifestyle,
  PreferenceConfigPublicCategoryEnum.mandatory,
  PreferenceConfigPublicCategoryEnum.physical,
  PreferenceConfigPublicCategoryEnum.relationshipStyle,
  PreferenceConfigPublicCategoryEnum.sexual,
  PreferenceConfigPublicCategoryEnum.substances,
  PreferenceConfigPublicCategoryEnum.misc,
];

class SettingsCategories extends StatefulWidget {
  const SettingsCategories({
    super.key,
  });

  @override
  SettingsCategoriesState createState() => SettingsCategoriesState();
}

class SettingsCategoriesState extends State<SettingsCategories> {
  late List<
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      )> categoriesAndGroups;

  @override
  void initState() {
    super.initState();
    final userModel = Provider.of<UserModel>(context, listen: false);
    categoriesAndGroups =
        preferenceConfigsToCategoriesAndGroups(userModel.preferenceConfigs!);
    userModel.getNumUsersIPreferDryRun();
    userModel.getNumUsersMutuallyPreferDryRun();
  }

  @override
  Widget build(BuildContext context) {
    //sorted category and groups (same order but Misc is at the bottom ($1))
    var sorted = [...categoriesAndGroups];
    sorted.sort((a, b) =>
        categoryOrdering.indexOf(a.$1) - categoryOrdering.indexOf(b.$1));

    final userModel = Provider.of<UserModel>(context, listen: true);
    var pageWidth = calcPageWidth(context);
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: pageWidth),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Users that match my preferences:',
                          style: Theme.of(context).textTheme.titleMedium),
                      AnimatedFlipCounter(
                        value: userModel.numUsersIPrefer,
                        duration: const Duration(seconds: 1),
                      ),
                      const SizedBox(height: 20),
                      Text('Users that prefer me:',
                          style: Theme.of(context).textTheme.titleMedium),
                      AnimatedFlipCounter(
                        value: userModel.numUsersMutuallyPrefer,
                        duration: const Duration(seconds: 1),
                      ),
                      //logout button
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          userModel.logout(context);
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Column(
                    children: [
                      Text('My Elo',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 20),
                      EloBadge(
                          eloLabel: userModel.me.elo, elo: userModel.me.eloNum),
                    ],
                  ),
                ),
              ],
            ),
            _buildSettingsListItem(constants["basicCategoryName"]!, 0),
            ...List.generate(
              sorted.length,
              (index) => _buildSettingsListItem(
                sorted[index].$1.toString(),
                index + 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsListItem(String title, int index) {
    return ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => EloNav.goHomeSettingsCategory(context, title));
  }
}
