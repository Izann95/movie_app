import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:http/http.dart' as http;

// TODO: isi dengan API Key (v3) dari themoviedb.org
// Jangan ikut di-push ke GitHub publik, kembalikan ke placeholder sebelum push.
const String tmdbApiKey = '5b001f687be33dc82640e3f5eb17dada';
const String imgBase = 'https://image.tmdb.org/t/p/';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          centerTitle: true,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ---------- Model & API ----------
const Map<int, String> genreMap = {
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Sci-Fi',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
};

class Movie {
  final String title;
  final String year;
  final String genre;
  final String description;
  final String? posterPath;

  Movie({
    required this.title,
    required this.year,
    required this.genre,
    required this.description,
    required this.posterPath,
  });

  factory Movie.fromJson(Map<String, dynamic> j) {
    final date = (j['release_date'] ?? '') as String;
    final ids = (j['genre_ids'] ?? []) as List;
    return Movie(
      title: (j['title'] ?? '-') as String,
      year: date.length >= 4 ? date.substring(0, 4) : '-',
      genre: ids.isNotEmpty ? (genreMap[ids.first] ?? 'Movie') : 'Movie',
      description: (j['overview'] ?? '') as String,
      posterPath: j['poster_path'] as String?,
    );
  }

  String poster([String size = 'w342']) => '$imgBase$size$posterPath';
}

Future<List<Movie>> fetchMovies(String path) async {
  final uri = Uri.parse(
      'https://api.themoviedb.org/3/$path?api_key=$tmdbApiKey&language=en-US');
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('Gagal memuat $path (kode ${res.statusCode}). '
        'Cek API key kamu.');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return (data['results'] as List)
      .map((e) => Movie.fromJson(e as Map<String, dynamic>))
      .where((m) => m.posterPath != null)
      .toList();
}

// Gambar dengan placeholder kalau gagal dimuat
class PosterImage extends StatelessWidget {
  final String url;
  const PosterImage(this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey.shade800,
        child: const Icon(Icons.movie, color: Colors.white38),
      ),
    );
  }
}

// ---------- Halaman utama ----------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<List<Movie>>> _future = Future.wait([
    fetchMovies('movie/now_playing'),
    fetchMovies('trending/movie/week'),
    fetchMovies('movie/popular'),
    fetchMovies('movie/top_rated'),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Now Playing',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<List<Movie>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final nowPlaying = snapshot.data![0].take(6).toList();
          final trending = snapshot.data![1].take(10).toList();
          final popular = snapshot.data![2];
          final topRated = snapshot.data![3];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NowPlayingCarousel(movies: nowPlaying),
                const SizedBox(height: 16),
                TrendingSwiper(movies: trending),
                MovieSection(title: 'Popular', movies: popular),
                MovieSection(title: 'Top Rated', movies: topRated),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------- Carousel Now Playing (carousel_slider) ----------
class NowPlayingCarousel extends StatelessWidget {
  final List<Movie> movies;
  const NowPlayingCarousel({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: movies.length,
      options: CarouselOptions(
        height: 300,
        viewportFraction: 0.92,
        enlargeCenterPage: false,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
      ),
      itemBuilder: (context, index, realIndex) {
        final movie = movies[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PosterImage(movie.poster('w780')),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${movie.year}   ${movie.genre}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              movie.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right,
                            color: Colors.black, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- Trending (flutter_card_swiper) ----------
class TrendingSwiper extends StatelessWidget {
  final List<Movie> movies;
  const TrendingSwiper({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trending',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('More',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: CardSwiper(
            cardsCount: movies.length,
            numberOfCardsDisplayed: 2,
            isLoop: true,
            scale: 0.9,
            padding: const EdgeInsets.fromLTRB(100, 8, 100, 40),
            cardBuilder: (context, index, percentX, percentY) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PosterImage(movies[index].poster('w500')),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------- Section list horizontal ----------
class MovieSection extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  const MovieSection({super.key, required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              const Text('More',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: PosterImage(movies[index].poster('w342')),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}