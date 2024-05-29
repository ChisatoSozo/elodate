import 'package:client/components/prop_pref_components/pref.dart';
import 'package:client/components/prop_pref_components/prep.dart';
import 'package:client/components/responsive_scaffold.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsFlowPage extends StatefulWidget {
  const SettingsFlowPage({super.key});

  @override
  SettingsFlowPageState createState() => SettingsFlowPageState();
}

class SettingsFlowPageState extends State<SettingsFlowPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FocusNode _buttonFocusNode = FocusNode();
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);
    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);
    _buttonFocusNode.requestFocus();

    if (!userModel.isLoading && !userModel.isLoaded) {
      userModel.initAll().then(
        (userModel) {
          setState(
            () {
              loaded = true;
              pageStateModel.initPrefsCategories(userModel);
            },
          );
        },
      );
    } else {
      setState(() {
        loaded = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const CircularProgressIndicator();
    }

    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);
    var userModel = Provider.of<UserModel>(context, listen: false);

    var (_, configs, index) = pageStateModel.getCurrentGroup();
    var (props, prefs) = userModel.getPropertyGroup(configs);

    return PopScope(
      onPopInvoked: (_) => pageStateModel.revertGroup(context),
      child: ResponsiveScaffold(
        title: configs.first.category.toString(),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              if (configs.first.valueQuestion.isNotEmpty) ...[
                Text(configs.first.valueQuestion,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                Prop(
                    configs: configs,
                    props: props,
                    onUpdated: (props) {
                      userModel.setPropertyGroup(props, prefs, index);
                    }),
                const SizedBox(height: 40),
              ],
              Text(configs.first.rangeQuestion,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              Pref(
                  configs: configs,
                  prefs: prefs,
                  onUpdated: (prefs) {
                    userModel.setPropertyGroup(props, prefs, index);
                  }),
              //next button
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  pageStateModel.advanceGroup(context);
                },
                focusNode: _buttonFocusNode,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
