/// Typed conversation workflow status representing the progression of an intent.
enum WorkflowStatus {
  /// No workflow currently active; ready for new requests.
  idle,

  /// Initial natural language interpretation and slot extraction.
  interpretingRequest,

  /// Ambiguous request or parameter requiring provider clarification.
  awaitingClarification,

  /// Multiple candidate entities exist (e.g. patients, readings, appointment slots).
  awaitingSelection,

  /// Collecting missing required or essential parameters.
  collectingInformation,

  /// Performing clinical validation on user provided values.
  validating,

  /// Consequential action requires explicit provider confirmation before committing.
  awaitingConfirmation,

  /// Authorizing and executing database write or query through application service.
  executingAction,

  /// Action succeeded and outcome is presented to provider.
  completed,

  /// Execution or validation failed; recovery/retry offered.
  failed,

  /// Workflow was explicitly cancelled by provider.
  cancelled,
}

extension WorkflowStatusX on WorkflowStatus {
  bool get isTerminal =>
      this == WorkflowStatus.completed ||
      this == WorkflowStatus.failed ||
      this == WorkflowStatus.cancelled;

  bool get isInteractive =>
      this == WorkflowStatus.awaitingClarification ||
      this == WorkflowStatus.awaitingSelection ||
      this == WorkflowStatus.collectingInformation ||
      this == WorkflowStatus.awaitingConfirmation;
}
