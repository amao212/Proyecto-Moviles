class MascotaData {
  final String nombreMascota;
  final String especieMascota;
  final String razaMascota;
  final String edadMascota;
  final String nombreDueno;
  final String telefonoContacto;
  final String correoDueno;
  final double latitudDomicilio;
  final double longitudDomicilio;

  const MascotaData({
    required this.nombreMascota,
    required this.especieMascota,
    required this.razaMascota,
    required this.edadMascota,
    required this.nombreDueno,
    required this.telefonoContacto,
    required this.correoDueno,
    required this.latitudDomicilio,
    required this.longitudDomicilio,
  });

  factory MascotaData.fromIntentMap(Map<dynamic, dynamic> map) {
    return MascotaData(
      nombreMascota: map['nombre_mascota']?.toString() ?? 'Sin nombre',
      especieMascota: map['especie_mascota']?.toString() ?? 'No especificada',
      razaMascota: map['raza_mascota']?.toString() ?? 'No especificada',
      edadMascota: map['edad_mascota']?.toString() ?? '0',
      nombreDueno: map['nombre_dueno']?.toString() ?? 'Sin dueño',
      telefonoContacto: map['telefono_contacto']?.toString() ?? 'Sin teléfono',
      correoDueno: map['correo_dueno']?.toString() ?? 'Sin correo',
      latitudDomicilio: double.tryParse(map['latitud_domicilio']?.toString() ?? '') ?? -0.1807,
      longitudDomicilio: double.tryParse(map['longitud_domicilio']?.toString() ?? '') ?? -78.4678,
    );
  }

  static double _toDouble(dynamic value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  Map<String, dynamic> toIntentMapForApp3({
    required String sucursalVeterinaria,
    required double latitudVeterinaria,
    required double longitudVeterinaria,
    required String motivoCita,
    required String modalidadAtencion,
    required String veterinarioAsignado,
    required String fechaCita,
    required String horaCita,
    required String observacionesCita,
    required String estadoCita,
  }) {
    return {
      'nombre_mascota': nombreMascota,
      'especie_mascota': especieMascota,
      'raza_mascota': razaMascota,
      'edad_mascota': edadMascota,
      'nombre_dueno': nombreDueno,
      'telefono_contacto': telefonoContacto,
      'correo_dueno': correoDueno,
      'latitud_domicilio': latitudDomicilio,
      'longitud_domicilio': longitudDomicilio,
      'sucursal_veterinaria': sucursalVeterinaria,
      'latitud_veterinaria': latitudVeterinaria,
      'longitud_veterinaria': longitudVeterinaria,
      'motivo_cita': motivoCita,
      'modalidad_atencion': modalidadAtencion,
      'veterinario_asignado': veterinarioAsignado,
      'fecha_cita': fechaCita,
      'hora_cita': horaCita,
      'observaciones_cita': observacionesCita,
      'estado_cita': estadoCita,
    };
  }

  // No agregar métodos específicos para Farmacia: usar los campos que ya
  // existen en `toIntentMapForApp3` y enviar solo esos.
}