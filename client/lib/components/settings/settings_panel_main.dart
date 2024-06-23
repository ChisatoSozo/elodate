import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:client/api/pkg/lib/api.dart';
import 'package:flutter/material.dart';

class MainPanel extends StatelessWidget {
  final double opacity;
  final bool absorbing;
  final List<
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      )> categoriesAndGroups;
  final Function(int) onCategoryTap;
  final int usersThatIPrefer;
  final int usersThatAlsoPreferMe;
  final String? error;
  final bool modified;
  final bool saving;
  final Function(BuildContext) onLogout;
  final VoidCallback onSaveChanges;

  const MainPanel({
    super.key,
    required this.opacity,
    required this.absorbing,
    required this.categoriesAndGroups,
    required this.onCategoryTap,
    required this.usersThatIPrefer,
    required this.usersThatAlsoPreferMe,
    required this.error,
    required this.modified,
    required this.saving,
    required this.onLogout,
    required this.onSaveChanges,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 300),
      child: AbsorbPointer(
        absorbing: absorbing,
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "See the results of your filters at the bottom of this page",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildSettingsList(),
            _buildStatsCard(),
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingsListItem("Basic Info", 0),
        ...List.generate(
          categoriesAndGroups.length,
          (index) => _buildSettingsListItem(
            categoriesAndGroups[index].$1.toString(),
            index + 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsListItem(String title, int index) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onCategoryTap(index),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFlipCounters(),
            if (error != null) _buildErrorText(),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipCounters() {
    final suffixIPrefer = usersThatIPrefer == 1 ? 'user' : 'users';
    final suffixAlsoPreferMe = usersThatAlsoPreferMe == 1 ? 'user' : 'users';
    final suffixAlsoPrefers = usersThatAlsoPreferMe == 1 ? 'prefers' : 'prefer';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedFlipCounter(
          value: usersThatIPrefer,
          duration: const Duration(milliseconds: 500),
          suffix: ' $suffixIPrefer after filter',
        ),
        AnimatedFlipCounter(
          value: usersThatAlsoPreferMe,
          duration: const Duration(milliseconds: 500),
          suffix: ' $suffixAlsoPreferMe also $suffixAlsoPrefers me',
        ),
      ],
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        error!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () => onLogout(context),
            child: const Text('Logout'),
          ),
          ElevatedButton(
            onPressed: modified && !saving ? onSaveChanges : null,
            child: Text(saving ? 'Saving...' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
