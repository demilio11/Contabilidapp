import 'package:contabilidad/globales.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Importar la librería de gráficos de pie

class PieChartWidget extends StatelessWidget {
  final List<CategoryEntity> categories;
  final bool positive;

  const PieChartWidget({super.key, required this.categories, required this.positive});

  // Función para construir las secciones del gráfico
  List<PieChartSectionData> _buildPieChartSections() {
    if (positive) {
      double totalAmount = categories.fold(0, (sum, category) => sum + category.ingresos);

      return categories.map((category) {
        final double percentage = (category.ingresos / totalAmount) * 100;
        return PieChartSectionData(
          color: category.color, // Usa el color asignado a cada categoría
          value: category.ingresos.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%', // Mostrar porcentaje
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    } else {
      double totalAmount = categories.fold(0, (sum, category) => sum + category.gastos);

      return categories.map((category) {
        final double percentage = (category.gastos / totalAmount) * 100;
        return PieChartSectionData(
          color: category.color, // Usa el color asignado a cada categoría
          value: category.gastos.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%', // Mostrar porcentaje
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: PieChart(
        PieChartData(
          sections: _buildPieChartSections(),
          centerSpaceRadius: 80,
          sectionsSpace: 4,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
