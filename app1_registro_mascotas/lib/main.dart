import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registrar Mascota',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFEBD3), // Fondo crema
        useMaterial3: true,
      ),
      home: const RegistroMascotaPage(),
    );
  }
}

class RegistroMascotaPage extends StatefulWidget {
  const RegistroMascotaPage({super.key});

  @override
  State<RegistroMascotaPage> createState() => _RegistroMascotaPageState();
}

class _RegistroMascotaPageState extends State<RegistroMascotaPage> {
  // Variables de mapas y coordenadas
  LatLng _ubicacionSeleccionada = const LatLng(-0.1807, -78.4678); 
  final MapController _mapController = MapController();

  // Controladores para capturar los textos ingresados
  final TextEditingController _nombreMascotaController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _duenoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController(); // Controlador para el correo
  final TextEditingController _buscarController = TextEditingController(); 
  
  // Estados para los menús desplegables y buscador
  String? _especieSeleccionada;
  String? _razaSeleccionada;
  List<dynamic> _sugerenciasDirecciones = []; // Guarda resultados del autocompletado

  // Listas de datos para especies y razas
  final List<String> _especies = ['Perro', 'Gato', 'Ave', 'Reptil', 'Otro'];

  final Map<String, List<String>> _razasPorEspecie = {
    'Perro': ['San Bernardo', 'Pastor Alemán', 'Golden Retriever', 'Pug', 'Otro'],
    'Gato': ['Persa', 'Siamés', 'Bengala', 'Angora', 'Otro'],
    'Ave': ['Canario', 'Perico', 'Loro', 'Otro'],
    'Reptil': ['Iguana', 'Tortuga', 'Camaleón', 'Otro'],
    'Otro': ['Sin especificar']
  };

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual(); // Pide el GPS apenas arranca la app
  }

  @override
  void dispose() {
    _nombreMascotaController.dispose();
    _edadController.dispose();
    _duenoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose(); // Limpieza del controlador de correo
    _buscarController.dispose();
    super.dispose();
  }

  // Permisos de GPS y centrado automático en el mapa
  Future<void> _obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }
    if (permiso == LocationPermission.deniedForever) return;

    Position posicion = await Geolocator.getCurrentPosition();
    setState(() {
      _ubicacionSeleccionada = LatLng(posicion.latitude, posicion.longitude);
      _mapController.move(_ubicacionSeleccionada, 16.0);
    });
  }

  // Obtiene sugerencias de direcciones en tiempo real (API libre Nominatim)
  Future<void> _obtenerSugerencias(String texto) async {
    if (texto.length < 3) {
      setState(() { _sugerenciasDirecciones = []; });
      return;
    }

    // Filtra la búsqueda agregando ", Quito, Ecuador" para que sea local
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(texto + ", Quito, Ecuador")}&format=json&limit=3');

    try {
      final respuesta = await http.get(url, headers: {'User-Agent': 'app_registro_mascotas'});
      if (respuesta.statusCode == 200) {
        setState(() {
          _sugerenciasDirecciones = json.decode(respuesta.body);
        });
      }
    } catch (e) {
      // Manejo silencioso de errores de red
    }
  }

  // Mueve el mapa al lugar seleccionado del autocompletado
  void _seleccionarSugerencia(dynamic lugar) {
    final lat = double.parse(lugar['lat']);
    final lon = double.parse(lugar['lon']);
    final nombreLargo = lugar['display_name'].toString().split(',');
    
    setState(() {
      _ubicacionSeleccionada = LatLng(lat, lon);
      _mapController.move(_ubicacionSeleccionada, 16.0);
      _buscarController.text = nombreLargo[0]; // Deja solo el nombre principal en el input
      _sugerenciasDirecciones = []; // Cierra la lista de sugerencias
    });
  }

  // Envía los datos empaquetados mediante un Intent hacia la App 2
  void _enviarDatosApp2() {
    if (_nombreMascotaController.text.isEmpty || 
        _duenoController.text.isEmpty || 
        _telefonoController.text.isEmpty || 
        _correoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena los campos obligatorios')),
      );
      return;
    }

    // Contrato de datos: Diccionario estructurado

    final Map<String, dynamic> datosMascota = {
      'nombre_mascota': _nombreMascotaController.text,
      'especie_mascota': _especieSeleccionada ?? 'No especificada',
      'raza_mascota': _razaSeleccionada ?? 'No especificada',
      'edad_mascota': _edadController.text,
      'nombre_dueno': _duenoController.text,
      'telefono_contacto': _telefonoController.text,
      'correo_dueno': _correoController.text,
      'latitud_domicilio': _ubicacionSeleccionada.latitude,
      'longitud_domicilio': _ubicacionSeleccionada.longitude,
    };

    // Configuración del Intent inter-procesos para Android
    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      package: 'com.example.app_veterinaria_agenda', // ID de la App 2
      componentName: 'com.example.app_veterinaria_agenda.MainActivity',
      arguments: datosMascota,
    );

    intent.launch().catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos listos. Esperando App 2: $e')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER DE LA APP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registrar Mascota',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        'Centro Veterinario Huellitas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.brown.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // CARD 1: DATOS DE LA MASCOTA
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pets, color: Color(0xFF9BCEC1), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'DATOS DE LA MASCOTA',
                            style: TextStyle(
                              color: Color(0xFF9BCEC1),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Nombre de la mascota', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nombreMascotaController,
                        hint: 'Ej: Luna, Max, Pelusa...',
                        icon: Icons.pets_outlined,
                      ),
                      const SizedBox(height: 16),
                      const Text('Especie', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      _buildDropdownField(),
                      const SizedBox(height: 16),

                      // Desplegable dinámico: Solo aparece si elegiste una especie
                      if (_especieSeleccionada != null) ...[
                        const Text('Raza', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        const SizedBox(height: 8),
                        _buildRazaDropdownField(),
                        const SizedBox(height: 16),
                      ],

                      const Text('Edad (años)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _edadController,
                        hint: 'Ej: 2',
                        icon: Icons.favorite_border,
                        type: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CARD 2: DATOS DEL DUEÑO
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Color(0xFF67A2C5), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'DATOS DEL DUEÑO',
                            style: TextStyle(
                              color: Color(0xFF67A2C5),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Nombre del dueño', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _duenoController,
                        hint: 'Nombre completo',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      const Text('Teléfono de contacto', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _telefonoController,
                        hint: 'Ej: 0991234567',
                        icon: Icons.phone_outlined,
                        type: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      const Text('Correo electrónico', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _correoController,
                        hint: 'Ej: usuario@correo.com',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress, // Optimiza el teclado para emails
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CARD 3: UBICACIÓN DEL DOMICILIO (MAPA + AUTOCOMPLETADO)
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF67A2C5), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'UBICACIÓN DEL DOMICILIO',
                            style: TextStyle(
                              color: Color(0xFF67A2C5),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Buscador inteligente con detector de escritura
                      TextField(
                        controller: _buscarController,
                        onChanged: (value) => _obtenerSugerencias(value), // Llama al autocompletado en vivo
                        decoration: InputDecoration(
                          hintText: 'Buscar dirección (Ej: El Giron)...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _buscarController.text.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear), 
                                  onPressed: () {
                                    _buscarController.clear();
                                    setState(() { _sugerenciasDirecciones = []; });
                                  })
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFF67A2C5), width: 2),
                          ),
                        ),
                      ),
                      
                      // Despliega la lista flotante de sugerencias si tiene elementos
                      if (_sugerenciasDirecciones.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _sugerenciasDirecciones.length,
                            itemBuilder: (context, index) {
                              final lugar = _sugerenciasDirecciones[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                                title: Text(
                                  lugar['display_name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                onTap: () => _seleccionarSugerencia(lugar),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      
                      // Caja del mapa ampliada a 320px de altura
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 320, 
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _ubicacionSeleccionada,
                                  initialZoom: 16.0,
                                  onTap: (tapPosition, point) {
                                    setState(() {
                                      _ubicacionSeleccionada = point; // Mueve el pin manual al tocar
                                    });
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.app_registro_mascotas',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _ubicacionSeleccionada,
                                        width: 45,
                                        height: 45,
                                        child: const Icon(
                                          Icons.location_on,
                                          size: 45,
                                          color: Color(0xFFFFB6A6), // Pin color Coral
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // Botón redondo para centrar el mapa en la ubicación del GPS
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: FloatingActionButton(
                                  mini: true,
                                  onPressed: _obtenerUbicacionActual,
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF67A2C5),
                                  shape: const CircleBorder(),
                                  child: const Icon(Icons.my_location),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Toca el mapa para ajustar la ubicación exacta',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // BOTÓN PRINCIPAL DE ENVÍO NEUBRUTALISTA
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, 4),
                    )
                  ]
                ),
                child: ElevatedButton.icon(
                  onPressed: _enviarDatosApp2,
                  icon: const Icon(Icons.vaccines, color: Colors.white),
                  label: const Text(
                    'Enviar a Veterinaria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB6A6), // Color Coral
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Estilo reutilizable para los campos de texto estándar
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF9BCEC1), width: 2),
        ),
      ),
    );
  }

  // Menú desplegable para Especies con bordes internos corregidos
  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: DropdownButtonFormField<String>(
        value: _especieSeleccionada,
        dropdownColor: Colors.white, // Bordes del panel flotante corregidos
        borderRadius: BorderRadius.circular(20), 
        hint: Text('Seleccionar...', style: TextStyle(color: Colors.grey.shade400)),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.star_border, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        items: _especies.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _especieSeleccionada = newValue;
            _razaSeleccionada = null; // Reinicia la raza si cambia la especie
          });
        },
      ),
    );
  }

  // Menú desplegable dinámico para Razas
  Widget _buildRazaDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: DropdownButtonFormField<String>(
        value: _razaSeleccionada,
        dropdownColor: Colors.white, // Bordes del panel flotante corregidos
        borderRadius: BorderRadius.circular(20),
        hint: Text('Seleccionar raza...', style: TextStyle(color: Colors.grey.shade400)),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.pets_outlined, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        items: (_razasPorEspecie[_especieSeleccionada] ?? []).map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _razaSeleccionada = newValue;
          });
        },
      ),
    );
  }
}