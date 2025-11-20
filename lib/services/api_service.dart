import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/producto.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'https://minimercadito-appservice-hncgbshndfahc4c0.canadacentral-01.azurewebsites.net/api';

  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<List<Producto>> getProductos() async {
    final uri = Uri.parse('$baseUrl/productos');
    final res = await client.get(uri);
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Producto.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener productos: ${res.statusCode}');
    }
  }

  // Crear producto con imagen
  Future<void> crearProductoConImagen({
    required String nombre,
    required int cantidad,
    required double precio,
    Uint8List? imagenBytes,
    String? imagenNombre,
  }) async {
    final uri = Uri.parse('$baseUrl/productos');
    final request = http.MultipartRequest('POST', uri);

    request.fields['nombre'] = nombre;
    request.fields['cantidad'] = cantidad.toString();
    request.fields['precio'] = precio.toString();

    if (imagenBytes != null && imagenNombre != null) {
      // Determinar el tipo MIME basado en la extensión del archivo
      String mimeType = 'image/jpeg'; // por defecto
      if (imagenNombre.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (imagenNombre.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (imagenNombre.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          imagenBytes,
          filename: imagenNombre,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode != 201) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Error al crear producto: ${response.statusCode} - $errorBody');
    }
  }

  // Actualizar producto CON imagen
  Future<void> updateProductoConImagen({
    required int id,
    required String nombre,
    required int cantidad,
    required double precio,
    required Uint8List imagenBytes, // Cambiado a required
    required String imagenNombre,   // Cambiado a required
  }) async {
    final uri = Uri.parse('$baseUrl/productos/$id');
    final request = http.MultipartRequest('PUT', uri);

    request.fields['nombre'] = nombre;
    request.fields['cantidad'] = cantidad.toString();
    request.fields['precio'] = precio.toString();

    // Determinar el tipo MIME basado en la extensión del archivo
    String mimeType = 'image/jpeg';
    if (imagenNombre.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else if (imagenNombre.toLowerCase().endsWith('.gif')) {
      mimeType = 'image/gif';
    } else if (imagenNombre.toLowerCase().endsWith('.webp')) {
      mimeType = 'image/webp';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'imagen',
        imagenBytes,
        filename: imagenNombre,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Error al actualizar producto: ${response.statusCode} - $errorBody');
    }
  }

  // Actualizar producto SIN imagen - CORREGIDO
  Future<void> updateProducto(int id, Producto p) async {
    final uri = Uri.parse('$baseUrl/productos/$id');
    
    // Usar http.put normal en lugar de MultipartRequest
    final res = await client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': p.nombre,
        'cantidad': p.cantidad,
        'precio': p.precio,
      }),
    );
    
    if (res.statusCode != 200) {
      throw Exception('Error al actualizar producto: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteProducto(int id) async {
    final uri = Uri.parse('$baseUrl/productos/$id');
    final res = await client.delete(uri);
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    } else {
      throw Exception('Error al eliminar producto: ${res.statusCode} ${res.body}');
    }
  }
}