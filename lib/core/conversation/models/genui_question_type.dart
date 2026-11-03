/// Identifies the reusable GenUI component chosen for a follow-up question.
enum GenUiQuestionType {
  /// Compact selectable option cards or radio choices for mutually exclusive options.
  singleChoice,

  /// Clear two-option controls (e.g. Yes / No, Accept / Reject).
  yesNo,

  /// Date picker or concise range selector (e.g. Today, Yesterday, custom range).
  datePicker,

  /// Rich patient cards displaying name, age/DOB, phone, emergency contact, and ID.
  patientSelection,

  /// Selectable chips or multi-select list (e.g. vitals, visits, notes, medications).
  multiSelect,

  /// Validated numeric fields with clinical units (e.g. mmHg, bpm, °C).
  numericInput,

  /// Compact editable text input (e.g. clinical observations, chief complaints, notes).
  textInput,

  /// Structured clinical record preview card.
  previewCard,

  /// Explicit confirmation card for consequential changes with proceed/cancel actions.
  confirmationCard,

  /// Clarification prompt presenting multiple potential interpretations.
  ambiguousChoices,
}
