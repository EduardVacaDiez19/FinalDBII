const mongoose = require('mongoose');
require('dotenv').config();

// Schemas with strict: false to allow flexible data as seen in Mongodb.js
const expedienteSchema = new mongoose.Schema({}, { strict: false, collection: 'Expedientes' });
const proveedorSchema = new mongoose.Schema({}, { strict: false, collection: 'Proveedores' });
const encuestaSchema = new mongoose.Schema({}, { strict: false, collection: 'Encuestas' });
const marketingSchema = new mongoose.Schema({}, { strict: false, collection: 'Marketing' });

// Models
const Expediente = mongoose.model('Expediente', expedienteSchema);
const Proveedor = mongoose.model('Proveedor', proveedorSchema);
const Encuesta = mongoose.model('Encuesta', encuestaSchema);
const Marketing = mongoose.model('Marketing', marketingSchema);

async function connectMongoDB() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB connected successfully');
    } catch (error) {
        console.error('MongoDB connection error:', error);
        // Don't throw to allow app to start even if Mongo is down, 
        // though server.js awaits it.
        // But server.js expects it to succeed or exits.
        throw error;
    }
}

module.exports = {
    connectMongoDB,
    Expediente,
    Proveedor,
    Encuesta,
    Marketing
};
