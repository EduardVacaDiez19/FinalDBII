# PRIMEROS PASOS — SISTEMA CLÍNICA DENTAL

Guía práctica para poner en marcha el proyecto de forma confiable en Windows, Linux o macOS. Usa un lenguaje directo, comandos copiables y el mínimo de suposiciones.

## PRINCIPIOS FUNDAMENTALES

Estos principios guían todo el proceso de instalación:

- **UN OBJETIVO:** Ver la aplicación funcionando en `http://localhost:3000` y la API en `http://localhost:3000/api`
- **UNA VERDAD FUENTE:** Los scripts SQL en `sql/` y el archivo `Mongodb.js` definen el estado base de las bases de datos
- **UN PASO A LA VEZ:** Ejecuta los comandos en orden. No te adelantes ni saltes pasos
- **SIN MAGIA:** Cada error tiene una causa. Lee el mensaje, verifica variables y servicios

## PRERREQUISITOS

- **Node.js LTS** (versión 18 o superior) y npm
- **Git** (para clonar el repositorio)
- **SQL Server** (2019 o superior):
  - Windows: Instalación local + SQL Server Management Studio (SSMS)
  - Linux/macOS: Contenedor Docker oficial de SQL Server
- **MongoDB** (versión 6 o superior):
  - Servicio local (`mongod`)
  - O contenedor Docker de MongoDB

**Opcional pero útil:** `curl` para probar la API desde terminal

## VARIABLES DE ENTORNO

Crea el archivo `.env` en la raíz del proyecto copiando desde `.env.example`:

```bash
cp .env.example .env
```

Ajusta las credenciales según tu entorno. **En Linux/macOS usa SIEMPRE autenticación SQL:**

```ini
PORT=3000

# SQL Server (autenticación SQL recomendada fuera de Windows)
SQL_SERVER=localhost
SQL_DATABASE=ClinicaDentalDB
SQL_USER=sa
SQL_PASSWORD=YourStrong!Passw0rd
SQL_PORT=1433

# MongoDB
MONGO_URI=mongodb://localhost:27017/ClinicaDentalNoSQL
```

**Notas importantes:**
- En Linux/macOS **DEBES** definir `SQL_USER` y `SQL_PASSWORD` para evitar problemas con `msnodesqlv8`
- La configuración por defecto usa `encrypt: false` y `trustServerCertificate: true` para desarrollo local

## INSTALACIÓN RÁPIDA (CON DOCKER)

Si no tienes SQL Server/MongoDB instalados localmente, usa contenedores Docker.

### 1. Levanta SQL Server en Docker

Monta la carpeta `sql/` desde el inicio para poder ejecutar los scripts:

```bash
docker run -d --name sqldental \
  -e 'ACCEPT_EULA=Y' \
  -e 'MSSQL_SA_PASSWORD=YourStrong!Passw0rd' \
  -p 1433:1433 \
  -v "$(pwd)/sql":/scripts \
  mcr.microsoft.com/mssql/server:2022-latest
```

**Espera 10-20 segundos** a que SQL Server inicie completamente.

### 2. Levanta MongoDB en Docker

```bash
docker run -d --name mongodental \
  -p 27017:27017 \
  mongo:6
```

### 3. Configura el proyecto

Crea el archivo `.env` e instala las dependencias:

```bash
cp .env.example .env
npm install
```

### 4. Inicializa SQL Server

Crea la base de datos y ejecuta los scripts en orden:

```bash
# Crear base de datos
docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong!Passw0rd' \
  -Q "CREATE DATABASE ClinicaDentalDB"

# Ejecutar scripts en orden
docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong!Passw0rd' \
  -d ClinicaDentalDB -i /scripts/CreaciondeTablas.sql

docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong!Passw0rd' \
  -d ClinicaDentalDB -i /scripts/StoredProcedures.sql

docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong!Passw0rd' \
  -d ClinicaDentalDB -i /scripts/Triggers.sql

docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong!Passw0rd' \
  -d ClinicaDentalDB -i /scripts/Transacciones.sql

docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong!Passw0rd' \
  -d ClinicaDentalDB -i /scripts/CreaciondeIndices.sql
```

### 5. Inicializa MongoDB

Ejecuta el script de semillas:

```bash
mongosh < Mongodb.js
```

### 6. Arranca el backend

Modo desarrollo con recarga automática:

```bash
npm run dev
```

### 7. Accede a la aplicación

Abre `http://localhost:3000` en tu navegador.

**Credenciales de prueba:**
- Usuario: `luis.s`
- Contraseña: `Paciente123!`

## INSTALACIÓN SIN DOCKER (SERVICIOS LOCALES)

### 1. SQL Server

**Windows:**
- Crea la base de datos `ClinicaDentalDB` con SQL Server Management Studio (SSMS)
- Ejecuta los scripts en orden:
  1. `sql/CreaciondeTablas.sql`
  2. `sql/StoredProcedures.sql`
  3. `sql/Triggers.sql`
  4. `sql/Transacciones.sql`
  5. `sql/CreaciondeIndices.sql`
  6. `sql/FixSecurity.sql` (opcional para seguridad adicional)

**Linux/macOS:**
- Instala las herramientas `sqlcmd`
- Ejecuta los scripts apuntando a tu instancia local

### 2. MongoDB

Asegura que el servicio `mongod` esté corriendo y ejecuta:

```bash
mongosh < Mongodb.js
```

### 3. Aplicación

Instala dependencias y arranca el servidor:

```bash
npm install
npm start      # Producción
# o
npm run dev    # Desarrollo con recarga automática
```

## PRUEBAS RÁPIDAS DE LA API

Verifica que la API está respondiendo correctamente:

```bash
# Saludo de la API
curl http://localhost:3000/api

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"luis.s","password":"Paciente123!"}'

# Obtener pacientes
curl http://localhost:3000/api/pacientes

# Obtener inventario
curl http://localhost:3000/api/inventario/productos

# Obtener encuestas
curl http://localhost:3000/api/encuestas
```

## ERRORES COMUNES Y SOLUCIÓN

### Error de driver `msnodesqlv8` en Linux/macOS
- **Causa:** Autenticación de Windows no disponible en estos sistemas
- **Solución:** Define `SQL_USER` y `SQL_PASSWORD` en `.env` para usar `mssql` puro

### `ECONNREFUSED` o timeout conectando a SQL Server
- Verifica que el contenedor/servicio esté activo
- Confirma que el puerto 1433 esté accesible
- Revisa el firewall
- Asegura que la base de datos `ClinicaDentalDB` existe y los scripts fueron ejecutados

### Error de conexión a MongoDB
- Verifica que `MONGO_URI` en `.env` sea correcto
- Confirma que `mongod` o el contenedor estén activos

### Login devuelve 401 (No autorizado)
- Verifica que los Stored Procedures se hayan ejecutado correctamente
- Las credenciales de prueba se crean durante el bootstrap de la base de datos

### CORS o recursos estáticos no cargan
- La aplicación sirve `public/` desde Express en el mismo puerto
- No cruces dominios distintos
- Verifica que el servidor esté corriendo en `http://localhost:3000`

### Datos vacíos en inventario/encuestas/expedientes
- Ejecuta el script de semillas: `mongosh < Mongodb.js`

## CONVENCIONES PARA EXTENDER

Si necesitas agregar funcionalidad al proyecto:

- **Nuevas rutas:** Agrégalas en `server.js` bajo el prefijo `/api/*` (o extrae por routers manteniendo el prefijo)
- **SQL Server:** Agrega stored procedures en `sql/StoredProcedures.sql` y consúmelos con `executeStoredProcedure()`
- **MongoDB:** Agrega nuevos modelos en `config/database.mongo.js` si es necesario, manteniendo `strict: false` cuando requieras flexibilidad
- **Respuestas JSON:** Mantén coherencia con el formato usado por `public/js/app.js`: `{ success, data, count, message, estadisticas }`

## MAPA RÁPIDO DEL REPOSITORIO

- `server.js` — Servidor Express principal con todas las rutas API
- `public/` — Frontend estático (HTML/CSS/JS)
  - `index.html` — Interfaz principal
  - `css/styles.css` — Estilos globales
  - `js/app.js` — Lógica del cliente
- `config/` — Configuraciones de bases de datos
  - `database.sql.js` — Wrapper para SQL Server
  - `database.mongo.js` — Conexión MongoDB y modelos
- `sql/` — Scripts de inicialización de SQL Server
- `Mongodb.js` — Script de semillas para MongoDB
- `.env.example` — Plantilla de variables de entorno
- `package.json` — Dependencias y scripts npm

---

**Si algo falla, vuelve a los principios fundamentales:** un objetivo, una verdad fuente, un paso a la vez. Documenta el mensaje exacto de error y el comando ejecutado; con eso, la causa aparece.
