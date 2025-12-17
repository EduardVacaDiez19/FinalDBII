	select P.PacienteID, U.NombreUsuario, C.FechaCita, C.EstadoCita
	from Usuarios as U
	inner join Pacientes as P
	on U.UsuarioID = P.UsuarioID
	inner join Citas as C
	on P.PacienteID = C.PacienteID

	select concat(P.Nombre,' ',P.Apellido) As Paciente, U.Email, U.NombreUsuario
	from Pacientes as P
	inner join Usuarios as U
	on P.UsuarioID = U.UsuarioID

	select P.PacienteID, P.Nombre
	from Pacientes as P 

	select U.UsuarioID, U.NombreUsuario, R.NombreRol
	from Doctores as D
	full outer join Usuarios as U
	on D.UsuarioID = U.UsuarioID
	full outer join Pacientes as P
	on U.UsuarioID = P.UsuarioID
	left join Roles as R
	on U.RolID = R.RolID
	order by U.UsuarioID desc
	

	select U.NombreUsuario, U.UsuarioID
	from Usuarios as U
	order by U.UsuarioID desc

	--Query para ver si la cita está pagada
	SELECT 
    C.CitaID,
    Pac.Nombre + ' ' + Pac.Apellido AS Paciente,
    Doc.Nombre AS Doctor,
    C.FechaCita,
    -- Aquí está la magia: Si existe un ID de pago, escribe 'SÍ', si no, 'NO'
    CASE 
        WHEN Pg.PagoID IS NOT NULL THEN 'SÍ PAGADA'
        ELSE 'PENDIENTE DE PAGO'
    END AS EstadoPago,
    
    ISNULL(Pg.Monto, 0.00) AS MontoPagado,
    Pg.MetodoPago
FROM Citas AS C
INNER JOIN Pacientes AS Pac ON C.PacienteID = Pac.PacienteID
INNER JOIN Doctores AS Doc ON C.DoctorID = Doc.DoctorID
-- Usamos LEFT JOIN porque queremos ver la cita AUNQUE no tenga pago todavía
LEFT JOIN Pagos AS Pg ON C.CitaID = Pg.CitaID;



