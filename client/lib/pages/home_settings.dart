import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/home_model.dart';
import 'package:client/pages/home_settings_matches.dart';
import 'package:client/pages/home_settings_me.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  UserWithImagesAndEloAndUuid? _me;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final homeModel = Provider.of<HomeModel>(context, listen: false);
      final me = await homeModel.getMe();
      setState(() {
        _me = me;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text("Error loading data"));
    }

    if (_me == null) {
      return const Center(child: Text("No data available"));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _me!.user.published == null || !_me!.user.published!
              ? const Text("Optional profile set-up")
              : const Text("Settings"),
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
            SettingsPageMe(me: _me!),
            UserPreferenceForm(me: _me!),
          ],
        ),
      ),
    );
  }
}
