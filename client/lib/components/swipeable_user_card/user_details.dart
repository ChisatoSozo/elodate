import 'package:flutter/material.dart';

class UserDetails extends StatelessWidget {
  final bool isCardExpanded;
  final Function toggleCard;
  final String displayName;
  final String description;

  const UserDetails({
    super.key,
    required this.isCardExpanded,
    required this.toggleCard,
    required this.displayName,
    required this.description,
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
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge,
                    ),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
