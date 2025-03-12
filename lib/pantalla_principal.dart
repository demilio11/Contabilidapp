import 'package:flutter/material.dart';

class AddWallet extends StatefulWidget {
  final Function onAdd; // Esta función se llamará cuando se presione el botón

  const AddWallet({super.key, required this.onAdd});

  @override
  _AddWalletState createState() => _AddWalletState();
}

class _AddWalletState extends State<AddWallet> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onAdd(); // Llamamos a la función para agregar un nuevo cuadrado
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 50),
        ),
      ),
    );
  }
}
