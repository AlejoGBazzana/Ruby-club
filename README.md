# Ruby Club

Aplicación web de gestión de actividades, socios y deportistas para un club deportivo. El proyecto combina un back-office administrativo con una API JSON versionada para uso del usuario final.

Este trabajo corresponde a la modalidad individual del TP2. El backend original fue desarrollado por el mismo autor del repositorio y el frontend se implementa con React + Vite consumiendo la API REST de Rails de manera separada.

## 1. Información general

### Temática
Ruby Club permite:

- administrar socios, deportistas, deportes, actividades e inscripciones desde un área administrativa bajo `/admin`;
- registrar usuarios con autenticación basada en Devise;
- gestionar la relación entre socios y deportistas;
- controlar cupos e inscripciones por actividad;
- consumir datos desde una API REST bajo `/api/v1`;
- enviar correos de confirmación con `Action Mailer` al cambiar una inscripción a `confirmada`;
- manejar archivos asociados a socios mediante `Active Storage`.

### Autor y modalidad
- Modalidad de trabajo: individual.
- Autor del backend original: autor único del trabajo (mismo desarrollador del repositorio).
- Frontend: React con Vite.

## 2. Stack tecnológico y versiones verificadas

### Backend (Ruby on Rails)

La evidencia del repositorio indica:

- Ruby: `4.0.6` según el archivo `.ruby-version`.
- Rails: `~> 8.1.3` en `Gemfile`.
- Bundler: la resolución del proyecto se ejecuta con Bundler 4.0.16 en el entorno actual.
- Base de datos: SQLite, configurada en `config/database.yml`.
- Autenticación: Devise.
- Autorización: Pundit.
- Servidor web: Puma.

### Frontend (React + Vite)

La evidencia del repositorio indica:

- Node.js: compatible con la versión 18.x o superior, según la documentación local del frontend.
- React: `^19.2.8`.
- Vite: `^8.3.0`.
- Vitest: `^5.0.3`.
- Testing Library React: `^16.3.3`.
- jsdom: `^30.1.2`.

Estos valores se verifican en `ruby-club-frontend/package.json`.

## 3. Requisitos previos

- Ruby 4.0.6.
- Bundler disponible.
- SQLite instalado y accesible localmente.
- Node.js y npm compatibles con el frontend React + Vite.
- Git para clonar el repositorio.

## 4. Instalación y preparación del entorno

### 4.1 Backend Rails

Desde la raíz del proyecto:

```powershell
cd "C:/GitHub/Facultad/Prog IV/Ruby_Club"
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

La base de datos del proyecto está definida en `config/database.yml` y usa SQLite para `development` y `test`.

> `db:seed` carga datos del dominio del sistema (socios, deportes, actividades e inscripciones). No crea usuarios Devise de manera explícita en este repositorio.

### 4.2 Frontend React

Desde la carpeta del frontend:

```powershell
cd "C:/GitHub/Facultad/Prog IV/Ruby_Club/ruby-club-frontend"
npm install
npm run dev
```

### 4.3 URLs locales de desarrollo

- Frontend: `http://localhost:5173`
- Backend: `http://127.0.0.1:3000`

El frontend se comunica con Rails usando la configuración de proxy de Vite en `ruby-club-frontend/vite.config.js`, que redirige `/api` hacia `http://127.0.0.1:3000`.

### 4.4 Variables de entorno

No se requieren variables de entorno adicionales para la ejecución local documentada del backend y del frontend. La integración local se resuelve con la configuración de Rails/Puma y el proxy de Vite para `/api`, y no hay una configuración de entorno específica verificada en el repositorio para esta ejecución.

## 5. Datos de prueba y usuarios

### Datos precargados mediante `db/seeds.rb`

El seed crea:

- socios;
- deportistas asociados a socios;
- deportes;
- actividades;
- inscripciones con distintos estados.

Esto está verificado en `db/seeds.rb`.

### Usuarios de autenticación

El modelo `User` se define en `app/models/user.rb` y admite los roles:

- `user`
- `admin`
- `superadmin`

La aplicación usa Devise para la autenticación del sistema y la API usa Bearer tokens para las llamadas protegidas.

### Mecanismo real para crear un usuario temporal de desarrollo

Sí puede crearse un usuario temporal en entorno local, verificando la estructura actual del modelo:

- `User` usa Devise y tiene `belongs_to :socio, optional: true`.
- `Socio` tiene `has_one :user` y `has_one :deportista`.
- `Deportista` pertenece a `Socio` y su `socio_id` es único.
- La autenticación de la API usa `User.find_for_database_authentication(email: ...)` y `valid_password?(password)`.

Por lo tanto, el procedimiento reproducible es crear un `User` asociado a un `Socio` que ya tenga un `Deportista` y que no esté enlazado a otro usuario. La creación debe hacerse en `development` y con un email temporal único.

```powershell
cd "C:/GitHub/Facultad/Prog IV/Ruby_Club"
$env:RAILS_ENV = "development"

bin/rails runner "
  socio = Socio.joins(:deportista).left_outer_joins(:user)
               .where(users: { id: nil })
               .order(:id)
               .first

  abort('No existe un Socio con Deportista libre para crear un usuario temporal.') unless socio

  email = 'temp.user.dev@example.com'
  abort('Ya existe un usuario con ese email temporal.') if User.exists?(email: email)

  user = User.create!(email: email, password: 'Password123', password_confirmation: 'Password123', role: 'user', socio: socio)
  puts \"Usuario temporal creado: #{user.email} (id=#{user.id})\"
"
```

Este procedimiento es válido para entorno local de desarrollo y no debe dejarse en la base de datos de producción. No se publican credenciales reales ni se incluye un usuario permanente en el repositorio.

## 6. Comunicación frontend-backend

El flujo real viene definido por:

- `ruby-club-frontend/src/api/client.js`: cliente HTTP centralizado para consumir la API.
- `ruby-club-frontend/vite.config.js`: proxy de Vite para `/api` hacia el backend Rails.
- `config/routes.rb`: rutas del backend.
- `app/controllers/api/v1/*`: controladores de la API.

En desarrollo, el navegador consulta el frontend en `localhost:5173`, y Vite reenvía las llamadas a `/api/...` hacia `127.0.0.1:3000`. Luego Rails responde con JSON y el frontend procesa esta respuesta en React.

## 7. API JSON y autenticación

La API está bajo `/api/v1` y se define en `config/routes.rb`.

Endpoints reales verificados:

- `POST /api/v1/login`
- `POST /api/v1/logout`
- `GET /api/v1/me`
- `GET /api/v1/actividades`
- `GET /api/v1/inscripciones`
- `POST /api/v1/inscripciones`
- `DELETE /api/v1/inscripciones/:id`

La autenticación API se hace con `Authorization: Bearer <token>` y la validación del token se resuelve en `app/controllers/api/v1/base_controller.rb` y `app/models/user.rb`.

## 8. Comandos de verificación y calidad

Los comandos reales del repositorio son los siguientes.

### Backend

```powershell
bundle exec rails test
bundle exec rubocop
bundle exec brakeman
```

### Frontend

```powershell
cd "C:/GitHub/Facultad/Prog IV/Ruby_Club/ruby-club-frontend"
npm test
npm run lint
npm run build
```

### CI del repositorio

La configuración de CI en `config/ci.rb` incluye:

```powershell
bin/setup --skip-server
bin/rubocop
bin/bundler-audit
bin/importmap audit
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/rails test
```

> No se afirmaron ejecuciones exitosas ni resultados de auditorías en esta sesión; los comandos se documentan según la configuración del proyecto y la evidencia del repositorio.

## 9. Deploy

No se realizó deploy del proyecto. Por lo tanto, no existe una URL pública verificada del frontend ni del backend.

Durante el desarrollo, las URLs locales son:

- Frontend: `http://localhost:5173`
- Backend: `http://127.0.0.1:3000`

## 10. Pendientes de documentación y limitaciones verificadas

Los siguientes puntos no tienen evidencia directa de implementación o deploy en el repositorio y, por eso, se documentan como limitaciones:

- No hay deploy verificado ni URLs públicas.
- No hay usuarios de demostración precargados en `db/seeds.rb`.
- No se documentan secretos ni credenciales reales.
- No se incluyen URLs de producción porque no existen en este repositorio.

## 11. Resumen de ejecución recomendado

1. Instalar dependencias del backend con Bundler.
2. Crear la base SQLite y ejecutar migraciones.
3. Cargar `db:seed` si se necesita data de prueba del dominio.
4. Iniciar el backend Rails en puerto 3000.
5. Instalar dependencias del frontend con npm.
6. Levantar Vite en puerto 5173.
7. Ejecutar tests, lint y build de acuerdo con los comandos documentados.

Este README representa la documentación verificada del repositorio y evita afirmar información no implementada o no comprobada en el código.
