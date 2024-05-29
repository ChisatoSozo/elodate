import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/swipeable_user_card/swipeable_user_card.dart';
import 'package:client/models/user_model.dart';
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
  final List<ApiUser> _potentialMatches = [];
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
      final user = await getPotentialMatch(index);

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
    if (isLiked) {
      var match = await likeUser(user);
      if (match) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("It's a match!")),
        );
      }
    } else {
      await dislikeUser(user);
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
          return const Center(child: Text('End of users, expand your prefs'));
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

  Future<ApiUser?> getPotentialMatch(int index) async {
    if (_potentialMatches.length < 5) {
      _fetchPotentialMatches()
          .then((matches) => _potentialMatches.addAll(matches));
    }
    if (_potentialMatches.isEmpty) {
      var matches = await _fetchPotentialMatches();
      if (matches.isEmpty) {
        return null;
      }
      _potentialMatches.addAll(matches);
      return _potentialMatches[index];
    }
    return _potentialMatches[index];
  }

  Future<bool> likeUser(ApiUser user) async {
    //pop the user from the potential matches
    _potentialMatches.remove(user);
    var client = Provider.of<UserModel>(context, listen: false).client;
    var result = await client.ratePost(RatingWithTarget(
        rating: RatingWithTargetRatingEnum.like, target: user.uuid));
    if (result == null) {
      throw Exception('Failed to like user');
    }
    return result;
  }

  Future<bool> dislikeUser(ApiUser user) async {
    //pop the user from the potential matches
    _potentialMatches.remove(user);

    var client = Provider.of<UserModel>(context, listen: false).client;
    var result = await client.ratePost(RatingWithTarget(
        rating: RatingWithTargetRatingEnum.pass, target: user.uuid));
    if (result == null) {
      throw Exception('Failed to dislike user');
    }
    return result;
  }

  Future<List<ApiUser>> _fetchPotentialMatches() async {
    var client = Provider.of<UserModel>(context, listen: false).client;
    var matches = await client
        .getNextUsersPost(_potentialMatches.map((e) => e.uuid).toList());
    if (matches == null) {
      throw Exception('Failed to get matches');
    }

    return matches.toList();
  }
}
