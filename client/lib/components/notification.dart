import 'package:flutter/material.dart';

class NotificationComponent extends StatefulWidget {
  final String title;
  final String body;
  final Function()? onTap;
  final Image? leftImage;

  const NotificationComponent({
    super.key,
    required this.title,
    required this.body,
    this.leftImage,
    this.onTap,
  });

  @override
  NotificationComponentState createState() => NotificationComponentState();
}

class NotificationComponentState extends State<NotificationComponent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color hoverColor = Theme.of(context).cardColor;
    //lighten the color by 10%
    hoverColor = Color.lerp(hoverColor, Colors.white, 0.1) ?? hoverColor;

    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: 350), // Adjust the maxWidth as needed

          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : theme.cardColor,
              borderRadius: widget.leftImage != null
                  ? BorderRadius.circular(100.0)
                  : BorderRadius.circular(8.0),
              border: Border.all(color: theme.colorScheme.primary),
            ),
            child: ListTile(
              onTap: widget.onTap,
              leading: CircleAvatar(
                backgroundImage: widget.leftImage?.image,
              ),
              title: Text(
                widget.title,
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                widget.body,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
