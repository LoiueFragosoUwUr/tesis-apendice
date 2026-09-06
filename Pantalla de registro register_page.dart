
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();

  final _namesCtrl = TextEditingController();     // Nombres = nombres + Patapellid + Matapellido
  final _paternoCtrl = TextEditingController();   // Apellido paterno
  final _maternoCtrl = TextEditingController();  // Apellido materno
  final _emailCtrl = TextEditingController();    // Email
  final _passCtrl = TextEditingController();     // Contraseña
  final _cedulaCtrl = TextEditingController();   // Cédula (solo profesional)
  final _especialidadCtrl = TextEditingController(); // <-- aquí

  String? _role; // "conventional" | "professional"
  bool _loading = false;

  @override
  void dispose() {
    _namesCtrl.dispose();
    _paternoCtrl.dispose();
    _maternoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _cedulaCtrl.dispose();
    _especialidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Hacemos validos a todos los campos visibles
    if (!_formKey.currentState!.validate()) return;

    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de usuario')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiClient.I.register(
        nombres: _namesCtrl.text.trim(),
        apellidoPaterno: _paternoCtrl.text.trim(),
        apellidoMaterno: _maternoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role!.trim().toLowerCase(),
        cedula: _role == 'professional' ? _cedulaCtrl.text.trim() : null,
        especialidad: _role == 'professional' ? _especialidadCtrl.text.trim() : null,
      );


      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Inicia sesión ')),
      );
      Navigator.pop(context);

    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? e.response?.data['detail']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Error (${status ?? 'desconocido'})')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfesional = (_role ?? '').toLowerCase().startsWith('pro');

// o simplemente: final isProfesional = _role == 'professional';


    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 1) DROP-DOWN: primero
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de usuario',
                    border: OutlineInputBorder(),
                  ),
                  value: _role,
                  items: const [
                    DropdownMenuItem(
                      value: "conventional",
                      child: Text('Usuario convencional'),
                    ),
                    DropdownMenuItem(
                      value: "professional",
                      child: Text('Profesional de la salud'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _role = v),
                  validator: (v) => v == null ? 'Selecciona un tipo de usuario' : null,
                ),
                const SizedBox(height: 16),

                // 2) Si es profesional, pedir Cédula
                if (isProfesional) ...[
                  TextFormField(
                    controller: _cedulaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cédula profesional',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (!isProfesional) return null;
                      if (v == null || v.trim().isEmpty) return 'La cédula es obligatoria';
                      if (v.trim().length < 5) return 'Cédula demasiado corta';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _especialidadCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Especialidad',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (!isProfesional) return null;
                      if (v == null || v.trim().isEmpty) return 'La especialidad es obligatoria';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // 3) Nombres
                TextFormField(
                  controller: _namesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().length < 3)
                      ? 'Mínimo 3 caracteres'
                      : null,
                ),

                const SizedBox(height: 16),
                // 4) Apellido paterno
                TextFormField(
                  controller: _paternoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Apellido paterno',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().length < 3)
                      ? 'Mínimo 3 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),

                // 4) Apellido materno
                TextFormField(
                  controller: _maternoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Apellido materno',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().length < 3)
                      ? 'Mínimo 3 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),

                // 4) Email
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa un email';
                    final hasAt = v.contains('@');
                    final hasDot = v.contains('.');
                    return (!hasAt || !hasDot) ? 'Email inválido' : null;
                  },
                ),
                const SizedBox(height: 16),

                // 5) Contraseña
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) =>
                  (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Crear cuenta'),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
