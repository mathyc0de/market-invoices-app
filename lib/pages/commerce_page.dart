import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/pages/products_page.dart';
import 'package:market_invoices_app/pages/sell_page.dart';
import 'package:market_invoices_app/widgets/buttons.dart';
import 'package:market_invoices_app/widgets/loadscreen.dart';

class CommercePage extends StatefulWidget {
  const CommercePage({super.key, required this.commerce});
  final Commerce commerce;

  @override
  State<CommercePage> createState() => _CommercePageState();
}

class _CommercePageState extends State<CommercePage> {
  bool _built = false;
  List<Tables> selectedTables = [];
  late List<Tables> tables;

  @override
  void initState() {
    db.getTables(widget.commerce.id!).then((value) {
      tables = value;
      _built = true;
      setState(() {});
    });
    super.initState();
  }

  Future<void> getData() async {
    tables = await db.getTables(widget.commerce.id!);
    setState(() {});
  }

  String __buildDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> addList(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: StatefulBuilder(
                builder: (context, setState) => SingleChildScrollView(
                  child: Column(
                    children: [
                      textFormFieldPers(
                          nameController, "Nome da Lista (opcional)"),
                      ElevatedButton(
                          onPressed: () async {
                            await db.insertTable(Tables(
                              name: nameController.text,
                              date: __buildDate(DateTime.now()),
                              commerceId: widget.commerce.id!,
                            ));
                            await getData();
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          child: const Text("Criar lista"))
                    ],
                  ),
                ),
              ),
            ));
    return;
  }

  Future<void> edit(Tables table) async {
    final TextEditingController nameController =
        TextEditingController(text: table.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              textFormFieldPers(nameController, "Nome da Lista"),
              ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    try {
                      await db.updateTable(Tables(
                          name: nameController.text,
                          date: table.date,
                          id: table.id,
                          commerceId: widget.commerce.id!));
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      await getData();
                    } catch (e) {
                      debugPrint('Erro ao editar tabela: $e');
                    }
                  },
                  child: const Text("Editar lista"))
            ],
          ),
        ),
      ),
    );
    nameController.dispose();
    return;
  }

  void onDeleteTable() async {
    for (final table in selectedTables) {
      await db.removeTable(table);
    }
    selectedTables.clear();
    await getData();
  }

void handleProductIDs() {
  showDialog(
    context: context,
    builder: (context) => ProductIDDialog(commerceId: widget.commerce.id!),
  );
}


  @override
  Widget build(BuildContext context) {
    if (!_built) return loadScreen();
    return Scaffold(
        floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Adicionar nova lista',
            onTap: ()  => addList(context),
          ),
          if (widget.commerce.useProductId)
          SpeedDialChild(
            child: const Icon(Icons.sell),
            label: 'Adicionar Códigos de Produtos',
            onTap: handleProductIDs,
          ),
        ],
      ),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 147, 199, 27),
          title: Text(widget.commerce.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.white)),
          centerTitle: true,
          actions: [
            if (selectedTables.isNotEmpty)
              IconButton(
                  onPressed: onDeleteTable,
                  icon: const Icon(Icons.delete, color: Color(0xFFFFFFFF))),
            if (selectedTables.length == 1)
              IconButton(
                  onPressed: () async {
                    await edit(selectedTables.first);
                    selectedTables.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.edit, color: Color(0xFFFFFFFF)))
          ],
        ),
        body: tables.isNotEmpty
            ? ListView(
                children: [
                  for (int index = 0; index <= tables.length - 1; index++)
                    ListTile(
                        onLongPress: () {
                          final Tables table = tables[index];
                          selectedTables.contains(table)
                              ? selectedTables.remove(table)
                              : selectedTables.add(table);
                          setState(() {});
                        },
                        onTap: () async {
                          if (selectedTables.isNotEmpty) {
                            final Tables table = tables[index];
                            selectedTables.contains(table)
                                ? selectedTables.remove(table)
                                : selectedTables.add(table);
                            setState(() {});
                            return;
                          }
                          final Tables table = tables[index];
                          widget.commerce.type == "precos"
                              ? Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ProductsPage(
                                    commerce: widget.commerce.name,
                                    id: table.id!,
                                    name: table.name,
                                    date: table.date,
                                  ),
                                ))
                              : Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ProductsPageWithWeight(
                                    commerce: widget.commerce,
                                    id: table.id!,
                                    name: table.name,
                                    date: table.date,
                                  ),
                                ));
                        },
                        title: Container(
                            color: selectedTables.contains(tables[index])
                                ? const Color.fromARGB(199, 134, 178, 83)
                                : const Color.fromARGB(0, 0, 0, 0),
                            child: Text(
                                "${tables[index].name} ${tables[index].date}"))),
                ],
              )
            : const Align(
                alignment: Alignment.center,
                child: Text("Crie uma nova lista!")));
  }
}











class ProductIDDialog extends StatefulWidget {
  const ProductIDDialog({
    super.key,
    required this.commerceId,
  });

  final int commerceId;

  @override
  State<ProductIDDialog> createState() => _ProductIDDialogState();
}

class _ProductIDDialogState extends State<ProductIDDialog> {
  final nameController = TextEditingController();
  final idController = TextEditingController();
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final loadedProducts = await db.getProducts(widget.commerceId);
    if (mounted) {
      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    }
  }

  Future<void> _addProduct() async {
    if (nameController.text.isEmpty || idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final int? productId = int.tryParse(idController.text);
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código inválido. Digite apenas números')),
      );
      return;
    }

    await db.insertProduct(Product(
      commerceId: widget.commerceId,
      productId: productId,
      name: nameController.text,
    ));

    nameController.clear();
    idController.clear();
    await _loadProducts();
  }

  Future<void> _removeProduct(int productId) async {
    await db.removeProduct(productId, widget.commerceId);
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Códigos de Produtos",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Lista de produtos existentes
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum produto cadastrado',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${product.productId}'),
                                ),
                                title: Text(product.name),
                                subtitle: Text('Código: ${product.productId}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeProduct(product.productId),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Formulário para adicionar novo produto
            const Text(
              'Adicionar novo produto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            textFormFieldPers(
              nameController,
              "Nome do Produto",
              maxLength: 21,
            ),
            textFormFieldPers(
              idController,
              "Código do Produto",
              keyboardType: TextInputType.number,
              maxLength: 10,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text("Adicionar Produto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 147, 199, 27),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}