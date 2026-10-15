import { useState } from 'react';

export default function Login({ onLoginSuccess, sessionExpired }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrorMessage('');

    const trimmedEmail = email.trim();
    if (!trimmedEmail || !password) {
      setErrorMessage('Por favor, completá tu email y contraseña.');
      return;
    }

    setIsLoading(true);
    try {
      await onLoginSuccess(trimmedEmail, password);
    } catch (err) {
      setIsLoading(false);
      if (err.code === 'invalid_credentials' || err.status === 401) {
        setErrorMessage('Email o contraseña inválidos. Verificá tus datos.');
      } else if (err.network) {
        setErrorMessage('No se pudo conectar con el servidor. Comprobá que la aplicación esté activa.');
      } else {
        setErrorMessage(err.message || 'Ocurrió un error al intentar iniciar sesión.');
      }
    }
  };

  return (
    <div className="club-container-narrow">
      <div className="login-card">
        <div className="login-header">
          <div className="login-logo">💎</div>
          <h1 className="login-title">Ruby Club</h1>
          <p className="login-subtitle">
            Ingresá con tus credenciales de socio para acceder a tus actividades e inscripciones.
          </p>
        </div>

        {/* Alerta de sesión expirada */}
        {sessionExpired && !errorMessage && (
          <div className="alert alert-warning">
            <span>⚠️</span>
            <span>Tu sesión ha expirado. Por favor, volvé a iniciar sesión.</span>
          </div>
        )}

        {/* Alerta de error */}
        {errorMessage && (
          <div className="alert alert-danger">
            <span>❌</span>
            <span>{errorMessage}</span>
          </div>
        )}

        {/* Formulario de Login */}
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="login-email" className="form-label">
              Correo electrónico
            </label>
            <input
              type="email"
              id="login-email"
              className="form-input"
              placeholder="ejemplo@club.com"
              required
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={isLoading}
            />
          </div>

          <div className="form-group">
            <label htmlFor="login-password" className="form-label">
              Contraseña
            </label>
            <input
              type="password"
              id="login-password"
              className="form-input"
              placeholder="••••••••"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isLoading}
            />
          </div>

          <button
            type="submit"
            className="btn btn-primary btn-block btn-lg"
            disabled={isLoading}
          >
            {isLoading ? 'Ingresando...' : 'Ingresar'}
          </button>
        </form>
      </div>
    </div>
  );
}
