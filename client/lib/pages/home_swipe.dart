import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/swipeable_user_card/swipeable_user_card.dart';
import 'package:client/models/home_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  SwipePageState createState() => SwipePageState();
}

class SwipePageState extends State<SwipePage> {
  UserWithImagesAndEloAndUuid? _nextUser;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNextUser();
  }

  Future<void> _loadNextUser() async {
    try {
      final user = await Provider.of<HomeModel>(context, listen: false)
          .getPotentialMatch();
      setState(() {
        _nextUser = user;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> handleSwipe(
      UserWithImagesAndEloAndUuid user, bool isLiked) async {
    if (isLiked) {
      await Provider.of<HomeModel>(context, listen: false).likeUser(user);
    } else {
      await Provider.of<HomeModel>(context, listen: false).dislikeUser(user);
    }
    _loadNextUser();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text('Error loading user'));
    }

    if (_nextUser == null) {
      return const Center(child: Text('No user available'));
    }

    return SwipeableUserCard(
      user: _nextUser!,
      onSwipe: handleSwipe,
    );
  }
}
