require('dotenv').config();

// Determinamos si usamos autenticación de Windows (si no hay usuario definido)
const useWindowsAuth = !process.env.SQL_USER || process.env.SQL_USER.trim() === '';

// Importamos el driver correcto según el modo
const sql = useWindowsAuth ? require('mssql/msnodesqlv8') : require('mssql');

const config = {
    server: process.env.SQL_SERVER || '.',
    database: process.env.SQL_DATABASE || 'ClinicaDentalDB',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true
    }
};

if (useWindowsAuth) {
    console.log(`🔌 Configurando SQL Server con WINDOWS AUTHENTICATION (Server: ${config.server})`);
    config.options.trustedConnection = true;
    config.driver = 'msnodesqlv8';
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
