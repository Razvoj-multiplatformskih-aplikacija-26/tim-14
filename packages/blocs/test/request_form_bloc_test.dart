import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  const milica = ProfessorProfile(id: UserId('milica'), fullName: 'Milica Jovanović', city: City.belgrade, bio: '');

  final mathListing = Listing(
    id: const ListingId('l-math'),
    professorId: milica.id,
    subject: Subject.mathematics,
    level: Level.highSchool,
    city: City.belgrade,
    description: 'Matematika za srednju školu',
    price: Price.parse(2000).valueOrNull!,
    duration: LessonDuration.minutes60,
  );

  final slot = Slot(
    id: const SlotId('s-free'),
    listingId: mathListing.id,
    professorId: milica.id,
    start: now.add(const Duration(days: 3)),
    duration: LessonDuration.minutes60,
  );

  late InMemoryProfessorRepository professors;
  late InMemoryLessonRepository lessons;

  RequestFormBloc buildBloc({SlotId? slotId}) {
    final clock = FixedClock(now);
    return RequestFormBloc(
      GetProfessorPage(professors, lessons, clock),
      RequestLesson(lessons, clock, student),
      milica.id,
      slotId ?? slot.id,
    );
  }

  final ready = RequestFormReady(profile: milica, listing: mathListing, slot: slot);

  setUp(() {
    professors = InMemoryProfessorRepository(profiles: [milica], listings: [mathListing], slots: [slot]);
    lessons = InMemoryLessonRepository();
  });

  blocTest<RequestFormBloc, RequestFormState>(
    'loads the slot and its listing',
    build: buildBloc,
    act: (bloc) => bloc.add(RequestFormStarted()),
    expect: () => [const RequestFormLoading(), ready],
  );

  blocTest<RequestFormBloc, RequestFormState>(
    'a slot that is not free anymore cannot be requested',
    build: () => buildBloc(slotId: const SlotId('s-missing')),
    act: (bloc) => bloc.add(RequestFormStarted()),
    expect: () => [const RequestFormLoading(), const RequestFormSlotGone()],
  );

  blocTest<RequestFormBloc, RequestFormState>(
    'shows a failure when loading throws',
    build: () {
      professors.fail = true;
      return buildBloc();
    },
    act: (bloc) => bloc.add(RequestFormStarted()),
    expect: () => [const RequestFormLoading(), const RequestFormLoadFailure('Nema mreže')],
  );

  blocTest<RequestFormBloc, RequestFormState>(
    'a message longer than 300 characters shows an error while typing',
    build: buildBloc,
    seed: () => ready,
    act: (bloc) => bloc.add(MessageChanged('a' * 301)),
    expect: () => [
      isA<RequestFormReady>()
          .having((state) => state.messageError, 'messageError', const InvalidRequestMessage(301))
          .having((state) => state.messageLength, 'messageLength', 301)
          .having((state) => state.canSend, 'canSend', false),
    ],
  );

  blocTest<RequestFormBloc, RequestFormState>(
    'an empty message is not an error, but cannot be sent',
    build: buildBloc,
    seed: () => ready,
    act: (bloc) => bloc.add(MessageChanged('   ')),
    expect: () => [
      isA<RequestFormReady>()
          .having((state) => state.messageError, 'messageError', null)
          .having((state) => state.canSend, 'canSend', false),
    ],
  );

  blocTest<RequestFormBloc, RequestFormState>(
    'sending saves a pending lesson',
    build: buildBloc,
    seed: () => ready,
    act: (bloc) => bloc
      ..add(MessageChanged('Treba mi pomoć oko integrala.'))
      ..add(RequestSubmitted()),
    expect: () => [
      isA<RequestFormReady>().having((state) => state.canSend, 'canSend', true),
      isA<RequestFormReady>().having((state) => state.isSending, 'isSending', true),
      isA<RequestFormSent>()
          .having((state) => state.lesson.status, 'status', const Pending())
          .having((state) => state.lesson.slotId, 'slot', slot.id),
    ],
    verify: (_) => expect(lessons.lessons, hasLength(1)),
  );

  blocTest<RequestFormBloc, RequestFormState>(
    'a fourth pending request shows the rule error',
    setUp: () {
      final inFourDays = now.add(const Duration(days: 4));
      lessons.lessons.addAll([
        lessonAt(inFourDays, id: 'a', slot: 's-a'),
        lessonAt(inFourDays, id: 'b', slot: 's-b'),
        lessonAt(inFourDays, id: 'c', slot: 's-c'),
      ]);
    },
    build: buildBloc,
    seed: () => ready,
    act: (bloc) => bloc
      ..add(MessageChanged('Zdravo'))
      ..add(RequestSubmitted()),
    skip: 2,
    expect: () => [
      isA<RequestFormReady>()
          .having((state) => state.submitError, 'submitError', const TooManyPendingRequests())
          .having((state) => state.isSending, 'isSending', false),
    ],
  );

  blocTest<RequestFormBloc, RequestFormState>(
    'a network error while sending keeps the message',
    build: buildBloc,
    seed: () => ready,
    act: (bloc) async {
      bloc.add(MessageChanged('Zdravo'));
      await Future<void>.delayed(Duration.zero);
      lessons.fail = true;
      bloc.add(RequestSubmitted());
    },
    skip: 2,
    expect: () => [
      isA<RequestFormReady>()
          .having((state) => state.networkError, 'networkError', 'Nema mreže')
          .having((state) => state.message, 'message', 'Zdravo'),
    ],
  );
}
