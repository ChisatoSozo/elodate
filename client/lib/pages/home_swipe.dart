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
  late Future<UserWithImagesAndEloAndUuid> _nextUserFuture;

  @override
  void initState() {
    super.initState();
    _nextUserFuture = getNextUser(context);
  }

  Future<UserWithImagesAndEloAndUuid> getNextUser(BuildContext context) async {
    final user = await Provider.of<HomeModel>(context, listen: false)
        .getPotentialMatch();
    return user;
  }

  Future<void> handleSwipe(
      UserWithImagesAndEloAndUuid user, bool isLiked) async {
    if (isLiked) {
      await Provider.of<HomeModel>(context, listen: false).likeUser(user);
    } else {
      await Provider.of<HomeModel>(context, listen: false).dislikeUser(user);
    }
    setState(() {
      _nextUserFuture = getNextUser(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Swipe"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<UserWithImagesAndEloAndUuid>(
        future: _nextUserFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading user'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No user available'));
          } else {
            final user = snapshot.data!;
            return SwipeableUserCard(
              user: user,
              onSwipe: handleSwipe,
            );
          }
        },
      ),
    );
  }
}
