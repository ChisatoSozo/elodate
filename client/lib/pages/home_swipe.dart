import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/swipable_user_card.dart';
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

  void handleSwipe(UserWithImagesAndEloAndUuid user, bool isLiked) {
    // Implement like/dislike functionality here
    // e.g., send the like/dislike to the backend

    // Fetch the next user
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
