import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/swipeable_user_card/swipeable_user_card.dart';
import 'package:client/models/home_model.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  SwipePageState createState() => SwipePageState();
}

class SwipePageState extends State<SwipePage> {
  final List<ApiUser?> _userStack = [null, null];
  bool _isLoading = true;
  String? _error;

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
        if (user == null) {
          _isLoading = false;
          return;
        }
        //if index is 1 and user is the same as the user at index 0, don't do anything
        if (index == 1 && _userStack[0] == null) {
          _isLoading = false;
          return;
        }
        if (index == 1 && user.uuid == _userStack[0]!.uuid) {
          _isLoading = false;
          return;
        }
        _userStack[index] = user;
        if (_userStack.every((user) => user != null)) {
          _isLoading = false;
        }
      });
    } catch (error) {
      setState(() {
        _error = formatApiError(error.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> handleSwipe(ApiUser user, bool isLiked) async {
    var homeModel = Provider.of<HomeModel>(context, listen: false);
    if (isLiked) {
      var match = await homeModel.likeUser(user);
      if (match) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("It's a match!")),
        );
        homeModel.chats = [];
        homeModel.initChats(homeModel.me);
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

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Stack(
      children: _userStack.reversed.map((user) {
        if (user == null) {
          return const Center(
              child: Text('End of users, expand your preferences'));
        }
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
