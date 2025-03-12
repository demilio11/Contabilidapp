import 'dart:ui';
import 'package:contabilidad/auxiliares.dart';
import 'package:contabilidad/globales.dart';
import 'package:contabilidad/pantalla_principal.dart';
import 'package:contabilidad/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Contabilidad(),
    );
  }
}

class Contabilidad extends StatefulWidget {
  const Contabilidad({super.key});

  @override
  State<Contabilidad> createState() => _ContabilidadState();
}

class _ContabilidadState extends State<Contabilidad> {
  List<Widget> walletList = []; // Lista para manejar los cuadrados
  bool _showDeleteArea = false; // Para mostrar o no el área de borrado de wallets
  @override
  void initState() {
    super.initState();

    // Llamar a leerShared y luego actualizar el estado
    leerShared().then((_) {
      setState(() {
        // Si hay wallets en globalWallets, las cargamos
        if (globalWallets.isNotEmpty) {
          for (int i = 0; i < globalWallets.length; i++) {
            walletList.add(_buildWallet(i)); // Agregar cada billetera a la lista
          }
        }

        // Siempre agregar el botón de añadir
        walletList.add(AddWallet(onAdd: _addWallet));
      });
    });
  }

  // Función para crear la billetera
  Widget _buildWallet(int index) {
    WalletEntity wallet;
    if (globalWallets.isEmpty) {
      //esto es necesario pq la primera se construye tarde, debido a que se crea en el initState
      wallet = WalletEntity(name: 'Wallet 1', internalData: [
        [0]
      ]);
    } else {
      wallet = globalWallets[index]; // Obtener la wallet correspondiente
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WalletScreen(wallet: wallet)),
        );
      },
      child: DragTarget<int>(onAcceptWithDetails: (draggedIndex) {
        _swapWallets(draggedIndex.data, index); // Intercambiar las billeteras
      }, builder: (context, candidateData, rejectedData) {
        return Draggable<int>(
          data: index, // El objeto que arrastro
          feedback: _buildWalletFeedback(), // Cómo se ve la wallet al arrastrarla
          childWhenDragging: Container(), // Dejar vacío mientras se arrastra
          onDragStarted: () {
            setState(() {
              _showDeleteArea = true; // Mostrar el área de eliminación
            });
          },
          onDraggableCanceled: (_, __) {
            setState(() {
              _showDeleteArea = false; // Ocultar el área si se cancela
            });
          },
          onDragEnd: (_) {
            setState(() {
              _showDeleteArea = false; // Ocultar el área después del arrastre
            });
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: gris,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(wallet.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26)),
            ),
          ),
        );
      }),
    );
  }

  // Función para mostrar cómo se verá la billetera mientras se arrastra
  Widget _buildWalletFeedback() {
    return Opacity(
      opacity: 0.7,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: gris,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Función para agregar una nueva billetera
  void _addWallet() {
    String walletName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900, // Cambiar el fondo a gris oscuro
          content: TextField(
            autofocus: true, // Para que el cursor parpadee automáticamente
            cursorColor: Colors.white, // Cambiar el color del cursor
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              // Restringir emojis y caracteres especiales
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s;/]')),
            ],
            style: const TextStyle(color: Colors.white, fontSize: 22),
            onChanged: (value) {
              walletName = value; // Almacenar el nombre ingresado
            },
            decoration: const InputDecoration(
              hintText: "Ingrese un nombre", // Texto de sugerencia
              hintStyle: TextStyle(color: Colors.grey, fontSize: 22), // Cambiar estilo del hint
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white), // Color del borde cuando está enfocado
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar sin crear la wallet
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ),
            TextButton(
              onPressed: () {
                if (walletName.isNotEmpty) {
                  // Crear la nueva wallet con el nombre ingresado
                  setState(() {
                    globalWallets.add(WalletEntity(
                      name: walletName,
                      internalData: [
                        [0]
                      ],
                    ));

                    // Reemplazar el botón + con la nueva billetera
                    walletList[walletList.length - 1] = _buildWallet(walletList.length - 1);

                    // Agregar el botón + en la siguiente posición
                    walletList.add(AddWallet(onAdd: _addWallet));
                    saveDataToSharedPreferences();
                  });
                }
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.green, fontSize: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar una billetera
  void _removeWallet(int index) {
    setState(() {
      String walletName = globalWallets[index].name;

      // Eliminar la wallet de globalWallets
      globalWallets.removeAt(index);

      // Eliminar la wallet de la lista visual
      walletList.removeAt(index);

      // Eliminar la wallet de los mapas de gastos e ingresos
      totalGastosPorWallet.remove(walletName);
      totalIngresosPorWallet.remove(walletName);
      globalData.remove(walletName);
      // Guardar los cambios en SharedPreferences
      saveDataToSharedPreferences();
    });
  }

  void _swapWallets(int fromIndex, int toIndex) {
    setState(() {
      // Intercambiar los elementos en la lista
      if (fromIndex != toIndex) {
        final temp = walletList[fromIndex];
        walletList[fromIndex] = walletList[toIndex];
        walletList[toIndex] = temp;

        // Intercambiar las posiciones en la lista globalWallets
        final tempWallet = globalWallets[fromIndex];
        globalWallets[fromIndex] = globalWallets[toIndex];
        globalWallets[toIndex] = tempWallet;
      }
    });
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900, // Cambiar el fondo a gris
          title: const Column(
            children: [
              Icon(
                Icons.warning,
                color: Colors.yellow,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Se eliminará la billetera de forma permanente',
                style: TextStyle(fontSize: 18, color: Colors.white), // Cambiar tamaño de letra y color
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly, // Centrar los botones
          actionsPadding: const EdgeInsets.only(bottom: 20), // Separar los botones del cuadro
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo sin eliminar
              },
              child: const Text(
                'Rechazar',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _removeWallet(index); // Eliminar la billetera
                saveDataToSharedPreferences(); //guardar en shared
              },
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.green, fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Column(
        children: [
          const SizedBox(height: 15),
          const Text("Billeteras:", style: TextStyle(color: Colors.white, fontSize: 30)),
          const SizedBox(height: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: GridView.builder(
                itemCount: walletList.length, // Número de elementos en la lista
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cuadrados por fila
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  // Si estamos en el último elemento, mostrar el botón de agregar
                  if (index == walletList.length - 1) {
                    return AddWallet(onAdd: _addWallet);
                  }
                  return _buildWallet(index); // El índice es generado dinámicamente
                },
              ),
            ),
          ),
          // Si el área de eliminación debe mostrarse, se muestra aquí
          if (_showDeleteArea)
            DragTarget<int>(
              onAcceptWithDetails: (index) {
                _showDeleteConfirmationDialog(index.data); // Eliminar la billetera si es soltada aquí
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: Colors.grey.shade900,
                  height: 100,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 50),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods like buildOverscrollIndicator and buildScrollbar
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
