import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:market_invoices_app/methods/printer.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/methods/str_manipulation.dart';
import 'package:market_invoices_app/widgets/buttons.dart';
import 'package:market_invoices_app/widgets/dialogs.dart' show AddManyDialog;
import 'package:market_invoices_app/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:market_invoices_app/widgets/speech2text.dart';


const int maxProducts = 57;

String unitaryCheck(bool boolean) {
    if (boolean) return "kg";
    return "un";
  }

double division(num op1, num op2) => (op1 / op2).toDouble();
double multiplication(num op1, num op2) => (op1 * op2).toDouble();

void autoComplete(TextEditingController reference, TextEditingController option1, TextEditingController option2, {double Function(num, num) operation = multiplication}) {
  if (double.tryParse(reference.text) != null) {
    if (double.tryParse(option2.text) != null) { 
      option1.text = (operation(double.parse(reference.text), double.parse(option2.text))).toString();
    }
    else if (double.tryParse(option1.text) != null) {
      option2.text = (operation(double.parse(reference.text), double.parse(option1.text))).toString();
    }
  }
}


class ProductsPageWithWeight extends StatefulWidget {
  const ProductsPageWithWeight({
    super.key, 
    required this.id, 
    required this.name, 
    required this.date,
    required this.commerce,
    });

  final String name;
  final int id;
  final String date;
  final Commerce commerce;
  
  @override
  State<ProductsPageWithWeight> createState() => _StateProductsPageWithWeight();
}

class _StateProductsPageWithWeight extends State<ProductsPageWithWeight> {

  bool _built = false;
  late List<DataRow> rows;
  List<Item> items = [];
  final List<Item> selectedItems = [];
  NumberFormat f = NumberFormat.currency(symbol: "R\$");
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();



  double sumTable(List<Item> items) {
    double total = 0;
    for (Item produto in items) {
      total += produto.price * produto.quantity;
    }
    return total;
  }

  void _updateRows() {
    rows = 
    [ 
      for (Item produto in items)
      DataRow(
        color: WidgetStatePropertyAll(selectedItems.contains(produto) ? const Color.fromARGB(199, 134, 178, 83) : const Color.fromARGB(0, 0, 0, 0)),
        cells: [
          DataCell(
          onTap: () {
          if (selectedItems.contains(produto)) {
            setState(() {
              selectedItems.remove(produto);
            });
            _updateRows();
            return;

          }
          setState(() {
          selectedItems.add(produto);
          });
          _updateRows();
        },
            Text(produto.name)
          ),
          DataCell(
            Text(f.format(produto.price))
          ),
          DataCell(
            Text("${produto.quantity} ${produto.type}")
          ),
        ] 
      ),
      if (items.isNotEmpty) 
      DataRow(
        cells: [
          const DataCell(Text("Total")),
          DataCell(Text(f.format(sumTable(items)))),
          const DataCell(Text("")),
        ]),

        
    ];
    setState(() {
    });
  }

  Future<void> _getRows() async {
    items = await db.getItems(widget.id);
    _updateRows();
  }

  @override
  void initState() {
    _getRows().then((val) {
      _built = true;
    });
    super.initState();
  }

  Future<void> addProduct() async {
    if (items.length < maxProducts) {
      await showDialog(context: context, builder: (context) => AddProductDialog(tableId: widget.id, commerceId: widget.commerce.id!, useProductId: widget.commerce.useProductId));
      await _getRows();
      return;
      }
  }

 


  void _addProductVoice() {
    if (items.length < maxProducts) {
      showDialog(
        context: context, 
        builder: (context) => SpeechDialog(tableid: widget.id)
      ).then((val) => _getRows());
      return;
    }
    scaffoldMessengerKey
      .currentState!
      .showSnackBar(const SnackBar(
        content: Text(
          "Você atingiu o limite de produtos adicionados nesta lista."
          )
        )
      );
  }

  void _addManyProducts() {
    if (items.length < maxProducts) {
      showDialog(
        context: context, 
        builder: (context) => AddManyDialog(tableid: widget.id)
      ).then((val) => _getRows());
      return;
    }
    scaffoldMessengerKey
      .currentState!
      .showSnackBar(const SnackBar(
        content: Text(
          "Você atingiu o limite de produtos adicionados nesta lista."
          )
        )
      );
  }

  
  String unitaryCheck(bool boolean) {
    if (boolean) return "un";
    return "kg";
  }

  Future<void> edit(Item product) async {
    await showDialog(context: context, builder: (context) => EditProductDialog(product: product, commerceId: widget.commerce.id!));
    await _getRows();
    return;
  }


  Future<void> removeProduct(Item produto) async {
    await db.removeItem(produto);
    await _getRows();
  }


  Future<void> printTable() async {
    List<Item> data = await db.getItems(widget.id);
    
    // Buscar informações da tabela para obter timestamp
    final tables = await db.getTables(widget.commerce.id!);
    final currentTable = tables.firstWhere((t) => t.id == widget.id);
    
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>  PrintPage(
        commereceType: "vendas", 
        data: data, 
        tableName: "${widget.name}      ${widget.date}", 
        useProductId: widget.commerce.useProductId,
        commerceId: widget.commerce.id,
        timestamp: currentTable.timestamp,
      ))
      );
  }


  @override
  Widget build(BuildContext context) {
    if (!_built) return loadScreen();
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        floatingActionButton: SpeedDial(
          backgroundColor: const Color.fromARGB(30, 106, 117, 117),
          foregroundColor: const Color.fromARGB(255, 139, 195, 74),
          elevation: 0,
           animatedIcon: AnimatedIcons.menu_close,
           children: [
            SpeedDialChild(
              label: "Adicionar Produto",
              child: const Icon(Icons.add),
              onTap: addProduct,
            ),
            SpeedDialChild(
              label: "Adicionar vários produtos",
              child: const Icon(Icons.add_circle),
              onTap: _addManyProducts
            ),
            SpeedDialChild(
              label: "Adicionar vários produtos por voz",
              child: const Icon(Icons.mic),
              onTap: _addProductVoice,

            ),
            SpeedDialChild(
              label: "Imprimir Tabela",
              child: const Icon(Icons.print),
              onTap: printTable
            )
           ],
        ),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 147, 199, 27),
          title: Text("${widget.commerce.name} ${widget.name} ${widget.date}", style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          centerTitle: true,
          actions: selectedItems.isEmpty? [
            Text("${items.length} / $maxProducts", style: TextStyle(fontWeight: FontWeight.bold, color: items.length < maxProducts? const Color(0xFFFFFFFF) : const Color(0xFFFF0000), fontSize: 18)),
          ] : [
            if (selectedItems.length == 1) IconButton(
              onPressed: () async {
                await edit(selectedItems.first);
                selectedItems.clear();
                _updateRows();
              }, 
              icon: const Icon(Icons.edit, color: Color(0xFFFFFFFF))
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFFFFFFF),),
              onPressed: () async {
                for (Item produto in selectedItems) {
                  await removeProduct(produto);
                }
                selectedItems.clear();
                _updateRows();
              }
            )
          ]
        ),
        body:
            SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Produto")),
                    DataColumn(label: Text("Preço")),
                    DataColumn(label: Text("Peso/Un")),
                    ],
                  rows: rows
                ),
              ),
            )
      ),
    );
  }
}



class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key, required this.tableId, required this.commerceId, required this.useProductId});
  final int tableId;
  final int commerceId;
  final bool useProductId;

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  String code = "";
  
  bool isUnitary = false;
  List<Product> availableProducts = [];
  bool _productsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    availableProducts = await db.getProducts(widget.commerceId);
    setState(() {
      _productsLoaded = true;
    });
  }

  void _onProductSelected(Product product) {
    setState(() {
      nameController.text = product.name;
      code = product.productId.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget brlSymbol = Text("R\$", style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold));
    
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            if (_productsLoaded && availableProducts.isNotEmpty)
              Autocomplete<Product>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Product>.empty();
                  }
                  return availableProducts.where((Product product) {
                    return product.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                           product.productId.toString().contains(textEditingValue.text);
                  });
                },
                displayStringForOption: (Product product) => product.name,
                onSelected: _onProductSelected,
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  nameController.addListener(() {
                    controller.text = nameController.text;
                  });
                  controller.addListener(() {
                    nameController.text = controller.text;
                  });
                  return textFormFieldPers(
                    controller,
                    "Nome do Produto",
                    keyboardType: TextInputType.name,
                    focusNode: focusNode,
                    onChanged: (value) {
                      Product product = availableProducts.firstWhere(
                        (product) => product.name == value, 
                        orElse: () => const Product(id: 0, commerceId: 0, productId: 0, name: "")
                      );
                      setState(() {
                        code = product.productId.toString();
                      });
                    },
                  );
                },
              )
            else
              textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
            textFormFieldPers(priceController, "Preço", keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false), prefix: brlSymbol, onChanged: (p0) => autoComplete(priceController, totalController, weightController)),
            textFormFieldPers(weightController, !isUnitary ? "Peso(kg)" : "Unidades", keyboardType: TextInputType.numberWithOptions(decimal: isUnitary ? false : true, signed: false), onChanged: (p0) => autoComplete(weightController, totalController, priceController)),
            textFormFieldPers(totalController, "Total (R\$)", prefix: brlSymbol, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (p0) => autoComplete(totalController, weightController, priceController, operation: division)),
            if (widget.useProductId) Text("Código: $code", style: const TextStyle(color: Colors.blueGrey)),
            CheckboxListTile(
              value: isUnitary,
              onChanged: (val) {
                setState(() => isUnitary = val!);
              },
              title: const Text("Unitário"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                
                int? productId;
                if (code.isNotEmpty) {
                  productId = int.tryParse(code);
                }
                
                await db.insertItem(Item(
                  name: nameController.text.capitalize(),
                  price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')),
                  tableId: widget.tableId,
                  type: unitaryCheck(!isUnitary),
                  quantity: double.parse(weightController.text.replaceFirst(RegExp(r','), '.')),
                  productId: productId,
                ));
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text("Adicionar produto")
            )
          ],
        ),
      ),
    );
  }
}



class EditProductDialog extends StatefulWidget {
  const EditProductDialog({super.key, required this.product, required this.commerceId});
  
  final Item product;
  final int commerceId;

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController weightController;
  late TextEditingController totalController;
  late TextEditingController codeController;
  late bool isUnitary;
  
  List<Product> availableProducts = [];
  bool _productsLoaded = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
    weightController = TextEditingController(text: widget.product.quantity.toString());
    totalController = TextEditingController(text: (widget.product.price * widget.product.quantity).toString());
    codeController = TextEditingController(text: widget.product.productId?.toString() ?? '');
    isUnitary = widget.product.type == "kg" ? false : true;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    availableProducts = await db.getProducts(widget.commerceId);
    setState(() {
      _productsLoaded = true;
    });
  }

  void _onProductSelected(Product product) {
    setState(() {
      nameController.text = product.name;
      codeController.text = product.productId.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget brlSymbol = Text("R\$", style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold));
    
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            if (_productsLoaded && availableProducts.isNotEmpty)
              Autocomplete<Product>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Product>.empty();
                  }
                  return availableProducts.where((Product product) {
                    return product.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                           product.productId.toString().contains(textEditingValue.text);
                  });
                },
                displayStringForOption: (Product product) => product.name,
                onSelected: _onProductSelected,
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  nameController.addListener(() {
                    controller.text = nameController.text;
                  });
                  controller.addListener(() {
                    nameController.text = controller.text;
                  });
                  return textFormFieldPers(
                    controller,
                    "Nome do Produto",
                    keyboardType: TextInputType.name,
                    focusNode: focusNode,
                  );
                },
              )
            else
              textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
            textFormFieldPers(codeController, "Código do Produto", keyboardType: TextInputType.number),
            textFormFieldPers(priceController, "Preço", prefix: brlSymbol, keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false), onChanged: (p0) => autoComplete(priceController, totalController, weightController)),
            textFormFieldPers(weightController, !isUnitary ? "Peso(kg)" : "Unidades", keyboardType: TextInputType.numberWithOptions(decimal: isUnitary ? false : true, signed: false), onChanged: (p0) => autoComplete(weightController, totalController, priceController)),
            textFormFieldPers(totalController, "Total (R\$)", prefix: brlSymbol, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (p0) => autoComplete(totalController, weightController, priceController, operation: division)),
            CheckboxListTile(
              value: isUnitary,
              onChanged: (val) {
                setState(() => isUnitary = val!);
              },
              title: const Text("Unitário"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty || weightController.text.isEmpty) return;
                
                int? productId;
                if (codeController.text.isNotEmpty) {
                  productId = int.tryParse(codeController.text);
                }
                
                await db.updateItem(Item(
                  name: nameController.text.capitalize(),
                  price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')),
                  tableId: widget.product.tableId,
                  quantity: double.parse(weightController.text.replaceFirst(RegExp(r','), '.')),
                  type: unitaryCheck(!isUnitary),
                  id: widget.product.id,
                  productId: productId,
                ));
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text("Atualizar produto")
            )
          ],
        ),
      ),
    );
  }
}
