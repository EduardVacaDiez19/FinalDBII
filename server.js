// =============================================
// SERVIDOR PRINCIPAL - Sistema Clínica Dental
// Arquitectura Híbrida: SQL Server + MongoDB
// =============================================

const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

// Configuraciones de BD
const { sql, executeStoredProcedure } = require('./config/database.sql');
const {  connectMongoDB, Expediente, Proveedor, Encuesta, Marketing } = require('./config/database.mongo');

const app = express();
const PORT = process.env.PORT || 3000;

// =============================================
// MIDDLEWARES
// =============================================
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Logger
app.use((req, res, next) => {
    console.log(`${req.method} ${req.url}`);
    next();
});

// =============================================
// RUTAS DE AUTENTICACIÓN (SQL Server)
// =============================================

// Login - Usa el SP ValidarLogin
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        const result = await executeStoredProcedure('ValidarLogin', {
            NombreUsuario: username,
            Password: password
        });

        if (result.recordset && result.recordset.length > 0) {
            const usuario = result.recordset[0];
            res.json({
                success: true,
                message: 'Login exitoso',
                usuario: {
                    usuarioID: usuario.UsuarioID,
                    nombreUsuario: usuario.NombreUsuario,
                    rol: usuario.NombreRol,
                    pacienteID: usuario.PacienteID,
                    doctorID: usuario.DoctorID,
                    nombreReal: usuario.NombreReal
                }
            });
        } else {
            res.status(401).json({
                success: false,
                message: 'Credenciales incorrectas'
            });
        }
    } catch (error) {
        console.error('Error en login:', error);
        res.status(500).json({
            success: false,
            message: 'Error en el servidor',
            error: error.message
        });
    }
});

// =============================================
// RUTAS DE PACIENTES (SQL Server)
// =============================================

// Listar pacientes
app.get('/api/pacientes', async (req, res) => {
    try {
        const pool = await require('./config/database.sql').getConnection();
        const result = await pool.request().query(`
            SELECT P.PacienteID, P.Nombre, P.Apellido, P.FechaNacimiento, 
                   P.Telefono, P.Direccion, P.Alergias,
                   U.Email, U.NombreUsuario
            FROM Pacientes P
            INNER JOIN Usuarios U ON P.UsuarioID = U.UsuarioID
            WHERE U.Estado = 1
            ORDER BY P.Apellido, P.Nombre
        `);
        
        res.json({
            success: true,
            data: result.recordset,
            count: result.recordset.length
        });
    } catch (error) {
        console.error('Error al listar pacientes:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener pacientes'
        });
    }
});

// Registrar paciente - Usa sp_RegistrarPacienteWeb
app.post('/api/pacientes', async (req, res) => {
    try {
        const { nombreUsuario, email, password, nombre, apellido, fechaNacimiento, telefono, direccion, alergias } = req.body;

        const result = await executeStoredProcedure('sp_RegistrarPacienteWeb', {
            NombreUsuario: nombreUsuario,
            Email: email,
            PasswordTextoPlano: password,
            Nombre: nombre,
            Apellido: apellido,
            FechaNac: fechaNacimiento,
            Telefono: telefono,
            Direccion: direccion,
            Alergias: alergias || 'Ninguna',
            output: {
                Mensaje: { type: sql.VarChar(100) }
            }
        });

        const mensaje = result.output.Mensaje;
        
        if (mensaje.includes('Éxito')) {
            res.status(201).json({
                success: true,
                message: mensaje
            });
        } else {
            res.status(400).json({
                success: false,
                message: mensaje
            });
        }
    } catch (error) {
        console.error('Error al registrar paciente:', error);
        res.status(500).json({
            success: false,
            message: 'Error al registrar paciente'
        });
    }
});

// Actualizar paciente - Usa sp_ActualizarPaciente
app.put('/api/pacientes/:id', async (req, res) => {
    try {
        const pacienteID = parseInt(req.params.id);
        const { telefono, direccion } = req.body;

        const result = await executeStoredProcedure('sp_ActualizarPaciente', {
            PacienteID: pacienteID,
            NuevoTelefono: telefono,
            NuevaDireccion: direccion,
            output: {
                Mensaje: { type: sql.VarChar(100) }
            }
        });

        const mensaje = result.output.Mensaje;
        
        res.json({
            success: mensaje.includes('Éxito'),
            message: mensaje
        });
    } catch (error) {
        console.error('Error al actualizar paciente:', error);
        res.status(500).json({
            success: false,
            message: 'Error al actualizar paciente'
        });
    }
});

// Eliminar paciente (Soft Delete) - Usa sp_EliminarPacienteWeb
app.delete('/api/pacientes/:id', async (req, res) => {
    try {
        const pacienteID = parseInt(req.params.id);

        const result = await executeStoredProcedure('sp_EliminarPacienteWeb', {
            PacienteID: pacienteID,
            output: {
                Mensaje: { type: sql.VarChar(100) }
            }
        });

        const mensaje = result.output.Mensaje;
        
        res.json({
            success: mensaje.includes('Éxito'),
            message: mensaje
        });
    } catch (error) {
        console.error('Error al eliminar paciente:', error);
        res.status(500).json({
            success: false,
            message: 'Error al eliminar paciente'
        });
    }
});

// =============================================
// RUTAS DE CITAS (SQL Server)
// =============================================

// Listar citas
app.get('/api/citas', async (req, res) => {
    try {
        const pool = await require('./config/database.sql').getConnection();
        const result = await pool.request().query(`
            SELECT C.CitaID, C.FechaCita, C.EstadoCita,
                   P.Nombre + ' ' + P.Apellido AS NombrePaciente,
                   D.Nombre + ' ' + D.Apellido AS NombreDoctor,
                   D.Especialidad
            FROM Citas C
            INNER JOIN Pacientes P ON C.PacienteID = P.PacienteID
            INNER JOIN Doctores D ON C.DoctorID = D.DoctorID
            ORDER BY C.FechaCita DESC
        `);
        
        res.json({
            success: true,
            data: result.recordset,
            count: result.recordset.length
        });
    } catch (error) {
        console.error('Error al listar citas:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener citas'
        });
    }
});

// Agendar cita - Usa sp_AgendarCita
app.post('/api/citas', async (req, res) => {
    try {
        const { pacienteID, doctorID, fechaCita } = req.body;

        const result = await executeStoredProcedure('sp_AgendarCita', {
            PacienteID: pacienteID,
            DoctorID: doctorID,
            FechaCita: fechaCita,
            output: {
                MensajeSalida: { type: sql.VarChar(100) }
            }
        });

        const mensaje = result.output.MensajeSalida;
        
        if (mensaje.includes('Exito')) {
            res.status(201).json({
                success: true,
                message: mensaje
            });
        } else {
            res.status(400).json({
                success: false,
                message: mensaje
            });
        }
    } catch (error) {
        console.error('Error al agendar cita:', error);
        res.status(500).json({
            success: false,
            message: 'Error al agendar cita'
        });
    }
});

// Listar doctores
app.get('/api/doctores', async (req, res) => {
    try {
        const pool = await require('./config/database.sql').getConnection();
        const result = await pool.request().query(`
            SELECT D.DoctorID, D.Nombre, D.Apellido, D.Especialidad, D.NumeroLicencia, D.Telefono
            FROM Doctores D
            INNER JOIN Usuarios U ON D.UsuarioID = U.UsuarioID
            WHERE U.Estado = 1
            ORDER BY D.Nombre
        `);
        
        res.json({
            success: true,
            data: result.recordset
        });
    } catch (error) {
        console.error('Error al listar doctores:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener doctores'
        });
    }
});

// =============================================
// RUTAS DE EXPEDIENTES (MongoDB)
// =============================================

// Listar expedientes
app.get('/api/expedientes', async (req, res) => {
    try {
        const expedientes = await Expediente.find().sort({ paciente_id: 1 });
        res.json({
            success: true,
            data: expedientes,
            count: expedientes.length
        });
    } catch (error) {
        console.error('Error al listar expedientes:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener expedientes'
        });
    }
});

// Obtener expediente por ID de paciente
app.get('/api/expedientes/paciente/:id', async (req, res) => {
    try {
        const pacienteID = parseInt(req.params.id);
        const expediente = await Expediente.findOne({ paciente_id: pacienteID });
        
        if (!expediente) {
            return res.status(404).json({
                success: false,
                message: 'Expediente no encontrado'
            });
        }
        
        res.json({
            success: true,
            data: expediente
        });
    } catch (error) {
        console.error('Error al obtener expediente:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener expediente'
        });
    }
});

// =============================================
// RUTAS DE INVENTARIO/PROVEEDORES (MongoDB)
// =============================================

// Listar productos
app.get('/api/inventario/productos', async (req, res) => {
    try {
        const productos = await Proveedor.find();
        res.json({
            success: true,
            data: productos,
            count: productos.length
        });
    } catch (error) {
        console.error('Error al listar productos:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener productos'
        });
    }
});

// =============================================
// RUTAS DE ENCUESTAS (MongoDB)
// =============================================

// Listar encuestas
app.get('/api/encuestas', async (req, res) => {
    try {
        const encuestas = await Encuesta.find().sort({ fecha: -1 });
        
        // Calcular estadísticas
        const totalEncuestas = encuestas.length;
        const promedioGeneral = totalEncuestas > 0
            ? (encuestas.reduce((sum, e) => sum + e.puntuacion_general, 0) / totalEncuestas).toFixed(2)
            : 0;
        
        res.json({
            success: true,
            data: encuestas,
            count: totalEncuestas,
            estadisticas: {
                promedioGeneral,
                totalEncuestas
            }
        });
    } catch (error) {
        console.error('Error al listar encuestas:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener encuestas'
        });
    }
});

// Crear encuesta
app.post('/api/encuestas', async (req, res) => {
    try {
        const nuevaEncuesta = new Encuesta({
            ...req.body,
            fecha: new Date()
        });
        
        await nuevaEncuesta.save();
        
        res.status(201).json({
            success: true,
            message: 'Encuesta registrada exitosamente',
            data: nuevaEncuesta
        });
    } catch (error) {
        console.error('Error al crear encuesta:', error);
        res.status(500).json({
            success: false,
            message: 'Error al registrar encuesta'
        });
    }
});

// =============================================
// RUTAS DE REPORTES/DASHBOARD
// =============================================

// Reporte de ingresos del día - Usa sp_ReporteIngresosDia
app.get('/api/reportes/ingresos-dia', async (req, res) => {
    try {
        const result = await executeStoredProcedure('ReporteIngresosDia');
        
        res.json({
            success: true,
            data: result.recordset[0]
        });
    } catch (error) {
        console.error('Error al obtener reporte:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener reporte de ingresos'
        });
    }
});

// =============================================
// RUTA PRINCIPAL
// =============================================
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api', (req, res) => {
    res.json({
        message: '🏥 API Clínica Dental - Sistema Completo',
        version: '1.0.0',
        database: {
            sql: 'ClinicaDentalDB',
            mongodb: 'ClinicaDentalNoSQL'
        }
    });
});

// Manejo de errores
app.use((err, req, res, next) => {
    console.error('Error:', err.stack);
    res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
    });
});

// =============================================
// INICIAR SERVIDOR
// =============================================
const startServer = async () => {
    try {
        console.log('🚀 Iniciando Sistema Clínica Dental...\n');

        // Conectar SQL Server
        console.log('📊 Conectando a SQL Server (ClinicaDentalDB)...');
        await require('./config/database.sql').getConnection();

        // Conectar MongoDB
        console.log('🍃 Conectando a MongoDB (ClinicaDentalNoSQL)...');
        await connectMongoDB();

        // Iniciar servidor
        app.listen(PORT, () => {
            console.log('\n✅ SISTEMA INICIADO CORRECTAMENTE\n');
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            console.log(`🌐 Servidor: http://localhost:${PORT}`);
            console.log(`📡 API: http://localhost:${PORT}/api`);
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            console.log('\n💡 Credenciales de prueba:');
            console.log('   Usuario: luis.s');
            console.log('   Contraseña: Paciente123!\n');
        });

    } catch (error) {
        console.error('\n❌ ERROR AL INICIAR:', error);
        process.exit(1);
    }
};

// Manejo de cierre
process.on('SIGINT', () => {
    console.log('\n⚠️  Cerrando servidor...');
    process.exit(0);
});

startServer();
