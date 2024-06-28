import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PreferCountAndSave extends StatelessWidget {
  const PreferCountAndSave({super.key});

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: true);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      color: theme.primaryColor,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCounterRow(
              context,
              'I Prefer',
              userModel.numUsersIPrefer,
              Icons.thumb_up,
            ),
            _buildCounterRow(
              context,
              'Prefer Me',
              userModel.numUsersMutuallyPrefer,
              Icons.favorite,
            ),
            //save button
            ElevatedButton(
              onPressed: userModel.changes
                  ? () {
                      userModel.updateMe();
                    }
                  : null,
              child: userModel.changes
                  ? const Text('Save')
                  : const Text('No Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(
      BuildContext context, String text, int value, IconData icon) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.primary,
    );
    final counterStyle = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.secondary,
      fontWeight: FontWeight.bold,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedFlipCounter(
              value: value,
              duration: const Duration(milliseconds: 500),
              textStyle: counterStyle,
            ),
            Text(text, style: textStyle),
          ],
        ),
      ],
    );
  }
}
