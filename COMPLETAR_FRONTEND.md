# 🎨 GUÍA DE COMPLETACIÓN DEL FRONTEND

## ✅ LO QUE YA TIENES COMPLETO

### Backend 100% Funcional
- ✅ server.js con TODAS las rutas API
- ✅ Configuración de SQL Server
- ✅ Configuración de MongoDB
- ✅ Integración con TUS Stored Procedures
- ✅ Integración con TUS schemas MongoDB
- ✅ Manejo de errores

### Base de Datos
- ✅ Todos tus archivos SQL originales en `/database/sql/`
- ✅ Tu archivo MongoDB original en `/database/mongodb/`

## 📝 LO QUE FALTA: ARCHIVOS FRONTEND

Necesitas crear 3 archivos en la carpeta `public/`:

### 1. public/index.html
```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clínica Dental</title>
    <link rel="stylesheet" href="css/styles.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div id="loginScreen" class="login-screen">
        <div class="login-box">
            <h1><i class="fas fa-tooth"></i> Clínica Dental</h1>
            <form id="loginForm">
                <input type="text" id="username" placeholder="Usuario" required>
                <input type="password" id="password" placeholder="Contraseña" required>
                <button type="submit">Ingresar</button>
                <div id="loginError" style="display:none; color:red;"></div>
            </form>
            <p><small>Prueba: luis.s / Paciente123!</small></p>
        </div>
    </div>

    <div id="appContainer" style="display:none;">
        <header>
            <h2>Clínica Dental</h2>
            <span id="userName"></span>
            <button id="logoutBtn">Salir</button>
        </header>
        
        <nav id="menu">
            <a href="#" data-section="inicio" class="active">Inicio</a>
            <a href="#" data-section="pacientes">Pacientes</a>
            <a href="#" data-section="citas">Citas</a>
            <a href="#" data-section="inventario">Inventario</a>
            <a href="#" data-section="expedientes">Expedientes</a>
            <a href="#" data-section="encuestas">Encuestas</a>
        </nav>

        <main id="content">
            <section id="section-inicio" class="active">
                <h1>Dashboard</h1>
                <div class="stats">
                    <div class="stat-card">
                        <h3 id="totalPacientes">0</h3>
                        <p>Pacientes</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="totalCitas">0</h3>
                        <p>Citas</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="totalProductos">0</h3>
                        <p>Productos</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="promedioCalidad">0</h3>
                        <p>Satisfacción</p>
                    </div>
                </div>
            </section>

            <section id="section-pacientes">
                <h1>Pacientes</h1>
                <button onclick="showModal('modalPaciente')">Nuevo Paciente</button>
                <table id="tablaPacientes">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nombre</th>
                            <th>Email</th>
                            <th>Teléfono</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </section>

            <section id="section-citas">
                <h1>Citas</h1>
                <button onclick="showModal('modalCita')">Nueva Cita</button>
                <table id="tablaCitas">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Fecha</th>
                            <th>Paciente</th>
                            <th>Doctor</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </section>

            <section id="section-inventario">
                <h1>Inventario</h1>
                <div id="productosGrid"></div>
            </section>

            <section id="section-expedientes">
                <h1>Expedientes</h1>
                <div id="expedientesList"></div>
            </section>

            <section id="section-encuestas">
                <h1>Encuestas</h1>
                <div id="estadisticas"></div>
                <table id="tablaEncuestas">
                    <thead>
                        <tr>
                            <th>Paciente</th>
                            <th>Fecha</th>
                            <th>Puntuación</th>
                            <th>Comentarios</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </section>
        </main>
    </div>

    <!-- Modales -->
    <div id="modalPaciente" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal('modalPaciente')">&times;</span>
            <h2>Registrar Paciente</h2>
            <form id="formPaciente">
                <input type="text" name="nombreUsuario" placeholder="Usuario" required>
                <input type="email" name="email" placeholder="Email" required>
                <input type="password" name="password" placeholder="Contraseña" required>
                <input type="text" name="nombre" placeholder="Nombre" required>
                <input type="text" name="apellido" placeholder="Apellido" required>
                <input type="date" name="fechaNacimiento">
                <input type="tel" name="telefono" placeholder="Teléfono">
                <input type="text" name="direccion" placeholder="Dirección">
                <input type="text" name="alergias" placeholder="Alergias">
                <button type="submit">Guardar</button>
            </form>
        </div>
    </div>

    <div id="modalCita" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal('modalCita')">&times;</span>
            <h2>Agendar Cita</h2>
            <form id="formCita">
                <select name="pacienteID" id="selectPaciente" required>
                    <option value="">Seleccionar Paciente</option>
                </select>
                <select name="doctorID" id="selectDoctor" required>
                    <option value="">Seleccionar Doctor</option>
                </select>
                <input type="datetime-local" name="fechaCita" required>
                <button type="submit">Agendar</button>
            </form>
        </div>
    </div>

    <div id="toast"></div>
    <script src="js/app.js"></script>
</body>
</html>
```

### 2. public/css/styles.css
```css
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
    font-family: 'Segoe UI', Tahoma, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
}

/* Login */
.login-screen {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
}

.login-box {
    background: white;
    padding: 40px;
    border-radius: 20px;
    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    text-align: center;
    max-width: 400px;
}

.login-box h1 {
    margin-bottom: 20px;
    color: #2563eb;
}

.login-box input {
    width: 100%;
    padding: 12px;
    margin: 10px 0;
    border: 2px solid #e5e7eb;
    border-radius: 8px;
}

.login-box button {
    width: 100%;
    padding: 12px;
    background: #2563eb;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-size: 16px;
}

.login-box button:hover {
    background: #1e40af;
}

/* App Container */
#appContainer {
    display: flex;
    flex-direction: column;
    height: 100vh;
    background: #f3f4f6;
}

header {
    background: white;
    padding: 15px 30px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

#menu {
    background: white;
    padding: 0;
    display: flex;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

#menu a {
    padding: 15px 30px;
    text-decoration: none;
    color: #6b7280;
    border-bottom: 3px solid transparent;
}

#menu a:hover, #menu a.active {
    color: #2563eb;
    border-bottom-color: #2563eb;
}

main {
    flex: 1;
    padding: 30px;
    overflow-y: auto;
}

section {
    display: none;
    background: white;
    padding: 30px;
    border-radius: 15px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

section.active {
    display: block;
}

/* Stats */
.stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    margin-top: 20px;
}

.stat-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 30px;
    border-radius: 15px;
    text-align: center;
}

.stat-card h3 {
    font-size: 36px;
    margin-bottom: 10px;
}

/* Tables */
table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
}

th, td {
    padding: 12px;
    text-align: left;
    border-bottom: 1px solid #e5e7eb;
}

th {
    background: #f9fafb;
    font-weight: 600;
}

/* Buttons */
button {
    padding: 10px 20px;
    background: #2563eb;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
}

button:hover {
    background: #1e40af;
}

/* Modal */
.modal {
    display: none;
    position: fixed;
    z-index: 1000;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background: rgba(0,0,0,0.5);
}

.modal-content {
    background: white;
    margin: 5% auto;
    padding: 30px;
    border-radius: 15px;
    max-width: 600px;
}

.close {
    float: right;
    font-size: 28px;
    cursor: pointer;
}

.modal-content input,
.modal-content select {
    width: 100%;
    padding: 10px;
    margin: 10px 0;
    border: 2px solid #e5e7eb;
    border-radius: 8px;
}

/* Products Grid */
#productosGrid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 20px;
    margin-top: 20px;
}

.producto-card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 10px;
    padding: 20px;
}

/* Toast */
#toast {
    position: fixed;
    bottom: -100px;
    right: 30px;
    background: #10b981;
    color: white;
    padding: 15px 25px;
    border-radius: 10px;
    transition: bottom 0.3s;
}

#toast.show {
    bottom: 30px;
}
```

### 3. public/js/app.js
```javascript
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
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({username, password})
        });
        const data = await res.json();
        
        if (data.success) {
            currentUser = data.usuario;
            document.getElementById('loginScreen').style.display = 'none';
            document.getElementById('appContainer').style.display = 'flex';
            document.getElementById('userName').textContent = data.usuario.nombreReal;
            loadDashboard();
        } else {
            document.getElementById('loginError').textContent = data.message;
            document.getElementById('loginError').style.display = 'block';
        }
    } catch (error) {
        console.error('Error:', error);
    }
});

// Logout
document.getElementById('logoutBtn')?.addEventListener('click', () => {
    currentUser = null;
    document.getElementById('loginScreen').style.display = 'flex';
    document.getElementById('appContainer').style.display = 'none';
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
    switch(section) {
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
        
        const tbody = document.querySelector('#tablaCitas tbody');
        tbody.innerHTML = data.data.map(c => `
            <tr>
                <td>${c.CitaID}</td>
                <td>${new Date(c.FechaCita).toLocaleString()}</td>
                <td>${c.NombrePaciente}</td>
                <td>${c.NombreDoctor}</td>
                <td>${c.EstadoCita}</td>
            </tr>
        `).join('');
        
        // Cargar pacientes y doctores para el modal
        loadPacientesSelect();
        loadDoctoresSelect();
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
                    ${Object.entries(p.especificaciones).map(([k,v]) => 
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
            headers: {'Content-Type': 'application/json'},
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
            headers: {'Content-Type': 'application/json'},
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
        const res = await fetch(`${API_URL}/pacientes/${id}`, {method: 'DELETE'});
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
```

## 🚀 PASOS FINALES

1. Copia estos 3 archivos a sus ubicaciones:
   - `public/index.html`
   - `public/css/styles.css`
   - `public/js/app.js`

2. Ejecuta `npm start`

3. Abre `http://localhost:3000`

4. ¡Listo! Tu sistema está completo y funcional.

## ✅ SISTEMA COMPLETO

Con esto tendrás:
- ✅ Login funcional (ValidarLogin SP)
- ✅ Gestión de Pacientes (con TUS SPs)
- ✅ Gestión de Citas (sp_AgendarCita)
- ✅ Inventario polimórfico (MongoDB)
- ✅ Expedientes clínicos (MongoDB)
- ✅ Encuestas (MongoDB)
- ✅ Dashboard con estadísticas

¡Todo adaptado a TUS archivos SQL y MongoDB originales!
