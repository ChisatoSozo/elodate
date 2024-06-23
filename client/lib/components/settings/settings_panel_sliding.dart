import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/settings/settings_panel_basic_info.dart';
import 'package:client/components/settings/settings_panel_category.dart';
import 'package:flutter/material.dart';

class SlidingPanel extends StatelessWidget {
  final int index;
  final List<
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      )> categoriesAndGroups;
  final VoidCallback onClose;
  final VoidCallback onModified;

  const SlidingPanel({
    super.key,
    required this.index,
    required this.categoriesAndGroups,
    required this.onClose,
    required this.onModified,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        child: Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onClose,
              ),
              title: Text(index == 0
                  ? "Basic Info"
                  : categoriesAndGroups[index - 1].$1.toString()),
            ),
            Expanded(
              child: index == 0
                  ? BasicInfoPanel(onModified: onModified)
                  : CategoryPanel(
                      categoryAndGroup: categoriesAndGroups[index - 1],
                      onModified: onModified,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
