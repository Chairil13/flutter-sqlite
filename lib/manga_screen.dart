import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'database_helper.dart';
import 'manga_detail_screen.dart';

class MangaItem {
  final int? id;
  final String title;
  final double rating;
  final String story;
  final File image;
  final String imagePath;

  MangaItem({
    this.id,
    required this.title,
    required this.rating,
    required this.story,
    required this.image,
    required this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'rating': rating,
      'story': story,
      'imagePath': imagePath,
    };
  }

  factory MangaItem.fromMap(Map<String, dynamic> map) {
    return MangaItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      rating: map['rating'] as double,
      story: map['story'] as String,
      imagePath: map['imagePath'] as String,
      image: File(map['imagePath']),
    );
  }
}

class MangaScreen extends StatefulWidget {
  const MangaScreen({super.key});

  @override
  State<MangaScreen> createState() => _MangaScreenState();
}

class _MangaScreenState extends State<MangaScreen> {
  final List<MangaItem> mangaList = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadMangaList();
  }

  Future<void> _loadMangaList() async {
    try {
      print('Loading manga list from database...');
      final mangaData = await _databaseHelper.getAllManga();
      print('Loaded manga data: $mangaData');
      setState(() {
        mangaList.clear();
        mangaList.addAll(
          mangaData.map((map) => MangaItem.fromMap(map)).toList(),
        );
      });
      print('Current manga list length: ${mangaList.length}');
    } catch (e) {
      print('Error loading manga list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.pink.shade400,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Manga List',
          style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              IconSnackBar.show(context,
                  label: 'Notified', snackBarType: SnackBarType.success);
            },
          )
        ],
      ),
      body: mangaList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/book.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'Belum ada manga yang ditambahkan!',
                        textStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 17,
                            fontStyle: FontStyle.italic),
                        speed: const Duration(milliseconds: 60),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: mangaList.length,
                itemBuilder: (context, index) {
                  final manga = mangaList[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MangaDetailScreen(manga: manga),
                        ),
                      );
                    },
                    child: Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.up,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) async {
                        final deletedManga = mangaList[index];
                        setState(() {
                          mangaList.removeAt(index);
                        });
                        await _databaseHelper.deleteManga(deletedManga.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('${manga.title} telah dihapus'),
                            action: SnackBarAction(
                              label: 'BATAL',
                              textColor: Colors.white,
                              onPressed: () async {
                                await _databaseHelper
                                    .insertManga(deletedManga.toMap());
                                _loadMangaList();
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  image: DecorationImage(
                                    image: FileImage(manga.image),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      manga.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        Text(
                                          ' ${manga.rating}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMangaForm(),
        backgroundColor: Colors.green.shade400,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _showAddMangaForm() async {
    final titleController = TextEditingController();
    final storyController = TextEditingController();
    File? selectedImage;
    double ratingValue = 2.5;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tambah Manga Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Manga',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rating:'),
                            Text(
                              ratingValue.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: ratingValue,
                          min: 0,
                          max: 5,
                          divisions: 50, // untuk increment 0.1
                          label: ratingValue.toStringAsFixed(1),
                          onChanged: (value) {
                            setModalState(() {
                              ratingValue = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: storyController,
                      decoration: const InputDecoration(
                        labelText: 'Cerita',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                            );
                            if (image != null) {
                              setModalState(() {
                                selectedImage = File(image.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Kamera'),
                        ),
                        const SizedBox(width: 10), // Spasi antara dua tombol
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setModalState(() {
                                selectedImage = File(image.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeri'),
                        ),
                      ],
                    ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Image.file(
                          selectedImage!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty &&
                            selectedImage != null) {
                          try {
                            print('Saving new manga...');
                            final mangaItem = MangaItem(
                              title: titleController.text,
                              rating: ratingValue,
                              story: storyController.text,
                              image: selectedImage!,
                              imagePath: selectedImage!.path,
                            );
                            print('Created manga item: ${mangaItem.toMap()}');

                            final id = await _databaseHelper
                                .insertManga(mangaItem.toMap());
                            print('Inserted manga with ID: $id');

                            setState(() {
                              mangaList.add(MangaItem(
                                id: id,
                                title: titleController.text,
                                rating: ratingValue,
                                story: storyController.text,
                                image: selectedImage!,
                                imagePath: selectedImage!.path,
                              ));
                            });

                            Navigator.pop(context);
                            print(
                                'Manga list updated, length: ${mangaList.length}');
                          } catch (e) {
                            print('Error saving manga: $e');
                          }
                        } else {
                          print('Title is empty or image is null');
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
