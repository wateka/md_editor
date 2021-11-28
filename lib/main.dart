import 'package:flutter/material.dart';
import 'package:rich_text_controller/rich_text_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      locale: Locale('ja', 'JP'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ja', 'JP')
      ],
      home: MyHomePage(title: 'Markdown Editor'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String editText = '';
  File editingFile;

  RichTextController _controller = RichTextController(
    patternMatchMap: {
      RegExp(r'(^|\n)###### .*($|\n)'): TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      RegExp(r'(^|\n)##### .*($|\n)'): TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      RegExp(r'(^|\n)#### .*($|\n)'): TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      RegExp(r'(^|\n)### .*($|\n)'): TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      RegExp(r'(^|\n)## .*($|\n)'): TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      RegExp(r'(^|\n)# .*($|\n)'): TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      RegExp(r'\*\*[^\n]*?\*\*'): TextStyle(fontWeight: FontWeight.bold),
      RegExp(r'\*[^\n]*?\*'): TextStyle(fontStyle: FontStyle.italic),
      RegExp(r'(^|\n)\s*- '): TextStyle(color: Colors.grey),
    },
    onMatch: (List<String> matches){
      // Do something with matches.
      //! P.S
      // as long as you're typing, the controller will keep updating the list.
    },
  );

  final FocusNode _editorNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.folder_open, color: Colors.black,),
            tooltip: 'ファイルを読み込み',
            onPressed: () => selectEditFile(),
          ),
          IconButton(
            icon: Icon(Icons.save, color: Colors.black,),
            tooltip: 'ファイルを上書き保存',
            onPressed: () => overrideEditFile(),
          ),
          IconButton(
            icon: Icon(Icons.note_add_outlined, color: Colors.black,),
            tooltip: '新しいファイルに保存',
            onPressed: () => selectSaveFile(),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        constraints: BoxConstraints.expand(),
        child: KeyboardActions(
          config: _keyboardActionConfig,
          child: TextField(
            controller: _controller,
            focusNode: _editorNode,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: TextStyle(fontSize: 16, height: 1.8,),
            decoration: InputDecoration(border: InputBorder.none, hintText: '# Markdown Editor\n\nInput your markdown code here.'),
            onChanged: (String val) {
              setState(() {
                editText = val;
              });
            },
          ),
        ),
      ),
    );
  }

  get _keyboardActionConfig {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      nextFocus: false,
      actions: [
        KeyboardActionsItem(focusNode: _editorNode, toolbarButtons: [
          (node) => toolbarShortcuts(node),
          (node) => toolbarDoneButton(node),
        ])
      ],
    );
  }

  Widget toolbarShortcuts(FocusNode node) {
    return Container(
      child: Row(
        children: [
          toolbarShortcutGenerator(node, 'H1'),
          toolbarShortcutGenerator(node, 'H2'),
          toolbarShortcutGenerator(node, 'H3'),
          toolbarShortcutGenerator(node, 'B'),
          toolbarShortcutGenerator(node, 'I'),
          toolbarShortcutGenerator(node, '-'),
        ]
      ),
    );
  }

  Widget toolbarShortcutGenerator(FocusNode node, String type) {
    int cursorPosition = _controller.selection.baseOffset;
    String beforeCursor = _controller.text.substring(0, cursorPosition);
    String afterCursor = _controller.text.substring(cursorPosition);
    int cursorMovingAmount;
    String inputText;

    switch (type) {
      case 'H1':
        inputText = '# ';
        cursorMovingAmount = 2;
        break;
      case 'H2':
        inputText = '## ';
        cursorMovingAmount = 3;
        break;
      case 'H3':
        inputText = '### ';
        cursorMovingAmount = 4;
        break;
      case 'B':
        inputText = '****';
        cursorMovingAmount = 2;
        break;
      case 'I':
        inputText = '**';
        cursorMovingAmount = 1;
        break;
      case '-':
        inputText = '- ';
        cursorMovingAmount = 2;
        break;
    }
    return TextButton(
      onPressed: () {
        setState(() {
          _controller.text = beforeCursor + inputText + afterCursor;
          _controller.selection = TextSelection(
            baseOffset: cursorPosition + cursorMovingAmount,
            extentOffset: cursorPosition + cursorMovingAmount,
          );
        });
      },
      child: Text(type),
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(Size(32, 32))
      ),
    );
  }

  Widget toolbarDoneButton(FocusNode node) {
    return ElevatedButton(
      onPressed: () => node.unfocus(),
      child: Text('Done'),
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
      ),
    );
  }

  void selectEditFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if(result != null) {
      editingFile = File(result.files.single.path);
      String readText = await editingFile.readAsString();
      setState(() async {
        _controller.text = readText.replaceAll('\r\n', '\n');
      });
    }
  }

  void overrideEditFile() {
    editingFile.writeAsString(_controller.text.replaceAll('\n', '\r\n'));
  }

  void selectSaveFile() async {
    String saveDir = await FilePicker.platform.getDirectoryPath();
    String saveFileName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('保存するファイル名を入力'),
        content: TextField(
          onChanged: (String val) => saveFileName = val,
        ),
        actions: [
          TextButton(
            onPressed: () {
              editingFile = File('$saveDir/$saveFileName.md');
              editingFile.writeAsString(_controller.text);
              Navigator.pop(context);
            },
            child: Text('保存'),
          )
        ],
      )
    );
  }
}
