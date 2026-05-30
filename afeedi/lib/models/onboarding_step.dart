class OnboardingStep {
  final String botMessage;
  final List<String> quickReplies;
  final bool allowTextInput;
  final String? inputPlaceholder;
  final bool isGenreSelection;
  final bool isPlatformSelection;
  final bool isLanguageSelection;
  final bool allowMultiSelect;
  final bool showSkipOption;
  final String? stepTitle;
  final String? stepDescription;
  final String? helpText;
  final String? socialProof;
  final String? key;

  OnboardingStep({
    required this.botMessage,
    required this.quickReplies,
    this.allowTextInput = false,
    this.inputPlaceholder,
    this.isGenreSelection = false,
    this.isPlatformSelection = false,
    this.isLanguageSelection = false,
    this.allowMultiSelect = false,
    this.showSkipOption = false,
    this.stepTitle,
    this.stepDescription,
    this.helpText,
    this.socialProof,
    this.key,
  });

  factory OnboardingStep.fromMap(Map<String, dynamic> map) {
    return OnboardingStep(
      botMessage: map['botMessage'] ?? '',
      quickReplies: List<String>.from(map['quickReplies'] ?? []),
      allowTextInput: map['allowTextInput'] ?? false,
      inputPlaceholder: map['inputPlaceholder'],
      isGenreSelection: map['isGenreSelection'] ?? false,
      isPlatformSelection: map['isPlatformSelection'] ?? false,
      isLanguageSelection: map['isLanguageSelection'] ?? false,
      allowMultiSelect: map['allowMultiSelect'] ?? false,
      showSkipOption: map['showSkipOption'] ?? false,
      stepTitle: map['stepTitle'],
      stepDescription: map['stepDescription'],
      helpText: map['helpText'],
      socialProof: map['socialProof'],
      key: map['key'],
    );
  }
}
