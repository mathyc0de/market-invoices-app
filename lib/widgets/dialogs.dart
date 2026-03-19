import 'dart:convert' show jsonDecode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:market_invoices_app/methods/ai_services.dart' show Prompt, sendToGroq;
import 'package:market_invoices_app/methods/database.dart' show Item, db;
import 'package:market_invoices_app/methods/str_manipulation.dart' show speechToList;
import 'package:market_invoices_app/widgets/buttons.dart';


class AddManyDialog extends StatefulWidget {
  const AddManyDialog({super.key, required this.tableid});
  final int tableid;

  @override
  State<AddManyDialog> createState() => _AddManyDialogState();
}

class _AddManyDialogState extends State<AddManyDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _out;
  List<Item> _items = [];


  void paste(TextEditingController controller) {
    Clipboard.getData(Clipboard.kTextPlain).then((value) {
      setState(() {
      controller.text = value!.text.toString();
      });
    }); 
  }

 Future<void> addToDB() async {
    try {
      for (Item item in _items) {
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
    _out = await sendToGroq(_controller.text, Prompt.sellPagePrompt);
    print(_out);
     if (!(await uploadStatus())) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
     }
     _controller.text = '';
    _items = speechToList(jsonDecode(_out!), widget.tableid);
    setState(() {
    });
  }


  
  @override
  Widget build(BuildContext context) {
    if (_items.isNotEmpty) {
      return Dialog(
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (var item in _items)
                ListTile(
                  title: Text("${item.quantity} ${item.type} ${item.name} R\$ ${item.price}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete), 
                    onPressed: () {
                      setState(() {
                        _items.remove(item);
                      });
                    },
                  ),
                ),
              ElevatedButton(
                onPressed: () async {
                  await addToDB();
                }, 
                child: const Text("Adicionar produtos"))
            ],
          ),
        ),
      );
    }
    return AlertDialog(
      actions: [
          TextButton(
            onPressed: () => paste(_controller), 
            child: const Text("Colar")
            ),
          TextButton(
            onPressed: processs,
            child: const Text("Adicionar Produtos")
            )
        ],
        content: SizedBox(
          height: 150,
          child: textFormFieldPers(
            maxLength: 1000,
            _controller, 
            "Descreva os produtos!",
            expands: true,
            ),
        ),
    );
  }
}



class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key, required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Erro"),
      actions: [
        TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
      ],
      content: SingleChildScrollView(
        child: Text(errorMessage),
      ),
    );
  }
}