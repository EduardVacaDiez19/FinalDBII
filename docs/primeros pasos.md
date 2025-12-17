# PRIMEROS PASOS — SISTEMA CLÍNICA DENTAL

Guía corta para ejecutar el proyecto usando las bases de datos existentes. Sin necesidad de configurar bases de datos desde cero.

## REQUISITOS PREVIOS

- Node.js LTS (18+ recomendado) y npm
- **SQL Server ya corriendo** (local o en Docker)
- **MongoDB ya corriendo** (local o en Docker)
- `.env` configurado correctamente con credenciales de acceso

Si tienes SQL Server y MongoDB corriendo en Docker/locales, estás listo.

## CONFIGURACIÓN DEL PROYECTO

### 1. Copiar variables de entorno

Crea el archivo `.env` desde el template:

```bash
cp .env.example .env
```

Verifica que `.env` contenga credenciales correctas para acceder a tus bases de datos existentes:

```ini
PORT=3000
SQL_SERVER=localhost
SQL_DATABASE=ClinicaDentalDB
SQL_USER=sa
SQL_PASSWORD=YourStrong!Passw0rd
SQL_PORT=1433
MONGO_URI=mongodb://localhost:27017/ClinicaDentalNoSQL
```

### 2. Instalar dependencias

```bash
npm install
```

### 3. Ejecutar el servidor

**Modo desarrollo** (con recarga automática):

```bash
npm run dev
```

**Modo producción**:

```bash
npm start
```

### 4. Acceder a la aplicación

Abre en tu navegador: **[http://localhost:3000](http://localhost:3000)**

**Credenciales de prueba**:
- Usuario: `luis.s`
- Contraseña: `Paciente123!`

---

O si tienes un usuario admin en la BD:
- Usuario: `admin.edu`
- Contraseña: `AdminSeguro123!`

## PRUEBAS RÁPIDAS DE LA API

Verifica que la API está respondiendo:

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

## SOLUCIÓN RÁPIDA DE PROBLEMAS

**SQL Server no se conecta**
- Verifica que el servicio/contenedor esté corriendo
- Confirma que `SQL_SERVER`, `SQL_PORT`, `SQL_USER` y `SQL_PASSWORD` en `.env` son correctos

**MongoDB no se conecta**
- Verifica que el servicio/contenedor `mongod` esté activo
- Confirma que `MONGO_URI` en `.env` es accesible

**Login falla (401)**
- Asegúrate de que los Stored Procedures en SQL Server fueron ejecutados
- Verifica que el usuario existe en la tabla `Usuarios`

**Recursos estáticos no cargan**
- El servidor sirve `public/` automáticamente en el puerto especificado
- Verifica que `PORT` en `.env` sea 3000 (o el puerto que uses)

## ESTRUCTURA DEL PROYECTO

- `server.js` — API Express principal
- `public/` — Frontend estático
- `config/` — Configuración de bases de datos
- `sql/` — Scripts SQL de inicialización
- `Mongodb.js` — Semillas de MongoDB
