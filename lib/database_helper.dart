// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    try {
      print('Initializing database...');
      // Ensure Flutter bindings are initialized
      WidgetsFlutterBinding.ensureInitialized();
      
      // Get the database path
      final databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'manga.db');
      print('Database path: $path');
      
      // Make sure the directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) {
          print('Database opened successfully');
        },
      );
      print('Database initialized successfully');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future _onCreate(Database db, int version) async {
    try {
      print('Creating manga table...');
      await db.execute('''
        CREATE TABLE manga (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          rating REAL NOT NULL,
          story TEXT NOT NULL,
          imagePath TEXT NOT NULL
        )
      ''');
      print('Manga table created successfully');
    } catch (e) {
      print('Error creating manga table: $e');
      rethrow;
    }
  }

  Future<int> insertManga(Map<String, dynamic> row) async {
    try {
      print('Inserting manga: $row');
      Database db = await database;
      final id = await db.insert('manga', row);
      print('Manga inserted with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting manga: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllManga() async {
    try {
      print('Getting all manga...');
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('manga');
      print('Retrieved ${maps.length} manga entries');
      return maps;
    } catch (e) {
      print('Error getting all manga: $e');
      rethrow;
    }
  }

  Future<int> updateManga(Map<String, dynamic> row) async {
    try {
      Database db = await database;
      int id = row['id'];
      return await db.update('manga', row, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error updating manga: $e');
      rethrow;
    }
  }

  Future<int> deleteManga(int id) async {
    try {
      Database db = await database;
      return await db.delete('manga', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting manga: $e');
      rethrow;
    }
  }
}
