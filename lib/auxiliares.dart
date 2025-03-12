import 'package:contabilidad/globales.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String walletToString(WalletEntity wallet) {
  List<String> internalDataStrings = wallet.internalData.map((list) => list.join(",")).toList();
  return "${wallet.name}|${internalDataStrings.join(";")}";
}

String categoryToString(CategoryEntity category) {
  return "${category.name}|${category.ingresos}|${category.gastos}|${category.color.value}";
}

String globalDataToString(Map<String, Map<String, List<Map<String, dynamic>>>> globalData) {
  return globalData.entries.map((walletEntry) {
    String walletName = walletEntry.key;
    String categories = walletEntry.value.entries.map((categoryEntry) {
      String categoryName = categoryEntry.key;
      String items = categoryEntry.value.map((item) {
        String dateString = (item['date'] as DateTime?)?.toIso8601String().split('T')[0] ?? '';
        return "${item['title']}:${item['amount']}:$dateString";
      }).join(";");
      return "$categoryName:$items";
    }).join("|");
    return "$walletName=>$categories";
  }).join("||");
}

String colorsByCategoryToString(Map<String, Map<String, Color>> colorsByCategory) {
  return colorsByCategory.entries.map((walletEntry) {
    String walletName = walletEntry.key;
    String categories = walletEntry.value.entries.map((categoryEntry) {
      return "${categoryEntry.key}:${categoryEntry.value.value}";
    }).join("|");
    return "$walletName=>$categories";
  }).join("||");
}

String totalToString(Map<String, int> totals) {
  return totals.entries.map((entry) => "${entry.key}:${entry.value}").join("|");
}

WalletEntity walletFromString(String walletString) {
  List<String> parts = walletString.split("|");
  String name = parts[0];

  // Verificar si internalData no está vacío y procesarlo
  List<List<dynamic>> internalData = [];
  if (parts[1].isNotEmpty) {
    internalData = parts[1].split(";").map((listString) {
      // Convertir cada lista separada por comas en una lista dinámica
      return listString.split(",").map((item) => int.tryParse(item) ?? item).toList();
    }).toList();
  }

  return WalletEntity(name: name, internalData: internalData);
}

CategoryEntity categoryFromString(String categoryString) {
  List<String> parts = categoryString.split("|");
  String name = parts[0];
  int ingresos = int.parse(parts[1]);
  int gastos = int.parse(parts[1]);
  Color color = Color(int.parse(parts[3]));
  return CategoryEntity(name: name, ingresos: ingresos, gastos: gastos, color: color);
}

Map<String, Map<String, List<Map<String, dynamic>>>> globalDataFromString(String globalDataString) {
  return globalDataString.split("||").fold({}, (acc, walletString) {
    if (walletString.isEmpty) return acc; // Si está vacío, ignorarlo
    List<String> walletParts = walletString.split("=>");
    String walletName = walletParts[0];

    // Verificar si hay categorías en la billetera
    if (walletParts.length < 2 || walletParts[1].isEmpty) {
      acc[walletName] = {}; // Si no hay categorías, asignar un map vacío
      return acc;
    }
    // Proceso las categorías de la wallet
    Map<String, List<Map<String, dynamic>>> categories = walletParts[1].split("|").fold({}, (categoryAcc, categoryString) {
      // Separar el nombre de la categoría del resto de los items
      List<String> categoryParts = categoryString.split(";");
      List<Map<String, dynamic>> items = [];
      String categoryName = "";
      String title;
      int amount;
      DateTime date;
      for (var item in categoryParts) {
        List<String> categoryMoves = item.split(":");
        if (categoryMoves.length < 3) {
          categoryName = categoryMoves[0];
          break;
        }
        if (categoryMoves.length == 4) {
          categoryName = categoryMoves[0];
          title = categoryMoves[1];
          amount = int.tryParse(categoryMoves[2]) ?? 0;
          date = DateTime.parse(categoryMoves[3]);
        } else {
          title = categoryMoves[0];
          amount = int.tryParse(categoryMoves[1]) ?? 0;
          date = DateTime.parse(categoryMoves[2]);
        }
        items.add({
          'title': title,
          'amount': amount,
          'date': date,
        });
      }

      // Almacenar los items bajo su categoría
      categoryAcc[categoryName] = items;
      return categoryAcc;
    });

    // Almacenar las categorías bajo su billetera
    acc[walletName] = categories;
    return acc;
  });
}

Map<String, Map<String, Color>> colorsByCategoryFromString(String colorsString) {
  return colorsString.split("||").fold({}, (acc, walletString) {
    if (walletString.isEmpty) return acc; // Verificar que no haya cadenas vacías
    List<String> walletParts = walletString.split("=>");

    String walletName = walletParts[0];

    Map<String, Color> categories = walletParts[1].split("|").fold({}, (categoryAcc, categoryString) {
      if (categoryString.isEmpty) return categoryAcc;

      List<String> categoryParts = categoryString.split(":");
      if (categoryParts.length == 2) {
        String categoryName = categoryParts[0];
        Color color = Color(int.parse(categoryParts[1]));
        categoryAcc[categoryName] = color;
      }
      return categoryAcc;
    });

    acc[walletName] = categories;
    return acc;
  });
}

Map<String, int> totalFromString(String totalString) {
  return Map<String, int>.fromEntries(
    totalString.split("|").map((entryString) {
      List<String> entryParts = entryString.split(":");
      return MapEntry(entryParts[0], int.parse(entryParts[1]));
    }),
  );
}

Future<void> saveDataToSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Guardar wallets
  List<String> walletsStrings = globalWallets.map((wallet) => walletToString(wallet)).toList();
  await prefs.setStringList('wallets', walletsStrings);

  // Guardar colorsByCategory
  await prefs.setString('colorsByCategory', colorsByCategoryToString(colorsByCategory));

  // Guardar globalData
  await prefs.setString('globalData', globalDataToString(globalData));

  // Guardar totales
  await prefs.setString('totalGastos', totalToString(totalGastosPorWallet));
  await prefs.setString('totalIngresos', totalToString(totalIngresosPorWallet));
}

Future<void> leerShared() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Leer wallets
  List<String>? walletsStrings = prefs.getStringList('wallets');
  if (walletsStrings != null && walletsStrings.isNotEmpty) {
    globalWallets = walletsStrings.map((walletString) => walletFromString(walletString)).toList();
  }

  // Leer colorsByCategory
  String? colorsString = prefs.getString('colorsByCategory');
  if (colorsString != null && colorsString.isNotEmpty) {
    colorsByCategory = colorsByCategoryFromString(colorsString);
  }

  // Leer globalData
  String? globalDataString = prefs.getString('globalData');
  if (globalDataString != null && globalDataString.isNotEmpty) {
    globalData = globalDataFromString(globalDataString);
  }

  String? totalGastosString = prefs.getString('totalGastos');
  if (totalGastosString != null && totalGastosString.isNotEmpty) {
    totalGastosPorWallet = totalFromString(totalGastosString);
  }

  // Leer totales de ingresos
  String? totalIngresosString = prefs.getString('totalIngresos');
  if (totalIngresosString != null && totalIngresosString.isNotEmpty) {
    totalIngresosPorWallet = totalFromString(totalIngresosString);
  }
}
