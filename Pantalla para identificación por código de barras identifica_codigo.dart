import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '/services/api_client.dart';
import '/metodos/selecciona/detalle_muestra/detalle_producto.dart';


class EscanerBarrasPage extends StatefulWidget {
  const EscanerBarrasPage({super.key});

  @override
  State<EscanerBarrasPage> createState() => _EscanerBarrasPageState();
}

class _EscanerBarrasPageState extends State<EscanerBarrasPage> {
  final _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
    // Agregar formatos básics de codigos de barras para alimentos
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );

  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String code) async {
    try {// Manda a llamar a la APO para buscar por código
      final r = await ApiClient.I.dio.get('/catalogoproducto/barcode/$code');
      final producto = Map<String, dynamic>.from(r.data);

      if (!mounted) return;

      // Abrir la pagina de detalle producto
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalleProductoPage(producto: producto)),
      );

      await _controller.start();
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto no encontrado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
      await _controller.start();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      await _controller.start();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código de barras'),
        actions: [
          // Permite encender o apagar led del teléfono móvil
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final torch = state.torchState;
              final disabled = torch == TorchState.unavailable;
              return IconButton(
                tooltip: torch == TorchState.on ? 'Apagar linterna' : 'Encender linterna',
                icon: Icon(torch == TorchState.on ? Icons.flash_on : Icons.flash_off),
                onPressed: disabled ? null : () => _controller.toggleTorch(),
              );
            },
          ),
          // Cambia la cámara
          IconButton(
            tooltip: 'Cambiar cámara',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final raw = capture.barcodes.firstOrNull?.rawValue;
              if (raw == null || raw.isEmpty || _processing) return;
              _processing = true;         // bandera/señalizacion para interna/led del teléfono (sin setState)
              _controller.stop();
              _handleBarcode(raw);
            },
          ),


          IgnorePointer(
            ignoring: true,
            child: Center(
              child: Container(
                width: 260,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 3),
                ),
              ),
            ),
          ),

          if (_processing)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
