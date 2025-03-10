import 'dart:convert';
import 'dart:math';

import 'package:btcview/btctool.dart';
import 'package:btcview/puzzle68/puzzle68.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Key Visualizer',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: PrivateKeyVisualizer(),
    );
  }
}

class PrivateKeyVisualizer extends StatefulWidget {
  const PrivateKeyVisualizer({super.key});

  @override
  _PrivateKeyVisualizerState createState() => _PrivateKeyVisualizerState();
}

class _PrivateKeyVisualizerState extends State<PrivateKeyVisualizer> {
  // Gera uma lista de 256 bits (0 ou 1) para simular uma chave privada
  List<int> privateKeyBits = List.generate(256, (index) => index);
  final hashHexController = TextEditingController();
  bool autoCheckBalance = false;
  Set<String> btcAddressList = {};

  Future<void> loadJson() async {
    try {
      // Carregar o JSON como String
      String jsonString = await rootBundle.loadString('assets/address.json');

      // Decodificar para um Map (caso o JSON seja um objeto) ou List (caso seja um array)
      final btcList = jsonDecode(jsonString);

      btcAddressList = btcList.map<String>((e) => e.toString()).toSet();
    } catch (e) {
      print('Erro ao carregar JSON: $e');
    }
  }

  // Armazena os índices dos bits selecionados
  Set<int> selectedBitIndices = {};

  final btc = BitcoinTOOL();

  // Gera um hash SHA-256 com base nos bits selecionados
  void genBin() {
    // Converte os bits selecionados em uma string
    final selectedBitsString = privateKeyBits
        .map((index) {
          final contain = selectedBitIndices.contains(index) ? '1' : '0';
          return contain;
        })
        .toList()
        .join('');

    hashBin = selectedBitsString;
  }

  String hashBin = '';
  String hashHex = '';
  String address = '';
  String addressc = '';

  void binaryToHex([bool addHystory = true]) {
    // Converte a string binária em um número inteiro
    BigInt decimalValue = BigInt.parse(hashBin, radix: 2);

    // Converte o número inteiro para uma string hexadecimal
    String hexString = decimalValue.toRadixString(16).toUpperCase();

    setState(() {
      hashHex = hexString;
      btc.setPrivateKeyHex(hashHex);
      address = btc.getAddress();
      addressc = btc.getAddress(true);
      if (autoCheckBalance) {
        address = '$address - ${getBalance(address)}';
        addressc = '$addressc - ${getBalance(addressc)}';
      }
    });
    if (addHystory) {
      hashHistory.add(hashHex);
    }
  }

  String getBalance(String addr) {
    if (btcAddressList.isEmpty) {
      loadJson();
    }
    final result = btcAddressList.firstWhere((address) {
      return address.split(',')[0] == addr;
    }, orElse: () => '0,0');
    final balance = result.split(',')[1];
    if (balance != '0') {
      showAdaptiveAboutDialog(context: context, children: [Text('Balance: $balance')], barrierDismissible: false);
      return balance;
    }
    return balance;
  }

  void loadVisualization(String hex) {
    selectedBitIndices.clear();
    final listBin = BigInt.parse(hex, radix: 16).toRadixString(2).split('');
    listBin.asMap().forEach((index, bin) {
      if (bin == '1') {
        selectedBitIndices.add(index);
      }
    });
    genBin();
    binaryToHex(false);
  }

  Set<String> hashHistory = {};

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Private Key (256-bit Visualization)', style: TextStyle(fontSize: 16)), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Check balance automatically', style: TextStyle(fontSize: 16)),
                Checkbox(
                  value: autoCheckBalance,
                  onChanged: (check) {
                    setState(() {
                      autoCheckBalance = check!;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Puzzle68Page()));
                  },
                  child: Text('Puzzle 68'),
                ),

                SizedBox(
                  height: MediaQuery.of(context).size.width - 32,
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 16, // 16 colunas
                      childAspectRatio: 1.0, // Quadrados perfeitos
                    ),
                    itemCount: 256, // 16x16 = 256 bits
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // Adiciona ou remove o índice do bit selecionado
                            if (selectedBitIndices.contains(index)) {
                              selectedBitIndices.remove(index);
                            } else {
                              selectedBitIndices.add(index);
                            }
                          });
                          genBin();
                          binaryToHex();
                          hashHexController.text = hashHex;
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedBitIndices.contains(index) ? Colors.blue : Colors.white,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              privateKeyBits[index].toString(),
                              style: TextStyle(fontSize: 8, color: selectedBitIndices.contains(index) ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: hashHexController, minLines: 2, maxLines: 6, onChanged: loadVisualization),
                    TextButton(
                      onLongPress: () async {
                        await Clipboard.setData(ClipboardData(text: address));
                      },
                      onPressed: () async {
                        final balance = getBalance(address);
                        setState(() {
                          address = '$address - $balance';
                        });
                      },
                      child: Text(address, style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ),
                    TextButton(
                      onLongPress: () async {
                        await Clipboard.setData(ClipboardData(text: addressc));
                      },
                      onPressed: () async {
                        final balance = getBalance(addressc);
                        setState(() {
                          addressc = '$addressc - $balance';
                        });
                      },
                      child: Text('(c): $addressc', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: null,
              onPressed: () {
                if (hashHistory.length > 1) {
                  hashHistory.remove(hashHistory.last);
                  loadVisualization(hashHistory.last);
                }
              },
              tooltip: 'Voltar uma chave',
              child: Icon(Icons.undo),
            ),
            SizedBox(width: 10),
            GestureDetector(
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  setState(() {
                    selectedBitIndices.clear(); // Limpa os bits selecionados
                    List.generate(256, (index) {
                      selectedBitIndices.add(Random().nextInt(256));
                    });
                  });
                  genBin();
                  binaryToHex();
                  hashHexController.text = hashHex;
                },
                tooltip: 'Gerar nova chave',
                child: Icon(Icons.refresh),
              ),
            ),
            SizedBox(width: 10),
            FloatingActionButton(
              heroTag: null,
              onPressed: () {
                setState(() {
                  // Gera uma nova chave privada com bits aleatórios
                  selectedBitIndices.clear(); // Limpa os bits selecionados
                });
                genBin();
                binaryToHex();
                hashHexController.text = hashHex;
              },
              tooltip: 'Limpar seleção',
              child: Icon(Icons.clear),
            ),
          ],
        ),
      ),
    );
  }
}
