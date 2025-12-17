// ==========================================
// ARCHIVO: mongo.js
// PROYECTO: Clínica Dental (Módulo NoSQL)
// DESCRIPCIÓN: Script para poblar la base de datos MongoDB con datos flexibles.
// ==========================================

// 1. Seleccionamos la Base de Datos
use ClinicaDentalNoSQL;

// ==========================================
// COLECCIÓN 1: EXPEDIENTES CLÍNICOS
// JUSTIFICACIÓN: Guardamos el Odontograma y antecedentes como estructuras complejas.
// ==========================================
db.Expedientes.insertMany([
  {
    "paciente_id": 1, // Referencia a SQL Server (Luis Silva)
    "tipo_sangre": "O+",
    "antecedentes": ["Diabetes Controlada", "Alergia a la Penicilina"],
    "odontograma": [
      { "diente": 18, "estado": "Caries Profunda", "tratamiento_sugerido": "Endodoncia" },
      { "diente": 21, "estado": "Fractura Leve", "tratamiento_sugerido": "Resina" }
    ],
    "notas_evolutivas": [
      { "fecha": "2023-12-01", "doctor": "Dr. Juan", "nota": "Paciente refiere dolor al frío." },
      { "fecha": "2023-12-05", "doctor": "Dr. Mario", "nota": "Se inicia tratamiento de conducto." }
    ]
  },
  {
    "paciente_id": 2, // Referencia a Maria Garcia
    "tipo_sangre": "A-",
    "antecedentes": ["Hipertensión"],
    "odontograma": [
      { "diente": 14, "estado": "Ausente", "tratamiento_sugerido": "Implante" }
    ],
    "archivos_adjuntos": [ 
      { "tipo": "Rayos-X", "url": "/imgs/rx_maria_01.jpg", "fecha": "2023-11-20" }
    ]
  }
]);

// ==========================================
// COLECCIÓN 2: CATÁLOGO DE PROVEEDORES (INVENTARIO)
// JUSTIFICACIÓN: Polimorfismo. Cada producto tiene 'especificaciones' técnicas distintas.
// ==========================================
db.Proveedores.insertMany([
  {
    "proveedor": "DentalCorp",
    "producto": "Implante Hexagonal",
    "categoria": "Implantología",
    "precio_lista": 150.00,
    "stock": 50,
    // Atributos únicos de un implante
    "especificaciones": {
      "material": "Titanio Grado 5",
      "diametro": "3.5mm",
      "longitud": "10mm",
      "conexion": "Interna"
    }
  },
  {
    "proveedor": "InsumosMed",
    "producto": "Guantes de Latex",
    "categoria": "Desechables",
    "precio_lista": 5.00,
    "stock": 200,
    // Atributos únicos de guantes (totalmente distintos al implante)
    "especificaciones": {
      "talla": "M",
      "unidades_caja": 100,
      "textura": "Lisa",
      "color": "Blanco"
    }
  }
]);

// ==========================================
// COLECCIÓN 3: ENCUESTAS DE SATISFACCIÓN
// JUSTIFICACIÓN: Flexibilidad. Las preguntas del formulario pueden cambiar con el tiempo.
// ==========================================
db.Encuestas.insertMany([
  {
    "paciente_id": 1,
    "fecha": new Date(),
    "puntuacion_general": 5,
    "comentarios": "Excelente atención del Dr. Juan.",
    "detalles": [
      { "pregunta": "¿Tiempo de espera?", "respuesta": "Menos de 10 min" },
      { "pregunta": "¿Limpieza del lugar?", "respuesta": "Impecable" }
    ]
  },
  {
    "paciente_id": 2,
    "fecha": new Date("2023-11-20"),
    "puntuacion_general": 3,
    "comentarios": "El aire acondicionado estaba muy frío.",
    "queja_formal": true 
  }
]);

// ==========================================
// COLECCIÓN 4: CAMPAÑAS DE MARKETING
// JUSTIFICACIÓN: Analítica. Seguimiento de interacciones (clics, aperturas) anidadas.
// ==========================================
db.Marketing.insertMany([
  {
    "nombre_campana": "Blanqueamiento 2x1 Navidad",
    "canal": "Email",
    "fecha_envio": new Date("2023-12-01"),
    "destinatarios": [
      {
        "paciente_id": 1,
        "estado": "Abierto",
        "interacciones": [
           { "accion": "Abrió correo", "hora": "10:05" }
        ]
      },
      {
        "paciente_id": 2,
        "estado": "Convertido", // ¡Agendó cita!
        "interacciones": [
           { "accion": "Abrió correo", "hora": "11:00" },
           { "accion": "Clic en 'Agendar'", "hora": "11:02" }
        ]
      }
    ]
  }
]);