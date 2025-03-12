import 'package:contabilidad/auxiliares.dart';
import 'package:contabilidad/globales.dart';
import 'package:flutter/material.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryEntity category;
  final String walletName; // Agregar esta propiedad para la billetera
  const CategoryDetailScreen({super.key, required this.category, required this.walletName});

  @override
  _CategoryDetailScreenState createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<Map<String, dynamic>> items = []; // Inicializar vacía
  Map<String, dynamic>? lastRemovedItem; // Almacenar el último ítem eliminado
  int? lastRemovedIndex; // Almacenar el índice del último ítem eliminado
  ScaffoldMessengerState? _scaffoldMessenger;
  bool isSnackBarActive = false; // Controlar si el SnackBar está activo
  @override
  void initState() {
    super.initState();

    // Cargar los datos de globalData usando walletName y category.name
    items = globalData[widget.walletName]?[widget.category.name] ?? [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context); // Inicializar el ScaffoldMessenger en didChangeDependencies
  }

  @override
  void dispose() {
    // Deshabilitar la función de deshacer y limpiar el SnackBar
    isSnackBarActive = false;
    _scaffoldMessenger?.clearSnackBars();
    super.dispose();
  }

  // Función para agregar un nuevo gasto o ingreso
  void _addItem() {
    String title = '';
    int amount = 0;
    DateTime selectedDate = DateTime.now(); // Fecha inicializada al principio

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text('Nuevo gasto/ingreso', style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      title = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ingrese el título',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      amount = int.tryParse(value) ?? 0;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ingrese el monto (positivo: ingreso, negativo: gasto)',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  // Botón para seleccionar la fecha
                  TextButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate; // Actualizar la fecha seleccionada en el dialog
                        });
                      }
                    },
                    child: Text(
                      'Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                if (title.isNotEmpty && amount != 0) {
                  setState(() {
                    // Solo cuando presiona "Aceptar" se guarda la fecha seleccionada
                    items.insert(0, {'title': title, 'amount': amount, 'date': selectedDate});
                    amount > 0
                        ? widget.category.ingresos += amount
                        : widget.category.gastos -= amount; // Actualizar el monto de la categoría
                    // Verificar si walletName y category.name existen en globalData
                    if (globalData[widget.walletName] == null) {
                      globalData[widget.walletName] = {};
                    }
                    if (globalData[widget.walletName]![widget.category.name] == null) {
                      globalData[widget.walletName]![widget.category.name] = [];
                    }

                    // Actualizar globalData con los nuevos items
                    globalData[widget.walletName]![widget.category.name] = items;
                    addTransaction(widget.walletName, amount); // Actualizar el total en globalData
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar un ítem y mostrar el botón de deshacer
  void _removeItem(int index) {
    setState(() {
      lastRemovedItem = items[index]; // Guardar el último ítem eliminado
      lastRemovedIndex = index; // Guardar el índice del último ítem eliminado
      items.removeAt(index); // Eliminar el ítem de la lista
      lastRemovedItem!['amount'] as int > 0
          ? widget.category.ingresos -= lastRemovedItem!['amount'] as int
          : widget.category.gastos += lastRemovedItem!['amount'] as int; // Ajustar el monto de la categoría
      globalData[widget.walletName]![widget.category.name] = items; // Actualizar la estructura global
      removeTransaction(widget.walletName, lastRemovedItem!['amount'] as int); // Actualizar el total en globalData
    });

    // Activar el SnackBar y la opción de deshacer
    isSnackBarActive = true;

    // Mostrar un Snackbar con la opción de deshacer
    _scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: const Text('Gasto/Ingreso eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            // Solo restaurar si el SnackBar está activo
            if (isSnackBarActive && lastRemovedItem != null && lastRemovedIndex != null) {
              setState(() {
                items.insert(lastRemovedIndex!, lastRemovedItem!); // Restaurar el último ítem eliminado
                lastRemovedItem!['amount'] as int > 0
                    ? widget.category.ingresos += lastRemovedItem!['amount'] as int
                    : widget.category.gastos += lastRemovedItem!['amount'] as int; // Ajustar el monto de la categoría
                if (lastRemovedItem!['amount'] as int > 0) {
                  totalIngresosPorWallet[widget.walletName] =
                      (totalIngresosPorWallet[widget.walletName] ?? 0) + lastRemovedItem!['amount'] as int;
                } else {
                  totalGastosPorWallet[widget.walletName] =
                      (totalGastosPorWallet[widget.walletName] ?? 0) + lastRemovedItem!['amount'] as int;
                }

                globalData[widget.walletName]![widget.category.name] = items; // Actualizar la estructura global
                // Limpiar después de restaurar
                lastRemovedItem = null;
                lastRemovedIndex = null;
              });
            }
          },
        ),
        duration: const Duration(seconds: 5), // Mostrar el botón de deshacer por 5 segundos
        onVisible: () {
          // Desactivar la opción de deshacer después de que el SnackBar desaparezca
          Future.delayed(const Duration(seconds: 5), () {
            isSnackBarActive = false;
          });
        },
      ),
    );
  }

  void addTransaction(String walletName, int amount) {
    if (!totalGastosPorWallet.containsKey(walletName)) {
      totalGastosPorWallet[walletName] = 0; // Inicializar si no existe
    }
    if (!totalIngresosPorWallet.containsKey(walletName)) {
      totalIngresosPorWallet[walletName] = 0; // Inicializar si no existe
    }
    if (amount < 0) {
      // Es un gasto
      totalGastosPorWallet[walletName] = totalGastosPorWallet[walletName]! + amount;
    } else {
      // Es un ingreso
      totalIngresosPorWallet[walletName] = totalIngresosPorWallet[walletName]! + amount;
    }
    saveDataToSharedPreferences();
  }

  void removeTransaction(String walletName, int amount) {
    if (amount < 0) {
      // Es un gasto
      if (totalGastosPorWallet.containsKey(walletName)) {
        totalGastosPorWallet[walletName] = totalGastosPorWallet[walletName]! - amount;
      }
    } else {
      // Es un ingreso
      if (totalIngresosPorWallet.containsKey(walletName)) {
        totalIngresosPorWallet[walletName] = totalIngresosPorWallet[walletName]! - amount;
      }
    }
    saveDataToSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> itemsByDate = {};

    // Filtrar ítems para no mostrar los "fantasmas"
    List<Map<String, dynamic>> filteredItems = items.where((item) {
      return item['amount'] != 0 || (item['title'] != null && item['title']!.isNotEmpty);
    }).toList();

    // Agrupar los ítems filtrados por fecha
    for (var item in filteredItems) {
      // Cambiar items por filteredItems
      String formattedDate;
      if (item.containsKey('date') && item['date'] != null) {
        DateTime date = item['date'] as DateTime;
        formattedDate = "${date.day}/${date.month}/${date.year}";
      } else {
        DateTime defaultDate = DateTime.now();
        formattedDate = "${defaultDate.day}/${defaultDate.month}/${defaultDate.year}";
      }
      if (!itemsByDate.containsKey(formattedDate)) {
        itemsByDate[formattedDate] = [];
      }
      itemsByDate[formattedDate]!.add(item);
    }

    // Ordenar las fechas de manera descendente
    List<String> sortedDates = itemsByDate.keys.toList()
      ..sort((a, b) {
        List<String> dateAComponents = a.split('/');
        List<String> dateBComponents = b.split('/');

        DateTime dateA = DateTime(
          int.parse(dateAComponents[2]), // Año
          int.parse(dateAComponents[1]), // Mes
          int.parse(dateAComponents[0]), // Día
        );

        DateTime dateB = DateTime(
          int.parse(dateBComponents[2]), // Año
          int.parse(dateBComponents[1]), // Mes
          int.parse(dateBComponents[0]), // Día
        );

        return dateB.compareTo(dateA); // Ordenar de más reciente a más antiguo
      });

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, true); // Volver a la pantalla anterior
          },
        ),
        centerTitle: true,
        title: Text(widget.category.name, style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mostrar el monto actual de la categoría
            Text(
              'Monto total: \$${widget.category.ingresos}',
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: sortedDates.map((date) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const Divider(color: Colors.white),
                      Column(
                        children: itemsByDate[date]!.map((item) {
                          return Dismissible(
                            key: Key(item['title'] ?? 'item-${filteredItems.indexOf(item)}'),
                            direction: DismissDirection.endToStart, // Deslizar a la izquierda para eliminar
                            onDismissed: (direction) {
                              _removeItem(filteredItems.indexOf(item)); // Llamar a la función para eliminar el ítem
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.grey.shade900,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ), // Sin cambio de color de fondo
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(10), // Bordes redondeados
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Título del ítem (limitar a 30 caracteres y truncar si es necesario)
                                  Expanded(
                                    child: Text(
                                      (item['title'] != null && item['title'].length > 30)
                                          ? "${item['title'].substring(0, 30)}..."
                                          : (item['title'] ?? 'Sin título'),
                                      style: const TextStyle(color: Colors.white, fontSize: 18),
                                      maxLines: 1, // Limitar a una línea
                                      overflow: TextOverflow.ellipsis, // Truncar con '...'
                                    ),
                                  ),
                                  // Monto del ítem (limitar a 12 cifras)
                                  Text(
                                    item.containsKey('amount') && item['amount'] != null // Verificar si existe el campo 'amount'
                                        ? (item['amount'].toString().length > 12
                                            ? item['amount'].toString().substring(0, 12)
                                            : item['amount'] >= 0
                                                ? '+\$${item['amount']}'
                                                : '-\$${item['amount']}')
                                        : 'Monto no disponible', // Mostrar el mensaje si el campo no existe
                                    style: TextStyle(
                                      color: item['amount'] != null && item['amount'] >= 0 ? Colors.green : Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.grey.shade800,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
