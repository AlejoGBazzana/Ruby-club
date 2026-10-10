# Ruby Club — Frontend (React + Vite) — TP2 Programación IV

Frontend de usuario final para **Ruby Club**, migrado desde las vistas de Rails a una Single Page Application (SPA) en **React** construida con **Vite**.

El sistema mantiene el backend en **Ruby on Rails** como fuente de verdad para la lógica de negocio, base de datos, panel administrativo `/admin` y API REST versionada (`/api/v1`).

---

## 1. Requisitos y versiones
 
 - **Node.js:** v18.x o superior (entorno probado y verificado: `v24.18.0`).
 - **npm:** v9.x o superior (entorno probado y verificado: `11.16.0`).
 - **Frontend stack:** React 19 (`^19.2.8`), Vite 8 (`^8.3.0`), Vitest 5 (`^5.0.3`), Testing Library React (`^16.3.3`), Testing Library DOM (`^10.4.2`), jsdom (`^30.1.2`).
 - **Backend:** Ruby compatible con Rails 8 y Rails 8.1.3 (`Gemfile`).
 - **Navegador web moderno** (Chrome, Firefox, Edge, Safari).
 
 ---

## 2. Arquitectura de la solución

```
+-------------------------------------------------------+
|                 Ruby Club System                      |
|                                                       |
|  +------------------------+                           |
|  | Frontend React + Vite  |  (Puerto 5173)            |
|  | - Single Page App      |                           |
|  | - Catálogo actividades |                           |
|  | - Mis inscripciones    |                           |
|  | - Autenticación Bearer |                           |
|  +-----------+------------+                           |
|              |                                        |
|              | HTTP / JSON (Proxy Vite -> /api)       |
|              v                                        |
|  +------------------------+   +--------------------+  |
|  | Backend Rails 8        |   | Panel Back-office  |  |
|  | - API REST (/api/v1)   |<->| - Namespace /admin |  |
|  | - Devise & Pundit      |   | - Vistas ERB       |  |
|  | - SQLite               |   +--------------------+  |
|  +------------------------+                           |
+-------------------------------------------------------+
```

- **React + Vite:** Se encarga de la interfaz interactiva, consumo de la API, manejo de estados de carga, confirmación y errores.
- **Rails API (`/api/v1`):** Autenticación mediante tokens Bearer (`/api/v1/login`, `/api/v1/logout`), consulta de usuario (`/api/v1/me`), listado de actividades (`/api/v1/actividades`) y altas/bajas de inscripciones (`/api/v1/inscripciones`).
- **Proxy de Vite:** En desarrollo, Vite redirige cualquier petición a `/api` hacia `http://127.0.0.1:3000` de forma transparente, evitando problemas de CORS sin alterar el backend.

---

## 3. Instalación de dependencias

Desde el directorio de la aplicación React:

```bash
cd "C:\GitHub\Facultad\Prog IV\Ruby_Club\ruby-club-frontend"
npm install
```

---

## 4. Ejecución en desarrollo (Rails y React en terminales separadas)

Para ejecutar la solución completa se utilizan dos terminales independientes:

### Terminal 1: Servidor Rails (Backend)

Desde la raíz del repositorio:
```bash
cd "C:\GitHub\Facultad\Prog IV\Ruby_Club"
bin/rails server
```
*El backend quedará escuchando en `http://127.0.0.1:3000`.*

### Terminal 2: Servidor Vite (Frontend)

Desde la carpeta del frontend:
```bash
cd "C:\GitHub\Facultad\Prog IV\Ruby_Club\ruby-club-frontend"
npm run dev
```
*El frontend iniciará en `http://localhost:5173`.*

Al acceder a `http://localhost:5173`, Vite proxyeará automáticamente las llamadas a la API de Rails.

---

## 5. Configuración para conectarse a la API

La conexión se realiza a través de `vite.config.js`:

```javascript
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:3000',
        changeOrigin: true,
      },
    },
  },
})
```

No se requieren variables de entorno complejas ni cambios en el código de Rails.

---

## 6. Credenciales de demostración

El sistema se inicializa con los usuarios de prueba generados por las tareas de seeds o creados vía consola/admin:
- **Email:** credencial del socio registrado en la base de datos (por ejemplo, los configurados en `seeds` o en el panel administrativo).
- **Contraseña:** la contraseña asignada al crear el usuario en Devise.

> **Nota:** La autenticación es provista por Devise. Si se ingresan credenciales incorrectas, la aplicación muestra de inmediato el mensaje de error correspondiente devuelto por la API.

---

## 7. Pruebas automatizadas y Build

### Pruebas automatizadas

El proyecto cuenta con una suite de 7 pruebas automatizadas distribuidas en 2 archivos, ejecutadas con **Vitest** en entorno `jsdom`:

- `test/api-client.test.js` (5 pruebas unitarias/integración): evalúa login exitoso con almacenamiento de token, error HTTP 401 por credenciales inválidas, error de negocio HTTP 422 con array de detalles de validación, tratamiento de fallas de red/conexión, y logout con revocación en API y limpieza de sesión.
- `test/login.test.jsx` (2 pruebas de interacción UI con React Testing Library): evalúa el flujo de inicio de sesión exitoso (deshabilitación de botón, llamado a handler, ausencia de alertas de error) y el flujo ante credenciales inválidas (renderizado del mensaje de error exacto devuelto por la API y rehabilitación del botón para reintentar).

Para ejecutar la suite completa de pruebas:

```bash
npm test
```

### Build de producción

Para verificar la compilación y empaquetado para producción:

```bash
npm run build
```

---

## 8. Tratamiento de errores y validaciones en la interfaz

- **Validación de campos obligatorios:** Los formularios validan campos completos en el cliente antes del envío y notifican si falta el email o contraseña.
- **Prevención de envíos dobles:** Los botones de inicio de sesión, inscripción y cancelación se deshabilitan inmediatamente durante la petición (`disabled`), mostrando indicadores de texto (`Ingresando...`, `Procesando inscripción...`, `Cancelando...`).
- **Errores de API enriquecidos:** Si la API devuelve un código HTTP 422 con un array de `details` (por ejemplo: "El cupo está completo" o "Ya tenés una inscripción activa"), el frontend muestra cada uno de los detalles específicos provistos por el backend.
- **Fallas de red:** Si el servidor no responde o está apagado, se presenta un mensaje claro solicitando comprobar la conexión.
- **Sesión expirada:** Si el token caduca o resulta inválido (HTTP 401), se limpia `sessionStorage` y se redirige al login con la alerta correspondiente.
