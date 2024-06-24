import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home/settings/prop_pref_components/pref.dart';
import 'package:client/pages/home/settings/prop_pref_components/prop.dart';
import 'package:client/router.dart';
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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);
    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);
    _buttonFocusNode.requestFocus();

    pageStateModel.initPrefsCategories(userModel);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);
    var userModel = Provider.of<UserModel>(context, listen: false);

    var (_, configs, index) = pageStateModel.getCurrentGroup();
    var (props, prefs) = userModel.getPropertyGroup(configs);

    var unset = props.any((p) => p.value == -32768);

    return PopScope(
      onPopInvoked: (_) => pageStateModel.revertGroup(context),
      child: Column(
        children: [
          if (configs.first.valueQuestion.isNotEmpty) ...[
            Text(configs.first.valueQuestion,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Prop(
                configs: configs,
                props: props,
                onUpdated: (props) {
                  userModel.setPropertyGroup(props, prefs, index);
                  setState(() {});
                }),
            const SizedBox(height: 40),
          ],
          Text(configs.first.rangeQuestion,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Pref(
              configs: configs,
              prefs: prefs,
              onUpdated: (prefs) {
                userModel.setPropertyGroup(props, prefs, index);
                setState(() {});
              }),
          //next button
          const SizedBox(height: 40),
          Row(
            //align buttons left and right
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //button with left arrow icon
              ElevatedButton(
                onPressed: () {
                  //pop one page
                  EloNav.goBack();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back),
                    Text('Back'),
                  ],
                ),
              ),
              //button with right arrow icon
              ElevatedButton(
                onPressed:
                    (configs.first.nonOptionalMessage != null && unset) ||
                            _loading
                        ? null
                        : () async {
                            setState(() {
                              _loading = true;
                            });
                            await pageStateModel.advanceGroup(context);
                            setState(() {
                              _loading = false;
                            });
                          },
                focusNode: _buttonFocusNode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _loading
                        ? const Text('Loading...')
                        : (configs.first.nonOptionalMessage != null && unset)
                            ? Text(configs.first.nonOptionalMessage!)
                            : const Text('Next'),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
