import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/elo_badge.dart';
import 'package:client/components/loading.dart';
import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home/swipe/page_indicator.dart';
import 'package:client/pages/home/swipe/swipe_overlay.dart';
import 'package:client/pages/home/swipe/swipeable_image_view.dart';
import 'package:client/pages/home/swipe/user_details.dart';
import 'package:client/services/image_cache_service.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';

class SwipeableUserCard extends StatefulWidget {
  final ApiUser user;
  final Function(ApiUser, bool) onSwipe;

  const SwipeableUserCard({
    super.key,
    required this.user,
    required this.onSwipe,
  });

  @override
  SwipeableUserCardState createState() => SwipeableUserCardState();
}

class SwipeableUserCardState extends State<SwipeableUserCard>
    with SingleTickerProviderStateMixin {
  late PreloadPageController _pageController;
  late int _currentIndex;
  List<UuidImageProvider>? _cachedImages;
  bool _isCardExpanded = false;

  // Variables for swipe animation
  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0.0;
  bool _isLiked = false;

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
    var userModel = Provider.of<UserModel>(context, listen: false);
    setState(() {
      _cachedImages = widget.user.images
          .map((image) => ImageCacheService.getImageProvider(image, userModel))
          .toList();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _cardOffset += details.delta;
      _cardRotation = _cardOffset.dx / 300;
      _isLiked = _cardOffset.dx > 0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_cardOffset.dx > 200 || _cardOffset.dx < -200) {
      // Trigger swipe
      bool isLiked = _cardOffset.dx > 0;
      widget.onSwipe(widget.user, isLiked);
    } else {
      // Reset card position
      setState(() {
        _cardOffset = Offset.zero;
        _cardRotation = 0.0;
        _isLiked = false;
      });
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
    var pageWidth = calcPageWidth(context);
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapUp: (details) => _onTapUp(details, context),
      child: Center(
        child: SizedBox(
          width: pageWidth,
          child: Transform.translate(
            offset: _cardOffset,
            child: Transform.rotate(
              angle: _cardRotation,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: _cachedImages == null
                        ? const Center(
                            child: Loading(text: 'Loading User For Match...'))
                        : SwipeableImageView(
                            images: _cachedImages!,
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                          ),
                  ),
                  SwipeOverlay(
                    overlayColor: _isLiked
                        ? Colors.green.withOpacity(0.7)
                        : _cardOffset == Offset.zero
                            ? Colors.transparent
                            : Colors.red.withOpacity(0.7),
                    swipeOffset: _cardOffset.dx,
                  ),
                  Positioned(
                    bottom: 60.0,
                    left: 0,
                    right: 0,
                    child: PageIndicator(
                      currentIndex: _currentIndex,
                      itemCount: widget.user.images.length,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: UserDetails(
                        isCardExpanded: _isCardExpanded,
                        toggleCard: _toggleCard,
                        user: widget.user),
                  ),
                  Positioned(
                    top: 0,
                    right: 16,
                    child: EloBadge(
                        eloLabel: widget.user.elo, elo: widget.user.eloNum),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
