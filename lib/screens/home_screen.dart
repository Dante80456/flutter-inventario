import 'dart:async'; // ✅ AGREGAR ESTA IMPORTACIÓN
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/producto.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  List<Producto> productos = [];
  bool loading = true;
  bool error = false;

  final formatMoney = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

  Future<void> fetchProductos() async {
    setState(() {
      loading = true;
      error = false;
    });
    try {
      final p = await api.getProductos();
      setState(() {
        productos = p;
      });
    } catch (e) {
      setState(() {
        error = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProductos();
  }

  void _openForm({Producto? producto}) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ProductoForm(
          producto: producto,
          onSaved: (Producto p, Uint8List? imagenBytes, String? imagenNombre, bool isNew) async {
  Navigator.of(context).pop();
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (isNew) {
      // CREAR producto nuevo
      await api.crearProductoConImagen(
        nombre: p.nombre,
        cantidad: p.cantidad,
        precio: p.precio,
        imagenBytes: imagenBytes,
        imagenNombre: imagenNombre,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Producto creado'), backgroundColor: Colors.green));
    } else {
      // ACTUALIZAR producto existente - FORMA CORREGIDA
      if (imagenBytes != null && imagenNombre != null) {
        // Si hay nueva imagen
        await api.updateProductoConImagen(
          id: p.id!,
          nombre: p.nombre,
          cantidad: p.cantidad,
          precio: p.precio,
          imagenBytes: imagenBytes,
          imagenNombre: imagenNombre,
        );
      } else {
        // Si NO hay nueva imagen - solo actualizar datos
        await api.updateProducto(p.id!, p);
      }
      messenger.showSnackBar(const SnackBar(content: Text('Producto actualizado'), backgroundColor: Colors.green));
    }
    fetchProductos();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
  }
},
        ),
      ),
    );
  }

  void _confirmDelete(Producto p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar "${p.nombre}"?'),
        content: const Text(
            'Esta acción no se puede deshacer. ¿Deseas eliminar este producto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await api.deleteProducto(p.id!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Producto eliminado'),
                    backgroundColor: Colors.green));
                fetchProductos();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Eliminar'),
          )
        ],
      ),
    );
  }

  Widget _buildList() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudieron cargar los productos.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
                onPressed: fetchProductos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (productos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No hay productos aún', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar primer producto')),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchProductos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: productos.length,
        itemBuilder: (context, i) {
          final p = productos[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openForm(producto: p),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      if (p.imagenUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            p.imagenUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildAvatar(p.nombre),
                          ),
                        )
                      else
                        _buildAvatar(p.nombre),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nombre,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(
                                  'Cantidad: ${p.cantidad}   |   Precio: ${formatMoney.format(p.precio)}',
                                  style:
                                      TextStyle(color: Colors.grey[700])),
                            ]),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openForm(producto: p);
                          } else if (value == 'delete') {
                            _confirmDelete(p);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Editar'))),
                          const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                  leading: Icon(Icons.delete),
                                  title: Text('Eliminar'))),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String nombre) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.green.shade100,
      child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.green)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topBar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Inventario - Minimercado',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: fetchProductos,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          topBar,
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

typedef OnSavedProducto = FutureOr<void> Function(
    Producto producto, Uint8List? imagenBytes, String? imagenNombre, bool isNew);

class ProductoForm extends StatefulWidget {
  final Producto? producto;
  final OnSavedProducto onSaved;

  const ProductoForm({super.key, this.producto, required this.onSaved});

  @override
  State<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _cantidadCtrl;
  late TextEditingController _precioCtrl;
  Uint8List? _imagenBytes;
  String? _imagenNombre;

  bool get isNew => widget.producto == null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.producto?.nombre ?? '');
    _cantidadCtrl =
        TextEditingController(text: widget.producto?.cantidad.toString() ?? '');
    _precioCtrl =
        TextEditingController(text: widget.producto?.precio.toString() ?? '');
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _imagenBytes = bytes;
        _imagenNombre = imagen.name;
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final nombre = _nombreCtrl.text.trim();
      final cantidad = int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
      final precio = double.tryParse(_precioCtrl.text.trim()) ?? 0.0;

      final producto = Producto(
        id: widget.producto?.id,
        nombre: nombre,
        cantidad: cantidad,
        precio: precio,
        imagenUrl: widget.producto?.imagenUrl,
      );

      widget.onSaved(producto, _imagenBytes, _imagenNombre, isNew);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 6,
              width: 70,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(height: 18),
            Text(isNew ? 'Agregar Producto' : 'Editar Producto',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            // Sección de imágenes
            Column(
              children: [
                // Mostrar imagen actual si existe (solo en edición) O nueva imagen seleccionada
                if (!isNew && widget.producto?.imagenUrl != null && _imagenBytes == null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.producto!.imagenUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Imagen actual',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Mostrar nueva imagen seleccionada
                if (_imagenBytes != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _imagenBytes!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Nueva imagen',
                          style: TextStyle(fontSize: 12, color: Colors.green)),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Botón para seleccionar imagen
                OutlinedButton.icon(
                  onPressed: _seleccionarImagen,
                  icon: const Icon(Icons.image),
                  label: Text(_imagenBytes != null
                      ? 'Cambiar imagen'
                      : 'Seleccionar imagen'),
                ),
                const SizedBox(height: 16),
              ],
            ),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cantidadCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null) return 'Ingresa una cantidad válida';
                      if (n < 0) return 'La cantidad no puede ser negativa';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _precioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Precio (S/)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null) return 'Ingresa un precio válido';
                      if (d < 0) return 'El precio no puede ser negativo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(isNew ? 'Agregar' : 'Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}