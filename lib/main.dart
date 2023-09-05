import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// you can follow the comment below to understand each method

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // this line for initializing the database and its created once because its singleton 
  await DbController().initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const NoteScreen(),
        '/addEditNote': (context) => const AddEditScreen()
      },
    );
  }
}

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  // this for calling the method used inside the ui like read , add ...etc
  NoteController noteController = NoteController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
            onPressed: () async {
              var value = await Navigator.pushNamed(context, '/addEditNote');
              // this for checking the completeness of the add function and update the ui using sateSate
              if (value == true) {
                setState(() {});
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('added successfully')));
              }
            },
            icon: const Icon(Icons.add)),
        title: const Text('My Notes'),
      ),
      body: FutureBuilder(
          future: NoteController().read(),
          builder: (context, snapshot) {
            // this for checking is there is an data inside the snapshot
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return Center(
                    child: Text(
                  'There is no note, you can add new one by press + button',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ));
              }
              return ListView.separated(
                  separatorBuilder: (context, index) => const SizedBox(
                        height: 10,
                      ),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => ListTile(
                        onTap: () async {
                          // this for navigation to edit screen and passing note object
                          bool value = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditScreen(
                                  note: snapshot.data![index],
                                ),
                              ));
                        // checking if the edit completed successfully and update the ui using setState
                          if (value == true) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('edited successfully')));
                          }
                        },
                        tileColor: Colors.blue.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(snapshot.data![index].title),
                        subtitle: Text(snapshot.data![index].details),
                        trailing: IconButton(
                            onPressed: () async {
                              // call delete function and after the operation done successfully update the ui 
                              bool result = await noteController
                                  .delete(snapshot.data![index].id);

                              setState(() {});
                              if (result) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('deleted successfully')));
                              }
                            },
                            icon: const Icon(Icons.delete)),
                      ));
            }
            // this is for checking if there is an error 
            if (snapshot.hasError) {
              return const Text('something went wrong');
            }
            // for showing loading
            return const CircularProgressIndicator();
          }),
    );
  }
}


// this screen for add and edit the note
class AddEditScreen extends StatefulWidget {
  const AddEditScreen({this.note, super.key});
  final Note? note;
  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  NoteController noteController = NoteController();

  late TextEditingController title;
  late TextEditingController details;

  // this form for call validation function for textfield
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    //internalize the controller for edit screen
    title = TextEditingController(text: widget.note?.title);
    details = TextEditingController(text: widget.note?.details);
  }

  @override
  void dispose() {
    title.dispose();
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
            onPressed: () async {
              // check the validation before calling add and edit
              if (formKey.currentState!.validate()) {
                // this called for edit
                if (widget.note != null) {
                  Note note = Note()
                    ..details = details.text
                    ..title = title.text
                    ..id = widget.note!.id;
                  var value = await noteController.update(note);
                  if (value == 1) {
                    Navigator.pop(context, true);
                  }
                } 
                // this called for add new note
                else {
                  Note note = Note()
                    ..details = details.text
                    ..title = title.text;
                  var value = await noteController.create(note);

                  print(value);
                  if (value != 0) {
                    Navigator.pop(context, true);
                  }
                }
              }
            },
            icon: const Icon(Icons.save)),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_forward_ios))
        ],
        title: Text(widget.note != null ? 'Edit Note' : 'Add Note'),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              const Text('Note Information'),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'required data';
                  }
                  return null;
                },
                decoration: InputDecoration(
                    label: const Text('Note Title'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.blue.shade300,
                        )),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.red,
                        ))),
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: details,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'required data';
                  }
                  return null;
                },
                decoration: InputDecoration(
                    label: const Text('Note Text'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.blue.shade300,
                        )),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.red,
                        ))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DbController {

  // this is singleton mainly used for create database instance once 

  static final DbController _instance = DbController._();
  late Database _database;
  factory DbController() {
    return _instance;
  }
  DbController._();

  Database get database => _database;

  Future<void> initDatabase() async {
        Directory directory = await getApplicationDocumentsDirectory();

    String path = join(directory.path, 'tazker.db');
    _database = await openDatabase(
      path,
      version: 1,
      onOpen: (Database db) {},
      onCreate: (Database db, int version) async {
        await db.execute('CREATE TABLE notes ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'title TEXT,'
        'details TEXT,'
        ')');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) {},
      onDowngrade: (Database db, int oldVersion, int newVersion) {},
    );
    print('created succfully');
  }
}

class NoteController {
  Database database = DbController().database;

  Future<int> create(Note note) async {
    int newRowId = await database.insert('notes', note.toJson());
    return newRowId;
  }

  Future<List<Note>> read() async {
    List<Map<String, dynamic>> recorders = await database.query('notes');
    return recorders
        .map((Map<String, dynamic> rowMap) => Note.fromJson(rowMap))
        .toList();
  }

  Future<int> update(Note note) async {
    int countOfUpdatedRows = await database
        .update('notes', note.toJson(), where: 'id=?', whereArgs: [note.id]);

    return countOfUpdatedRows;
  }

  Future<bool> delete(int id) async {
    int countOfDeletedRows =
        await database.delete('notes', where: 'id = ?', whereArgs: [id]);
    return countOfDeletedRows == 1;
  }
}

class Note {
  late int id;
  late String title;
  late String details;
  Note();
  // fromMap to read form database
  Note.fromJson(Map<String, dynamic> rowMap) {
    id = rowMap['id'];
    title = rowMap['title'];
    details = rowMap['details'];
  }

  // toMap to store on database
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = <String, dynamic>{};
    map['title'] = title;
    map['details'] = details;
    return map;
  }

  @override
  String toString() => 'Note(id: $id, title: $title, details: $details)';
}
