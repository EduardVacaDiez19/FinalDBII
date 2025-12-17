const API_URL = 'http://localhost:3000/api';
let currentUser = null;

// Login
document.getElementById('loginForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;

    try {
        const res = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        const data = await res.json();

        if (data.success) {
            currentUser = data.usuario;
            // Guardar usuario en sesion (opcional, pero util si refrescan)
            sessionStorage.setItem('currentUser', JSON.stringify(currentUser));

            document.getElementById('loginScreen').style.display = 'none';
            document.getElementById('appContainer').style.display = 'flex';
            document.getElementById('userName').textContent = `${currentUser.nombreReal} (${currentUser.rol})`;

            applyRolePermissions(currentUser.rol);
            loadDashboard();
        } else {
            document.getElementById('loginError').textContent = data.message;
            document.getElementById('loginError').style.display = 'block';
        }
    } catch (error) {
        console.error('Error:', error);
    }
});

// Role Permissions
const ROLE_PERMISSIONS = {
    'Administrador': {
        sections: ['inicio', 'pacientes', 'citas', 'inventario', 'expedientes', 'encuestas'],
        actions: ['create_paciente', 'delete_paciente', 'create_cita', 'view_all_citas']
    },
    'Dentista': {
        sections: ['inicio', 'pacientes', 'citas', 'expedientes'],
        actions: ['create_cita', 'view_all_citas', 'view_all_pacientes']
    },
    'Paciente': {
        sections: ['inicio', 'citas', 'encuestas'],
        actions: ['create_cita', 'view_own_citas']
    }
};

function applyRolePermissions(role) {
    const perms = ROLE_PERMISSIONS[role] || ROLE_PERMISSIONS['Paciente']; // Fallback

    // 1. Hide/Show Menu Items
    document.querySelectorAll('#menu a').forEach(link => {
        const section = link.dataset.section;
        if (perms.sections.includes(section)) {
            link.style.display = 'block';
        } else {
            link.style.display = 'none';
        }
    });

    // 2. Adjust Dashboard Stats Visibility (Optional, handled in data loading)

    // 3. Hide Action Buttons if needed
    if (!perms.actions.includes('create_paciente')) {
        const btn = document.querySelector('button[onclick="showModal(\'modalPaciente\')"]');
        if (btn) btn.style.display = 'none';
    }
}

// Override Logout to clear session
document.getElementById('logoutBtn')?.addEventListener('click', () => {
    currentUser = null;
    sessionStorage.removeItem('currentUser');
    window.location.reload(); // Simple reload to clear state
});

// Navigation
document.querySelectorAll('#menu a').forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const section = e.target.dataset.section;

        document.querySelectorAll('#menu a').forEach(a => a.classList.remove('active'));
        e.target.classList.add('active');

        document.querySelectorAll('main section').forEach(s => s.classList.remove('active'));
        document.getElementById(`section-${section}`).classList.add('active');

        loadSectionData(section);
    });
});

// Load Dashboard
async function loadDashboard() {
    try {
        const [pacientes, citas, productos, encuestas] = await Promise.all([
            fetch(`${API_URL}/pacientes`).then(r => r.json()),
            fetch(`${API_URL}/citas`).then(r => r.json()),
            fetch(`${API_URL}/inventario/productos`).then(r => r.json()),
            fetch(`${API_URL}/encuestas`).then(r => r.json())
        ]);

        document.getElementById('totalPacientes').textContent = pacientes.count || 0;
        document.getElementById('totalCitas').textContent = citas.count || 0;
        document.getElementById('totalProductos').textContent = productos.count || 0;
        document.getElementById('promedioCalidad').textContent =
            encuestas.estadisticas?.promedioGeneral || 0;
    } catch (error) {
        console.error('Error:', error);
    }
}

// Load Section Data
function loadSectionData(section) {
    switch (section) {
        case 'pacientes': loadPacientes(); break;
        case 'citas': loadCitas(); break;
        case 'inventario': loadInventario(); break;
        case 'expedientes': loadExpedientes(); break;
        case 'encuestas': loadEncuestas(); break;
    }
}

// Load Pacientes
async function loadPacientes() {
    try {
        const res = await fetch(`${API_URL}/pacientes`);
        const data = await res.json();

        const tbody = document.querySelector('#tablaPacientes tbody');
        tbody.innerHTML = data.data.map(p => `
            <tr>
                <td>${p.PacienteID}</td>
                <td>${p.Nombre} ${p.Apellido}</td>
                <td>${p.Email}</td>
                <td>${p.Telefono || 'N/A'}</td>
                <td>
                    <button onclick="eliminarPaciente(${p.PacienteID})">Eliminar</button>
                </td>
            </tr>
        `).join('');
    } catch (error) {
        console.error('Error:', error);
    }
}

// Load Citas
async function loadCitas() {
    try {
        const res = await fetch(`${API_URL}/citas`);
        const data = await res.json();

        let citas = data.data;

        // FILTRO POR ROL: Pacientes solo ven sus propias citas
        if (currentUser && currentUser.rol === 'Paciente') {
            // Usamos nombreReal porque el ID no siempre está disponible en la lista
            // Una mejor implementación sería que el backend devolviera solo las citas del ID del usuario
            citas = citas.filter(c => c.NombrePaciente === currentUser.nombreReal || c.NombrePaciente.includes(currentUser.nombreReal));
        }

        const tbody = document.querySelector('#tablaCitas tbody');
        if (citas.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;">No hay citas registradas para mostrar.</td></tr>';
        } else {
            tbody.innerHTML = citas.map(c => `
                <tr>
                    <td>${c.CitaID}</td>
                    <td>${new Date(c.FechaCita).toLocaleString()}</td>
                    <td>${c.NombrePaciente}</td>
                    <td>${c.NombreDoctor}</td>
                    <td>${c.EstadoCita}</td>
                </tr>
            `).join('');
        }

        // Configuración del Modal de Nueva Cita según permisos
        if (currentUser.rol === 'Paciente') {
            // El paciente solo puede agendarse a sí mismo
            const select = document.getElementById('selectPaciente');
            // Limpiamos y ponemos solo al usuario actual
            select.innerHTML = `<option value="${currentUser.pacienteID}" selected>${currentUser.nombreReal}</option>`;
            // Cargamos doctores normalmente
            loadDoctoresSelect();
        } else {
            // Admin y Doctor pueden seleccionar cualquier paciente
            loadPacientesSelect();
            loadDoctoresSelect();
        }
    } catch (error) {
        console.error('Error:', error);
    }
}

// Load Inventario
async function loadInventario() {
    try {
        const res = await fetch(`${API_URL}/inventario/productos`);
        const data = await res.json();

        const grid = document.getElementById('productosGrid');
        grid.innerHTML = data.data.map(p => `
            <div class="producto-card">
                <h3>${p.producto}</h3>
                <p><strong>Proveedor:</strong> ${p.proveedor}</p>
                <p><strong>Categoría:</strong> ${p.categoria}</p>
                <p><strong>Precio:</strong> $${p.precio_lista.toFixed(2)}</p>
                <p><strong>Stock:</strong> ${p.stock}</p>
                <div>
                    <strong>Especificaciones:</strong>
                    ${Object.entries(p.especificaciones).map(([k, v]) =>
            `<br>${k}: ${v}`
        ).join('')}
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Error:', error);
    }
}

// Load Expedientes
async function loadExpedientes() {
    try {
        const res = await fetch(`${API_URL}/expedientes`);
        const data = await res.json();

        const list = document.getElementById('expedientesList');
        list.innerHTML = data.data.map(e => `
            <div style="border: 1px solid #ccc; padding: 15px; margin: 10px 0; border-radius: 8px;">
                <h3>Paciente ID: ${e.paciente_id}</h3>
                <p><strong>Tipo Sangre:</strong> ${e.tipo_sangre}</p>
                <p><strong>Antecedentes:</strong> ${e.antecedentes.join(', ')}</p>
                <h4>Odontograma:</h4>
                ${e.odontograma.map(d => `
                    <p>Diente ${d.diente}: ${d.estado} - ${d.tratamiento_sugerido}</p>
                `).join('')}
            </div>
        `).join('');
    } catch (error) {
        console.error('Error:', error);
    }
}

// Load Encuestas
async function loadEncuestas() {
    try {
        const res = await fetch(`${API_URL}/encuestas`);
        const data = await res.json();

        document.getElementById('estadisticas').innerHTML = `
            <p>Total Encuestas: ${data.count}</p>
            <p>Promedio: ${data.estadisticas.promedioGeneral}/5</p>
        `;

        const tbody = document.querySelector('#tablaEncuestas tbody');
        tbody.innerHTML = data.data.map(e => `
            <tr>
                <td>${e.paciente_id}</td>
                <td>${new Date(e.fecha).toLocaleDateString()}</td>
                <td>${e.puntuacion_general}/5</td>
                <td>${e.comentarios}</td>
            </tr>
        `).join('');
    } catch (error) {
        console.error('Error:', error);
    }
}

// Form Paciente
document.getElementById('formPaciente')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const data = Object.fromEntries(formData);

    try {
        const res = await fetch(`${API_URL}/pacientes`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        const result = await res.json();

        if (result.success) {
            showToast('Paciente registrado exitosamente');
            closeModal('modalPaciente');
            loadPacientes();
            e.target.reset();
        } else {
            showToast(result.message, 'error');
        }
    } catch (error) {
        console.error('Error:', error);
    }
});

// Form Cita
document.getElementById('formCita')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const data = Object.fromEntries(formData);
    data.pacienteID = parseInt(data.pacienteID);
    data.doctorID = parseInt(data.doctorID);

    try {
        const res = await fetch(`${API_URL}/citas`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        const result = await res.json();

        if (result.success) {
            showToast('Cita agendada exitosamente');
            closeModal('modalCita');
            loadCitas();
            e.target.reset();
        } else {
            showToast(result.message, 'error');
        }
    } catch (error) {
        console.error('Error:', error);
    }
});

// Load Selects
async function loadPacientesSelect() {
    const res = await fetch(`${API_URL}/pacientes`);
    const data = await res.json();
    const select = document.getElementById('selectPaciente');
    select.innerHTML = '<option value="">Seleccionar Paciente</option>' +
        data.data.map(p => `<option value="${p.PacienteID}">${p.Nombre} ${p.Apellido}</option>`).join('');
}

async function loadDoctoresSelect() {
    const res = await fetch(`${API_URL}/doctores`);
    const data = await res.json();
    const select = document.getElementById('selectDoctor');
    select.innerHTML = '<option value="">Seleccionar Doctor</option>' +
        data.data.map(d => `<option value="${d.DoctorID}">${d.Nombre} ${d.Apellido} - ${d.Especialidad}</option>`).join('');
}

// Delete Paciente
async function eliminarPaciente(id) {
    if (!confirm('¿Eliminar paciente?')) return;

    try {
        const res = await fetch(`${API_URL}/pacientes/${id}`, { method: 'DELETE' });
        const data = await res.json();

        if (data.success) {
            showToast('Paciente eliminado');
            loadPacientes();
        } else {
            showToast(data.message, 'error');
        }
    } catch (error) {
        console.error('Error:', error);
    }
}

// Modal Functions
function showModal(id) {
    document.getElementById(id).style.display = 'block';
}

function closeModal(id) {
    document.getElementById(id).style.display = 'none';
}

// Toast
function showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast ${type} show`;
    setTimeout(() => toast.classList.remove('show'), 3000);
}

window.showModal = showModal;
window.closeModal = closeModal;
window.eliminarPaciente = eliminarPaciente;
