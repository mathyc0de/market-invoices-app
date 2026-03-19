import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/pages/commerce_page.dart';
import 'package:market_invoices_app/widgets/buttons.dart';
import 'package:market_invoices_app/widgets/loadscreen.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _built = false;
  bool _editorMode = false;
  int _navBarIndex = 0;
  late List<Commerce> commerces;
  List<Commerce> displaiedCommerces = [];

  @override
  void initState() {
    db.getCommerces().then((value) {
      commerces = value;
      updateDisplaiedCommerces(_navBarIndex);
      _built = true;
      setState(() {});
    });
    super.initState();
  }

  Future<void> getData() async {
    commerces = await db.getCommerces();
    updateDisplaiedCommerces(_navBarIndex);
    setState(() {
    });
  }


  Future<void> addCommerce(BuildContext context) async {
    await showDialog(context: context, builder: (context) => AddCommerceDialog(type: _navBarIndex == 0? "vendas" : "precos"));
    await getData();
    return;
  }
  
  Future<void> edit(Commerce commerce) async {
    await showDialog(context: context, builder: (context) => EditCommerceDialog(commerce: commerce));
    await getData();
    return;
  }

  void removeList() {
    setState(() {
      _editorMode = true;
    });
    return;
  }

  Color getRandomColor() {
    final Random random = Random();
    Color color;
    int R, G, B;
    do {
      (R, G, B) = (
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256)
        );
      color = Color.fromARGB(
        255,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );
    } while ((R + G + B) > 700 || (R + G + B) < 50);
    return color;
  }

  Future<bool> _confirmDelete(BuildContext context, String commerce) async {
    bool? result = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
        ],
        content: Text("Você tem certeza que deseja deletar a lista $commerce?")
      )
    );
    result ??= false;
    return result;
  }

  void updateDisplaiedCommerces(int index) {
    _navBarIndex = index;
    displaiedCommerces = commerces.where((element) => element.type == (index == 0? "vendas": "precos")).toList();
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_built) return loadScreen();
    return Scaffold(
      floatingActionButton:SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Adicionar novo comércio',
            onTap: ()  => addCommerce(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete),
            label: 'Deletar comércio',
            onTap: removeList,
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 147, 199, 27),
        title: const Text("Market Invoices", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),),
        centerTitle: true,
        leading: _editorMode? IconButton(
          icon: const Icon(Icons.do_not_disturb_on_rounded), 
          onPressed: () {
            _editorMode = false;
            setState(() {
            });
          }, 
          color: Colors.red)
          : null,
      ),
      body: displaiedCommerces.isNotEmpty?
        ListView(
          children: [
            for (int index = 0; index <= displaiedCommerces.length - 1; index++)
            ListTile(
              onLongPress: () => edit(displaiedCommerces[index]),
              onTap: () async {
                if (!_editorMode) {
                  final Commerce commerce = displaiedCommerces[index];
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommercePage(
                          commerce: commerce,
                        ),
                      )
                  );
                }
                else {
                  final Commerce commerce = displaiedCommerces[index];
                  if (await _confirmDelete(context, commerce.name)) {
                    db.removeCommerce(commerce.id!);
                    getData();
                  }
                  _editorMode = false;
                  setState(() {
                    });
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minVerticalPadding: 0,
              title: Container(
                decoration: BoxDecoration(
                  boxShadow: kElevationToShadow[12],
                  border: Border.all(color: Colors.black),
                  color: getRandomColor(), 
                  borderRadius: const BorderRadius.all(Radius.circular(4))),
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(displaiedCommerces[index].name, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),),
                    // Text(tables[index].date, style: const TextStyle(color: Colors.grey))
                  ]
                  ),
              )
              ),
            ],
          )
      :
      const Align(
        alignment: Alignment.center,
        child: Text("Adicione um novo comércio!")),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navBarIndex,
        onTap: updateDisplaiedCommerces,
        items: const [
            BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: "Listas de Vendas",
            ),
          BottomNavigationBarItem(icon: Icon(Icons.price_change),
            label: "Listas de Preços"
          )
        ]
        )
      );
  }
}




class AddCommerceDialog extends StatelessWidget {
  AddCommerceDialog({super.key, required this.type});
  final TextEditingController nameController = TextEditingController();
  final String type;

  @override
  Widget build(BuildContext context) {
    bool useProduct = false;
    return AlertDialog(
      content: StatefulBuilder(builder: (context, setState) => SingleChildScrollView(
        child:  Column(
              children: [
                textFormFieldPers(nameController, "Nome do Comércio"),
                Row(
                  children: [
                    Checkbox(
                      value: useProduct, 
                      onChanged: (bool? value) {
                        useProduct = value!;
                        setState(() {
                        });
                      }),
                    const Text("Usar IDs de produtos")
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    await db.insertCommerce(
                      Commerce(
                        name: nameController.text,
                        type: type,
                        useProductId: useProduct
                        )
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    }, 
                  child: const Text("Criar comércio"))
              ],
            ),
      )),
    );
  }
}

class EditCommerceDialog extends StatelessWidget {
  EditCommerceDialog({super.key, required this.commerce}) : nameController = TextEditingController(text: commerce.name);
  final TextEditingController nameController;
  final Commerce commerce;


  @override
  Widget build(BuildContext context) {
    bool useProduct = commerce.useProductId;
    return AlertDialog(
      content: StatefulBuilder(builder: (context, setState) => SingleChildScrollView(
        child: Column(
              children: [
                textFormFieldPers(nameController, "Nome do comércio"),
                Row(
                  children: [
                    Checkbox(
                      value: useProduct, 
                      onChanged: (bool? value) {
                        useProduct = value!;
                        setState(() {
                        });
                      }),
                    const Text("Usar IDs de produtos")
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty && commerce.useProductId == useProduct) return;
                    await db.updateCommerce(
                      commerce.id!, nameController.text, useProduct
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    }, 
                  child: const Text("Editar comércio"))
              ],
            ),
      )),
    );
  }

}