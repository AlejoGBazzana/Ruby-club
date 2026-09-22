# Ruby Club

Aplicación web de gestión de actividades, socios y deportistas para un club deportivo, desarrollada con Ruby on Rails. El proyecto combina un back-office administrativo con una API JSON versionada para el uso del usuario final.

## 1. Descripción general

Ruby Club permite:

- administrar socios, deportistas, deportes, actividades e inscripciones desde un área administrativa bajo `/admin`;
- registrar usuarios con autenticación basada en Devise;
- gestionar la relación entre socios y deportistas;
- controlar cupos e inscripciones por actividad;
- consumir datos desde una API REST bajo `/api/v1`;
- enviar correos de confirmación por `Action Mailer` cuando una inscripción pasa a estado `confirmada`;
- manejar archivos de imagen asociados a socios mediante Active Storage.

## 2. Tecnologías utilizadas

- Ruby
- Rails 8.1.3 (`Gemfile`)
- SQLite (`config/database.yml`)
- Devise
- Pundit
- Active Storage
- Action Mailer
- API JSON versionada (`/api/v1`)
- Tests con Rails (`bundle exec rails test`)
- RuboCop (`bundle exec rubocop`)
- Brakeman (`bundle exec brakeman`)

## 3. Requisitos e instalación

### Requisitos

- Ruby compatible con Rails 8.
- Bundler.
- SQLite disponible localmente.
- La versión exacta de Ruby no está fijada explícitamente en el repositorio, pero el proyecto declara `rails ~> 8.1.3` en el `Gemfile`.

### Instalación

Desde la raíz del proyecto:

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails server
```

El proyecto usa la base SQLite definida en `config/database.yml` para desarrollo y test.

## 4. Estructura funcional

### Back-office administrativo

El back-office está implementado bajo el namespace `/admin` y gestiona los recursos:

- `Socios`
- `Deportistas`
- `Deportes`
- `Actividades`
- `Inscripciones`

Los controladores administrativos heredan de `Admin::BaseController`, que aplica:

- `before_action :authenticate_user!`
- autorización con Pundit mediante `UserPolicy#access_admin?`

### Usuario final / frontend

El frontend se sirve desde `FrontendController` con rutas como:

- `/`
- `/login`
- `/actividades`
- `/mis-inscripciones`

El frontend consume la API JSON bajo `/api/v1` a través de `app/javascript/api_client.js`.

### Autenticación

- La autenticación web y de back-office usa Devise.
- La API usa autenticación por token Bearer.

## 5. Modelos principales

### User

- Hereda de `ApplicationRecord` y usa Devise.
- Tiene roles: `user`, `admin`, `superadmin`.
- Está asociado opcionalmente a un `Socio`.
- Guarda la contraseña cifrada con Devise (`encrypted_password`).
- Tiene soporte para generar e invalidar token de API.

### Socio

- Representa a la persona asociada al club.
- Tiene relación `has_one :deportista`.
- Tiene relación `has_one :user`.
- Tiene `has_one_attached :foto_perfil` para la foto de perfil.
- Valida nombre, apellido, email y fecha de inscripción.

### Deportista

- Está asociado a un `Socio`.
- Tiene muchos deportes mediante `has_and_belongs_to_many :deportes`.
- Tiene muchas inscripciones y muchas actividades a través de ellas.
- Cada deportista tiene un `socio_id` único.

### Deporte

- Tiene muchos deportistas y muchas actividades.
- El nombre es único en forma insensible a mayúsculas/minúsculas.

### Actividad

- Pertenece a un `Deporte`.
- Tiene muchas inscripciones y deportistas a través de ellas.
- Tiene validaciones de nombre, fecha, horario y cupo.
- Calcula `cupo_disponible` usando la cantidad de inscripciones activas.

### Inscripcion

- Pertenece a un `Deportista` y a una `Actividad`.
- Estados posibles: `pendiente`, `confirmada`, `cancelada`.
- Valida unicidad de inscripción activa por deportista y actividad.
- Verifica cupo disponible en la actividad.
- `cancelar!` cambia el estado a `cancelada`.

## 6. Back-office implementado

El namespace administrativo existe y se define en `config/routes.rb`:

```ruby
namespace :admin do
  resources :socios
  resources :deportistas
  resources :deportes
  resources :actividades
  resources :inscripciones
end
```

Los CRUDs concretos implementados son:

- Socios
- Deportistas
- Deportes
- Actividades
- Inscripciones

Cada controlador del back-office usa autenticación por Devise y autorización por Pundit a través de `Admin::BaseController`.

## 7. API JSON versionada

La API se encuentra bajo el namespace `/api/v1` y está definida en `config/routes.rb`.

### Endpoints reales existentes

| Método | Ruta | Controlador/acción | Autenticación | Propósito |
|---|---|---|---|---|
| `POST` | `/api/v1/login` | `Api::V1::AuthenticationController#login` | No | iniciar sesión con email y contraseña |
| `POST` | `/api/v1/logout` | `Api::V1::AuthenticationController#logout` | Sí (Bearer token) | invalidar token actual |
| `GET` | `/api/v1/me` | `Api::V1::MeController#show` | Sí (Bearer token) | devolver usuario autenticado y datos relacionados |
| `GET` | `/api/v1/actividades` | `Api::V1::ActividadesController#index` | Sí (Bearer token) | listar actividades |
| `GET` | `/api/v1/inscripciones` | `Api::V1::InscripcionesController#index` | Sí (Bearer token) | listar inscripciones del deportista autenticado |
| `POST` | `/api/v1/inscripciones` | `Api::V1::InscripcionesController#create` | Sí (Bearer token) | crear inscripción para el deportista autenticado |
| `DELETE` | `/api/v1/inscripciones/:id` | `Api::V1::InscripcionesController#destroy` | Sí (Bearer token) | cancelar inscripción propia |

### Parámetros importantes

- `POST /api/v1/login`
  - `email`
  - `password`
- `POST /api/v1/inscripciones`
  - `actividad_id` (obligatorio)

### Respuesta general

La API responde en JSON con estructura tipo:

```json
{
  "error": {
    "code": "unauthorized",
    "message": "Token de autenticación inválido o ausente."
  }
}
```

Cuando la operación es exitosa, responde con payloads JSON específicos por endpoint; por ejemplo:

```json
{
  "token": "token-generado-por-el-servidor",
  "user": {
    "id": 1,
    "email": "usuario@example.com",
    "role": "user"
  }
}
```

No se encuentran más endpoints `/api/v1` en las rutas actuales del proyecto.

## 8. Autenticación API

La autenticación API se implementa con bearer tokens.

- El cliente envía `Authorization: Bearer <token>`.
- `Api::V1::BaseController#authenticate_api_user!` valida el token.
- `User#generate_api_token!` genera un token aleatorio y guarda su hash `api_token_digest` en base de datos.
- `User.authenticate_api_token` compara el digest del token recibido con el valor almacenado.
- `logout` invalida el token actual con `invalidate_api_token!`.

Esto implica que:

- el token real se entrega al cliente;
- el servidor no almacena el token original en texto plano;
- se evita exponer `encrypted_password` y `api_token_digest` en la API.

## 9. Active Storage

El proyecto usa Active Storage para la foto de perfil del socio.

- `Socio` define `has_one_attached :foto_perfil`.
- Las restricciones implementadas son:
  - tipos permitidos: `image/jpeg`, `image/png`, `image/webp`;
  - tamaño máximo: 5 MB.

La validación real está en `Socio#foto_perfil_valida`.

## 10. Action Mailer

El proyecto implementa `InscripcionMailer` para confirmar inscripciones.

- `InscripcionMailer#confirmacion` arma el correo para el email del socio asociado.
- Se dispara desde `Inscripcion` mediante `after_commit`, cuando el estado pasa a `confirmada`.
- La lógica real del envío está en `Inscripcion#notificar_confirmacion?` y `Inscripcion#enviar_correo_de_confirmacion`.

No se documenta en el repositorio una configuración de producción para envíos reales fuera del entorno local/test del proyecto.

## 11. Tests

La suite completa del proyecto se ejecuta con:

```bash
bundle exec rails test
```

Resultado verificado en el proyecto actual:

- `114 runs`
- `356 assertions`
- `0 failures`
- `0 errors`
- `0 skips`

También se pueden ejecutar tests específicos de la API con:

```bash
bundle exec rails test test/controllers/api/v1
```

Resultado verificado para esa suite específica:

- `16 runs`
- `61 assertions`
- `0 failures`
- `0 errors`
- `0 skips`

## 12. Calidad y seguridad

Se incluye verificación de estilo y seguridad con:

```bash
bundle exec rubocop
bundle exec brakeman
```

La verificación ejecutada sobre el proyecto mostró:

- RuboCop: `76 files inspected, no offenses detected`
- Brakeman: `Errors: 0` y `Security Warnings: 0`

## 13. Credenciales

No hay credenciales hardcodeadas ni usuarios predefinidos almacenados en el repositorio para acceder al sistema en desarrollo o producción.

La forma real de disponer un usuario es creando registros de `User` en la aplicación o en tests, por ejemplo con `User.create!(email: ..., password: ..., role: ...)`.

- El back-office usa autenticación web de Devise mediante `devise_for :users` y `before_action :authenticate_user!` en `Admin::BaseController`.
- La API usa autenticación por token Bearer. El flujo real es:
  1. el cliente envía `email` y `password` a `POST /api/v1/login`;
  2. si las credenciales son válidas, el servidor genera un token;
  3. el cliente envía ese token en el header `Authorization: Bearer <token>`.

Los usuarios y sus permisos se manejan con Devise y Pundit, pero no hay credenciales ni accesos fijos en Git. Se evita exponer contraseñas, hashes de tokens o secretos en la API y en la respuesta JSON.

## 14. Deploy

No se encontró una configuración de despliegue ni una URL de producción documentada en el proyecto inspeccionado. Por ese motivo, no se incluye ningún dato de deploy que no esté respaldado por el código.

## 15. Observaciones finales

- El proyecto presenta una arquitectura clara: back-office administrativo, frontend y API JSON.
- La API actual está implementada y versionada bajo `/api/v1`.
- La autenticación web y de API se apoya en Devise y en tokens Bearer.
- No se documentan secretos, credenciales ni despliegue real en el repositorio.
- La evidencia disponible permite documentar la implementación actual sin inventar funcionalidad adicional.
