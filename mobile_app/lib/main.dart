import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';

void main() => runApp(MaterialApp(home: Home()));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _canTare = false;
  String _weight = 'Brak danych';
  String _previousWeight = '';

  Future<void> _connect() async {
    try {
      setState(() => _weight = 'Łączenie...');
      final device = await FlutterBluetoothSerial.instance.getBondedDevices()
          .then((devices) => devices.firstWhere((d) => d.name == "WagaESP32"));
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);

      setState(() {
        _connection = connection;
        _isConnected = true;
        _canTare = true;
        _weight = 'Połączono';
      });

      _sendCommand("START\n");

      connection.input?.listen((data) {
        final newWeight = String.fromCharCodes(data).trim();
        if (newWeight.isNotEmpty) {
          setState(() {
            _weight = newWeight;
            _previousWeight = newWeight;
          });
        } else {
          setState(() {
            _weight = _previousWeight;
          });
        }
      }, onDone: () {
        setState(() {
          _isConnected = false;
          _weight = 'Brak danych';
        });
      }, onError: (error) {
        setState(() {
          _isConnected = false;
          _weight = 'Błąd odczytu';
        });
      });
    } catch (e) {
      setState(() {
        _weight = 'Błąd połączenia';
      });
    }
  }

  void _sendCommand(String command) {
    if (_isConnected && _connection != null) {
      _connection!.output.add(Uint8List.fromList(command.codeUnits));
      _connection!.output.allSent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WAGA ELEKTRONICZNA',
          style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        toolbarHeight: 100,
      ),
      backgroundColor: Colors.grey[800],
      body: Padding(
        padding: EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'Odczyt wagi:',
                  style: TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20.0),
                Container(
                  width: 300.0,
                  height: 100.0,
                  padding: EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Center(
                    child: Text(
                      _weight,
                      style: TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isConnected ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[900],
                    minimumSize: Size(150, 60),
                  ),
                  child: Text(
                    _isConnected ? 'Połączono' : 'START',
                    style: TextStyle(fontSize: 23, color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: _canTare ? () => _sendCommand("TAROWANIE\n") : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[900],
                    minimumSize: Size(150, 60),
                  ),
                  child: Text(
                    'TAROWANIE',
                    style: TextStyle(fontSize: 23, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}