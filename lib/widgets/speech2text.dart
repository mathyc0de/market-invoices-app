import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:market_invoices_app/methods/ai_services.dart';
import 'package:market_invoices_app/methods/database.dart' show Item, db;
import 'package:market_invoices_app/methods/str_manipulation.dart' show speechToList;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:market_invoices_app/widgets/dialogs.dart' show ErrorDialog;



            // """
                // Me responda, no formato JSON, uma LISTA [] de objetos, com os seguintes campos:
                // quantidade: float, nome: string, preço: float e formato: 'un' ou 'kg'
                // sem comentários adicionais. Ignore o r\$.
                // exemplos: 
                // "uma caixa de batata 100": {"quantidade" 1, "nome": "caixa de batata", "preço": 100, "formato": "un"}
                // "534 G batata doce 100 reais": {"quantidade": 0.534, "nome": "batata doce", "preço": 100, "formato": "kg"}
                // """





class SpeechDialog extends StatefulWidget {
  const SpeechDialog({super.key, required this.tableid});
  final int tableid;

  @override
  State<SpeechDialog> createState() => _SpeechDialogState();
}

class _SpeechDialogState extends State<SpeechDialog> {
  final SpeechToText _speech = SpeechToText();
  String _speechText = "";
  final List<String> _items = [];
  List<dynamic> _decoded = [];
  String? _out;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void onStatus(String status) {
    if (status == "done") {
      if (_speechText.isNotEmpty) {
        _items.add(_speechText);
        _speechText = "";
      }
    }
    setState(() {});
  }

  Future<void> _initSpeech() async {
    if (!_speech.isAvailable) {
      await _speech.initialize(
        onStatus: onStatus,
        finalTimeout: const Duration(seconds: 2));
        setState(() {
        });
        return;
    }
    _speech.statusListener = onStatus;
  }

   Future<void> start() async {
    await _speech.listen(
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(
        cancelOnError: true
      ),
      onResult: (result) {
        setState(() {
          _speechText = result.recognizedWords;
        });
      },
    );
    setState(() {
      
    });
  }

  Future<bool> uploadStatus() async{
    if (_out == null) {
      await showDialog(
        context: context, 
        builder: (context) => const ErrorDialog(
          errorMessage: "Houve um erro de conexão, certifique-se de estar conectado e tente novamente."
        ));
        return false;
    }
    return true;
  }

  Future<void> processs() async {
    await _speech.stop();
    final String input = _items.join("\n");
    _out = await sendToGroq(input, Prompt.sellPagePrompt);
    _decoded = jsonDecode(_out!);
     if (!(await uploadStatus())) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
     }
    setState(() {
    });
  }

  Future<void> addToDB() async {
    try {
      final List<Item> items = speechToList(_decoded, widget.tableid);
      for (Item item in items) {
        await db.insertItem(item);
      }
    }
    catch (e) {
      if (!mounted) return;
      await showDialog(context: context, builder: (context) => const ErrorDialog(
        errorMessage: "Houve um erro ao adicionar os itens, certifique-se de informar a quantidade, o nome e o preço corretamente."
        ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_speech.isAvailable) return const Dialog(child: CircularProgressIndicator());
    if (_decoded.isNotEmpty) {
        return Dialog(
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (var item in _decoded)
                ListTile(
                  title: Text("${item['quantidade'] ?? '?'} ${item['formato'] ?? '?'} ${item['nome'] ?? '?'} R\$ ${item['preço']?? '?'}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete), 
                    onPressed: () {
                      setState(() {
                        _decoded.remove(item);
                      });
                    },
                  ),
                ),
              Row(
                children: [
                  TextButton(
                    onPressed: addToDB, 
                    child: const Text("Adicionar")
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Cancelar")
                  )
                ],
              )
            ],
          ),
        ),
      );
    }
    return Dialog(
      child: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              IconButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateColor.fromMap({
                    WidgetState.any: _speech.isListening?Colors.green : Colors.white
                  }),
                ),
                onPressed: _speech.isListening? null : start, 
                icon: const Icon(Icons.mic, color: Colors.black)
                ),
                const Text("Clique no botão para falar"),
                for (int i=0; i < _items.length; i++)
                ListTile(
                  title: Text(_items[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _items.removeAt(i);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _items.isNotEmpty?  processs : null, 
                  child: const Text("Processar")
                  )
            ],
          ),
        ),
        ),
    );
  }
}
