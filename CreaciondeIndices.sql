-- 1. ÍNDICES PARA BÚSQUEDAS FRECUENTES (UX/Recepción)

CREATE NONCLUSTERED INDEX IX_Pacientes_Apellido_Nombre
ON Pacientes (Apellido, Nombre);
GO

-- 2. ÍNDICES PARA AGENDA Y REPORTES (Filtros de Fechas)

CREATE NONCLUSTERED INDEX IX_Citas_Fecha_Doctor
ON Citas (FechaCita, DoctorID)
INCLUDE (EstadoCita); 
GO

-- 3. ÍNDICES PARA INTEGRIDAD Y JOINS (Llaves Foráneas)

-- Para unir rápidamente Pacientes con sus Usuarios
CREATE NONCLUSTERED INDEX IX_Pacientes_UsuarioID
ON Pacientes (UsuarioID);
GO

-- Para unir rápidamente Doctores con sus Usuarios
CREATE NONCLUSTERED INDEX IX_Doctores_UsuarioID
ON Doctores (UsuarioID);
GO

-- Para ver el historial de un paciente rápidamente
CREATE NONCLUSTERED INDEX IX_Citas_PacienteID
ON Citas (PacienteID);
GO

-- 4. ÍNDICES PARA EL CATÁLOGO (Búsqueda de Tratamientos)

CREATE NONCLUSTERED INDEX IX_Servicios_Nombre
ON Servicios (NombreServicio);
GO