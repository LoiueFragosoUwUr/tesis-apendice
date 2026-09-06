    import 'package:flutter/material.dart';
import '../services/api_client.dart';

class RegistrarDatosPage extends StatefulWidget {
  const RegistrarDatosPage({super.key});

  @override
  State<RegistrarDatosPage> createState() => _RegistrarDatosPageState();

}
/*
  Widget build(BuildContext context) => const Scaffold(
    appBar: AppBar(title: Text('Registrar datos')),
    body: Center(child: Text('Aquí va el formulario de progreso')),
     );
*/

  class _RegistrarDatosPageState extends State<RegistrarDatosPage> {
  final _formKey = GlobalKey<FormState>();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _caderaCtrl = TextEditingController();
  final _comentCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  // Cambia aquí si tu endpoint o el ID es distinto
  static const int progresoId = 1;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    _cinturaCtrl.dispose();
    _caderaCtrl.dispose();
    _comentCtrl.dispose();
    super.dispose();
  }

  double? _toDouble(String s) {
    if (s.trim().isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }

  Future<void> _cargar() async {
    try {
      final r = await ApiClient.I.dio.get('/progreso/$progresoId');
      final data = Map<String, dynamic>.from(r.data);
      _pesoCtrl.text    = (data['peso_kg'] ?? '').toString();
      _alturaCtrl.text  = (data['altura_m'] ?? '').toString();
      _cinturaCtrl.text = (data['cintura_cm'] ?? '').toString();
      _caderaCtrl.text  = (data['cadera_cm'] ?? '').toString();
      _comentCtrl.text  = (data['comentarios'] ?? '').toString();
    } catch (_) {
      // Deja el id inicial como prograso ID 1
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'peso_kg': _toDouble(_pesoCtrl.text),
      'altura_m': _toDouble(_alturaCtrl.text),
      'cintura_cm': _toDouble(_cinturaCtrl.text),
      'cadera_cm': _toDouble(_caderaCtrl.text),
      'comentarios': _comentCtrl.text.trim().isEmpty ? null : _comentCtrl.text.trim(),
      'fecha_medicion': DateTime.now().toIso8601String(),
    };


    setState(() => _saving = true);
    try {
      await ApiClient.I.dio.post('/progreso', data: payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progreso guardado')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _reqPositivo(String? v, {String label = 'valor'}) {
    final d = _toDouble(v ?? '');
    if (d == null) return 'Ingresa $label';
    if (d <= 0) return '$label debe ser mayor que 0';
    return null;
    // Nota: altura_m > 0 (en metros) y peso_kg > 0
  }

  String? _opcionalPositivo(String? v, {String label = 'valor'}) {
    if ((v ?? '').trim().isEmpty) return null;
    final d = _toDouble(v!);
    if (d == null) return 'Número inválido en $label';
    if (d <= 0) return '$label debe ser mayor que 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar progreso (ID 1)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _pesoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    hintText: 'Ej. 74.2',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _reqPositivo(v, label: 'peso'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _alturaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Altura (m)',
                    hintText: 'Ej. 1.75',
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _reqPositivo(v, label: 'altura'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cinturaCtrl,
                  decoration: const InputDecoration(
                    labelText: Cintura (cm)  opcional,
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      _opcionalPositivo(v, label: 'cintura'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _caderaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cadera (cm)  opcional',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _opcionalPositivo(v, label: 'cadera'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comentarios (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Guardando...' : 'Guardar'),
                    onPressed: _saving ? null : _guardar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
