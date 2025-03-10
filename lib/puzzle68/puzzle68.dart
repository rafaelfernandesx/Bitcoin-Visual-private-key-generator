import 'dart:async';
import 'dart:math';

import 'package:btcview/btctool.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

class Puzzle68Page extends StatefulWidget {
  const Puzzle68Page({super.key});

  @override
  State<Puzzle68Page> createState() => _Puzzle68PageState();
}

class _Puzzle68PageState extends State<Puzzle68Page> {
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
      address = '$address - ${getBalance(address)}';
      addressc = '$addressc - ${getBalance(addressc)}';
    });
    if (addHystory) {
      hashHistory.add(hashHex);
    }
    if (hashHistory.length > 300) {
      hashHistory.clear();
    }
  }

  String getBalance(String addr) {
    if (addr == '1MVDYgVaSN6iKKEsbzRUAYFrYJadLYZvvZ') {
      showAdaptiveAboutDialog(context: context, children: [Text('1MVDYgVaSN6iKKEsbzRUAYFrYJadLYZvvZ')], barrierDismissible: false);
      return 'Found';
    }

    return '0';
  }

  void loadVisualization(String hex) {
    selectedBitIndices.clear();
    final listBin = BigInt.parse(hex, radix: 16).toRadixString(2).split('');
    listBin.asMap().forEach((index, bin) {
      if (bin == '1') {
        selectedBitIndices.add(index + 188);
      }
    });
    genBin();
    binaryToHex(false);
  }

  Set<String> hashHistory = {};

  Timer? _timer;

  void _startRepeatingAction() {
    _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      setState(() {
        selectedBitIndices.clear(); // Limpa os bits selecionados
        List.generate(68, (index) {
          selectedBitIndices.add((188 + Random().nextInt(256 - 188 + 1)));
        });
      });
      genBin();
      binaryToHex();
      hashHexController.text = hashHex;
    });
  }

  void _stopRepeatingAction() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Puzzle 68 finder', style: TextStyle(fontSize: 16)), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.width / 2,
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 12, // 16 colunas
                      childAspectRatio: 1.0, // Quadrados perfeitos
                    ),
                    itemCount: 68, // 16x16 = 256 bits
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // Adiciona ou remove o índice do bit selecionado
                            if (selectedBitIndices.contains(index + 188)) {
                              selectedBitIndices.remove(index + 188);
                            } else {
                              selectedBitIndices.add(index + 188);
                            }
                          });
                          genBin();
                          binaryToHex();
                          hashHexController.text = hashHex;
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: selectedBitIndices.contains(index + 188) ? Colors.blue : Colors.white,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              privateKeyBits[index + 188].toString(),
                              style: TextStyle(fontSize: 8, color: selectedBitIndices.contains(index + 188) ? Colors.white : Colors.black),
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
                    Row(
                      children: [
                        Expanded(child: TextField(controller: hashHexController, minLines: 2, maxLines: 6, onChanged: loadVisualization)),
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: hashHex));
                          },
                        ),
                      ],
                    ),
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
              onLongPressStart: (_) => _startRepeatingAction(),
              onLongPressEnd: (_) => _stopRepeatingAction(),
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  setState(() {
                    selectedBitIndices.clear(); // Limpa os bits selecionados
                    List.generate(68, (index) {
                      selectedBitIndices.add((188 + Random().nextInt(256 - 188 + 1)));
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
