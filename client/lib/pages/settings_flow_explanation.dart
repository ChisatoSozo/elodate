import 'package:client/router/elo_router_nav.dart';
import 'package:flutter/material.dart';

class SettingsFlowExplainerPage extends StatelessWidget {
  const SettingsFlowExplainerPage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_rounded,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Get to Know You Better',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We have prepared a series of about 80 questions to help us understand you better. '
            'You can skip any question or click "Skip All" at any time to proceed to the main app. '
            'Each answered question rewards you with 1 ELO point!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => EloNav.goSettings(context, 1, 0),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Start Questionnaire',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
