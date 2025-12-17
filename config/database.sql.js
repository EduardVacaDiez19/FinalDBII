require('dotenv').config();

// En Linux/Docker, siempre usamos SQL AUTH aunque SQL_USER='.'
// El '.' es solo un marcador para indicar autenticación Windows
const sql = require('mssql');

// Determinamos si usamos autenticación de Windows
const useWindowsAuth = !process.env.SQL_USER ||
    process.env.SQL_USER.trim() === '' ||
    process.env.SQL_USER.trim() === '.';

const config = {
    server: process.env.SQL_SERVER || 'localhost',
    database: process.env.SQL_DATABASE || 'ClinicaDentalDB',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true
    }
};

if (useWindowsAuth) {
    // Para Linux/Docker con SQL Server en contenedor:
    // Usa usuario SA (admin por defecto)
    console.log(`🔌 Configurando SQL Server CON AUTENTICACIÓN WINDOWS`);
    console.log(`   → En Docker/Linux usando usuario SA (SQL Auth alternativa)`);
    config.user = process.env.SQL_USER_DOCKER || 'sa';
    config.password = process.env.SQL_PASSWORD_DOCKER || 'YourStrong!Passw0rd';
    config.port = parseInt(process.env.SQL_PORT) || 1433;
} else {
    console.log(`🔌 Configurando SQL Server con SQL AUTH (User: ${process.env.SQL_USER})`);
    config.user = process.env.SQL_USER;
    config.password = process.env.SQL_PASSWORD;
    config.port = parseInt(process.env.SQL_PORT) || 1433;
}

let pool = null;

async function getConnection() {
    try {
        if (pool) return pool;
        pool = await sql.connect(config);
        console.log('Connected to SQL Server');
        return pool;
    } catch (error) {
        console.error('SQL Connection Error:', error);
        throw error;
    }
}

async function executeStoredProcedure(procName, params = {}) {
    try {
        const pool = await getConnection();
        const request = pool.request();

        // Add inputs
        for (const [key, value] of Object.entries(params)) {
            if (key !== 'output') {
                request.input(key, value);
            }
        }

        // Add outputs
        if (params.output) {
            for (const [key, type] of Object.entries(params.output)) {
                // Handle complex output definition like { type: sql.VarChar(100) }
                const dataType = type.type || type;
                request.output(key, dataType);
            }
        }

        const result = await request.execute(procName);
        return result;
    } catch (error) {
        console.error(`Error executing SP ${procName}:`, error);
        throw error;
    }
}

module.exports = {
    sql,
    getConnection,
    executeStoredProcedure
};
