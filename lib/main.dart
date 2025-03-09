import 'dart:math';

import 'package:btcview/btctool.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Private Key Visualizer', theme: ThemeData(primarySwatch: Colors.blue), home: PrivateKeyVisualizer());
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

  void binaryToHex() {
    // Converte a string binária em um número inteiro
    BigInt decimalValue = BigInt.parse(hashBin, radix: 2);

    // Converte o número inteiro para uma string hexadecimal
    String hexString = decimalValue.toRadixString(16).toUpperCase();

    setState(() {
      hashHex = hexString;
      btc.setPrivateKeyFromSeed(hashHex);
      address = btc.getAddress();
      addressc = btc.getAddress(true);
    });
    hashHistory.add(hashHex);
  }

  Future<String> getBalance(String addr) async {
    try {
      final url = 'https://blockchain.info/q/addressbalance/$addr';
      final response = await Dio().get(url);

      final balance = await response.data;
      return balance;
    } catch (e) {
      return 'Error';
    }
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
    binaryToHex();
  }

  Set<String> hashHistory = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Private Key (256-bit Visualization)', style: TextStyle(fontSize: 16)), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              // Exibe o hash gerado com base nos bits selecionados
              // Text('Hash BIN: $hashBin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: hashHexController, minLines: 2, maxLines: 6, onChanged: loadVisualization),
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: hashHex));
                    },
                    child: Text('Hash HEX: $hashHex', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      // await Clipboard.setData(ClipboardData(text: address));
                      final balance = await getBalance(address);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Balance: $balance'), duration: Duration(milliseconds: 250)));
                    },
                    child: Text(address, style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      // await Clipboard.setData(ClipboardData(text: addressc));
                      final balance = await getBalance(addressc);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Balance: $balance'), duration: Duration(milliseconds: 250)));
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
            onPressed: () {
              if (hashHistory.isNotEmpty) {
                hashHistory.remove(hashHistory.last);
                loadVisualization(hashHistory.last);
              }
            },
            tooltip: 'Voltar uma chave',
            child: Icon(Icons.undo),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                // Gera uma nova chave privada com bits aleatórios
                selectedBitIndices.clear(); // Limpa os bits selecionados
                List.generate(256, (index) {
                  selectedBitIndices.add(Random().nextInt(255));
                });
              });
              genBin();
              binaryToHex();
              hashHexController.text = hashHex;
            },
            tooltip: 'Gerar nova chave',
            child: Icon(Icons.refresh),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
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
    );
  }
}
