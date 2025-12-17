--SP para validar login

CREATE PROCEDURE ValidarLogin

    @NombreUsuario VARCHAR(50),
    @Password VARCHAR(50)

AS
BEGIN

    SET NOCOUNT ON; 

    DECLARE @PassHash VARBINARY(64);
    SET @PassHash = HASHBYTES('SHA2_256', @Password);

    SELECT 
        U.UsuarioID,
        U.NombreUsuario,
        R.NombreRol,
        -- Truco: Devolvemos el ID de Paciente o Doctor si corresponde
        ISNULL(P.PacienteID, 0) AS PacienteID,
        ISNULL(D.DoctorID, 0) AS DoctorID,
        ISNULL(P.Nombre, D.Nombre) AS NombreReal
    FROM Usuarios U
    INNER JOIN Roles R ON U.RolID = R.RolID
    LEFT JOIN Pacientes P ON U.UsuarioID = P.UsuarioID
    LEFT JOIN Doctores D ON U.UsuarioID = D.UsuarioID
    WHERE U.NombreUsuario = @NombreUsuario 
      AND U.PasswordHash = @PassHash
      AND U.Estado = 1; -- Solo usuarios activos
END
GO





--SP para agendar citas

CREATE PROCEDURE sp_AgendarCita
    @PacienteID INT,
    @DoctorID INT,
    @FechaCita DATETIME,
    @MensajeSalida VARCHAR(100) OUTPUT 
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validación: No agendar en el pasado
    IF @FechaCita < GETDATE()
    BEGIN
        SET @MensajeSalida = 'Error: No se pueden agendar citas en el pasado.';
        RETURN;
    END

    -- 2. El doctor no debe tener otra cita a la misma hora
    IF EXISTS (
        SELECT 1 FROM Citas 
        WHERE DoctorID = @DoctorID 
        AND FechaCita BETWEEN @FechaCita AND DATEADD(MINUTE, 29, @FechaCita)
        AND EstadoCita NOT IN ('Cancelada')
    )
    BEGIN
        SET @MensajeSalida = 'Error: El doctor ya tiene una cita en ese horario.';
        RETURN;
    END

    -- 3. Si pasa las validaciones, inserto
    INSERT INTO Citas (PacienteID, DoctorID, FechaCita, EstadoCita)
    VALUES (@PacienteID, @DoctorID, @FechaCita, 'Pendiente');

    SET @MensajeSalida = 'Exito: Cita agendada correctamente.';
END
GO





--SP para ver el historial del paciente

CREATE PROCEDURE ObtenerHistorialPaciente

    @UsuarioID INT

AS
BEGIN

    SET NOCOUNT ON;

    SELECT 

        C.CitaID,
        C.FechaCita,
        D.Nombre + ' ' + D.Apellido AS NombreDoctor,
        D.Especialidad,
        C.EstadoCita

    FROM Citas C
    INNER JOIN Pacientes P ON C.PacienteID = P.PacienteID
    INNER JOIN Doctores D ON C.DoctorID = D.DoctorID
    WHERE P.UsuarioID = @UsuarioID
    ORDER BY C.FechaCita DESC;

END
GO

--SP para Registrar pagos


-- 3. Ahora sí, creamos el Stored Procedure del Reporte
CREATE PROCEDURE sp_ReporteIngresosDia
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        COUNT(P.PagoID) as TotalPagos,
        ISNULL(SUM(P.Monto), 0) as TotalDinero,
        GETDATE() as FechaReporte
    FROM Pagos P
    WHERE CAST(P.FechaPago AS DATE) = CAST(GETDATE() AS DATE); -- Solo pagos de HOY
END
GO

--SP para reportes de ingreso. DASHBOARD admin

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Pagos' AND COLUMN_NAME = 'Monto')
BEGIN
    ALTER TABLE Pagos ADD Monto DECIMAL(10, 2);
END

-- 2. Agregamos la columna FechaPago si no existe
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Pagos' AND COLUMN_NAME = 'FechaPago')
BEGIN
    ALTER TABLE Pagos ADD FechaPago DATETIME DEFAULT GETDATE();
END
GO

CREATE PROCEDURE ReporteIngresosDia
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        COUNT(P.PagoID) as TotalPagos,
        ISNULL(SUM(P.Monto), 0) as TotalDinero,
        GETDATE() as FechaReporte
    FROM Pagos P
    WHERE CAST(P.FechaPago AS DATE) = CAST(GETDATE() AS DATE); -- Solo pagos de HOY
END
GO  


--SP para agregar un paciente 

CREATE PROCEDURE sp_RegistrarPacienteWeb
    @NombreUsuario VARCHAR(50),
    @Email VARCHAR(100),
    @PasswordTextoPlano VARCHAR(50),
    @Nombre VARCHAR(100),
    @Apellido VARCHAR(100),
    @FechaNac DATE,
    @Telefono VARCHAR(20),
    @Direccion VARCHAR(200),
    @Alergias VARCHAR(MAX),
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Validar duplicados
        IF EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = @NombreUsuario OR Email = @Email)
        BEGIN
            THROW 51000, 'Error: El usuario o correo ya existen.', 1;
        END

        -- 2. Insertar en USUARIOS
        DECLARE @NuevoID INT;
        
        -- Buscamos el ID del Rol 'Paciente' automáticamente
        DECLARE @RolPacienteID INT = (SELECT RolID FROM Roles WHERE NombreRol = 'Paciente');

        INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID, Estado)
        VALUES (@NombreUsuario, @Email, HASHBYTES('SHA2_256', @PasswordTextoPlano), @RolPacienteID, 1);
        
        SET @NuevoID = SCOPE_IDENTITY();

        -- 3. Insertar en PACIENTES
        INSERT INTO Pacientes (UsuarioID, Nombre, Apellido, FechaNacimiento, Telefono, Direccion, Alergias)
        VALUES (@NuevoID, @Nombre, @Apellido, @FechaNac, @Telefono, @Direccion, @Alergias);

        COMMIT TRANSACTION;
        SET @Mensaje = 'Éxito: Paciente registrado correctamente.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @Mensaje = 'Error al registrar: ' + ERROR_MESSAGE();
    END CATCH
END
GO


--Eliminar paciente
CREATE PROCEDURE sp_EliminarPacienteWeb
    @PacienteID INT,
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Buscamos el UsuarioID asociado a ese paciente
    DECLARE @UsuarioID INT;
    SELECT @UsuarioID = UsuarioID FROM Pacientes WHERE PacienteID = @PacienteID;

    IF @UsuarioID IS NULL
    BEGIN
        SET @Mensaje = 'Error: Paciente no encontrado.';
        RETURN;
    END

    -- 2. "Apagamos" al usuario (Estado = 0)
    -- Al poner Estado en 0, el SP de Login ya no lo dejará entrar.
    UPDATE Usuarios 
    SET Estado = 0 
    WHERE UsuarioID = @UsuarioID;

    SET @Mensaje = 'Éxito: El paciente ha sido dado de baja (Inactivo).';
END
GO




--SP para registrar un doctor
CREATE PROCEDURE sp_RegistrarDoctorAdmin
    @NombreUsuario VARCHAR(50),
    @Email VARCHAR(100),
    @PasswordTextoPlano VARCHAR(50),
    @Nombre VARCHAR(100),
    @Apellido VARCHAR(100),
    @Especialidad VARCHAR(100),
    @NumeroLicencia VARCHAR(50), -- Dato importante para doctores
    @Telefono VARCHAR(20),
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Validar duplicados (Usuario o Email)
        IF EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = @NombreUsuario OR Email = @Email)
        BEGIN
            THROW 51000, 'Error: El usuario o correo ya existen.', 1;
        END

        -- 2. Validar que no exista otro doctor con la misma Licencia
        IF EXISTS (SELECT 1 FROM Doctores WHERE NumeroLicencia = @NumeroLicencia)
        BEGIN
            THROW 51000, 'Error: Ya existe un doctor con esa Licencia Médica.', 1;
        END

        -- 3. Insertar en USUARIOS
        DECLARE @NuevoID INT;
        
        -- Buscamos el ID del Rol 'Dentista' (o 'Doctor')
        -- Nota: Asegúrate que en tu tabla Roles se llame 'Dentista' o 'Doctor'
        DECLARE @RolDoctorID INT = (SELECT TOP 1 RolID FROM Roles WHERE NombreRol IN ('Dentista', 'Doctor'));

        INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID, Estado)
        VALUES (@NombreUsuario, @Email, HASHBYTES('SHA2_256', @PasswordTextoPlano), @RolDoctorID, 1);
        
        SET @NuevoID = SCOPE_IDENTITY();

        -- 4. Insertar en DOCTORES
        INSERT INTO Doctores (UsuarioID, Nombre, Apellido, Especialidad, NumeroLicencia, Telefono)
        VALUES (@NuevoID, @Nombre, @Apellido, @Especialidad, @NumeroLicencia, @Telefono);

        COMMIT TRANSACTION;
        SET @Mensaje = 'Éxito: Doctor registrado correctamente.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @Mensaje = 'Error al registrar doctor: ' + ERROR_MESSAGE();
    END CATCH
END
GO




--SP para eliminar un doctor
CREATE PROCEDURE sp_EliminarDoctorAdmin
    @DoctorID INT,
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Buscamos el UsuarioID asociado a ese Doctor
    DECLARE @UsuarioID INT;
    SELECT @UsuarioID = UsuarioID FROM Doctores WHERE DoctorID = @DoctorID;

    IF @UsuarioID IS NULL
    BEGIN
        SET @Mensaje = 'Error: Doctor no encontrado.';
        RETURN;
    END

    -- 2. Borrado Lógico (Soft Delete)
    -- Ponemos Estado = 0 para bloquear su acceso
    UPDATE Usuarios 
    SET Estado = 0 
    WHERE UsuarioID = @UsuarioID;

    SET @Mensaje = 'Éxito: El doctor ha sido desactivado del sistema.';
END
GO



--Sp para agregar secretari@ o admin
    CREATE PROCEDURE sp_RegistrarStaff
        @NombreUsuario VARCHAR(50),
        @Email VARCHAR(100),
        @PasswordTextoPlano VARCHAR(50),
        @RolNombre VARCHAR(50), -- 'Administrador' o 'Recepcionista'
        @Mensaje VARCHAR(100) OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
    
        -- Buscamos el ID del Rol
        DECLARE @RolID INT = (SELECT RolID FROM Roles WHERE NombreRol = @RolNombre);

        IF @RolID IS NULL
        BEGIN
            SET @Mensaje = 'Error: El Rol especificado no existe.';
            RETURN;
        END

        BEGIN TRY
            -- Solo insertamos en Usuarios (Staff no tiene tabla extra)
            INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, RolID, Estado)
            VALUES (@NombreUsuario, @Email, HASHBYTES('SHA2_256', @PasswordTextoPlano), @RolID, 1);
        
            SET @Mensaje = 'Éxito: Usuario administrativo creado.';
        END TRY
        BEGIN CATCH
            SET @Mensaje = 'Error: ' + ERROR_MESSAGE();
        END CATCH
    END
    GO





--SP para actualizar datos del paciente
CREATE PROCEDURE sp_ActualizarPaciente
    @PacienteID INT,
    @NuevoTelefono VARCHAR(20),
    @NuevaDireccion VARCHAR(200),
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Pacientes WHERE PacienteID = @PacienteID)
        BEGIN
             THROW 51000, 'Error: Paciente no encontrado.', 1;
        END

        -- Actualizar datos
        UPDATE Pacientes
        SET Telefono = @NuevoTelefono,
            Direccion = @NuevaDireccion
        WHERE PacienteID = @PacienteID;

        SET @Mensaje = 'Éxito: Datos de contacto actualizados.';
    END TRY
    BEGIN CATCH
        SET @Mensaje = 'Error al actualizar: ' + ERROR_MESSAGE();
    END CATCH
END
GO

--Ejecutadores

-- Debería devolver los datos de Luis
EXEC ValidarLogin 'maria.g', 'Paciente123!'; 

-- Debería salir vacío (password incorrecto)
EXEC ValidarLogin 'luis.s', 'ClaveErronea';

DECLARE @Mensaje VARCHAR(100);

-- Paciente 1 (Luis), Doctor 1 (Juan)
EXEC sp_AgendarCita 6, 3, '2025-12-29 12:00:00', @Mensaje OUTPUT;

-- Ver el resultado
SELECT @Mensaje as Resultado;

--Registrar pagos
DECLARE @MensajeRespuesta VARCHAR(100);

-- Cambia el '1' por el ID de tu Cita real
EXEC RegistrarPago 
    @CitaID = 4, 
    @Monto = 150.00, 
    @MetodoPago = 'Tarjeta', 
    @Resultado = @MensajeRespuesta OUTPUT;

SELECT @MensajeRespuesta;

EXEC sp_ReporteIngresosDia;

--registrar un paciente

DECLARE @RespuestaDelSistema VARCHAR(100); 

DECLARE @Respuesta VARCHAR(100);

    EXEC sp_RegistrarPacienteWeb
        @NombreUsuario = 'eduu.vdy',
        @Email = 'edu@test.com',
        @PasswordTextoPlano = 'Paciente123!',
        @Nombre = 'Eduard',
        @Apellido = 'Vaca Diez',
        @FechaNac = '1995-08-15',
        @Telefono = '7000-1111',
        @Direccion = 'Av. Test 123',
        @Alergias = 'Ninguna',
        @Mensaje = @Respuesta OUTPUT;

    SELECT @Respuesta AS Resultado;

    --Exec para eliminar paciente

    DECLARE @RespuestaDelSistema VARCHAR(100);

EXEC sp_EliminarPacienteWeb 
    @PacienteID = 7, 
    @Mensaje = @RespuestaDelSistema OUTPUT;

SELECT @RespuestaDelSistema AS Resultado;

SELECT U.UsuarioID, U.NombreUsuario, U.Estado 
FROM Usuarios U
JOIN Pacientes P ON U.UsuarioID = P.UsuarioID
WHERE P.PacienteID = 7;

--EXEC para registrar un doctor

DECLARE @RespuestaDoc VARCHAR(100);

EXEC sp_RegistrarDoctorAdmin
    @NombreUsuario = 'dr.gomez',
    @Email = 'gomez@clinica.com',
    @PasswordTextoPlano = 'Doctor123!',
    @Nombre = 'Roberto',
    @Apellido = 'Gomez',
    @Especialidad = 'Ortodoncia',
    @NumeroLicencia = 'MED-998877',
    @Telefono = '6000-5555',
    @Mensaje = @RespuestaDoc OUTPUT;

SELECT @RespuestaDoc AS ResultadoRegistro;
SELECT * FROM Doctores WHERE NumeroLicencia = 'MED-998877';


--EXEC eliminar doctor
DECLARE @RespuestaBaja VARCHAR(100);


EXEC sp_EliminarDoctorAdmin 
    @DoctorID = 2, 
    @Mensaje = @RespuestaBaja OUTPUT;

SELECT @RespuestaBaja AS ResultadoBaja;


SELECT D.Nombre, U.NombreUsuario, U.Estado 
FROM Doctores D
JOIN Usuarios U ON D.UsuarioID = U.UsuarioID
WHERE D.DoctorID = 2;


--exec para actualizar paciente
-- 1. Declaramos la variable para recibir el mensaje
DECLARE @RespuestaUpdate VARCHAR(100);

EXEC sp_ActualizarPaciente
    @PacienteID = 6,              
    @NuevoTelefono = '6000-9999', 
    @NuevaDireccion = 'Calle Nueva #456, Zona Norte', 
    @Mensaje = @RespuestaUpdate OUTPUT;

SELECT @RespuestaUpdate AS ResultadoOperacion;



--exec para registrar admin
-- 1. Declaramos la variable
DECLARE @RespuestaStaff VARCHAR(100);

-- 2. Ejecutamos el SP para crear una Secretaria o Admin
EXEC sp_RegistrarStaff
    @NombreUsuario = 'admin.edu',
    @Email = 'edu@clinica.com',
    @PasswordTextoPlano = 'AdminSeguro123!',
    @RolNombre = 'Administrador', 
    @Mensaje = @RespuestaStaff OUTPUT;

SELECT @RespuestaStaff AS ResultadoRegistro;
