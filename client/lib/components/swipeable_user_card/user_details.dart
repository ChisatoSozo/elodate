import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/swipeable_user_card/user_gender.dart';
import 'package:client/utils/preference_utils.dart';
import 'package:flutter/material.dart';

class UserDetails extends StatelessWidget {
  final bool isCardExpanded;
  final Function toggleCard;
  final ApiUser user;

  const UserDetails({
    super.key,
    required this.isCardExpanded,
    required this.toggleCard,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy < 0) {
          toggleCard();
        } else if (details.velocity.pixelsPerSecond.dy > 0) {
          toggleCard();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isCardExpanded ? 200.0 : 60.0,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 10.0,
              spreadRadius: 5.0,
            ),
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => toggleCard(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GenderDisplay(
                        maleValue: (getPropByName(user.props, "percent_male")
                                .value as double) /
                            100.0,
                        femaleValue:
                            (getPropByName(user.props, "percent_female").value
                                    as double) /
                                100.0),
                    const SizedBox(width: 10),
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      isCardExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: theme.iconTheme.color,
                    ),
                  ],
                ),
              ),
            ),
            if (isCardExpanded)
              Expanded(
                child: Column(
                  children: [
                    SingleChildScrollView(
                      child: Text(user.description,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
