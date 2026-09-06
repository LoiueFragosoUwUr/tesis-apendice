// lib/paginas/identificacion_texto_page.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '/services/api_client.dart';
import '/metodos/selecciona/detalle_muestra/detalle_producto.dart';
const String _searchPath = '/catalogoproducto/search';


class IdentificaTexto extends StatefulWidget {
  const IdentificaTexto({super.key});

  @override
  State<IdentificaTexto> createState() => _IdentificaTextoState();
}

class _IdentificaTextoState extends State<IdentificaTexto> {
  final _qCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;
  String _recognized = '';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  Future<void> _send() async {
    final q1 = _recognized.trim();
    if (q1.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay texto reconocido')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final res = await ApiClient.I.dio.get(
        '/catalogoproducto/search',
        queryParameters: {'nombre': q1},

      );

      final List<Map<String, dynamic>> list =
      (res.data is List ? res.data : (res.data['items'] ?? []))
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;
      final r = await ApiClient.I.dio.get('/catalogoproducto/search?nombre=q1');
      final producto = Map<String, dynamic>.from(r.data);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalleProductoPage(producto: producto)),
      );
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();
    final q1 = _qCtrl.text.trim();
    if (q1.isEmpty) {
      setState(() {
        _items = const [];
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.I.dio.get(
        _searchPath,
        queryParameters: {'nombre': q1}, // <- tu backend busca por nombre
      );

      final data = res.data;
      // Acepta formatos: List o {items: [...]}
      final List list = data is List ? data : (data['items'] ?? []);
      final parsed = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

      setState(() => _items = parsed);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificación por texto'),
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qCtrl,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _buscar(),
                      decoration: InputDecoration(
                        labelText: 'Nombre de producto',
                        hintText: 'Ej. Avena Integral',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _qCtrl.text.isEmpty
                            ? null
                            : IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _qCtrl.clear();
                            setState(() {
                              _items = const [];
                              _error = null;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _loading ? null : _buscar,
                    icon: const Icon(Icons.manage_search),
                    label: const Text('Buscar'),
                  ),
                ],
              ),
            ),
          ),

          if (_loading) const LinearProgressIndicator(),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Error: $_error',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ),

          Expanded(
            child: _items.isEmpty && !_loading && _error == null
                ? const _VacioView()
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = _items[i];
                final nombre = (p['nombre'] ?? p['Nombre'] ?? '').toString();
                final marca = (p['marca'] ?? p['Marca'] ?? '').toString();
                final categoria = (p['categoria'] ?? p['Categoria'] ?? '').toString();
                final esUltra = (p['esultraprocesado'] ?? p['EsUltraprocesado'] ?? false) == true;
                final desc = (p['descripcion'] ?? p['Descripcion'] ?? '').toString();

                return Card(
                  elevation: 1.5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    title: Text(
                      nombre.isEmpty ? '(Sin nombre)' : nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (marca.isNotEmpty) Text('Marca: $marca'),
                        if (categoria.isNotEmpty) Text('Categoría: $categoria'),
                        if (desc.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: esUltra ? Colors.red.withOpacity(.12) : Colors.green.withOpacity(.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            esUltra ? 'Ultraprocesado' : 'No ultra',
                            style: TextStyle(
                              color: esUltra ? Colors.red.shade700 : Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Regresa el producto seleccionado a la pantalla anterior (opcional)
                      Navigator.pop(context, p);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VacioView extends StatelessWidget {
  const _VacioView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          Escribe un nombre y presiona Buscar(se quitaron comillas por error de latex). 
              'Aquí verás los productos de tu tabla catalogoproducto.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
