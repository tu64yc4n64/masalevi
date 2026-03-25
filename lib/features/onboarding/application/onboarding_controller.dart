import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  const OnboardingState({required this.completed});
  final bool completed;

  OnboardingState copyWith({bool? completed}) =>
      OnboardingState(completed: completed ?? this.completed);
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState(completed: false);

  void markCompleted() {
    state = state.copyWith(completed: true);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);

