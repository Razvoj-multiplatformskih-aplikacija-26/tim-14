enum LessonDuration {
  minutes45(45),
  minutes60(60),
  minutes90(90);

  const LessonDuration(this.minutes);

  final int minutes;

  Duration get duration => Duration(minutes: minutes);
}
