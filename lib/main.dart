import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MarvelComicsApp());
}

class MarvelComicsApp extends StatelessWidget {
  const MarvelComicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marvel Comics Reader',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const ComicsListScreen(),
    );
  }
}

class ComicsListScreen extends StatefulWidget {
  const ComicsListScreen({super.key});

  @override
  State<ComicsListScreen> createState() => _ComicsListScreenState();
}

class _ComicsListScreenState extends State<ComicsListScreen> {
  List<dynamic> comics = [];
  bool isLoading = false;
  String errorMessage = '';

  // Replace these with your actual keys (store securely in production)
  final String publicKey = '9f40638b99be344f5645cf69963dc280'; // e.g., '9f40638b99be344f5645cf69963dc280'
  final String privateKey = '306f93644d90b5c4ded02a754eb192c71ffea7ad'; // e.g., '306f93644d90b5c4ded02a754eb192c71ffea7ad'

  @override
  void initState() {
    super.initState();
    fetchComics();
  }

  Future<void> fetchComics() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final hash = generateMd5('$ts$privateKey$publicKey');
      final url = Uri.parse(
        'https://gateway.marvel.com/v1/public/comics?ts=$ts&apikey=$publicKey&hash=$hash&limit=20',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          comics = data['data']['results'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load comics: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String generateMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marvel Comics'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
          : comics.isEmpty
          ? const Center(child: Text('No comics found'))
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.7,
        ),
        itemCount: comics.length,
        itemBuilder: (context, index) {
          final comic = comics[index];
          final thumbnail = comic['thumbnail'];
          final imageUrl = thumbnail != null
              ? '${thumbnail['path']}.${thumbnail['extension']}'
              : 'https://via.placeholder.com/150';
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComicDetailScreen(comic: comic),
                ),
              );
            },
            child: Card(
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      comic['title'] ?? 'No Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ComicDetailScreen extends StatelessWidget {
  final dynamic comic;

  const ComicDetailScreen({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    final thumbnail = comic['thumbnail'];
    final imageUrl = thumbnail != null
        ? '${thumbnail['path']}.${thumbnail['extension']}'
        : 'https://via.placeholder.com/150';
    final description = comic['description'] ?? 'No description available';
    final pageCount = comic['pageCount'] ?? 'Unknown';
    final onSaleDate = comic['dates']?.firstWhere(
          (date) => date['type'] == 'onsaleDate',
      orElse: () => {'date': null},
    )['date'] ??
        'Unknown';
    final formattedDate = onSaleDate != 'Unknown'
        ? DateFormat.yMMMd().format(DateTime.parse(onSaleDate))
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(comic['title'] ?? 'Comic Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 100),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic['title'] ?? 'No Title',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Page Count: $pageCount'),
                  Text('On Sale Date: $formattedDate'),
                  const SizedBox(height: 16),
                  const Text(
                    'Description:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}