import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/conversation/widgets/adaptive_genui_follow_up_card.dart';
import '../bloc/bloc.dart';
import '../../../patients/data/models/patient_model.dart';

export '../../../../core/conversation/widgets/adaptive_genui_follow_up_card.dart';

/// Reusable presentation widget observing [ConversationBloc] and rendering the
/// active interactive GenUI card or outcome.
class ConversationWorkflowView extends StatelessWidget {
  final List<PatientModel> existingPatients;
  final VoidCallback? onCompleted;

  const ConversationWorkflowView({
    super.key,
    this.existingPatients = const [],
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationBloc, ConversationState>(
      listener: (context, state) {
        if (state is ConversationSuccess) {
          onCompleted?.call();
        }
      },
      builder: (context, state) {
        if (state is ConversationProcessing || state is ConversationExecutingAction) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ConversationFailure) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<ConversationBloc>().add(
                          ConversationRetryRequested(existingPatients: existingPatients),
                        );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ConversationAwaitingInput ||
            state is ConversationAwaitingSelection ||
            state is ConversationAwaitingConfirmation) {
          final q = state.workflowState.currentQuestion;
          if (q == null) return const SizedBox.shrink();

          return AdaptiveGenUiFollowUpCard(
            question: q,
            state: state.workflowState,
            onAnswer: (val) {
              context.read<ConversationBloc>().add(
                    FollowUpOptionSelected(
                      q.targetField,
                      val,
                      existingPatients: existingPatients,
                    ),
                  );
            },
            onConfirm: () {
              context.read<ConversationBloc>().add(
                    const WorkflowConfirmationRequested(),
                  );
            },
            onCancel: () {
              context.read<ConversationBloc>().add(
                    const WorkflowCancelled(),
                  );
            },
            onSkip: () {
              context.read<ConversationBloc>().add(
                    FollowUpOptionSelected(
                      'skip_${q.targetField}',
                      true,
                      existingPatients: existingPatients,
                    ),
                  );
            },
            onBack: () {
              context.read<ConversationBloc>().add(
                    const WorkflowBackRequested(),
                  );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
