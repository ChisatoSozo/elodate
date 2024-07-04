import 'package:client/api/pkg/lib/api.dart';
import 'package:client/pages/home/swipe/user_gender.dart';
import 'package:client/utils/prefs_utils.dart';
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
        child: Card(
          elevation: 5.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
          ),
          //no margin
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isCardExpanded ? 200.0 : 60.0,
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
                                  100.0,
                        ),
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
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isCardExpanded)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          user.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }
}
