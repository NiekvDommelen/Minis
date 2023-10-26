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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minis',
      theme: ThemeData(
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: Colors.white, fontSize: 72.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(
              color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white),
        ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 89, 0),
          primary: const Color.fromARGB(255, 255, 252, 242),
          onPrimary: Colors.white,
        ).copyWith(background: const Color.fromARGB(255, 64, 61, 57)),
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
  final TextEditingController _titleSearchController = TextEditingController();
  final TextEditingController _licenceSearchController =
      TextEditingController();
  String selectedSearchLocation = '';

  List<Widget> elementList = [];

  var boolFilter = false;

  Widget _addElement(
      String title, String location, String path, String licence) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              backgroundColor: const Color.fromARGB(150, 100, 100, 100),
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
                      onPressed: () async {
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            titleTextStyle: const TextStyle(color: Colors.red),
                            title: const Text('Are you sure?'),
                            content: const Text(
                                "Are you sure you want to delete this post?"),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('NO'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (await _removeItem(path)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('post deleted'),
                                      ),
                                    );
                                  } else {
                                    showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                        titleTextStyle:
                                            const TextStyle(color: Colors.red),
                                        title: const Text('Error'),
                                        content: const Text(
                                            'Something went wrong while deleting item.'),
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
                                child: const Text(
                                  'YES',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ok',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          );
        },
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                const Color.fromARGB(255, 255, 85, 0)),
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
                    children: [
                      Text(licence),
                      const Text(" - "),
                      Text(location)
                    ],
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

  void _switchPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadPage()),
    );
  }

  Future<bool> _removeItem(String path) async {
    path = "path=..${path.split("..")[1]}";

    final url = Uri.parse(
        "http://simplexflow.nl/minis/?$path"); //http://simplexflow.nl/minis/   http://10.59.138.58:8080/

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      Navigator.pop(context);
      Navigator.pop(context);
      _updateListWithSearch();

      return true;
    } else {
      return false;
    }
  }

  void _updateListWithSearch() async {
    var title = _titleSearchController.text;
    var licence = _licenceSearchController.text;
    var location = selectedSearchLocation;

    final url = Uri.parse(
        "http://10.59.138.158:8080?title=$title&licence=$licence&location=$location"); //http://simplexflow.nl/minis/
    //TODO: remove debug!!
    print(url);
    final response = await http.get(url);
    elementList.clear();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      final data = jsonDecode(response.body);
      setState(() {
        for (var i = 0; i < data.length; i++) {
          var data2 = data[i];

          // Clear the list before adding new elements
          // Access specific values using keys
          String location = data2["location"];
          String title = data2["title"];
          String pathData = data2["path"];
          String path = 'http://simplexflow.nl/$pathData';
          String licence = data2["licence"];

          // Create widgets or perform any other actions with the extracted data
          elementList.insert(0, _addElement(title, location, path, licence));
        }
      });
      //TODO: remove debug!!
      print(" ${DateTime.timestamp()} : '\x1B[33mupdated with search\x1B[0m'");
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to reach server');
    }
  }

  void _clearFilter() {
    _titleSearchController.clear();
    _licenceSearchController.clear();
    selectedSearchLocation = '';
    _updateListWithSearch();
  }

  //TODO: Remove unused function
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
      print(" ${DateTime.timestamp()} : '\x1B[33mupdated\x1B[0m'");
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
      _updateListWithSearch();
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
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: screenWidth - 50,
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: _titleSearchController,
                    onSubmitted: (value) {
                      setState(() {
                        _updateListWithSearch();
                      });
                    },
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search),
                      iconColor: Colors.white,
                      border: UnderlineInputBorder(),
                      hintText: 'Search title',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  onPressed: () {
                    setState(() {
                      boolFilter = !boolFilter;
                    });
                  },
                  icon: const Icon(Icons.filter_list),
                  color: Colors.white,
                )
              ],
            ),
          ),
          if (boolFilter) ...{
            const SizedBox(
              height: 10,
            ),
            SizedBox(
                height: 110,
                width: screenWidth,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 40,
                        ),
                        SizedBox(
                          height: 35,
                          width: screenWidth - 230,
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (value) {
                              setState(() {
                                _updateListWithSearch();
                              });
                            },
                            controller: _licenceSearchController,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              hintText: 'Licence',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          width: screenWidth - 240,
                          child: DropdownButton<String>(
                            padding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                            value: selectedSearchLocation,
                            onChanged: (newValue) {
                              setState(() {
                                selectedSearchLocation = newValue!;
                              });
                            },
                            items: const [
                              DropdownMenuItem<String>(
                                value: "",
                                child: Text(
                                  "location",
                                  style: TextStyle(color: Colors.grey),
                                ),
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
                            hint: const Text(
                              "Location",
                              style: TextStyle(color: Colors.grey),
                            ),
                            itemHeight: 50,
                            // Optional hint text
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: Colors.grey,

                            // Optional background color for the dropdown menu
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white), // Optional dropdown icon
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: screenWidth - 250,
                          child: TextButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        const Color.fromARGB(255, 255, 89, 0)),
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  side: BorderSide.none,
                                ))),
                            onPressed: _clearFilter,
                            child: const Text(
                              "clear",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: screenWidth - 250,
                          child: TextButton(
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<
                                        Color>(
                                    const Color.fromARGB(58, 255, 255, 255)),
                                shape: MaterialStateProperty.all(
                                    const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  side: BorderSide.none,
                                ))),
                            onPressed: () {
                              setState(() {
                                _updateListWithSearch();
                              });
                            },
                            child: const Text(
                              "Search",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ))
          },
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: RefreshIndicator(
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
              onRefresh: () {
                return Future.delayed(
                  const Duration(seconds: 1),
                  () {
                    setState(() {
                      _updateListWithSearch();
                    });
                    if (DateTime.now().hour == 15) {
                      // Easter egg
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('tijd voor Chicken Nuggies!!!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Page Refreshed'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
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
    final imageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

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
        "http://simplexflow.nl/minis/"); //http://simplexflow.nl/minis/   http://10.59.138.141:8080/

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

  Future<bool> _licenceDuplicateCheck() async{

    String licence = _licenceController.text;
    final url = Uri.parse("http://10.59.138.158:8080");
    final response = await http.post(url, body: {"licence": licence});

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if(data["code"]){
          return true;
        }else{
          return false;
        }

      } else {
        throw Exception("Failed to reach server");
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
                        ? Column(
                            children: [
                              ElevatedButton(
                                onPressed: _takePicture,
                                child: const Text('Open Camera'),
                              ),
                              const Text("or"),
                              TextButton(
                                onPressed: _selectPicture,
                                child: const Text('Select image '),
                              ),
                              const SizedBox(height: 20.0),
                            ],
                          )
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

                                print("result: ${await _licenceDuplicateCheck()}");

                                if (await _licenceDuplicateCheck()) {
                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      titleTextStyle:
                                          const TextStyle(color: Colors.red),
                                      title: const Text('Duplicate licence'),
                                      content: const Text(
                                          'This licence is already used. \nWould you like to upload this post anyways?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, 'NO'),
                                          child: const Text('NO'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            if (await _saveImage(
                                                _imageFile!.path)) {
                                              Navigator.popAndPushNamed(
                                                  context, '/');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text('post Uploaded'),
                                                ),
                                              );
                                            } else {
                                              showDialog<String>(
                                                context: context,
                                                builder:
                                                    (BuildContext context) =>
                                                        AlertDialog(
                                                  titleTextStyle:
                                                      const TextStyle(
                                                          color: Colors.red),
                                                  title: const Text('Error'),
                                                  content: const Text(
                                                      'Please try again'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, 'OK'),
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('YES'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  if (await _saveImage(_imageFile!.path)) {
                                    Navigator.popAndPushNamed(context, '/');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('post Uploaded'),
                                      ),
                                    );
                                  } else {
                                    showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) =>
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
                                      ),
                                    );
                                  }
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
