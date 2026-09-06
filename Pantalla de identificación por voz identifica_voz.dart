import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '/services/api_client.dart';
import '/metodos/selecciona/detalle_muestra/detalle_producto.dart';

class IdentificaVozPage extends StatefulWidget {
  const IdentificaVozPage({super.key});
  @override
  State<IdentificaVozPage> createState() => _IdentificaVozPageState();
}

class _IdentificaVozPageState extends State<IdentificaVozPage> {
  final SpeechToText _stt = SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;
  String _recognized = '';
  String? _localeId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    // 1) Permiso de micrófono
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mic.isPermanentlyDenied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('El micrófono está bloqueado. Abre Ajustes para permitirlo.'),
            action: SnackBarAction(label: 'Ajustes', onPressed: openAppSettings),
          ),
        );
      }
      setState(() => _speechAvailable = false);
      return;
    }

    // 2) Inicializa motor de voz (protegido con try/catch por si lanza PlatformException)
    bool ok = false;
    try {
      ok = await _stt.initialize(
        onStatus: (s) => debugPrint('STT status: $s'),
        onError:  (e) => debugPrint('STT error:  $e'),
      );
    } on PlatformException catch (e) {
      debugPrint('STT init PlatformException: $e');
      ok = false;
    }

    // 3) Idioma
    String? locale = (await _stt.systemLocale())?.localeId;
    locale ??= 'es-MX';

    if (!mounted) return;
    setState(() {
      _speechAvailable = ok;
      _localeId = locale;
    });

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reconocimiento no disponible. Actualiza "Google" y "Speech Services by Google", '
                'y habilita Entrada de voz en Ajustes.',
          ),
        ),
      );
    }
  }

  Future<void> _start() async {
    if (!_speechAvailable) {
      await _initSpeech(); // reintenta por si recién habilitaste algo
      if (!_speechAvailable) return;
    }
    setState(() {
      _recognized = '';
      _listening = true;
    });
    await _stt.listen(
      localeId: _localeId,
      listenMode: ListenMode.search, // frases cortas (búsqueda)
      onResult: (r) {
        setState(() => _recognized = r.recognizedWords);
        if (r.finalResult) _stop();
      },
    );
  }

  Future<void> _stop() async {
    await _stt.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _send() async {
    final q = _recognized.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay texto reconocido')),
      );
      return;
    }
    setState(() => _sending = true);

    try {
      final res = await ApiClient.I.dio.get(
        '/catalogoproducto/search',
        queryParameters: {'nombre': q},          // usa la variable q
      );

      // Normaliza a List<Map<String,dynamic>>
      final List<Map<String, dynamic>> items =
      (res.data is List ? res.data : (res.data['items'] ?? []))
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin coincidencias')),
        );
        return;
      }

      Map<String, dynamic>? producto;

      if (items.length == 1) {
        // Un solo resultado detalle directo
        producto = items.first;
      } else {
        // Varios dejar elegir uno
        producto = await _elegirProducto(items);
        if (producto == null) return; // usuario canceló
      }

      // Abrir detalle ( pasa 'producto', no 'items')
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalleProductoPage(producto: producto!)),
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
  Future<Map<String, dynamic>?> _elegirProducto(
      List<Map<String, dynamic>> items,
      ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p   = items[i];
              final nom = (p['nombre'] ?? p['Nombre'] ?? '').toString();
              final mar = (p['marca']  ?? p['Marca']  ?? '').toString();
              return ListTile(
                title: Text(nom.isEmpty ? '(Sin nombre)' : nom),
                subtitle: mar.isNotEmpty ? Text('Marca: $mar') : null,
                onTap: () => Navigator.pop(ctx, p),   // devuelve el elegido
              );
            },
          ),
        );
      },
    );
  }



  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_listening && _recognized.trim().isNotEmpty && !_sending;

    return Scaffold(
      appBar: AppBar(title: const Text('Identificación por voz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_speechAvailable)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'El reconocimiento de voz no está disponible.\n'
                        '1) Permite el micrófono\n'
                        '2) Actualiza "Google" y "Speech Services by Google"\n'
                        '3) Habilita "Entrada de voz" (Gboard)',
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Texto reconocido
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _recognized.isEmpty
                        Toca el micrófono y comienza a hablar
                        : _recognized,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Controles
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(_listening ? Icons.stop : Icons.mic),
                    label: Text(_listening ? 'Detener' : 'Comenzar'),
                    onPressed: !_speechAvailable
                        ? _initSpeech
                        : (_listening ? _stop : _start),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: Text(_sending ? 'Enviando...' : 'Buscar'),
                    onPressed: canSend ? _send : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
