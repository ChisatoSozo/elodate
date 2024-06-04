import 'package:flutter/material.dart';

// class ResponsiveScaffold extends StatelessWidget {
//   final bool scrollable;
//   final Widget child;
//   final String? title; // Title property
//   final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

//   // Constructor to take child and title as parameters
//   ResponsiveScaffold(
//       {super.key,
//       required this.child,
//       required this.title,
//       this.scrollable = true});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: title != null
//           ? AppBar(
//               title: Text(title!),
//             )
//           : null,
//       key: scaffoldKey,
//       body: scrollable
//           ? SingleChildScrollView(
//               child: Center(
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(
//                       maxWidth: 400), // Set maximum width to 400
//                   child: child,
//                 ),
//               ),
//             )
//           : Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(
//                     maxWidth: 400), // Set maximum width to 400
//                 child: child,
//               ),
//             ),
//     );
//   }
// }

// class ResponsiveContainer extends StatelessWidget {
//   final bool scrollable;
//   final Widget child;
//   final String? title; // Title property

//   // Constructor to take child and title as parameters
//   const ResponsiveContainer(
//       {super.key, required this.child, this.scrollable = false, this.title});

//   @override
//   Widget build(BuildContext context) {
//     return scrollable
//         ? SingleChildScrollView(
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(
//                     maxWidth: 400), // Set maximum width to 400
//                 child: child,
//               ),
//             ),
//           )
//         : Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(
//                   maxWidth: 400), // Set maximum width to 400
//               child: Column(
//                 children: [
//                   if (title != null) Text(title!),
//                   child,
//                 ],
//               ),
//             ),
//           );
//   }
// }

class ResponsiveForm extends StatelessWidget {
  final List<Widget> children;
  final String? title; // Title property
  final bool titleAtTop;
  final GlobalKey<FormState>? _formKey;
  final GlobalKey<FormState> _defaultFormKey = GlobalKey<FormState>();

  // Constructor to take children and title as parameters
  ResponsiveForm(
      {super.key,
      required this.children,
      this.title,
      this.titleAtTop = false,
      GlobalKey<FormState>? formKey})
      : _formKey = formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey ?? _defaultFormKey,
      child: Scaffold(
        appBar: titleAtTop && title != null
            ? AppBar(
                title: Text(title!),
              )
            : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                      maxWidth: 400, minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null && !titleAtTop) ...[
                          Text(title!,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                        ],
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
