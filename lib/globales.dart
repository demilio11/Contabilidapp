import 'package:flutter/material.dart';

Function estadoPrincipal = () {};
bool showIncomes = true; // true para ingresos, false para gastos

class WalletEntity {
  String name;
  List<List<dynamic>> internalData; // Lista de listas para almacenar datos internos

  WalletEntity({required this.name, required this.internalData});
}

// Lista global para almacenar todas las wallets
List<WalletEntity> globalWallets = [];

class CategoryEntity {
  String name;
  int gastos;
  int ingresos;
  Color color; // Nueva propiedad para el color

  CategoryEntity({
    required this.name,
    required this.gastos,
    required this.ingresos,
    this.color = Colors.grey,
  });
}

Map<String, Map<String, List<Map<String, dynamic>>>> globalData = {
  // Billetera -> Categoría -> Lista de conceptos (gastos/ingresos)
};
Map<String, Map<String, Color>> colorsByCategory = {};
Map<String, int> totalGastosPorWallet = {};
Map<String, int> totalIngresosPorWallet = {};

const Color fondo = Color.fromARGB(255, 0, 0, 0);
const Color gris = Color.fromARGB(255, 82, 82, 82);
