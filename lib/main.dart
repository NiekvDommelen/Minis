
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: Colors.white, fontSize: 72.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(
              color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white),
        ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent)
            .copyWith(background: const Color.fromARGB(255, 69, 69, 69)),
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/uploadPage': (context) => const UploadPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Widget> elementList = [];

  Widget _addElement(
      String title, String location, String path, String licence) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              actionsPadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.zero,
              titleTextStyle:
                  const TextStyle(color: Colors.white, fontSize: 34),
              title: Text(title),
              content: Image.network(path,
                  cacheWidth: 1000, filterQuality: FilterQuality.none,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              }),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(

                      onPressed: () => Navigator.pop(context),
                      child: const Text('Delete', style: TextStyle(color: Colors.red),),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ok'),
                    ),
                  ],
                )
              ],
            ),
          );
        },
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                const Color.fromARGB(255, 0, 0, 169)),
            shape: MaterialStateProperty.all(const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide.none,
            ))),
        child: Container(
          padding: const EdgeInsets.all(2.0),
          height: 100,
          margin: const EdgeInsets.all(3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Row(
                    children: [ Text(licence), const Text(" - "), Text(location)],
                  ),
                ],
              ),
              Image.network(path,
                  filterQuality: FilterQuality.none,
                  cacheHeight: 66,
                  cacheWidth: 50, loadingBuilder: (BuildContext context,
                      Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _SwitchPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadPage()),
    );
  }

  void _updateList() async {
    final response = await http.get(Uri.parse('http://simplexflow.nl/minis/'));
    elementList.clear();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      final data = jsonDecode(response.body);
      for (var i = 0; i < data.length; i++) {
        var data2 = data[i];

        setState(() {
          // Clear the list before adding new elements
          // Access specific values using keys
          String location = data2["location"];
          String title = data2["title"];
          String pathData = data2["path"];
          String path = 'http://simplexflow.nl/$pathData';
          String licence = data2["licence"];

          // Create widgets or perform any other actions with the extracted data
          elementList.insert(0, _addElement(title, location, path, licence));
        });
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to reach server');
    }


  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the current route
    final currentRoute = ModalRoute.of(context);

    // Check if the current route is the homepage
    if (currentRoute?.settings.name == '/') {
      // Run your function here
      _updateList();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(58, 255, 255, 255),
        title: const Text(
          'Minis',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: screenHeight - 100,
            width: screenWidth,
            child: ListView.builder(
              itemCount: elementList.length,
              itemBuilder: (context, index) {
                if (index < elementList.length) {
                  return elementList[index];
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _SwitchPage,
        child: const Icon(Icons.add_box),
      ),
    );
  }
}

class UploadPage extends StatefulWidget {
  final List<Widget>? elementList;

  final Function(List<Widget> updatedList)? updateListCallback;

  const UploadPage({Key? key, this.elementList, this.updateListCallback})
      : super(key: key);

  @override
  UploadPageState createState() => UploadPageState();
}

class UploadPageState extends State<UploadPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _licenceController = TextEditingController();
  String selectedLocation = ' ';

  File? _imageFile;

  Future<void> _takePicture() async {
    const imageSrc = ImageSource.camera;
    final imageFile = await ImagePicker().pickImage(source: imageSrc);

    if (imageFile != null) {
      setState(() {
        _imageFile = File(imageFile.path);
      });
    }
  }
  Future<void> _selectPicture() async {

    final imageFile = await ImagePicker().pickMedia();

    if (imageFile != null) {
      setState(() {
        _imageFile = File(imageFile.path);
      });
    }
  }


  Future<bool> _saveImage(String path) async {
    String Title = _titleController.text;
    String licence = _licenceController.text;
    String location = selectedLocation;

    final url = Uri.parse(
        "http://simplexflow.nl/minis/"); //http://simplexflow.nl/minis/   http://10.59.138.58:8080/

    final request = http.MultipartRequest('POST', url);

    request.fields["title"] = Title;
    request.fields["licence"] = licence;
    request.fields["location"] = location;
    request.files.add(
      await http.MultipartFile.fromPath(
          'file', // 'file' is the name of the field that will receive the file
          path),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Upload mini'),
        ),
        body: Column(
          children: [
            SizedBox(
                height: screenHeight - 140,
                width: screenWidth - 50,
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        floatingLabelStyle:
                            TextStyle(color: Color.fromARGB(255, 17, 84, 159)),
                        labelStyle:
                            TextStyle(color: Color.fromARGB(50, 255, 255, 255)),
                        hintText: "Title",
                        hintStyle:
                            TextStyle(color: Color.fromARGB(50, 255, 255, 255)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                            width: screenWidth / 2,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: TextField(
                                controller: _licenceController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'licence',
                                  floatingLabelStyle: TextStyle(
                                      color: Color.fromARGB(255, 17, 84, 159)),
                                  labelStyle: TextStyle(
                                      color: Color.fromARGB(50, 255, 255, 255)),
                                  hintText: "licence",
                                  hintStyle: TextStyle(
                                      color: Color.fromARGB(50, 255, 255, 255)),
                                ),
                              ),
                            )),
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 45, 0, 0),
                          child: DropdownButton<String>(
                            value: selectedLocation,
                            onChanged: (newValue) {
                              setState(() {
                                selectedLocation = newValue!;
                              });
                            },
                            items: const [
                              DropdownMenuItem<String>(
                                value: " ",
                                child: Text(""),
                              ),
                              DropdownMenuItem<String>(
                                value: "valkenswaard",
                                child: Text("Valkenswaard"),
                              ),
                              DropdownMenuItem<String>(
                                value: "eindhoven",
                                child: Text("Eindhoven"),
                              ),
                              DropdownMenuItem<String>(
                                value: "overige",
                                child: Text("Overige"),
                              ),
                            ],
                            hint: const Text("Location"),
                            // Optional hint text
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: Colors.grey,
                            // Optional background color for the dropdown menu
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white), // Optional dropdown icon
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    _imageFile == null
                        ? Column( children: [ElevatedButton(
                      onPressed: _takePicture,
                      child: const Text('Open Camera'),
                    ),
                      const Text("or"),
                      TextButton(
                        onPressed: _selectPicture,
                        child: const Text('Select image '),
                      ),
                      const SizedBox(height: 20.0),],)
                        : Image.file(
                            _imageFile!,
                            height: screenHeight / 2,
                            filterQuality: FilterQuality.none,
                          ),
                  ],
                )),
            Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: screenWidth / 2 - 1,
                        margin: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                            border: Border(
                                right:
                                    BorderSide(width: 0.2, color: Colors.white),
                                bottom: BorderSide(
                                    width: 0.2, color: Colors.white))),
                        child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        const Color.fromARGB(0, 255, 255, 255)),
                                shape: MaterialStateProperty.all(
                                    const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  side: BorderSide.none,
                                ))),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white),
                            )),
                      ),
                      Container(
                        width: screenWidth / 2 - 1,
                        margin: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                            border: Border(
                                left:
                                    BorderSide(width: 0.2, color: Colors.white),
                                bottom: BorderSide(
                                    width: 0.2, color: Colors.white))),
                        child: TextButton(
                            onPressed: () async {
                              if (_imageFile != null &&
                                  _licenceController.text != "" &&
                                  _titleController.text != "" &&
                                  selectedLocation != " ") {
                                if (await _saveImage(_imageFile!.path)) {
                                  Navigator.pop(context);
                                } else {
                                  AlertDialog(
                                    titleTextStyle:
                                        const TextStyle(color: Colors.red),
                                    title: const Text('Error'),
                                    content: const Text('Please try again'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'OK'),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                }
                              } else {
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    titleTextStyle:
                                        const TextStyle(color: Colors.red),
                                    title: const Text('Error'),
                                    content: const Text(
                                        'Please dont leave any input field empty.'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'OK'),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        const Color.fromARGB(0, 255, 255, 255)),
                                shape: MaterialStateProperty.all(
                                    const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  side: BorderSide.none,
                                ))),
                            child: const Text(
                              "Save",
                              style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white),
                            )),
                      ),
                    ],
                  )
                ]),
          ],
        ));
  }
}
