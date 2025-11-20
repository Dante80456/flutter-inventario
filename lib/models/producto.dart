class Producto {
  final int? id;
  final String nombre;
  final int cantidad;
  final double precio;
  final String? imagenUrl;

  Producto({
    this.id,
    required this.nombre,
    required this.cantidad,
    required this.precio,
    this.imagenUrl,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] != null ? int.tryParse(json['cantidad'].toString()) ?? 0 : 0,
      precio: json['precio'] != null ? double.tryParse(json['precio'].toString()) ?? 0.0 : 0.0,
      imagenUrl: json['imagen_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'cantidad': cantidad,
      'precio': precio,
      if (imagenUrl != null) 'imagen_url': imagenUrl,
    };
  }
}