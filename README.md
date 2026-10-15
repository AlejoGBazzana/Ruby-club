# Ruby Club

Aplicación web de gestión de actividades, socios y deportistas para un club deportivo. El proyecto combina un back-office administrativo con una API JSON versionada para uso del usuario final.

Este trabajo corresponde a la modalidad individual del TP2 y continúa con el backend desarrollado en el TP1, manteniendo la API JSON y el back-office administrativo bajo `/admin`. El frontend de usuario final se implementa con React + Vite y consume la API REST de Rails de manera separada.

## 1. Descripción general

Ruby Club permite:

- administrar socios, deportistas, deportes, actividades e inscripciones desde un área administrativa bajo `/admin`;
- registrar usuarios con autenticación basada en Devise;
- gestionar la relación entre socios y deportistas;
- controlar cupos e inscripciones por actividad;
- consumir datos desde una API REST bajo `/api/v1`;
- enviar correos de confirmación con `Action Mailer` al cambiar una inscripción a `confirmada`;
- manejar archivos de imagen asociados a socios mediante `Active Storage`.

## 2. Versiones y requisitos verificados

### Ruby y Rails

- Ruby: `4.0.6` según `.ruby-version`.
- Rails: `~> 8.1.3` declarado en el `Gemfile`.
- Bundler: la resolución del proyecto se ejecuta con Bundler 4.0.16 en el entorno de trabajo actual.

### Frontend

El proyecto React + Vite indica en su documentación local versiones compatibles con:

- Node.js `18.x` o superior;
- React `^19.2.8`;
- Vite `^8.3.0`;
- Vitest `^5.0.3`;
- Testing Library React `^16.3.3`;
- jsdom `^30.1.2`.

Estos valores se verifican en `ruby-club-frontend/package.json` y en la documentación del frontend del repositorio.

### Dependencias del backend

- SQLite para desarrollo y test, según `config/database.yml`.
- Devise para autenticación.
- Pundit para autorización.
- Active Storage y Action Mailer.

## 3. Instalación y preparación del entorno

### 3.1. Requisitos locales

- Ruby `4.0.6` (según `.ruby-version`).
- Bundler disponible en el entorno.
- SQLite local instalado y accesible.
- Node.js compatible con el frontend React + Vite.

### 3.2. Backend Rails

Desde la raíz del proyecto:

```bash
cd "C:/GitHub/Facultad/Prog IV/Ruby_Club"
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

La base de datos del proyecto está definida en `config/database.yml` y usa SQLite para `development` y `test`.

> `db:seed` existe y carga datos de prueba del dominio del sistema (socios, deportes, actividades e inscripciones). La carga de seeds no crea usuarios Devise de manera explícita en este repositorio.

### 3.3. Frontend React

Desde la carpeta del frontend:

```bash
cd "C:/GitHub/Facultad/Prog IV/Ruby_Club/ruby-club-frontend"
npm install
npm run dev
```

El frontend queda disponible en `http://localhost:5173` y el backend en `http://127.0.0.1:3000`.

La configuración del proxy de Vite está definida en `ruby-club-frontend/vite.config.js` y redirige las peticiones a `/api` al backend Rails.

### CORS y entorno local

En desarrollo, la integración se resuelve con un proxy de Vite hacia `http://127.0.0.1:3000`; no hay una configuración explícita de CORS en Rails para este repositorio. Esa decisión es compatible con el flujo local previsto y no requiere middleware adicional ni cambios en el backend. Si más adelante se despliega el frontend en un origen distinto del backend, entonces deberá evaluarse una configuración explícita de CORS por requisito de despliegue, pero eso no forma parte del alcance actual de este proyecto.

## 4. Estructura funcional

### Back-office administrativo

El back-office está implementado bajo `/admin` y gestiona los recursos:

- `Socios`
- `Deportistas`
- `Deportes`
- `Actividades`
- `Inscripciones`

La definición real de las rutas está en `config/routes.rb`.

### Usuario final / frontend

El frontend se sirve desde rutas como:

- `/`
- `/login`
- `/actividades`
- `/mis-inscripciones`

### Autenticación

- La autenticación web y del back-office usa Devise.
- La API usa autenticación por token Bearer.

## 5. Modelo `User` y preparación de usuarios de prueba

El modelo `User` está definido en `app/models/user.rb` y admite los roles:

- `user`
- `admin`
- `superadmin`

La clase usa Devise y define `:database_authenticatable`, `:registerable`, `:recoverable`, `:rememberable` y `:validatable`.

### Limitación verificada

No existe en el repositorio un procedimiento oficial, reproducible y seguro para crear usuarios de prueba con `User.create` o con un seed de usuarios Devise. La semilla disponible (`db/seeds.rb`) crea socios, deportes, actividades e inscripciones, pero no crea usuarios de autenticación.

Por ese motivo, esta documentación no inventa un paso de creación de usuarios ni expone credenciales reales, tokens, contraseñas ni secretos.

### Procedimiento seguro para una cuenta temporal de demostración (solo desarrollo)

Para probar el recorrido del usuario final en el frontend con un `User` válido, el proyecto exige que exista un `Socio` con un `Deportista` asociado y que ese `Socio` no esté ya vinculado a otro `User`. Esa restricción está dada por los modelos de `User`, `Socio` y `Deportista`, y no debe alterarse para un entorno de prueba.

La forma segura y mínima de prepararla en un entorno local es la siguiente:

1. Garantizar que se trabaja sobre la base de desarrollo del proyecto.
2. Buscar un `Socio` que tenga un `Deportista` asociado y que no esté ya enlazado a ningún `User`.
3. Crear un `User` nuevo con rol `user`, un email temporal único y una contraseña válida según Devise.
4. Asociarlo al `Socio` elegido.
5. Verificar la relación antes de usar la cuenta.
6. Eliminar solo ese `User` temporal al finalizar la prueba únicamente si se verifican conjuntamente:
   - el `id` exacto devuelto al crear esa cuenta,
   - que ese `id` sigue correspondiendo al email temporal esperado,
   - y que la cuenta fue creada específicamente para esta prueba.
   La limpieza no debe eliminar ni modificar el `Socio`, el `Deportista` ni las `Inscripcion`.

Ejemplo de procedimiento documentado, sin ejecutar ni dejar credenciales persistentes en el repositorio:

```powershell
cd "C:/GitHub/Facultad/Prog IV/Ruby_Club"
$env:RAILS_ENV = "development"

bin/rails runner "
raise 'No se está en development' unless Rails.env.development?
if User.exists?(email: 'temp.user.dev@example.com')
  abort('TEMP_USER_ALREADY_EXISTS')
end
candidate = Socio.joins(:deportista).left_outer_joins(:user).where(users: { id: nil }).order(:id).first
abort('NO_EXISTE_SOCIO_CANDIDATO') if candidate.nil?
user = User.create!(email: 'temp.user.dev@example.com', password: 'Password123', password_confirmation: 'Password123', role: 'user', socio_id: candidate.id)
puts \"TEMP_USER_ID=#{user.id}\"
"
```

El comando anterior solo se usa como ejemplo de procedimiento local y debe ejecutarse únicamente en `development`, con una dirección temporal que no corresponda a un usuario real del sistema. No se deben conservar credenciales reales ni usuarios creados de forma permanente. Si la cuenta temporal no puede prepararse con estas condiciones, el procedimiento debe detenerse sin crear datos.

## 6. API JSON versionada

La API se encuentra bajo ` /api/v1 ` y está definida en `config/routes.rb`.

### Endpoints reales existentes

| Método | Ruta | Controlador/acción | Autenticación | Propósito |
|---|---|---|---|---|
| `POST` | `/api/v1/login` | `Api::V1::AuthenticationController#login` | No | iniciar sesión con email y contraseña |
| `POST` | `/api/v1/logout` | `Api::V1::AuthenticationController#logout` | Sí | invalidar token actual |
| `GET` | `/api/v1/me` | `Api::V1::MeController#show` | Sí | devolver usuario autenticado |
| `GET` | `/api/v1/actividades` | `Api::V1::ActividadesController#index` | Sí | listar actividades |
| `GET` | `/api/v1/inscripciones` | `Api::V1::InscripcionesController#index` | Sí | listar inscripciones del usuario autenticado |
| `POST` | `/api/v1/inscripciones` | `Api::V1::InscripcionesController#create` | Sí | crear inscripción |
| `DELETE` | `/api/v1/inscripciones/:id` | `Api::V1::InscripcionesController#destroy` | Sí | cancelar inscripción propia |

### Autenticación API

La autenticación API se implementa con bearer tokens. El cliente envía `Authorization: Bearer <token>`, y el backend valida dicho token para cada operación protegida. `User#generate_api_token!` crea un token y lo guarda como digest; el valor real no se expone como texto plano.

## 7. Tests, lint, build, RuboCop y Brakeman

### Rails

```bash
bundle exec rails test
```

### Frontend

```bash
cd "C:/GitHub/Facultad/Prog IV/Ruby_Club/ruby-club-frontend"
npm test
npm run lint
npm run build
```

### RuboCop

```bash
bundle exec rubocop
```

### Brakeman

```bash
bundle exec brakeman
```

### Advertencia conocida del entorno

En el entorno actual de Windows con Ruby `4.0.6`, Bundler `4.0.16` y Brakeman `8.0.6`, la ejecución puede mostrar mensajes adicionales sobre `Process.fork` o rutas no encontradas. En este proyecto, el análisis final generó salida con código `0`, pero esa evidencia no debe interpretarse como una auditoría perfecta ni como una garantía de ausencia total de alertas en todos los entornos.

## 8. Limitaciones y no-objetivos documentados

- El repositorio no incluye un enunciado oficial del TP2 ni la sección 9.1 del mismo.
- No se documenta un procedimiento verificado para crear usuarios Devise con la semilla del proyecto.
- No hay enlaces de despliegue verificados en el repositorio.
- No se publican contraseñas, tokens ni secretos en esta documentación.

## 9. Resumen del flujo de ejecución recomendado

1. Instalar dependencias del backend con Bundler.
2. Crear la base SQLite y migrar la estructura.
3. Ejecutar `db:seed` si se desea cargar datos del dominio.
4. Iniciar el backend Rails.
5. Instalar dependencias del frontend y levantar Vite.
6. Ejecutar tests, lint, build y auditorías de seguridad según corresponda.

Este README se mantiene orientado a lo que está comprobado en el repositorio y evita describir pasos no verificados ni inventar requisitos ajenos al código real del proyecto.
