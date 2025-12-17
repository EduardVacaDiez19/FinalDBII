# 🏥 Sistema Web Clínica Dental - Proyecto Final DBII
## Arquitectura Híbrida: SQL Server (ClinicaDentalDB) + MongoDB (ClinicaDentalNoSQL)

---

## 📋 ESTRUCTURA DE TU PROYECTO

Tu proyecto implementa una arquitectura híbrida profesional con:

### **SQL Server (ClinicaDentalDB)** - Módulo Transaccional
- ✅ Tablas: Usuarios, Roles, Pacientes, Doctores, Citas, Servicios, Pagos
- ✅ Stored Procedures: ValidarLogin, sp_AgendarCita, sp_RegistrarPacienteWeb, sp_ActualizarPaciente, sp_EliminarPacienteWeb, etc.
- ✅ Triggers: Auditoría de pacientes, validación de borrado de doctores, historial de precios, límite de citas
- ✅ Transacciones: RealizarPagoSeguro, sp_ReprogramarCita, sp_ReasignarCitasEmergencia
- ✅ Índices para optimización

### **MongoDB (ClinicaDentalNoSQL)** - Módulo Flexible
- ✅ Expedientes Clínicos: Odontogramas, notas evolutivas, archivos adjuntos
- ✅ Proveedores: Inventario polimórfico (especificaciones dinámicas)
- ✅ Encuestas: Satisfacción del paciente
- ✅ Marketing: Campañas con tracking de interacciones

---

## 🚀 INSTALACIÓN RÁPIDA

### Paso 1: Instalar Dependencias
```bash
npm install
```

### Paso 2: Configurar Archivo `.env`
Copia `.env.example` a `.env` y edita las credenciales:
```env
PORT=3000
SQL_SERVER=localhost
SQL_DATABASE=ClinicaDentalDB
SQL_USER=sa
SQL_PASSWORD=TuPassword
MONGO_URI=mongodb://localhost:27017/ClinicaDentalNoSQL
```

### Paso 3: Crear Bases de Datos

**SQL Server:**
1. Ejecuta en orden:
   - `database/sql/CreaciondeTablas.sql`
   - `database/sql/StoredProcedures.sql`
   - `database/sql/Triggers.sql`
   - `database/sql/Transacciones.sql`
   - `database/sql/CreaciondeIndices.sql`

**MongoDB:**
1. Ejecuta: `mongosh < database/mongodb/mongo.js`

### Paso 4: Iniciar Sistema
```bash
npm start
```

### Paso 5: Acceder
```
http://localhost:3000

Credenciales de Prueba:
- Paciente: luis.s / Paciente123!
- Doctor: dr.juan / Doctor123!
```

---

## 🏗️ ARQUITECTURA DEL SISTEMA

### Backend (Node.js + Express)
```
server.js                    → Servidor principal con todas las rutas
config/
  ├── database.sql.js       → Conexión SQL Server
  └── database.mongo.js     → Conexión MongoDB con Schemas
```

### Frontend (Vanilla JS)
```
public/
  ├── index.html            → Interfaz principal
  ├── css/styles.css        → Estilos profesionales
  └── js/app.js             → Lógica del cliente
```

### Base de Datos
```
database/
  ├── sql/                  → Scripts SQL Server
  └── mongodb/              → Scripts MongoDB
```

---

## 📡 ENDPOINTS DE LA API

### Autenticación
- `POST /api/auth/login` - Login con ValidarLogin SP

### Pacientes (SQL Server + SPs)
- `GET /api/pacientes` - Listar pacientes activos
- `POST /api/pacientes` - Registrar (sp_RegistrarPacienteWeb)
- `PUT /api/pacientes/:id` - Actualizar (sp_ActualizarPaciente)
- `DELETE /api/pacientes/:id` - Eliminar (sp_EliminarPacienteWeb - Soft Delete)

### Citas (SQL Server + SPs)
- `GET /api/citas` - Listar citas
- `POST /api/citas` - Agendar (sp_AgendarCita con validaciones)
- `GET /api/doctores` - Listar doctores disponibles

### Expedientes (MongoDB)
- `GET /api/expedientes` - Listar expedientes
- `GET /api/expedientes/paciente/:id` - Obtener por paciente

### Inventario (MongoDB)
- `GET /api/inventario/productos` - Listar productos (Polimórfico)

### Encuestas (MongoDB)
- `GET /api/encuestas` - Listar con estadísticas
- `POST /api/encuestas` - Crear encuesta

### Reportes
- `GET /api/reportes/ingresos-dia` - Reporte del día (ReporteIngresosDia SP)

---

## 🎯 FUNCIONALIDADES DESTACADAS

### 1. **Stored Procedures (SQL Server)**
Toda la lógica SQL está encapsulada en SPs, siguiendo mejores prácticas:
- ✅ ValidarLogin con hash SHA2_256
- ✅ sp_AgendarCita con validaciones de disponibilidad
- ✅ sp_RegistrarPacienteWeb con transacción (Usuarios + Pacientes)
- ✅ Soft Delete (sp_EliminarPacienteWeb marca Estado=0)

### 2. **Triggers Automáticos**
- ✅ **trg_Auditoria_Pacientes_Update**: Registra cambios en AuditoriaPacientes
- ✅ **trg_ValidarBorradoDoctor**: Bloquea borrado si tiene citas pendientes
- ✅ **trg_Historial_CambioPrecio**: Registra cambios de precios de servicios
- ✅ **trg_LimiteCitasPendientes**: Máximo 2 citas pendientes por paciente

### 3. **Transacciones (ACID)**
- ✅ **RealizarPagoSeguro**: Pago + Actualización de estado (Todo o Nada)
- ✅ **sp_ReprogramarCita**: Validación de disponibilidad con rollback
- ✅ **sp_ReasignarCitasEmergencia**: Reasignación masiva de citas

### 4. **Polimorfismo en MongoDB**
Productos con especificaciones dinámicas según categoría:
```javascript
// Implante
{ especificaciones: { material: "Titanio", diametro: "3.5mm" } }

// Guantes
{ especificaciones: { talla: "M", unidades_caja: 100 } }
```

### 5. **Expedientes Clínicos Complejos**
Odontogramas con estructura anidada:
```javascript
{
  paciente_id: 1,
  odontograma: [
    { diente: 18, estado: "Caries", tratamiento_sugerido: "Endodoncia" }
  ],
  notas_evolutivas: [
    { fecha: "2023-12-01", doctor: "Dr. Juan", nota: "..." }
  ]
}
```

---

## 💡 PUNTOS CLAVE PARA TU EVALUACIÓN

### ✅ Arquitectura Híbrida Justificada
**SQL Server para:**
- Datos relacionales y críticos (Usuarios, Pacientes, Citas)
- Transacciones ACID (Pagos, Reprogramaciones)
- Integridad referencial estricta
- Stored Procedures para lógica de negocio

**MongoDB para:**
- Datos flexibles y polimórficos (Inventario)
- Documentos complejos (Expedientes con odontogramas)
- Esquemas que evolucionan (Encuestas con preguntas variables)
- Alto volumen de lectura (Marketing, Analytics)

### ✅ Uso Correcto de Stored Procedures
- ❌ **MAL**: `INSERT INTO Pacientes ...` directo en código
- ✅ **BIEN**: `EXEC sp_RegistrarPacienteWeb @params`

### ✅ Triggers para Integridad de Negocio
- Auditoría automática de cambios
- Validaciones complejas (no solo FK)
- Historial de precios para trazabilidad

### ✅ Transacciones para Consistencia
- Operaciones atómicas (Pago + Estado)
- Rollback automático en errores
- Validaciones pre-commit

---

## 🔧 SOLUCIÓN DE PROBLEMAS

### Error: "Cannot connect to SQL Server"
```bash
# Verificar que SQL Server esté corriendo
services.msc  # Windows
sudo systemctl status mssql-server  # Linux

# Verificar credenciales en .env
# Verificar puerto 1433 abierto
```

### Error: "Cannot connect to MongoDB"
```bash
# Verificar MongoDB
mongod --version
mongosh --version

# Iniciar servicio
net start MongoDB  # Windows
sudo systemctl start mongod  # Linux
```

### Error: "SP not found"
```bash
# Ejecutar scripts SQL en orden:
1. CreaciondeTablas.sql
2. StoredProcedures.sql
3. Triggers.sql
4. Transacciones.sql
5. CreaciondeIndices.sql
```

---

## 📊 MODELO DE DATOS

### SQL Server - Relacional
```
Usuarios (1:1) Pacientes
Usuarios (1:N) Doctores
Pacientes (N:M) Doctores → Citas
Citas (1:N) DetalleCita → Servicios
Citas (1:N) Pagos
```

### MongoDB - Documentos
```
Expedientes {
  paciente_id: ref(SQL.Pacientes),
  odontograma: [...],
  notas_evolutivas: [...]
}

Proveedores {
  especificaciones: Mixed  // Polimórfico
}
```

---

## 🎓 CONCEPTOS DEMOSTRADOS

1. **Arquitectura Híbrida**
   - Justificación técnica de cada BD
   - Integración efectiva entre SQL y NoSQL

2. **SQL Server Avanzado**
   - Stored Procedures
   - Triggers (AFTER, INSTEAD OF)
   - Transacciones (BEGIN TRANSACTION, COMMIT, ROLLBACK)
   - Funciones de Hash (HASHBYTES)
   - Auditoría automática

3. **MongoDB**
   - Polimorfismo (especificaciones dinámicas)
   - Documentos anidados (odontograma)
   - Referencias a SQL (paciente_id)
   - Índices para optimización

4. **Backend Profesional**
   - API RESTful
   - Manejo de errores
   - Validaciones
   - Separación de responsabilidades

---

## 📞 SOPORTE

Para dudas:
1. Revisa los comentarios en el código
2. Consulta la documentación de los SPs
3. Verifica logs del servidor (consola)
4. Revisa console del navegador (F12)

---

## 🚀 ¡Listo para Presentar!

Este sistema demuestra:
- ✅ Arquitectura híbrida profesional
- ✅ Uso correcto de Stored Procedures
- ✅ Triggers para integridad
- ✅ Transacciones ACID
- ✅ Polimorfismo en MongoDB
- ✅ API RESTful completa
- ✅ Frontend funcional

**¡Éxito en tu proyecto final!** 🎓
