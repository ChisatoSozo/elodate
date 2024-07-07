import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home/settings/prop_pref_components/pref.dart';
import 'package:client/pages/home/settings/prop_pref_components/prop.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsFlowPage extends StatefulWidget {
  final int categoryIndex;
  final int groupIndex;

  const SettingsFlowPage(
      {super.key, required this.categoryIndex, required this.groupIndex});

  @override
  SettingsFlowPageState createState() => SettingsFlowPageState();
}

class SettingsFlowPageState extends State<SettingsFlowPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FocusNode _buttonFocusNode = FocusNode();
  bool _loading = false;
  bool _loadingFinish = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);

    _buttonFocusNode.requestFocus();

    initPrefsCategories(userModel);
    userModel.updateUsersPerfered();
  }

  @override
  void dispose() {
    super.dispose();
  }

  late List<
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      )> categories;

  Future<void> finish(BuildContext context) async {
    var userModel = Provider.of<UserModel>(context, listen: false);
    try {
      await userModel.updateMe();
    } catch (e) {
      setState(() {
        _loadingFinish = false;
        _error = e.toString();
      });
      return;
    }
    if (!context.mounted) {
      setState(() {
        _loadingFinish = false;
        _error = 'Failed to update user, ctx not mounted?';
      });
      return;
    }
    EloNav.goRedir(context);
  }

  Future<void> advanceGroup(BuildContext context) async {
    var newGroupIndex = widget.groupIndex;
    var newCategoryIndex = widget.categoryIndex;
    if (widget.groupIndex < categories[widget.categoryIndex].$2.length - 1) {
      newGroupIndex++;
    } else if (widget.categoryIndex < categories.length - 1) {
      newCategoryIndex++;
      newGroupIndex = 0;
    } else {
      await finish(context);
      return;
    }
    EloNav.goSettings(context, newCategoryIndex, newGroupIndex);
  }

  double percentDone() {
    var totalGroups = 0;
    for (var category in categories) {
      totalGroups += category.$2.length;
    }
    var currentTotalGroup = 0;
    for (var i = 0; i < widget.categoryIndex; i++) {
      currentTotalGroup += categories[i].$2.length;
    }
    currentTotalGroup += widget.groupIndex;
    return currentTotalGroup / totalGroups;
  }

  void initPrefsCategories(UserModel userModel) {
    categories =
        preferenceConfigsToCategoriesAndGroups(userModel.preferenceConfigs!);
  }

  (String, List<PreferenceConfigPublic>, int) getCurrentGroup() {
    return categories[widget.categoryIndex].$2[widget.groupIndex];
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);

    var (_, configs, index) = getCurrentGroup();
    var (props, prefs) = userModel.getPropertyGroup(configs);

    var unset = props.any((p) => p.value == -32768);

    return Column(
      children: [
        if (configs.first.valueQuestion.isNotEmpty) ...[
          Text(configs.first.valueQuestion,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Prop(
              configs: configs,
              props: props,
              onUpdated: (_) {
                userModel.setPropertyGroup(props, prefs, index);
                setState(() {});
              }),
          const SizedBox(height: 40),
        ],
        Text(configs.first.rangeQuestion,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        Pref(
            configs: configs,
            prefs: prefs,
            onUpdated: (_) {
              userModel.setPropertyGroup(props, prefs, index);
              setState(() {});
            }),
        //next button
        const SizedBox(height: 20),
        if (_error != null) Text(_error!),
        const SizedBox(height: 20),
        Row(
          //align buttons left and right
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //button with left arrow icon
            ElevatedButton(
              onPressed: () {
                //pop one page
                EloNav.goBack(context);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back),
                  Text('Back'),
                ],
              ),
            ),

            if (widget.categoryIndex > 0)
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _loadingFinish = true;
                  });
                  await finish(context);
                },
                child: _loadingFinish
                    ? const Text('Loading...')
                    : const Text('Skip All'),
              ),
            //button with right arrow icon
            ElevatedButton(
              onPressed: (configs.first.nonOptionalMessage != null && unset) ||
                      _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                      });
                      await advanceGroup(context);
                      setState(() {
                        _loading = false;
                      });
                    },
              focusNode: _buttonFocusNode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _loading
                      ? const Text('Loading...')
                      : (configs.first.nonOptionalMessage != null && unset)
                          ? Text(configs.first.nonOptionalMessage!)
                          : const Text('Next'),
                  const Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
