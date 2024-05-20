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
  final List<UserWithImagesAndEloAndUuid?> _userStack = [null, null];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    await _loadNextUser(0);
    await _loadNextUser(1);
  }

  Future<void> _loadNextUser(int index) async {
    try {
      final user = await Provider.of<HomeModel>(context, listen: false)
          .getPotentialMatch(index);
      setState(() {
        _userStack[index] = user;
        if (_userStack.every((user) => user != null)) {
          _isLoading = false;
        }
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
    var homeModel = Provider.of<HomeModel>(context, listen: false);
    if (isLiked) {
      var match = await homeModel.likeUser(user);
      if (match) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("It's a match!")),
        );
        homeModel.chats = [];
        homeModel.initChats();
      }
    } else {
      await homeModel.dislikeUser(user);
    }

    setState(() {
      _userStack[0] = _userStack[1];
      _userStack[1] = null;
    });

    await _loadNextUser(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text('Error loading user'));
    }

    if (_userStack[0] == null) {
      return const Center(child: Text('End of users, expand your preferences'));
    }

    return Stack(
      children: _userStack.reversed.map((user) {
        if (user == null) return Container();
        return Positioned.fill(
          child: SwipeableUserCard(
            user: user,
            onSwipe: handleSwipe,
            key: ValueKey(user.uuid),
          ),
        );
      }).toList(),
    );
  }
}
