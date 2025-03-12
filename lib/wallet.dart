import 'package:contabilidad/auxiliares.dart';
import 'package:contabilidad/gastos_ingresos.dart';
import 'package:contabilidad/globales.dart';
import 'package:contabilidad/grafico.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class WalletScreen extends StatefulWidget {
  final WalletEntity wallet;

  const WalletScreen({super.key, required this.wallet});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<CategoryEntity> categories = []; // Lista para almacenar las categorías
  TextEditingController searchController = TextEditingController();
  String? categoryToHighlight; // Almacena la categoría encontrada
  bool isHighlighted = false; // Flag para manejar el parpadeo
  final ScrollController _scrollController = ScrollController();
  DateTime? startDate = DateTime(2000); //fecha de inicio del gráfico
  DateTime? endDate = DateTime.now(); //fecha de fin del gráfico
  int totalGastos = 0;
  int totalIngresos = 0;

  // Función para mostrar un diálogo y pedir el nombre de la categoría
  void _addCategory() {
    String categoryName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900, // Fondo gris oscuro
          title: const Text('Nombre de la categoría', style: TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (value) {
              if (value.length <= 20) {
                categoryName = value;
              }
            },
            maxLength: 25, // Limitar a 25 caracteres
            decoration: const InputDecoration(
              hintText: 'Ingrese el nombre',
              hintStyle: TextStyle(color: Colors.grey),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            style: const TextStyle(color: Colors.white),
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
                final prohibitedCharacters = RegExp(r'[!@#\$%^&*(),.?":{}|<>];');

                if (categoryName.isEmpty || prohibitedCharacters.hasMatch(categoryName)) {
                  // Mostrar un AlertDialog para el error de caracteres prohibidos
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey.shade900,
                        title: const Text('Error', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'El nombre contiene caracteres prohibidos',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
                          ),
                        ],
                      );
                    },
                  );
                } else if (categories.any((cat) => cat.name.toLowerCase() == categoryName.toLowerCase())) {
                  // Mostrar un AlertDialog para el error de nombre duplicado
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey.shade900,
                        title: const Text('Error', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Ya existe una categoría con ese nombre',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Agregar la categoría si no hay errores
                  setState(() {
                    categories.add(
                        CategoryEntity(name: categoryName, gastos: 0, ingresos: 0)); // Agregar la categoría con monto inicial 0
                    // Guardar inmediatamente la categoría en globalData
                    if (globalData[widget.wallet.name] == null) {
                      globalData[widget.wallet.name] = {}; // Crear el mapa para la wallet si no existe
                    }
                    globalData[widget.wallet.name]![categoryName] = []; // Guardar la categoría vacía
                    saveDataToSharedPreferences();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  //función para cambiar el nombre de la categoría
  void _editCategory(int index) {
    String newCategoryName = categories[index].name; // El nombre actual de la categoría
    String oldCategoryName = categories[index].name; // Almacenar el nombre antiguo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900, // Fondo gris oscuro
          title: const Text('Editar nombre', style: TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (value) {
              if (value.length <= 20) {
                newCategoryName = value; // Actualizar el nombre temporalmente
              }
            },
            maxLength: 25, // Limitar a 25 caracteres
            controller: TextEditingController(text: categories[index].name), // Mostrar el nombre actual
            decoration: const InputDecoration(
              hintText: 'Ingrese un nuevo nombre',
              hintStyle: TextStyle(color: Colors.grey),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo sin editar
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                final prohibitedCharacters = RegExp(r'[!@#\$%^&*(),.?":{}|<>];');

                // Verificar si hay caracteres prohibidos
                if (newCategoryName.isEmpty || prohibitedCharacters.hasMatch(newCategoryName)) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey.shade900,
                        title: const Text('Error', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'El nombre contiene caracteres prohibidos',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
                          ),
                        ],
                      );
                    },
                  );
                }
                // Verificar si el nombre ya existe en otra categoría
                else if (categories
                    .any((cat) => cat.name.toLowerCase() == newCategoryName.toLowerCase() && cat != categories[index])) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey.shade900,
                        title: const Text('Error', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Ya existe una categoría con ese nombre',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Si no hay errores, actualizar el nombre de la categoría
                  setState(() {
                    categories[index].name = newCategoryName;

                    // Actualizar el nombre en la estructura global
                    if (globalData[widget.wallet.name] != null) {
                      var categoryData = globalData[widget.wallet.name]![oldCategoryName];
                      globalData[widget.wallet.name]!.remove(oldCategoryName); // Eliminar la antigua entrada
                      globalData[widget.wallet.name]![newCategoryName] = categoryData ?? []; // Asignar los datos al nuevo nombre
                    }
                    saveDataToSharedPreferences();
                  });
                  Navigator.of(context).pop(); // Cerrar el diálogo
                }
              },
              child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _resetCategories() {
    setState(() {
      for (var category in categories) {
        // Restablecer el monto de cada categoría a cero
        category.gastos = 0;
        category.ingresos = 0;

        // Borrar el contenido de la categoría en la estructura global
        if (globalData[widget.wallet.name] != null && globalData[widget.wallet.name]![category.name] != null) {
          globalData[widget.wallet.name]![category.name] = []; // Eliminar los items, pero no la categoría
        }
      }

      // También actualizar los totales de ingresos y gastos para esta wallet
      totalGastosPorWallet[widget.wallet.name] = 0;
      totalIngresosPorWallet[widget.wallet.name] = 0;
    });
    saveDataToSharedPreferences();
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          content: const Text(
            'Está seguro que desea reiniciar todas las categorías? Esta acción es irreversible.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo sin reiniciar
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontSize: 18)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _resetCategories(); // Llamar a la función de reinicio
              },
              child: const Text('Aceptar', style: TextStyle(color: Colors.green, fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  void _selectColor(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: categories[index].color, // Color actual de la categoría
              onColorChanged: (Color color) {
                setState(() {
                  categories[index].color = color; // Actualizar el color de la categoría

                  // Guardar el color en la nueva estructura de colores por categoría y wallet
                  if (colorsByCategory[widget.wallet.name] == null) {
                    colorsByCategory[widget.wallet.name] = {};
                  }
                  colorsByCategory[widget.wallet.name]![categories[index].name] = color;
                  saveDataToSharedPreferences();
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _scrollToCategory(int index) {
    _scrollController.animateTo(
      index * 100.0, // Ajusta este valor dependiendo de la altura de los elementos
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    // Verificar si ya existen categorías para esta wallet en globalData
    if (globalData[widget.wallet.name] != null) {
      categories = globalData[widget.wallet.name]!.entries.map((entry) {
        String categoryName = entry.key;

        // Obtener el color de la categoría desde la estructura colorsByCategory
        Color categoryColor = Colors.grey; // Color por defecto
        if (colorsByCategory[widget.wallet.name] != null && colorsByCategory[widget.wallet.name]![categoryName] != null) {
          categoryColor = colorsByCategory[widget.wallet.name]![categoryName]!;
        }

        // Calcular los gastos e ingresos
        int gastos = entry.value.fold(0, (sum, item) {
          if (item.containsKey('amount') && item['amount'] != null) {
            // Si el monto es negativo, lo consideramos como gasto
            int amount = item['amount'] as int;
            return amount < 0 ? sum + amount.abs() : sum;
          } else {
            return sum;
          }
        });

        int ingresos = entry.value.fold(0, (sum, item) {
          if (item.containsKey('amount') && item['amount'] != null) {
            // Si el monto es positivo, lo consideramos como ingreso
            int amount = item['amount'] as int;
            return amount > 0 ? sum + amount : sum;
          } else {
            return sum;
          }
        });

        // Convertir los datos globales en instancias de CategoryEntity
        return CategoryEntity(
          name: categoryName,
          gastos: gastos,
          ingresos: ingresos,
          color: categoryColor, // Asignar el color cargado
        );
      }).toList();
    }
  }

  List<CategoryEntity> getFilteredCategoriesByDateRangeAndType() {
    if (startDate == null || endDate == null) {
      // Si no se seleccionó un rango de fechas, devolvemos las categorías con sus gastos e ingresos originales
      return categories;
    } else {
      return categories.map((category) {
        // Filtrar los ítems de la categoría según el rango de fechas y tipo (ingresos o gastos)
        List<Map<String, dynamic>> filteredItems = globalData[widget.wallet.name]?[category.name]?.where((item) {
              DateTime itemDate = item['date'] as DateTime;
              int amount = item['amount'] as int;
              bool withinDateRange = itemDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                  itemDate.isBefore(endDate!.add(const Duration(days: 1)));
              bool isMatchingType = showIncomes ? amount > 0 : amount < 0; // Filtrar según ingresos o gastos
              return withinDateRange && isMatchingType;
            }).toList() ??
            [];

        // Calcular los gastos e ingresos filtrados
        int filteredGastos = filteredItems.fold(0, (sum, item) {
          int amount = item['amount'] as int;
          return amount < 0 ? sum + amount.abs() : sum; // Solo sumar si es un gasto (monto negativo)
        });

        int filteredIngresos = filteredItems.fold(0, (sum, item) {
          int amount = item['amount'] as int;
          return amount > 0 ? sum + amount : sum; // Solo sumar si es un ingreso (monto positivo)
        });

        // Crear una nueva instancia de la categoría con los valores filtrados
        return CategoryEntity(
          name: category.name,
          gastos: filteredGastos,
          ingresos: filteredIngresos,
          color: category.color,
        );
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el monto de la cuenta desde internalData
    final int montoEnCuenta = (totalIngresosPorWallet[widget.wallet.name] ?? 0) + (totalGastosPorWallet[widget.wallet.name] ?? 0);

// Filtrar las categorías con ingresos positivos
    List<CategoryEntity> positiveCategories = categories.where((category) => category.ingresos > 0).toList();

// Ordenar las categorías
    categories.sort((a, b) {
      int montoA = a.ingresos - a.gastos;
      int montoB = b.ingresos - b.gastos;

      if (montoA != montoB) {
        return montoB.compareTo(montoA); // Mayor a menor por saldo neto (ingresos - gastos)
      } else {
        return a.name.compareTo(b.name); // En caso de empate, orden lexicográfico
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade900, // Fondo gris oscuro
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white), // Icono del drawer de color blanco
        toolbarHeight: 50, // Achicar el AppBar
        flexibleSpace: Stack(
          children: [
            Center(
              child: Text(
                widget.wallet.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              size: 30,
              color: Colors.white, // Icono de la flecha apuntando a sí misma
            ),
            onPressed: () {
              _showResetConfirmationDialog(); // Llamar a la función de reinicio
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.search,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.grey.shade900,
                    title: const Text('Buscar categoría', style: TextStyle(color: Colors.white)),
                    content: TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ingrese nombre de la categoría',
                        hintStyle: TextStyle(color: Colors.grey),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
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
                          String searchQuery = searchController.text.trim();

                          int categoryIndex = categories.indexWhere((cat) => cat.name.toLowerCase() == searchQuery.toLowerCase());

                          if (categoryIndex != -1) {
                            // Si la categoría existe, destacar y desplazar
                            setState(() {
                              categoryToHighlight = searchQuery;
                              isHighlighted = true;
                            });
                            _scrollToCategory(categoryIndex); // Desplazar hacia la categoría
                            Navigator.of(context).pop();
                          } else {
                            // Mostrar mensaje de error si no existe
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.grey.shade900,
                                  content: const Text(
                                    'Categoría no encontrada',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        child: const Text('Buscar', style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.home,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar el monto en la cuenta
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.topCenter, // Centrar en el eje vertical
                child: Text(
                  '\$$montoEnCuenta',
                  style: const TextStyle(fontSize: 28, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800, // Mantener el tono gris
                      borderRadius: BorderRadius.circular(10), // Bordes redondeados
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showIncomes = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey.shade800, // Texto blanco
                        padding: const EdgeInsets.symmetric(vertical: 30), // Botones más chicos
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Borde redondeado
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('Gastos', style: TextStyle(fontSize: 22)),
                          const SizedBox(height: 5), // Espacio entre el texto y el monto
                          Text(
                            '\$${totalGastosPorWallet[widget.wallet.name]?.abs() ?? 0}', // Total de gastos
                            style: const TextStyle(fontSize: 20, color: Colors.red), // Texto rojo para gastos
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  width: 1.5,
                  height: 80,
                  color: Colors.white,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800, // Mantener el tono gris
                      borderRadius: BorderRadius.circular(10), // Bordes redondeados
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showIncomes = true; // true para ingresos
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey.shade800, // Texto blanco
                        padding: const EdgeInsets.symmetric(vertical: 30), // Botones más chicos
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Borde redondeado
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('Ingresos', style: TextStyle(fontSize: 22)),
                          const SizedBox(height: 5), // Espacio entre el texto y el monto
                          Text(
                            '\$${totalIngresosPorWallet[widget.wallet.name]?.abs() ?? 0}', // Total de ingresos
                            style: const TextStyle(fontSize: 20, color: Colors.green), // Texto verde para ingresos
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Container(
              height: 1, // Línea horizontal inferior
              color: Colors.white,
              margin: const EdgeInsets.only(top: 10),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800, // Fondo
                    borderRadius: BorderRadius.circular(20), // Bordes redondeados
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sección "Desde"
                      Padding(
                        padding: const EdgeInsets.only(left: 25),
                        child: Row(
                          children: [
                            const Text('Desde:', style: TextStyle(color: Colors.white)),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () async {
                                final DateTime? pickedStartDate = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedStartDate != null && pickedStartDate != startDate) {
                                  setState(() {
                                    startDate = pickedStartDate;
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white), // Ícono de calendario
                                  const SizedBox(width: 5),
                                  Text(
                                    startDate != null
                                        ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                                        : 'Seleccionar',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Separador horizontal entre "Desde" y "Hasta"
                      const SizedBox(width: 20),
                      // Sección "Hasta"
                      Padding(
                        padding: const EdgeInsets.only(right: 25),
                        child: Row(
                          children: [
                            const Text('Hasta:', style: TextStyle(color: Colors.white)),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () async {
                                final DateTime? pickedEndDate = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedEndDate != null && pickedEndDate != endDate) {
                                  setState(() {
                                    endDate = pickedEndDate;
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white), // Ícono de calendario
                                  const SizedBox(width: 5),
                                  Text(
                                    endDate != null ? '${endDate!.day}/${endDate!.month}/${endDate!.year}' : 'Seleccionar',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 300, // Ajusta la altura según lo que necesites
              child: positiveCategories.isNotEmpty
                  ? PieChartWidget(
                      categories: getFilteredCategoriesByDateRangeAndType(), positive: showIncomes) // Muestra el gráfico normal
                  : const Center(
                      child: Text(
                        "No hay ingresos para mostrar",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
            ),
            // Mostrar las categorías creadas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    bool shouldHighlight = categories[index].name.toLowerCase() == categoryToHighlight?.toLowerCase();

                    return Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          color: shouldHighlight && isHighlighted ? Colors.yellow.shade600 : Colors.grey.shade800,
                          onEnd: () {
                            if (shouldHighlight) {
                              setState(() {
                                isHighlighted = false; // Deja de parpadear después de la animación
                              });
                            }
                          },
                          child: Dismissible(
                            key: Key(categories[index].name),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.grey.shade900,
                                    title: const Text('Eliminar categoría', style: TextStyle(color: Colors.white)),
                                    content: const Text('Esta acción es irreversible',
                                        style: TextStyle(color: Colors.white, fontSize: 20)),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontSize: 20)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text('Aceptar', style: TextStyle(color: Colors.green, fontSize: 20)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              setState(() {
                                totalIngresosPorWallet[widget.wallet.name] =
                                    (totalIngresosPorWallet[widget.wallet.name]! - categories[index].ingresos);
                                totalGastosPorWallet[widget.wallet.name] =
                                    (totalGastosPorWallet[widget.wallet.name]! + categories[index].gastos);
                                globalData[widget.wallet.name]!
                                    .remove(categories[index].name); // Eliminar la categoría de globalData
                                categories.removeAt(index);
                                saveDataToSharedPreferences();
                              });
                            },
                            background: Container(
                              color: Colors.grey.shade900,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(20), // Borde redondeado
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _selectColor(index); // Llamar a la función para seleccionar color
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: categories[index].color, // Usar el color de la categoría
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onLongPress: () {
                                        _editCategory(index);
                                      },
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CategoryDetailScreen(
                                              category: categories[index],
                                              walletName: widget.wallet.name,
                                            ),
                                          ),
                                        );

                                        if (result == true) {
                                          setState(() {});
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          categories[index].name,
                                          style: const TextStyle(fontSize: 18, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${(categories[index].ingresos - categories[index].gastos).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color:
                                          categories[index].ingresos - categories[index].gastos >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10), // Espaciado entre categorías
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      // Botón redondo de "+" en la parte inferior derecha
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: Colors.grey.shade800,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
