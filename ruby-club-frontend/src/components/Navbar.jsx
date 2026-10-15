
export default function Navbar({ user, onNavigate, activePage, onLogout }) {
  const isAuthenticated = !!user;

  const getDisplayName = () => {
    if (!user) return 'Socio';
    if (user.socio) {
      return `${user.socio.nombre} ${user.socio.apellido}`;
    }
    return user.email || 'Socio';
  };

  return (
    <header className="club-navbar">
      <div className="navbar-inner">
        <button
          type="button"
          onClick={() => onNavigate(isAuthenticated ? 'actividades' : 'login')}
          className="navbar-brand"
        >
          <span className="brand-icon">💎</span>
          <span>RUBY CLUB</span>
        </button>

        {isAuthenticated && (
          <ul className="navbar-nav">
            <li>
              <button
                type="button"
                className={`nav-link ${activePage === 'actividades' || activePage === 'actividad-detalle' ? 'active' : ''}`}
                onClick={() => onNavigate('actividades')}
              >
                Actividades
              </button>
            </li>
            <li>
              <button
                type="button"
                className={`nav-link ${activePage === 'mis-inscripciones' ? 'active' : ''}`}
                onClick={() => onNavigate('mis-inscripciones')}
              >
                Mis Inscripciones
              </button>
            </li>
          </ul>
        )}

        <div className="navbar-actions">
          {isAuthenticated ? (
            <>
              <span className="user-badge">
                <span>👤</span>
                <strong>{getDisplayName()}</strong>
              </span>
              <button
                type="button"
                className="btn btn-outline btn-sm"
                onClick={onLogout}
              >
                Cerrar sesión
              </button>
            </>
          ) : (
            <div>
              <button
                type="button"
                className="btn btn-primary btn-sm"
                onClick={() => onNavigate('login')}
              >
                Ingresar
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
