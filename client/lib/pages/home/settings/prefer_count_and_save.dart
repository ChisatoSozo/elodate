import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:client/models/user_model.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PreferCountAndSave extends StatelessWidget {
  const PreferCountAndSave({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var userModel = Provider.of<UserModel>(context, listen: true);
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
      color: theme.cardColor,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const PreferenceCounters(),
            SaveButton(
              hasChanges: userModel.changes,
              onSave: () {
                userModel.updateMe();
                EloNav.goBack(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PreferenceCounters extends StatelessWidget {
  const PreferenceCounters({super.key});

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: true);
    return Row(
      children: [
        CounterRow(
          text: 'I Prefer',
          value: userModel.numUsersIPrefer,
          icon: Icons.thumb_up,
        ),
        const SizedBox(width: 16), // Add some spacing between the counters
        CounterRow(
          text: 'Prefer Me',
          value: userModel.numUsersMutuallyPrefer,
          icon: Icons.favorite,
        ),
      ],
    );
  }
}

class CounterRow extends StatelessWidget {
  final String text;
  final int value;
  final IconData icon;

  const CounterRow({
    super.key,
    required this.text,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.secondary,
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

class SaveButton extends StatelessWidget {
  final bool hasChanges;
  final VoidCallback onSave;

  const SaveButton({
    super.key,
    required this.hasChanges,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: hasChanges ? onSave : null,
      child: Text(hasChanges ? 'Save' : 'No Changes'),
    );
  }
}
