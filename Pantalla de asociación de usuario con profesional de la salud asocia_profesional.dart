    // lib/asocia_profesional.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class AsociaProfesionalPage extends StatefulWidget {
  const AsociaProfesionalPage({super.key});
  @override
  State<AsociaProfesionalPage> createState() => _AsociaProfesionalPageState();
}

class _AsociaProfesionalPageState extends State<AsociaProfesionalPage> {
  final _searchCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  List<ProfesionalLite> _items = [];
  ProfesionalLite? _sel;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({String? q}) async {
    setState(() => _loading = true);
    final r = await ApiClient.I.dio.get('/profesionales', queryParameters: {
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),

    });
    final list = (r.data as List)
        .map((e) => ProfesionalLite.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _guardar() async {
    if (_sel == null) return;
    setState(() => _saving = true);
    try {
      await ApiClient.I.dio.post('/atencion', data: {
        'profesional_user_id': _sel!.userId,
        'estado': 'activo',
        'notas': _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
        'fecha_inicio': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asociación creada')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asociar profesional')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Buscador
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar (nombre, cédula, especialidad)',
                    ),
                    onSubmitted: (v) => _fetch(q: v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _fetch(q: _searchCtrl.text),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = _items[i];
                  final selected = _sel?.userId == p.userId;
                  return ListTile(
                    leading: Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    ),
                    title: Text(p.nombreCompleto),
                    subtitle: Text(
                      [
                        if (p.cedula != null) 'Cédula: ${p.cedula}',
                        if (p.especialidad != null) 'Esp: ${p.especialidad}',
                      ]. join(" punto " (se le pusieron comillas por error de latex)),
                    ),
                    onTap: () => setState(() => _sel = p),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            TextField(
              controller: _notasCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Botón asociar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.link),
                label: Text(_saving
                    ? 'Asociando...'
                    : (_sel == null ? 'Selecciona un profesional' : 'Asociar a ${_sel!.nombreCompleto}')),
                onPressed: (_sel == null || _saving) ? null : _guardar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
