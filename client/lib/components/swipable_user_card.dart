import 'dart:convert';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/elo_badge.dart';
import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';

class SwipeableUserCard extends StatefulWidget {
  final UserWithImagesAndEloAndUuid user;
  final Function(UserWithImagesAndEloAndUuid, bool) onSwipe;

  const SwipeableUserCard({
    super.key,
    required this.user,
    required this.onSwipe,
  });

  @override
  SwipeableUserCardState createState() => SwipeableUserCardState();
}

class SwipeableUserCardState extends State<SwipeableUserCard> {
  late PreloadPageController _pageController;
  late int _currentIndex;
  final List<MemoryImage> _cachedImages = [];
  bool _isCardExpanded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PreloadPageController();
    _currentIndex = 0;

    _preloadImages();

    _pageController.addListener(() {
      int newIndex = _pageController.page!.round();
      if (_currentIndex != newIndex) {
        setState(() {
          _currentIndex = newIndex;
        });
      }
    });
  }

  void _preloadImages() {
    for (var image in widget.user.images) {
      var imageData = base64Decode(image.b64Content);
      _cachedImages.add(MemoryImage(imageData));
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dx > 0) {
      widget.onSwipe(widget.user, true); // Liked
    } else if (details.velocity.pixelsPerSecond.dx < 0) {
      widget.onSwipe(widget.user, false); // Disliked
    }
  }

  void _onTapUp(TapUpDetails details, BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var dx = details.globalPosition.dx;

    if (dx > screenWidth / 2) {
      if (_currentIndex < widget.user.images.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    } else {
      if (_currentIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    }
  }

  void _toggleCard() {
    setState(() {
      _isCardExpanded = !_isCardExpanded;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          GestureDetector(
            onTapUp: (details) => _onTapUp(details, context),
            child: PreloadPageView.builder(
              controller: _pageController,
              itemCount: widget.user.images.length,
              preloadPagesCount: 3,
              itemBuilder: (context, index) {
                return Image(
                  image: _cachedImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),
          Positioned(
            bottom: _isCardExpanded ? 200.0 : 60.0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.user.images.length, (index) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  width: 10.0,
                  height: 10.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index ? Colors.blue : Colors.grey,
                  ),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy < 0) {
                  _toggleCard();
                } else if (details.velocity.pixelsPerSecond.dy > 0) {
                  _toggleCard();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isCardExpanded ? 200.0 : 60.0,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      spreadRadius: 5.0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _toggleCard,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.user.user.displayName,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              _isCardExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isCardExpanded)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Text(
                              widget.user.user.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Add the EloBadge widget here
          Positioned(
            top: 16,
            right: 16,
            child: EloBadge(eloLabel: widget.user.elo),
          ),
        ],
      ),
    );
  }
}
