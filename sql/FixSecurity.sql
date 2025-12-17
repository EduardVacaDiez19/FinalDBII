-- =============================================
-- REFACTORIZACIÓN DE SEGURIDAD - CLÍNICA DENTAL
-- Implementación de Salting y Normalización de Roles
-- =============================================

USE ClinicaDentalDB;
GO

-- 1. MODIFICACIÓN DE ESQUEMA: Agregar Salt
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Usuarios') AND name = 'Salt')
BEGIN
    ALTER TABLE Usuarios ADD Salt VARCHAR(36) NOT NULL DEFAULT (CAST(NEWID() AS VARCHAR(36)));
    PRINT 'Columna Salt agregada a la tabla Usuarios';
END
GO

-- 2. ACTUALIZACIÓN DEL SP: ValidarLogin (con Salting)
OR ALTER PROCEDURE ValidarLogin
    @NombreUsuario VARCHAR(50),
    @Password VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PassHash VARBINARY(64);
    DECLARE @Salt VARCHAR(36);

    -- Obtenemos el salt primero
    SELECT @Salt = Salt FROM Usuarios WHERE NombreUsuario = @NombreUsuario AND Estado = 1;

    IF @Salt IS NOT NULL
    BEGIN
        -- Generamos el hash con el salt recuperado
        SET @PassHash = HASHBYTES('SHA2_256', @Password + @Salt);

        SELECT
            U.UsuarioID,
            U.NombreUsuario,
            R.NombreRol, -- SSOT para el Frontend
            ISNULL(P.PacienteID, 0) AS PacienteID,
            ISNULL(D.DoctorID, 0) AS DoctorID,
            COALESCE(P.Nombre + ' ' + P.Apellido, D.Nombre + ' ' + D.Apellido, U.NombreUsuario) AS NombreReal
        FROM Usuarios U
        INNER JOIN Roles R ON U.RolID = R.RolID
        LEFT JOIN Pacientes P ON U.UsuarioID = P.UsuarioID
        LEFT JOIN Doctores D ON U.UsuarioID = D.UsuarioID
        WHERE U.NombreUsuario = @NombreUsuario
          AND U.PasswordHash = @PassHash
          AND U.Estado = 1;
    END
END
GO

-- 3. ACTUALIZACIÓN DEL SP: RegistrarPaciente (con Salting)
OR ALTER PROCEDURE sp_RegistrarPacienteWeb
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
    DECLARE @Salt VARCHAR(36) = CAST(NEWID() AS VARCHAR(36));

    BEGIN TRANSACTION;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = @NombreUsuario OR Email = @Email)
        BEGIN
            THROW 51000, 'Error: El usuario o correo ya existen.', 1;
        END

        DECLARE @RolPacienteID INT = (SELECT RolID FROM Roles WHERE NombreRol = 'Paciente');
        DECLARE @NuevoID INT;

        INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, Salt, RolID, Estado)
        VALUES (
            @NombreUsuario,
            @Email,
            HASHBYTES('SHA2_256', @PasswordTextoPlano + @Salt),
            @Salt,
            @RolPacienteID,
            1
        );

        SET @NuevoID = SCOPE_IDENTITY();

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

-- 4. ACTUALIZACIÓN DEL SP: RegistrarDoctor (con Salting)
OR ALTER PROCEDURE sp_RegistrarDoctorAdmin
    @NombreUsuario VARCHAR(50),
    @Email VARCHAR(100),
    @PasswordTextoPlano VARCHAR(50),
    @Nombre VARCHAR(100),
    @Apellido VARCHAR(100),
    @Especialidad VARCHAR(100),
    @NumeroLicencia VARCHAR(50),
    @Telefono VARCHAR(20),
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Salt VARCHAR(36) = CAST(NEWID() AS VARCHAR(36));

    BEGIN TRANSACTION;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Usuarios WHERE NombreUsuario = @NombreUsuario OR Email = @Email)
            THROW 51000, 'Error: El usuario o correo ya existen.', 1;

        IF EXISTS (SELECT 1 FROM Doctores WHERE NumeroLicencia = @NumeroLicencia)
            THROW 51000, 'Error: Licencia médica duplicada.', 1;

        DECLARE @RolDoctorID INT = (SELECT TOP 1 RolID FROM Roles WHERE NombreRol IN ('Dentista', 'Doctor'));
        DECLARE @NuevoID INT;

        INSERT INTO Usuarios (NombreUsuario, Email, PasswordHash, Salt, RolID, Estado)
        VALUES (
            @NombreUsuario,
            @Email,
            HASHBYTES('SHA2_256', @PasswordTextoPlano + @Salt),
            @Salt,
            @RolDoctorID,
            1
        );

        SET @NuevoID = SCOPE_IDENTITY();

        INSERT INTO Doctores (Nombre, Apellido, Especialidad, NumeroLicencia, Telefono, UsuarioID)
        VALUES (@Nombre, @Apellido, @Especialidad, @NumeroLicencia, @Telefono, @NuevoID);

        COMMIT TRANSACTION;
        SET @Mensaje = 'Éxito: Doctor registrado correctamente.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @Mensaje = 'Error al registrar: ' + ERROR_MESSAGE();
    END CATCH
END
GO
