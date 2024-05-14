import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/home_model.dart';
import 'package:client/pages/home_settings_matches.dart';
import 'package:client/pages/home_settings_me.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserWithImagesAndEloAndUuid?>(
      future: Provider.of<HomeModel>(context).getMe(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading data"));
        } else if (snapshot.hasData) {
          final me = snapshot.data;
          if (me == null) {
            return const Center(child: Text("No data available"));
          }
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Settings"),
                automaticallyImplyLeading: false,
                bottom: const TabBar(
                  tabs: [
                    Tab(text: "Me"),
                    Tab(text: "Matches"),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  SettingsPageMe(me: me),
                  const UserPreferenceForm(),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: Text("No data available"));
        }
      },
    );
  }
}
