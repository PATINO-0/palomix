import 'package:equatable/equatable.dart';


abstract class MovieEvent extends Equatable {
  const MovieEvent();
  
  @override
  List<Object?> get props => [];
}

class MovieSearchRequested extends MovieEvent {
  final String query;
  
  const MovieSearchRequested(this.query);
  
  @override
  List<Object?> get props => [query];
}


class MovieDetailsRequested extends MovieEvent {
  final int movieId;
  
  const MovieDetailsRequested(this.movieId);
  
  @override
  List<Object?> get props => [movieId];
}


class PersonalizedRecommendationsRequested extends MovieEvent {}


class AddToFavoritesRequested extends MovieEvent {
  final int movieId;
  final String movieTitle;
  final String? posterPath;
  
  const AddToFavoritesRequested({
    required this.movieId,
    required this.movieTitle,
    this.posterPath,
  });
  
  @override
  List<Object?> get props => [movieId, movieTitle, posterPath];
}


class RemoveFromFavoritesRequested extends MovieEvent {
  final int movieId;
  
  const RemoveFromFavoritesRequested(this.movieId);
  
  @override
  List<Object?> get props => [movieId];
}


class LoadFavoritesRequested extends MovieEvent {}


class TrendingMoviesRequested extends MovieEvent {}


class TopRatedMoviesRequested extends MovieEvent {}


class MoviesByGenreRequested extends MovieEvent {
  final int genreId;
  final String genreName;
  const MoviesByGenreRequested({
    required this.genreId,
    required this.genreName,
  });
  @override
  List<Object?> get props => [genreId, genreName];
}

class MoviesByGenreLoadMore extends MovieEvent {
  final int genreId;
  final String genreName;
  final int nextPage;
  const MoviesByGenreLoadMore({
    required this.genreId,
    required this.genreName,
    required this.nextPage,
  });
  @override
  List<Object?> get props => [genreId, genreName, nextPage];
}

class ExploreContentRequested extends MovieEvent {}
