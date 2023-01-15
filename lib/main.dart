import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

void main() {
  runApp(const MainWidget());
}

class MainWidget extends StatelessWidget {
  const MainWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Tic Tac Toe",
      theme: ThemeData(primarySwatch: Colors.green),
      home: const Home(title: "Multiplayer TicTacToe"),
    );
  }
}

late String joinerName, yourSymbol, creatorName, yourName, roomCode;
String? move;
late bool roomReady = false;
BuildContext? _dialogContext;
late socket_io.Socket socket;

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    debugPrint('connecting...');

    // socket = socket_io.io('https://tictactoe-kxqw.onrender.com/');
    socket = socket_io
        .io('https://tictactoe-kxqw.onrender.com/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      debugPrint('connected successfully');
    });
    socket.on('create-room', (data) => onCreateRoom(data));
    socket.on('join-status', (res) => onJoinRoom(res));
    socket.connect();
  }

  onCreateRoom(var data) {
    roomCode = data["roomCode"];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _dialogContext = context;
        return AlertDialog(
          title: TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: roomCode),
              );
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text("Room code copied to clipboard"),
                ),
              );
            },
            child: Text("Room code : $roomCode"),
          ),
          content: const Text("Waiting for someone to join"),
          actions: [
            TextButton(
              onPressed: () {
                socket.emit("delete-room", roomCode);
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  onJoinRoom(var res) {
    if (res["statusOk"]) {
      if (res['statusCode'] == 100) {
        roomCode = res["roomCode"];
        creatorName = res["creatorName"];
      } else {
        joinerName = res["statusString"];
      }
      roomReady = true;
      move = res["firstMove"];
      yourSymbol = res["yourSymbol"];
      if (_dialogContext != null) {
        Navigator.pop(_dialogContext!);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Main(
            title: "Game",
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['statusString']),
        ),
      );
    }
  }

  void _createRoom(String creator) {
    creatorName = creator.trim();
    yourName = creatorName;
    if (creatorName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hey you! Don't you have a name? :)"),
        ),
      );
    } else {
      socket.emit('create-room', {"name": creatorName});
    }
  }

  void _joinRoom(String jName, String roomCode) {
    jName = tfJoiner.text.trim();
    roomCode = tfRoomCode.text.trim();
    if (jName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hey you! Don't you have a name? :)"),
        ),
      );
    } else if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You forgot to enter the room code!!'),
        ),
      );
    } else {
      yourName = jName;
      joinerName = jName;
      socket.emit('join-room', {'roomCode': roomCode, 'name': jName});
    }
  }

  TextEditingController tfCreator = TextEditingController();
  TextEditingController tfRoomCode = TextEditingController();
  TextEditingController tfJoiner = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: TextField(
                controller: tfCreator,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Your name",
                ),
              ),
            ),
            Container(
                margin: const EdgeInsets.only(top: 14.0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  ),
                  onPressed: () => _createRoom(tfCreator.text),
                  child: const Text(
                    "Create room",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                )),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: const Text(
                "OR",
                style: TextStyle(
                  fontSize: 30.0,
                  color: Colors.black,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                const SizedBox(
                  width: 20.0,
                ),
                Flexible(
                  child: TextField(
                    controller: tfJoiner,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Your name",
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20.0,
                ),
                Flexible(
                  child: TextField(
                    controller: tfRoomCode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Room code",
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20.0,
                ),
              ],
            ),
            Container(
                margin: const EdgeInsets.only(top: 14.0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  ),
                  onPressed: () => _joinRoom(tfJoiner.text, tfRoomCode.text),
                  child: const Text(
                    "Join room",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class Main extends StatefulWidget {
  final String title;

  const Main({Key? key, required this.title}) : super(key: key);

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  void initState() {
    super.initState();

    _updatePlayers("$creatorName\n$joinerName");
    _updateStatus("$yourSymbol is your symbol\n$move moves first");

    socket.on("move", (res) {
      move = res['currentMove'];
      _markOnBoard({'index': res['index'], 'move': res['move']});
    });
    socket.on("winner", (res) {
      if (res['draw']) {
        _updateStatus(
            "Oops :/ Match drawn. That was an amazing clash! Both of you should try again :D");
      } else {
        _updateStatus(
            "${res['winner']} with symbol ${res['symbol']} is the winner!! Congrats to the champion.");
      }
      move = null;
      //  retry button visible
      setState(() {
        retryVisible = true;
      });
    });
    socket.on('retry-game', (res) => _resetGame(res['move']));
    socket.on('delete-room', (res) {
      Navigator.pop(context);
    });
  }

  var textButtonStyle = TextButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 205, 237, 237),
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: Color.fromARGB(255, 40, 145, 182), width: 2),
    ),
  );

  List<String> listItems = [];
  String players = "";
  bool retryVisible = false;
  Map<String, String> boardBtnTexts = {
    "b0": "",
    "b1": "",
    "b2": "",
    "b3": "",
    "b4": "",
    "b5": "",
    "b6": "",
    "b7": "",
    "b8": ""
  };

  Text _getTextStyle(String index) {
    return Text(
      boardBtnTexts['b$index'] ?? "",
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: (boardBtnTexts['b$index'] == "O"
            ? const Color.fromARGB(255, 130, 7, 7)
            : const Color.fromARGB(255, 12, 6, 113)),
      ),
    );
  }

  _updatePlayers(String newPlayer) {
    setState(() {
      players = newPlayer;
    });
  }

  _updateStatus(String status) {
    setState(() {
      listItems.insert(0, status);
    });
  }

  _markOnBoard(board) {
    setState(() {
      boardBtnTexts["b${board['index']}"] = board['move'];
    });
  }

  _boxListener(String index) {
    if (boardBtnTexts["b$index"]!.isEmpty && move == yourSymbol) {
      socket.emit(
        'move',
        {
          "roomCode": roomCode,
          "index": index,
          "move": move,
          "player": yourName
        },
      );
      _markOnBoard({'index': index, 'move': yourSymbol});
    }
  }

  _resetGame(String currentMove) {
    move = currentMove;
    setState(() {
      retryVisible = false;
      for (int i = 0; i <= 8; i++) {
        boardBtnTexts['b$i'] = "";
      }
      listItems.clear();
    });

    _updateStatus("'$yourSymbol' is your symbol\n'$move' moves first");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text("Exit?"),
                content: const Text("Are you sure you want to exit?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("No"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      socket.emit("delete-room", roomCode);
                    },
                    child: const Text("Yes"),
                  ),
                ],
              );
            },
          );
          return false;
        },
        child: Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  "Room code : $roomCode",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(5),
                child: Text(
                  "Players present in room:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  players,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.width * 0.5,
                width: MediaQuery.of(context).size.width * 0.5,
                constraints:
                    const BoxConstraints(maxWidth: 270, maxHeight: 270),
                child: GridView.count(
                  crossAxisCount: 3,
                  children: <Widget>[
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("0"),
                      child: _getTextStyle("0"),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("1"),
                      child: _getTextStyle("1"),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("2"),
                      child: _getTextStyle("2"),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("3"),
                      child: _getTextStyle("3"),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("4"),
                      child: _getTextStyle("4"),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("5"),
                      child: _getTextStyle("5"),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("6"),
                      child: _getTextStyle("6"),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("7"),
                      child: _getTextStyle("7"),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _boxListener("8"),
                      child: _getTextStyle("8"),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 11,
              ),
              Visibility(
                child: TextButton(
                  child: const Text("Retry"),
                  onPressed: () {
                    socket.emit('retry-game',
                        {'roomCode': roomCode, 'symbol': yourSymbol});
                  },
                ),
                visible: retryVisible,
              ),
              const SizedBox(
                height: 8,
              ),
              const Padding(
                padding: EdgeInsets.all(5),
                child: Text(
                  "Game status:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        listItems[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}
