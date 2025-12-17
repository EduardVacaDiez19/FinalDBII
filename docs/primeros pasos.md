# PRIMEROS PASOS — SISTEMA CLÍNICA DENTAL

Guía corta y universal para poner el proyecto en marcha de forma confiable en Windows, Linux o macOS. Usa un lenguaje directo, comandos copiables y el mínimo de suposiciones.

## AXIOMAS UNIVERSALES

- UN OBJETIVO: ver la app en [http://localhost:3000](http://localhost:3000) y la API en [http://localhost:3000/api](http://localhost:3000/api).
- UNA VERDAD FUENTE: los scripts SQL en `sql/` y el archivo `Mongodb.js` son el estado base de datos esperado.
- UN PASO A LA VEZ: ejecuta los comandos en orden; no "adelantes" pasos.
- SIN MAGIA: cada error tiene causa. Lee el mensaje, verifica variables y servicios.

## PRERREQUISITOS

- Node.js LTS (18+ recomendado) y npm
- Git
- SQL Server (2019+). Opciones:
	- Windows: instalación local + SQL Server Management Studio (SSMS)
	- Linux/macOS: contenedor Docker oficial de SQL Server
- MongoDB (6+). Opciones:
	- Servicio local (mongod)
	- Contenedor Docker de MongoDB

Opcional pero útil: `curl` para probar la API desde terminal.

## VARIABLES DE ENTORNO

Crea el archivo `.env` en la raíz copiando desde `.env.example` y ajusta credenciales. Valores mínimos recomendados (Linux/macOS usa SIEMPRE autenticación SQL):

```ini
PORT=3000

# SQL Auth (recomendado fuera de Windows)
SQL_SERVER=localhost
SQL_DATABASE=ClinicaDentalDB
SQL_USER=sa
SQL_PASSWORD=YourStrong!Passw0rd
SQL_PORT=1433

# Mongo
MONGO_URI=mongodb://localhost:27017/ClinicaDentalNoSQL
```

Notas:
- En Linux/macOS DEBES definir `SQL_USER` y `SQL_PASSWORD` para evitar `msnodesqlv8`.
- Certificados/TLS: la config por defecto usa `encrypt: false` y `trustServerCertificate: true`.

## INSTALACIÓN RÁPIDA (CON DOCKER PARA BD)

Si no tienes SQL Server/Mongo instalados localmente, usa contenedores. Abre una terminal en la raíz del repo.

1. Levanta SQL Server en Docker (contraseña fuerte requerida por la imagen):

```bash
docker run -d --name sqldental \
	-e 'ACCEPT_EULA=Y' \
	-e 'MSSQL_SA_PASSWORD=YourStrong!Passw0rd' \
	-p 1433:1433 \
	mcr.microsoft.com/mssql/server:2022-latest
```

1. Levanta MongoDB en Docker:

```bash
docker run -d --name mongodental -p 27017:27017 mongo:6
```

1. Crea `.env` y dependencias del proyecto:

```bash
cp .env.example .env
npm install
```

1. Copia el servidor a la raíz (el repo trae la versión lista en `mnt/...`):

```bash
cp mnt/user-data/outputs/clinica-dental-real/server.js ./server.js
```

1. Inicializa la base relacional ejecutando los scripts en orden dentro del contenedor SQL:

```bash
docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong!Passw0rd' -Q "CREATE DATABASE ClinicaDentalDB"
docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong!Passw0rd' -d ClinicaDentalDB -i /scripts/CreaciondeTablas.sql
docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong!Passw0rd' -d ClinicaDentalDB -i /scripts/StoredProcedures.sql
docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong!Passw0rd' -d ClinicaDentalDB -i /scripts/Triggers.sql
docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong!Passw0rd' -d ClinicaDentalDB -i /scripts/Transacciones.sql
docker exec -it sqldental /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong!Passw0rd' -d ClinicaDentalDB -i /scripts/CreaciondeIndices.sql
```

Para que los `-i` funcionen, monta la carpeta `sql/` dentro del contenedor (una sola vez, recreando el contenedor):

```bash
docker rm -f sqldental
docker run -d --name sqldental \
	-e 'ACCEPT_EULA=Y' \
	-e 'MSSQL_SA_PASSWORD=YourStrong!Passw0rd' \
	-p 1433:1433 \
	-v "$(pwd)/sql":/scripts \
	mcr.microsoft.com/mssql/server:2022-latest
# Espera ~10-20s a que inicie SQL y repite los comandos sqlcmd anteriores
```

1. Inicializa Mongo con datos de ejemplo:

```bash
mongosh < Mongodb.js
```

1. Arranca el backend (modo desarrollo con recarga):

```bash
npm run dev
```

Abre http://localhost:3000. Credenciales de prueba: usuario `luis.s`, contraseña `Paciente123!`.

## INSTALACIÓN SIN DOCKER (SERVICIOS LOCALES)

1) SQL Server
- Windows: crea BD `ClinicaDentalDB` con SSMS y ejecuta en orden los scripts en `sql/` (Tablas → StoredProcedures → Triggers → Transacciones → Índices). Opcional: `FixSecurity.sql`.
- Linux/macOS: instala herramientas `sqlcmd` y ejecuta los scripts apuntando a tu instancia local.

2) MongoDB
- Asegura el servicio `mongod` corriendo y ejecuta: `mongosh < Mongodb.js`.

3) App
- `cp mnt/user-data/outputs/clinica-dental-real/server.js ./server.js`
- `npm install`
- `npm start` o `npm run dev`

## PRUEBAS RÁPIDAS DE LA API

```bash
curl http://localhost:3000/api
curl -X POST http://localhost:3000/api/auth/login \
	-H 'Content-Type: application/json' \
	-d '{"username":"luis.s","password":"Paciente123!"}'
curl http://localhost:3000/api/pacientes
curl http://localhost:3000/api/inventario/productos
curl http://localhost:3000/api/encuestas
```

## ERRORES COMUNES Y SOLUCIÓN

- `npm start` falla por no encontrar `server.js` en la raíz
	- Solución: `cp mnt/user-data/outputs/clinica-dental-real/server.js ./server.js`

- Error de driver `msnodesqlv8` en Linux/macOS
	- Causa: autenticación de Windows no disponible
	- Solución: define `SQL_USER`/`SQL_PASSWORD` en `.env` para usar `mssql` puro

- `ECONNREFUSED` o tiempo de espera conectando a SQL Server
	- Verifica: contenedor/servicio activo, puerto 1433, firewall
	- Asegura que la BD `ClinicaDentalDB` existe y los scripts fueron ejecutados

- `MongoDB connection error`
	- Verifica `MONGO_URI` y que `mongod`/contenedor estén activos

- Login devuelve 401
	- Verifica que los Stored Procedures se ejecutaron; las credenciales de prueba se crean en el bootstrap

- CORS o recursos estáticos no cargan
	- La app sirve `public/` desde Express en el mismo puerto (no cruces dominios distintos)

## CONVENCIONES PARA EXTENDER

- Añade rutas bajo el prefijo `/api/*` siguiendo el patrón de `server.js`.
- SQL: consume SIEMPRE SPs vía `executeStoredProcedure()` (`config/database.sql.js`). Evita SQL en cadena.
- Mongo: modelos exportados desde `config/database.mongo.js` (`strict:false` para flexibilidad).
- Respuestas JSON coherentes con el frontend (`{ success, data, count, message, estadisticas }`).

## MAPA RÁPIDO DEL REPO

- `public/` Frontend estático (HTML/CSS/JS)
- `config/` Conexiones a BD (`database.sql.js`, `database.mongo.js`)
- `sql/` Scripts de base de datos relacional
- `Mongodb.js` Semillas para colecciones NoSQL
- `mnt/user-data/outputs/clinica-dental-real/server.js` Servidor listo para copiar a la raíz

---
Si algo falla, vuelve a los axiomas: uno objetivo, una verdad fuente, un paso a la vez. Documenta el mensaje exacto de error y el comando ejecutado; con eso, la causa aparece.
