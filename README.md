#general: El proyecto solo usa almacenamiento local, no utilizar bases de datos ni cuentas
#auxiliares.dart:
    En auxiliares tenemos funciones que convierten estructuras de datos complejas a strings o listas y viceversa, con el objetivo de poder guardarlas en shared, ademas están las funciones de lectura y escritura en shared, para mantener la info de manera local.
#gastos_ingresos:
    Acá se gestionan los movimientos individuales dentro de una categoría, se enlistan por fecha de inserción y el usuario puede manipular intencionalmente la fecha según su disposición
#globales:
    Tenemos las dos clases fundamentales, Wallet y Category, las cuales almacenan información crucial para la app.
#grafico:
    El gráfico recibe un booleano, el cual determina si graficará los valores positivos o negativos de las categorias.
#main.dart: 
    La pantalla de inicio, donde se crean, borran e intercambian las billeteras
#wallet.dart:
    La pantalla principal de cada wallet, donde se crean/borran/renombran categorias, se observa el gráfico y se elije si uno quiere verlo de gastos o de ingresos.