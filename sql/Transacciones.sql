--Transacciones
--Evitar que se pague dos veces por error
CREATE PROCEDURE RealizarPagoSeguro
    @CitaID INT,
    @Monto DECIMAL(10,2),
    @MetodoPago VARCHAR(50), -- Efectivo, Tarjeta, etc.
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Iniciamos la transacción (Aquí empieza el "Todo o Nada")
    BEGIN TRANSACTION;

    BEGIN TRY
        -- VALIDACIÓN: Verificar si la cita existe y no ha sido pagada aún
        IF EXISTS (SELECT 1 FROM Citas WHERE CitaID = @CitaID AND EstadoCita = 'Completada')
        BEGIN
            -- Si ya estaba pagada, provocamos un error para ir al CATCH
            THROW 51000, 'Error: Esta cita ya fue pagada anteriormente.', 1;
        END

        -- PASO A: Insertar el registro del dinero
        INSERT INTO Pagos (CitaID, Monto, MetodoPago, FechaPago)
        VALUES (@CitaID, @Monto, @MetodoPago, GETDATE());

        -- PASO B: Actualizar el estado de la cita
        UPDATE Citas 
        SET EstadoCita = 'Completada' 
        WHERE CitaID = @CitaID;

        -- SI LLEGAMOS AQUÍ, TODO SALIÓ BIEN
        COMMIT TRANSACTION; -- ¡Guardamos los cambios permanentemente!
        SET @Mensaje = 'Éxito: Pago registrado y cita cerrada correctamente.';
    END TRY
    BEGIN CATCH
        -- SI OCURRIÓ CUALQUIER ERROR
        ROLLBACK TRANSACTION; -- ¡Deshacemos todo! (Borra el pago si se había insertado)
        
        -- Devolvemos el mensaje de error
        SET @Mensaje = 'Fallo Transaccional: ' + ERROR_MESSAGE();
    END CATCH
END
GO

--reprogramar una cita segura

CREATE PROCEDURE sp_ReprogramarCita
    @CitaID INT,
    @NuevaFecha DATETIME,
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    BEGIN TRY
        DECLARE @DoctorID INT;
        -- Obtenemos el doctor de la cita original
        SELECT @DoctorID = DoctorID FROM Citas WHERE CitaID = @CitaID;

        -- 1. Validar que la cita existe
        IF @DoctorID IS NULL
        BEGIN
             THROW 51000, 'Error: La cita no existe.', 1;
        END

        -- 2. Validar que la NUEVA fecha esté libre
        IF EXISTS (SELECT 1 FROM Citas WHERE DoctorID = @DoctorID AND FechaCita = @NuevaFecha)
        BEGIN
            THROW 51000, 'Error: La nueva fecha deseada ya está ocupada.', 1;
        END

        -- 3. Actualizar la fecha (El cambio real)
        UPDATE Citas
        SET FechaCita = @NuevaFecha,
            EstadoCita = 'Pendiente' -- La reseteamos a pendiente por si estaba confirmada
        WHERE CitaID = @CitaID;

        COMMIT TRANSACTION;
        SET @Mensaje = 'Éxito: Cita movida correctamente a la nueva fecha.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION; -- Si algo falla, la cita se queda en su fecha original
        SET @Mensaje = 'No se pudo reprogramar: ' + ERROR_MESSAGE();
    END CATCH
END
GO

--Reasignar citas
CREATE PROCEDURE sp_ReasignarCitasEmergencia
    @DoctorOrigenID INT, -- El que se enfermó
    @DoctorDestinoID INT, -- El que cubrirá
    @Fecha DATETIME, -- El día del problema
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Definimos el rango del día (00:00 a 23:59)
    DECLARE @InicioDia DATETIME = CAST(@Fecha AS DATE);
    DECLARE @FinDia DATETIME = DATEADD(DAY, 1, @InicioDia);

    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Verificar Conflictos
        -- Buscamos si el Doctor Destino YA tiene citas en los MISMOS horarios que el Doctor Origen
        IF EXISTS (
            SELECT 1 
            FROM Citas C1 -- Citas del doctor enfermo
            JOIN Citas C2 -- Citas del doctor suplente
                ON C1.FechaCita = C2.FechaCita 
            WHERE C1.DoctorID = @DoctorOrigenID 
              AND C2.DoctorID = @DoctorDestinoID
              AND C1.FechaCita >= @InicioDia AND C1.FechaCita < @FinDia
              AND C1.EstadoCita = 'Pendiente'
              AND C2.EstadoCita IN ('Pendiente', 'Confirmada')
        )
        BEGIN
            THROW 51000, 'Error: El doctor suplente no tiene disponibilidad para cubrir TODOS los horarios.', 1;
        END

        -- 2. Si no hay choques, movemos TODAS las citas de golpe
        UPDATE Citas
        SET DoctorID = @DoctorDestinoID
        WHERE DoctorID = @DoctorOrigenID
          AND FechaCita >= @InicioDia AND FechaCita < @FinDia
          AND EstadoCita = 'Pendiente';

        COMMIT TRANSACTION;
        SET @Mensaje = 'Éxito: Todas las citas fueron reasignadas al doctor suplente.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION; -- Si falla, las citas se quedan con el doctor original
        SET @Mensaje = 'Fallo en reasignación: ' + ERROR_MESSAGE();
    END CATCH
END
GO