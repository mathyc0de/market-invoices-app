import 'package:flutter/material.dart';
import 'package:market_invoices_app/methods/database.dart' show DBManager, db;
import 'package:market_invoices_app/pages/home.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await dotenv.load(fileName: ".env");
  db = DBManager(db: await openDatabase(
    join(await getDatabasesPath(),'data.db'),
    onOpen: (db) => db.execute("PRAGMA foreign_keys = ON;"),
    onUpgrade: (db, oldVersion, newVersion) {
      if (oldVersion < 2) {
        db.execute("ALTER TABLE commerces ADD COLUMN use_product_id INTEGER DEFAULT 0;");
        db.execute("ALTER TABLE items ADD COLUMN product_id INTEGER;");
        db.execute(
          """
          CREATE TABLE products(
          id INTEGER PRIMARY KEY,
          commerce_id INTEGER,
          product_id INTEGER NOT NULL,
          name TEXT,
          UNIQUE(commerce_id, product_id),
          FOREIGN KEY (commerce_id) REFERENCES commerces(commerce_id) ON DELETE CASCADE);
          """
        );
      }
      if (oldVersion < 3) {
        db.execute("ALTER TABLE tables ADD COLUMN timestamp INTEGER DEFAULT 0;");
        // Atualizar registros existentes com timestamps incrementais
        db.execute("""
          UPDATE tables 
          SET timestamp = (
            SELECT COUNT(*) 
            FROM tables t2 
            WHERE t2.table_id <= tables.table_id AND t2.commerce_id = tables.commerce_id
          )
        """);
      }
    },
    onCreate: (db, version) {
      db.execute(
        """
        CREATE TABLE commerces(
        commerce_id INTEGER PRIMARY KEY, 
        name TEXT, 
        type TEXT,
        use_product_id INTEGER DEFAULT 0);
        """
      );
      db.execute(
        """
        CREATE TABLE products(
        id INTEGER PRIMARY KEY,
        commerce_id INTEGER,
        product_id INTEGER NOT NULL,
        name TEXT,
        UNIQUE(commerce_id, product_id),
        FOREIGN KEY (commerce_id) REFERENCES commerces(commerce_id) ON DELETE CASCADE);
        """
      );
      db.execute(
        """
        CREATE TABLE tables(
        table_id INTEGER PRIMARY KEY, 
        name TEXT, 
        date TEXT,
        commerce_id INTEGER,
        timestamp INTEGER DEFAULT 0,
        FOREIGN KEY (commerce_id) REFERENCES commerces(commerce_id) ON DELETE CASCADE);
        """
      );
      db.execute(
        """
        CREATE TABLE items(
        item_id INTEGER PRIMARY KEY,
        name TEXT,
        price FLOAT,
        quantity FLOAT,
        type VARCHAR(2) NOT NULL,
        table_id INTEGER,
        product_id INTEGER,
        FOREIGN KEY (table_id) REFERENCES tables(table_id) ON DELETE CASCADE
        );
        """
      );
    },
    version: 3
  ));
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData(
        // brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      theme: ThemeData( 
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 186, 255, 23)),
      ),
      home: const HomePage(),
    );
  }
}
