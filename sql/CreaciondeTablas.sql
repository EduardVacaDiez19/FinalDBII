CREATE DATABASE ClinicaDentalDB;
GO

USE ClinicaDentalDB;
GO

-- Tabla de Roles (Para manejar Admin, Paciente, Dentista, etc.)
CREATE TABLE Roles (
    RolID INT IDENTITY(1,1) PRIMARY KEY,
    NombreRol VARCHAR(50) NOT NULL UNIQUE, 
    Descripcion VARCHAR(255)
);

-- Tabla de Usuarios (Credenciales de acceso)

CREATE TABLE Usuarios (
    UsuarioID INT IDENTITY(1,1) PRIMARY KEY,
    NombreUsuario VARCHAR(50) NOT NULL UNIQUE,
    Email VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL, 
    RolID INT NOT NULL,
    FechaRegistro DATETIME DEFAULT GETDATE(),
    Estado BIT DEFAULT 1, -- 1: Activo, 0: Inactivo
    CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (RolID) REFERENCES Roles(RolID)
);

-- 3. Crear Tablas de Entidades Principales

-- Tabla de Doctores/Dentistas
CREATE TABLE Doctores (
    DoctorID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Apellido VARCHAR(100) NOT NULL,
    Especialidad VARCHAR(100) NOT NULL,
    NumeroLicencia VARCHAR(50) NOT NULL UNIQUE,
    Telefono VARCHAR(20),
    UsuarioID INT NULL, -- Opcional: Si el doctor también se loguea en el sistema
    CONSTRAINT FK_Doctores_Usuarios FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

-- Tabla de auditorias

CREATE TABLE AuditoriaPacientes (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    PacienteID INT,
    Accion VARCHAR(50), -- 'Insertar', 'Modificar', 'Borrar'
    DatosAntiguos VARCHAR(MAX),
    DatosNuevos VARCHAR(MAX),
    FechaCambio DATETIME DEFAULT GETDATE(),
    UsuarioSistema VARCHAR(100) -- Quién hizo el cambio en SQL
);
GO

-- Tabala de historial de precios

CREATE TABLE HistorialPrecios (
    HistorialID INT IDENTITY(1,1) PRIMARY KEY,
    ServicioID INT,
    PrecioAnterior DECIMAL(10, 2),
    PrecioNuevo DECIMAL(10, 2),
    FechaCambio DATETIME DEFAULT GETDATE(),
    UsuarioResponsable VARCHAR(100)
);
GO

-- Tabla de Pacientes
-- Se vincula con UsuarioID para que puedan iniciar sesión
CREATE TABLE Pacientes (
    PacienteID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL UNIQUE, -- Relación 1 a 1 con Usuarios
    Nombre VARCHAR(100) NOT NULL,
    Apellido VARCHAR(100) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Telefono VARCHAR(20),
    Direccion VARCHAR(255),
    Alergias VARCHAR(MAX), -- Información clínica básica
    CONSTRAINT FK_Pacientes_Usuarios FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

-- Tabla de Servicios o Tratamientos (Catálogo)
CREATE TABLE Servicios (
    ServicioID INT IDENTITY(1,1) PRIMARY KEY,
    NombreServicio VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(255),
    PrecioBase DECIMAL(10, 2) NOT NULL CHECK (PrecioBase >= 0)
);

-- 4. Crear Tablas Transaccionales (Citas y Tratamientos)

-- Tabla de Citas (Cabecera)
CREATE TABLE Citas (
    CitaID INT IDENTITY(1,1) PRIMARY KEY,
    PacienteID INT NOT NULL,
    DoctorID INT NOT NULL,
    FechaCita DATETIME NOT NULL,
    EstadoCita VARCHAR(20) NOT NULL DEFAULT 'Pendiente', 
    FechaCreacion DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Citas_Pacientes FOREIGN KEY (PacienteID) REFERENCES Pacientes(PacienteID),
    CONSTRAINT FK_Citas_Doctores FOREIGN KEY (DoctorID) REFERENCES Doctores(DoctorID),
    -- Constraint para validar estados válidos
    CONSTRAINT CHK_EstadoCita CHECK (EstadoCita IN ('Pendiente', 'Confirmada', 'Cancelada', 'Completada'))
);

-- Tabla de Detalles de Cita (Qué se hizo en la cita)
-- Relación muchos a muchos entre Citas y Servicios
CREATE TABLE DetalleCita (
    DetalleID INT IDENTITY(1,1) PRIMARY KEY,
    CitaID INT NOT NULL,
    ServicioID INT NOT NULL,
    PrecioAplicado DECIMAL(10, 2) NOT NULL, -- El precio puede variar del base (descuentos, etc.)
    Observaciones VARCHAR(MAX),
    DienteTratado VARCHAR(50), -- Opcional, para odontograma
    CONSTRAINT FK_Detalle_Citas FOREIGN KEY (CitaID) REFERENCES Citas(CitaID),
    CONSTRAINT FK_Detalle_Servicios FOREIGN KEY (ServicioID) REFERENCES Servicios(ServicioID)
);

-- Tabla de Historial de Pagos (Para completar el ciclo transaccional)
USE ClinicaDentalDB;
GO

-- 2. Creamos la tabla PAGOS con TODAS las columnas necesarias
CREATE TABLE Pagos (
    PagoID INT IDENTITY(1,1) PRIMARY KEY,
    CitaID INT NOT NULL,
    Monto DECIMAL(10, 2) NOT NULL,        -- Esta columna faltaba
    FechaPago DATETIME DEFAULT GETDATE(), -- Esta columna faltaba
    MetodoPago VARCHAR(50), 
    CONSTRAINT FK_Pagos_Citas FOREIGN KEY (CitaID) REFERENCES Citas(CitaID)
);
GO

--Insertar datos

-- 1. Insertar Roles (Si no existen aún)
INSERT INTO Roles (NombreRol, Descripcion) VALUES 
('Administrador', 'Acceso total al sistema'),
('Dentista', 'Personal médico, ve agenda y pacientes'),
('Paciente', 'Cliente, ve sus citas e historial');
GO

-- 2. Insertar Servicios (Catálogo de Tratamientos)
INSERT INTO Servicios (NombreServicio, Descripcion, PrecioBase) VALUES 
('Consulta General', 'Evaluación inicial y diagnóstico', 150.00),
('Limpieza Dental Profunda', 'Profilaxis y eliminación de sarro', 250.00),
('Obturación con Resina', 'Restauración de diente con caries (Tapadura)', 300.00),
('Extracción Simple', 'Extracción de pieza dental no quirúrgica', 200.00),
('Blanqueamiento LED', 'Blanqueamiento estético avanzado', 1200.00),
('Endodoncia (Tratamiento de Canal)', 'Desvitalización del nervio dental', 800.00),
('Ortodoncia Mensual', 'Control y ajuste de brackets', 350.00);
GO

-- =============================================
-- 3. INSERTAR DOCTORES (5 Odontólogos)
-- Se crea primero el usuario, se captura el ID y se crea el doctor
-- =============================================

DECLARE @IdRolDentista INT = (SELECT RolID FROM Roles WHERE NombreRol = 'Dentista');
DECLARE @IdNuevoUsuario INT;

-- =============================================
-- DOCTOR 1: Juan Pérez (Ortodoncista)
-- =============================================
-- 1. Insertamos el Usuario (Si ya existe, dará error, ignóralo y sigue al paso 2)
INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
VALUES ('dr.juan', 'juan.perez@clinica.com', HASHBYTES('SHA2_256', 'Doctor123!'), (SELECT RolID FROM Roles WHERE NombreRol = 'Dentista'));

-- 2. Insertamos el Doctor BUSCANDO el ID del usuario directamente
INSERT INTO Doctores (Nombre, Apellido, Especialidad, NumeroLicencia, Telefono, UsuarioID)
VALUES ('Juan', 'Pérez', 'Ortodoncia', 'ORT-001', '7001-0001', 
       (SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'dr.juan')); -- <--- AQUÍ ESTÁ EL TRUCO
GO

-- =============================================
-- DOCTOR 2: Ana López (Odontopediatra)
-- =============================================
INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
VALUES ('dra.ana', 'ana.lopez@clinica.com', HASHBYTES('SHA2_256', 'Doctor123!'), (SELECT RolID FROM Roles WHERE NombreRol = 'Dentista'));

INSERT INTO Doctores (Nombre, Apellido, Especialidad, NumeroLicencia, Telefono, UsuarioID)
VALUES ('Ana', 'López', 'Odontopediatría', 'PED-002', '7001-0002', 
       (SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'dra.ana'));
GO

-- =============================================
-- DOCTOR 3: Carlos Ruiz (Cirujano)
-- =============================================
INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
VALUES ('dr.carlos', 'carlos.ruiz@clinica.com', HASHBYTES('SHA2_256', 'Doctor123!'), (SELECT RolID FROM Roles WHERE NombreRol = 'Dentista'));

INSERT INTO Doctores (Nombre, Apellido, Especialidad, NumeroLicencia, Telefono, UsuarioID)
VALUES ('Carlos', 'Ruiz', 'Cirugía Maxilofacial', 'CIR-003', '7001-0003', 
       (SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'dr.carlos'));
GO

-- =============================================
-- DOCTOR 4: Elena Diaz (General)
-- =============================================
INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
VALUES ('dra.elena', 'elena.diaz@clinica.com', HASHBYTES('SHA2_256', 'Doctor123!'), (SELECT RolID FROM Roles WHERE NombreRol = 'Dentista'));

INSERT INTO Doctores (Nombre, Apellido, Especialidad, NumeroLicencia, Telefono, UsuarioID)
VALUES ('Elena', 'Díaz', 'Odontología General', 'GEN-004', '7001-0004', 
       (SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'dra.elena'));
GO

-- =============================================
-- DOCTOR 5: Mario Gomez (Endodoncista)
-- =============================================
INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
VALUES ('dr.mario', 'mario.gomez@clinica.com', HASHBYTES('SHA2_256', 'Doctor123!'), (SELECT RolID FROM Roles WHERE NombreRol = 'Dentista'));

INSERT INTO Doctores (Nombre, Apellido, Especialidad, NumeroLicencia, Telefono, UsuarioID)
VALUES ('Mario', 'Gómez', 'Endodoncia', 'END-005', '7001-0005', 
       (SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'dr.mario'));
GO


-- =============================================
-- 4. INSERTAR PACIENTES (5 Pacientes)
-- =============================================

DECLARE @IdRolPaciente INT = (SELECT RolID FROM Roles WHERE NombreRol = 'Paciente');

USE ClinicaDentalDB;
GO

-- =============================================
-- PACIENTE 1: Luis Silva
-- =============================================
IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = 'luis.s')
BEGIN
    -- 1. Crear Usuario
    INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
    VALUES ('luis.s', 'luis.silva@gmail.com', HASHBYTES('SHA2_256', 'Paciente123!'), 
           (SELECT RolID FROM Roles WHERE NombreRol = 'Paciente'));

    -- 2. Crear Paciente (Buscando el ID del usuario recién creado)
    INSERT INTO Pacientes (UsuarioID, Nombre, Apellido, FechaNacimiento, Telefono, Direccion, Alergias)
    VALUES ((SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'luis.s'), 
            'Luis', 'Silva', '1990-05-15', '6001-0001', 'Av. Las Palmeras 123', 'Ninguna');
END
GO

-- =============================================
-- PACIENTE 2: Maria Garcia
-- =============================================
IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = 'maria.g')
BEGIN
    INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
    VALUES ('maria.g', 'maria.garcia@hotmail.com', HASHBYTES('SHA2_256', 'Paciente123!'), 
           (SELECT RolID FROM Roles WHERE NombreRol = 'Paciente'));

    INSERT INTO Pacientes (UsuarioID, Nombre, Apellido, FechaNacimiento, Telefono, Direccion, Alergias)
    VALUES ((SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'maria.g'), 
            'María', 'García', '1985-11-20', '6001-0002', 'Calle 24 de Septiembre', 'Penicilina');
END
GO

-- =============================================
-- PACIENTE 3: Pedro Torres
-- =============================================
IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = 'pedro.t')
BEGIN
    INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
    VALUES ('pedro.t', 'pedro.torres@yahoo.com', HASHBYTES('SHA2_256', 'Paciente123!'), 
           (SELECT RolID FROM Roles WHERE NombreRol = 'Paciente'));

    INSERT INTO Pacientes (UsuarioID, Nombre, Apellido, FechaNacimiento, Telefono, Direccion, Alergias)
    VALUES ((SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'pedro.t'), 
            'Pedro', 'Torres', '2001-02-10', '6001-0003', 'Barrio Equipetrol', 'Ninguna');
END
GO

-- =============================================
-- PACIENTE 4: Sofia Mendez
-- =============================================
IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = 'sofia.m')
BEGIN
    INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
    VALUES ('sofia.m', 'sofia.mendez@gmail.com', HASHBYTES('SHA2_256', 'Paciente123!'), 
           (SELECT RolID FROM Roles WHERE NombreRol = 'Paciente'));

    INSERT INTO Pacientes (UsuarioID, Nombre, Apellido, FechaNacimiento, Telefono, Direccion, Alergias)
    VALUES ((SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'sofia.m'), 
            'Sofía', 'Méndez', '1995-08-30', '6001-0004', 'Condominio Sevilla', 'Látex');
END
GO

-- =============================================
-- PACIENTE 5: Jorge Vargas
-- =============================================
IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = 'jorge.v')
BEGIN
    INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID) 
    VALUES ('jorge.v', 'jorge.vargas@outlook.com', HASHBYTES('SHA2_256', 'Paciente123!'), 
           (SELECT RolID FROM Roles WHERE NombreRol = 'Paciente'));

    INSERT INTO Pacientes (UsuarioID, Nombre, Apellido, FechaNacimiento, Telefono, Direccion, Alergias)
    VALUES ((SELECT UsuarioID FROM Usuarios WHERE NombreUsuario = 'jorge.v'), 
            'Jorge', 'Vargas', '1978-12-05', '6001-0005', 'Zona Sur', 'Ibuprofeno');
END
GO

USE ClinicaDentalDB;
GO

-- 1. Agregamos la columna Monto si no existe