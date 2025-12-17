--Triggers
-- Este se dispara AUTOMÁTICAMENTE después de que alguien haga un UPDATE en Pacientes
CREATE TRIGGER trg_Auditoria_Pacientes_Update
ON Pacientes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Insertamos en la tabla de auditoría lo que pasó
    INSERT INTO AuditoriaPacientes (PacienteID, Accion, DatosAntiguos, DatosNuevos, UsuarioSistema)
    SELECT 
        i.PacienteID, 
        'Modificacion', 
        -- Guardamos el nombre viejo
        'Antes: ' + d.Nombre + ' ' + d.Apellido + ' (Alergias: ' + d.Alergias + ')',
        -- Guardamos el nombre nuevo
        'Ahora: ' + i.Nombre + ' ' + i.Apellido + ' (Alergias: ' + i.Alergias + ')',
        SYSTEM_USER
    FROM inserted i
    INNER JOIN deleted d ON i.PacienteID = d.PacienteID;
END
GO


--Trigger para validar si se puede borrar un doctor o no
    CREATE TRIGGER trg_ValidarBorradoDoctor
    ON Doctores
    INSTEAD OF DELETE
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @DoctorID INT;
        SELECT @DoctorID = DoctorID FROM deleted;

        -- 1. Verificamos si tiene citas PENDIENTES o CONFIRMADAS
        IF EXISTS (SELECT 1 FROM Citas WHERE DoctorID = @DoctorID AND EstadoCita IN ('Pendiente', 'Confirmada'))
        BEGIN
            -- Si tiene citas futuras, CANCELAMOS el borrado y lanzamos error
            RAISERROR ('¡ALTO! No puede eliminar a este doctor porque tiene citas pendientes. Cancele o reasigne las citas primero.', 16, 1);
            ROLLBACK TRANSACTION;
        END
        ELSE
        BEGIN
            -- 2. Si está libre, permitimos el borrado
            -- Como es un trigger "INSTEAD OF", tenemos que ejecutar el DELETE manualmente
            DELETE FROM Doctores WHERE DoctorID = @DoctorID;
        END
    END
    GO

    --Trigger Historial de precios

    -- 2. Creamos el Trigger
CREATE TRIGGER trg_Historial_CambioPrecio
ON Servicios
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Solo nos interesa si el precio cambió (Ignoramos si solo corrigieron el nombre)
    IF UPDATE(PrecioBase)
    BEGIN
        INSERT INTO HistorialPrecios (ServicioID, PrecioAnterior, PrecioNuevo, UsuarioResponsable)
        SELECT 
            i.ServicioID, 
            d.PrecioBase, -- Precio Viejo (deleted)
            i.PrecioBase, -- Precio Nuevo (inserted)
            SYSTEM_USER
        FROM inserted i
        INNER JOIN deleted d ON i.ServicioID = d.ServicioID
        WHERE i.PrecioBase <> d.PrecioBase; -- Solo si son diferentes
    END
END
GO

-- Trigger para limitar las citas del paciente

CREATE TRIGGER trg_LimiteCitasPendientes
ON Citas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PacienteID INT;
    DECLARE @ConteoPendientes INT;

    -- Obtenemos el ID del paciente que acaba de agendar
    SELECT @PacienteID = PacienteID FROM inserted;

    -- Contamos cuántas citas "Pendientes" tiene ese paciente en total
    SELECT @ConteoPendientes = COUNT(*) 
    FROM Citas 
    WHERE PacienteID = @PacienteID 
    AND EstadoCita = 'Pendiente';

    -- REGLA: Si tiene más de 2 citas pendientes (incluyendo la nueva), bloqueamos.
    IF @ConteoPendientes > 2
    BEGIN
        RAISERROR ('ERROR: El paciente ya tiene el máximo permitido de citas pendientes (2). Complete o cancele las anteriores.', 16, 1);
        ROLLBACK TRANSACTION; -- Deshacemos la inserción
    END
END
GO