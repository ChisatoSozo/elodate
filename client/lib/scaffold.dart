import 'package:client/components/bug_report_button.dart';
import 'package:client/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EloScaffold extends StatelessWidget {
  final Widget child;
  //state and context
  final GoRouterState state;

  const EloScaffold({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: pages.firstWhere((page) => page.path == state.path).appBar,
          bottomNavigationBar:
              pages.firstWhere((page) => page.path == state.path).bottomNav,
          resizeToAvoidBottomInset: true,
          body: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const BugReportButton()
      ],
    );
  }
}
