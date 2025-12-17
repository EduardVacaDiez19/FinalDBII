# Sistema Clínica Dental — Instrucciones para Copilot

Este archivo guía a Copilot (chat y agentes) para trabajar eficientemente en este repositorio a la primera, minimizando intentos fallidos de build/ejecución.

## Resumen del Proyecto

Aplicación web para gestión de una Clínica Dental con arquitectura híbrida: datos operacionales en SQL Server (PACIENTES, CITAS, DOCTORES, etc.) y datos flexibles/analíticos en MongoDB (Expedientes, Proveedores/Inventario, Encuestas, Marketing). Frontend estático (HTML/CSS/JS) consumiendo una API REST en Express.

## Tech Stack

### Backend
- Node.js + Express
- SQL Server mediante `mssql` (auth SQL) o `mssql/msnodesqlv8` (auth Windows). En Linux usa SIEMPRE auth SQL definiendo variables `SQL_USER` y `SQL_PASSWORD` para evitar `msnodesqlv8`.
- MongoDB con `mongoose`
- Configuración por `.env` (`dotenv`)
- CORS con `cors`

### Frontend
- Estático en `public/` (HTML, CSS, Vanilla JS).
- El cliente usa `API_URL = http://localhost:3000/api` (ver `public/js/app.js`).

### Desarrollo
- `nodemon` para recarga en modo dev.

## Guías de Código
- Módulos CommonJS (`require`, `module.exports`).
- API REST bajo `/api/*` siguiendo el patrón existente.
- SQL Server: usa SIEMPRE stored procedures a través de `executeStoredProcedure()` expuesto por `config/database.sql.js`. Evita concatenar SQL.
- Manejo de errores: responde `{ success: false, message }` con `res.status(4xx/5xx)` y loguea el error en servidor.
- Validación de entrada: castea tipos numéricos (ej. `parseInt`) en endpoints que lo requieran.
- MongoDB: utiliza los modelos exportados por `config/database.mongo.js` (`Expediente`, `Proveedor`, `Encuesta`, `Marketing`). Esquemas con `strict:false` para soportar documentos polimórficos.
- Estilo JS sencillo (sin framework en frontend). Mantén consistencia con el código existente.

## Estructura del Proyecto

- `server.js` — Servidor Express principal con todas las rutas API
- `public/` — Frontend estático
  - `index.html` — Interfaz principal
  - `css/styles.css` — Estilos globales
  - `js/app.js` — Lógica del cliente (navegación SPA + consumo de API)
- `config/` — Configuraciones de bases de datos
  - `database.sql.js` — Wrapper para SQL Server (`getConnection`, `executeStoredProcedure`)
  - `database.mongo.js` — Conexión MongoDB y modelos (`Expediente`, `Proveedor`, `Encuesta`, `Marketing`)
- `sql/` — Scripts SQL para inicialización
  - `CreaciondeTablas.sql` — Esquema de tablas
  - `StoredProcedures.sql` — Procedimientos almacenados
  - `Triggers.sql` — Triggers de auditoría
  - `Transacciones.sql` — Transacciones complejas
  - `CreaciondeIndices.sql` — Índices de optimización
  - `FixSecurity.sql` — Configuración de seguridad (opcional)
- `Mongodb.js` — Script de semillas para MongoDB
- `.env.example` — Plantilla de variables de entorno
- `package.json` — Dependencias y scripts npm

## Variables de Entorno
Crea un `.env` basado en `.env.example`. Mínimos para Linux/macOS (auth SQL):

```
PORT=3000

# SQL Auth (recomendado en Linux)
SQL_SERVER=localhost
SQL_DATABASE=ClinicaDentalDB
SQL_USER=sa
SQL_PASSWORD=YourStrong!Passw0rd
SQL_PORT=1433

# Mongo
MONGO_URI=mongodb://localhost:27017/ClinicaDentalNoSQL
```

Notas:
- Si NO defines `SQL_USER`, el backend intentará usar autenticación de Windows y el driver `msnodesqlv8` (solo Windows). En Linux/macOS define `SQL_USER`/`SQL_PASSWORD` para evitarlo.
- `encrypt: false` y `trustServerCertificate: true` están activados por defecto. Ajusta según tu TLS.

## Puesta en Marcha (Local)

1) **Base de datos SQL Server**
   - Crea la base de datos `ClinicaDentalDB` y ejecuta los scripts en orden:
     1. `sql/CreaciondeTablas.sql`
     2. `sql/StoredProcedures.sql`
     3. `sql/Triggers.sql`
     4. `sql/Transacciones.sql`
     5. `sql/CreaciondeIndices.sql`
     6. `sql/FixSecurity.sql` (opcional para seguridad adicional)

2) **MongoDB**
   - Asegura que `mongod` esté corriendo
   - Ejecuta las semillas: `mongosh < Mongodb.js`

3) **Backend**
   - Instala dependencias: `npm install`
   - Arranca el servidor:
     - Desarrollo: `npm run dev` (con recarga automática)
     - Producción: `npm start`

4) **Frontend**
   - Abre `http://localhost:3000/` en tu navegador
   - **Credenciales de prueba:**
     - Usuario: `luis.s`
     - Contraseña: `Paciente123!`

## Endpoints Principales
- `POST /api/auth/login`
- `GET /api/pacientes` — `POST /api/pacientes` — `PUT /api/pacientes/:id` — `DELETE /api/pacientes/:id`
- `GET /api/citas` — `POST /api/citas`
- `GET /api/doctores`
- `GET /api/expedientes` — `GET /api/expedientes/paciente/:id`
- `GET /api/inventario/productos`
- `GET /api/encuestas` — `POST /api/encuestas`
- `GET /api/reportes/ingresos-dia`

## Recursos para Copilot
- Scripts SQL en `sql/` para bootstrap; úsense como verdad fuente del modelo relacional y SPs.
- Wrapper SQL: `config/database.sql.js` con `executeStoredProcedure()` (preferido) y `getConnection()` para consultas puntuales.
- Modelos Mongo: `config/database.mongo.js`.
- Frontend: `public/js/app.js` define llamadas y estructuras esperadas en respuestas (e.g., `data`, `count`, `estadisticas`).

## Errores Comunes y Cómo Evitarlos
- **Instalación de `msnodesqlv8` en Linux/macOS:** Evita autenticación Windows definiendo `SQL_USER`/`SQL_PASSWORD` en `.env` para usar `mssql` puro.
- **CORS/puertos:** El cliente asume `http://localhost:3000/api`. Asegúrate de que el servidor esté corriendo en el puerto correcto.
- **Datos vacíos:** Si no ejecutas `Mongodb.js`, no verás datos de inventario/encuestas/expedientes.
- **Error de conexión SQL Server:** Verifica que el servicio esté activo, el puerto 1433 accesible y las credenciales en `.env` sean correctas.
- **Error de conexión MongoDB:** Verifica que `mongod` esté corriendo y `MONGO_URI` en `.env` sea correcto.

## Convenciones al Extender
- Nuevas rutas: colocarlas en `server.js` (o extraer por routers manteniendo prefijo `/api`).
- SQL: agrega SPs en `sql/StoredProcedures.sql` y consúmelos con `executeStoredProcedure()`.
- Mongo: agrega nuevos modelos en `config/database.mongo.js` si es necesario, manteniendo `strict:false` cuando se requiera flexibilidad.
- Respuestas JSON coherentes con las ya usadas por `public/js/app.js`.

---
Este archivo busca acelerar a Copilot con contexto real del proyecto: qué hace, cómo corre, cómo se estructura y qué trampas evitar. Mantenerlo en sync con el código y scripts.
