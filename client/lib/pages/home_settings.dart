import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/settings/settings_panel_main.dart';
import 'package:client/components/settings/settings_panel_sliding.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/router.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../utils/utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late List<
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      )> categoriesAndGroups;
  int _usersThatIPrefer = 0;
  int _usersThatAlsoPreferMe = 0;
  String? _error;
  bool _modified = false;
  bool _saving = false;
  int _currentPanelIndex = -1;

  @override
  void initState() {
    super.initState();
    final userModel = Provider.of<UserModel>(context, listen: false);
    categoriesAndGroups =
        preferenceConfigsToCategoriesAndGroups(userModel.preferenceConfigs!);
    _fetchPreferCounts();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPanelIndex == -1,
      onPopInvoked: (didPop) {
        if (!didPop && _currentPanelIndex != -1) {
          _closePanel();
        }
      },
      child: Stack(
        children: [
          MainPanel(
            opacity: _currentPanelIndex == -1 ? 1.0 : 0.3,
            absorbing: _currentPanelIndex != -1,
            categoriesAndGroups: categoriesAndGroups,
            onCategoryTap: _openPanel,
            usersThatIPrefer: _usersThatIPrefer,
            usersThatAlsoPreferMe: _usersThatAlsoPreferMe,
            error: _error,
            modified: _modified,
            saving: _saving,
            onLogout: _logout,
            onSaveChanges: _saveChanges,
          ),
          if (_currentPanelIndex != -1)
            SlidingPanel(
              index: _currentPanelIndex,
              categoriesAndGroups: categoriesAndGroups,
              onClose: _closePanel,
              onModified: _onModified,
            ),
        ],
      ),
    );
  }

  void _openPanel(int index) => setState(() => _currentPanelIndex = index);

  void _closePanel() => setState(() => _currentPanelIndex = -1);

  void _onModified() => setState(() => _modified = true);

  void _fetchPreferCounts() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    userModel
        .getNumUsersIPreferDryRun()
        .then((value) => setState(() => _usersThatIPrefer = value));
    userModel
        .getNumUsersMutuallyPreferDryRun()
        .then((value) => setState(() => _usersThatAlsoPreferMe = value));
  }

  void _logout(BuildContext context) {
    localStorage.removeItem("jwt");
    localStorage.removeItem("uuid");
    EloNav.goLogin(context);
  }

  Future<void> _saveChanges() async {
    setState(() {
      _error = null;
      _saving = true;
      _modified = false;
    });

    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      await userModel.updateMe();
    } catch (error) {
      setState(() => _error = formatApiError(error.toString()));
    } finally {
      setState(() => _saving = false);
    }
  }
}
