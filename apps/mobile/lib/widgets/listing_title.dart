import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:use_cases/use_cases.dart';

// Čas pamti samo id oglasa. Naslov se čita iz oglasa tog profesora, jednom po profesoru, i pamti dok aplikacija radi.
// Isto radi nad serverom i nad demo podacima, jer ide preko porta ProfessorRepository.
final class ListingTitles {
  ListingTitles(this._professors);

  final ProfessorRepository _professors;
  final _byProfessor = <UserId, Future<Map<ListingId, String>>>{};

  Future<String?> of(Lesson lesson) async {
    final titles = await _byProfessor.putIfAbsent(lesson.professorId, () => _load(lesson.professorId));
    return titles[lesson.listingId];
  }

  Future<Map<ListingId, String>> _load(UserId professor) async {
    try {
      final listings = await _professors.listingsOf(professor);
      return {for (final listing in listings) listing.id: listing.description};
    } on RepositoryException {
      // Bez naslova se kartica i dalje vidi. Sledeći put se pokuša ponovo.
      _byProfessor.removeWhere((id, _) => id == professor);
      return const {};
    }
  }
}

// Naslov oglasa za čas, ili prazan red dok ne stigne.
class ListingTitle extends StatefulWidget {
  const ListingTitle({super.key, required this.lesson, this.style});

  final Lesson lesson;
  final TextStyle? style;

  @override
  State<ListingTitle> createState() => _ListingTitleState();
}

class _ListingTitleState extends State<ListingTitle> {
  late Future<String?> _title = context.read<ListingTitles>().of(widget.lesson);

  @override
  void didUpdateWidget(ListingTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.listingId != widget.lesson.listingId) {
      _title = context.read<ListingTitles>().of(widget.lesson);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _title,
      builder: (context, snapshot) => Text(snapshot.data ?? '', style: widget.style),
    );
  }
}
