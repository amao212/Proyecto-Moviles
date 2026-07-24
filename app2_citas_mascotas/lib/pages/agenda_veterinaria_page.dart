import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/mascota_data.dart';
import '../services/intent_bridge_service.dart';
import '../services/intent_dispatcher_service.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';

class AgendaVeterinariaPage extends StatefulWidget {
  const AgendaVeterinariaPage({super.key});

  @override
  State<AgendaVeterinariaPage> createState() => _AgendaVeterinariaPageState();
}

class _AgendaVeterinariaPageState extends State<AgendaVeterinariaPage> {
  final MapController _mapController = MapController();
  final TextEditingController _observacionesController = TextEditingController();

  MascotaData? _mascotaData;
  bool _isLoading = true;

  final List<String> _motivosCita = [
    'Consulta Médica General',
    'Vacunación y Refuerzos',
    'Desparasitación Interna/Externa',
    'Control Post-Operatorio / Cirugía',
    'Urgencia / Emergencia Médica',
    'Exámenes de Laboratorio e Imágenes',
    'Profilaxis / Salud Dental',
    'Especialidad (Dermatología, Cardiología, Oftalmología)',
    'Peluquería y Estética Canina/Felina',
    'Eutanasia / Cuidados Paliativos',
  ];

  final List<String> _modalidades = [
    'Presencial en Clínica',
    'Atención a Domicilio',
  ];

  final List<String> _veterinarios = [
    'Asignación Automática / Disponible',
    'Dr. Carlos Mendoza (Medicina General)',
    'Dra. Sofía Benítez (Dermatología & Cirugía)',
    'Dr. Mateo Guerrero (Cardiología & Exámenes)',
  ];

  final List<VeterinariaSucursal> _sucursales = [
    const VeterinariaSucursal(nombre: 'Clínica Veterinaria Central', latitud: -0.1807, longitud: -78.4678),
    const VeterinariaSucursal(nombre: 'Sucursal Norte', latitud: -0.1670, longitud: -78.4920),
    const VeterinariaSucursal(nombre: 'Sucursal Sur', latitud: -0.1980, longitud: -78.4520),
  ];

  String? _motivoSeleccionado;
  String? _modalidadSeleccionada;
  String? _veterinarioSeleccionado;
  String? _sucursalSeleccionada;
  double? _latitudVeterinaria;
  double? _longitudVeterinaria;
  DateTime? _fechaCita;
  TimeOfDay? _horaCita;

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeIntent();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosDesdeIntent() async {
    final payload = await IntentBridgeService.instance.readInitialIntentData();

    // 🔍 Registro en consola para verificar los datos entrantes del Intent
    debugPrint("--------------------------------------------------");
    debugPrint("DATOS RECIBIDOS DESDE INTENT (App 1): $payload");
    debugPrint("CANTIDAD DE CAMPOS: ${payload.length}");
    debugPrint("--------------------------------------------------");

    if (!mounted) return;

    setState(() {
      _mascotaData = payload.isEmpty
          ? const MascotaData(
        nombreMascota: 'Luna',
        especieMascota: 'Perro',
        razaMascota: 'Golden Retriever',
        edadMascota: '3 años',
        nombreDueno: 'Ana Gómez',
        telefonoContacto: '0999999999',
        correoDueno: 'ana@correo.com',
        latitudDomicilio: -0.1807,
        longitudDomicilio: -78.4678,
      )
          : MascotaData.fromIntentMap(payload);

      _sucursalSeleccionada = _sucursales.first.nombre;
      _latitudVeterinaria = _sucursales.first.latitud;
      _longitudVeterinaria = _sucursales.first.longitud;
      _motivoSeleccionado = _motivosCita.first;
      _modalidadSeleccionada = _modalidades.first;
      _veterinarioSeleccionado = _veterinarios.first;
      _fechaCita = DateTime.now().add(const Duration(days: 1));
      _horaCita = const TimeOfDay(hour: 10, minute: 0);
      _isLoading = false;
    });

    // Mover la cámara del mapa únicamente después de que el widget fue renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Centrar en la sucursal seleccionada (no mover al domicilio del cliente)
        _mapController.move(
          LatLng(_latitudVeterinaria ?? -0.1807, _longitudVeterinaria ?? -78.4678),
          13.0,
        );
      }
    });
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaCita ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _fechaCita = picked);
    }
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaCita ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      setState(() => _horaCita = picked);
    }
  }

  void _confirmarAgenda() {
    if (_mascotaData == null) {
      _mostrarMensaje('No se recibieron datos de mascota desde App 1.');
      return;
    }

    final payload = _mascotaData!.toIntentMapForApp3(
      sucursalVeterinaria: _sucursalSeleccionada ?? 'No especificada',
      latitudVeterinaria: _latitudVeterinaria ?? 0.0,
      longitudVeterinaria: _longitudVeterinaria ?? 0.0,
      motivoCita: _motivoSeleccionado ?? 'No especificado',
      modalidadAtencion: _modalidadSeleccionada ?? 'No especificado',
      veterinarioAsignado: _veterinarioSeleccionado ?? 'No especificado',
      fechaCita: _fechaCita?.toIso8601String().split('T').first ?? '',
      horaCita: _horaCita?.format(context) ?? '',
      observacionesCita: _observacionesController.text.trim(),
      estadoCita: 'Confirmada',
    );

    IntentDispatcherService.emitToApp3(payload);
    _mostrarMensaje('Cita confirmada y datos enviados hacia App 3.');
  }

  void _enviarAFarmacia() {
    if (_mascotaData == null) {
      _mostrarMensaje('No se recibieron datos de mascota desde App 1.');
      return;
    }

    // Construir payload exactamente con los campos que ya maneja app2
    final payload = _mascotaData!.toIntentMapForApp3(
      sucursalVeterinaria: _sucursalSeleccionada ?? 'No especificada',
      latitudVeterinaria: _latitudVeterinaria ?? _mascotaData!.latitudDomicilio,
      longitudVeterinaria: _longitudVeterinaria ?? _mascotaData!.longitudDomicilio,
      motivoCita: _motivoSeleccionado ?? '',
      modalidadAtencion: _modalidadSeleccionada ?? '',
      veterinarioAsignado: _veterinarioSeleccionado ?? '',
      fechaCita: _fechaCita?.toIso8601String().split('T').first ?? '',
      horaCita: _horaCita?.format(context) ?? '',
      observacionesCita: _observacionesController.text.trim(),
      estadoCita: 'EnviadoAFarmacia',
    );

    IntentDispatcherService.emitToFarmacia(payload);
    _mostrarMensaje('Datos enviados a la App Farmacia.');
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _mascotaData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Agendamiento Veterinaria'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade300,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'Resumen de Mascota y Dueño',
                icon: Icons.pets,
                child: Column(
                  children: [
                    InfoRow(label: 'Mascota', value: _mascotaData!.nombreMascota),
                    InfoRow(label: 'Especie', value: _mascotaData!.especieMascota),
                    InfoRow(label: 'Raza', value: _mascotaData!.razaMascota),
                    InfoRow(label: 'Edad', value: _mascotaData!.edadMascota),
                    InfoRow(label: 'Dueño', value: _mascotaData!.nombreDueno),
                    InfoRow(label: 'Teléfono', value: _mascotaData!.telefonoContacto),
                    InfoRow(label: 'Correo', value: _mascotaData!.correoDueno),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Selección en Mapa',
                icon: Icons.map,
                child: Column(
                  children: [
                    SizedBox(
                      height: 280,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            _latitudVeterinaria ?? -0.1807,
                            _longitudVeterinaria ?? -78.4678,
                          ),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app_veterinaria_agenda',
                          ),
                          MarkerLayer(
                            markers: [
                              // 1. PIN DEL DOMICILIO DEL CLIENTE (Rojo)
                              Marker(
                                point: LatLng(
                                  _mascotaData!.latitudDomicilio,
                                  _mascotaData!.longitudDomicilio,
                                ),
                                width: 50,
                                height: 50,
                                child: const Tooltip(
                                  message: 'Domicilio del Cliente',
                                  child: Icon(Icons.home, color: Colors.red, size: 36),
                                ),
                              ),
                              // 2. PINS DE LAS SUCURSALES VETERINARIAS (Azul/Verde)
                              ..._sucursales.map((sucursal) {
                                final esSeleccionada = sucursal.nombre == _sucursalSeleccionada;
                                return Marker(
                                  point: LatLng(sucursal.latitud, sucursal.longitud),
                                  width: 50,
                                  height: 50,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _sucursalSeleccionada = sucursal.nombre;
                                        _latitudVeterinaria = sucursal.latitud;
                                        _longitudVeterinaria = sucursal.longitud;
                                      });
                                      _mostrarMensaje('Sucursal seleccionada: ${sucursal.nombre}');
                                    },
                                    child: Icon(
                                      Icons.local_hospital,
                                      color: esSeleccionada ? Colors.blue.shade800 : Colors.blue.shade300,
                                      size: esSeleccionada ? 38 : 30,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Sucursal Autocompletada: $_sucursalSeleccionada\nCoordenadas: ${_latitudVeterinaria?.toStringAsFixed(4)}, ${_longitudVeterinaria?.toStringAsFixed(4)}',
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Formulario de Agendamiento',
                icon: Icons.calendar_month,
                child: Column(
                  children: [
                    _buildDropdown(
                      label: 'Motivo de Cita',
                      value: _motivoSeleccionado,
                      items: _motivosCita,
                      onChanged: (value) => setState(() => _motivoSeleccionado = value),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Tipo de Atención / Modalidad',
                      value: _modalidadSeleccionada,
                      items: _modalidades,
                      onChanged: (value) => setState(() => _modalidadSeleccionada = value),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Veterinario / Especialista',
                      value: _veterinarioSeleccionado,
                      items: _veterinarios,
                      onChanged: (value) => setState(() => _veterinarioSeleccionado = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _seleccionarFecha,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Cita',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _fechaCita == null
                                    ? 'Seleccionar fecha'
                                    : '${_fechaCita!.day}/${_fechaCita!.month}/${_fechaCita!.year}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _seleccionarHora,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Hora de Cita',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _horaCita == null ? 'Seleccionar hora' : _horaCita!.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _observacionesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones o Síntomas Previos',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _confirmarAgenda,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmar Agendamiento'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _enviarAFarmacia,
                        icon: const Icon(Icons.local_pharmacy),
                        label: const Text('Enviar a Farmacia'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade700,
                          side: BorderSide(color: Colors.teal.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true, // 👈 Evita desbordamiento en textos de opciones largas
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          overflow: TextOverflow.ellipsis,
        ),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class VeterinariaSucursal {
  final String nombre;
  final double latitud;
  final double longitud;

  const VeterinariaSucursal({
    required this.nombre,
    required this.latitud,
    required this.longitud,
  });
}