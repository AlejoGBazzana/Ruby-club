import React, { useState, useEffect, useCallback } from 'react';
import Navbar from './components/Navbar';
import Login from './components/Login';
import Actividades from './components/Actividades';
import ActividadDetalle from './components/ActividadDetalle';
import MisInscripciones from './components/MisInscripciones';
import { apiClient } from './api/client';

export default function App() {
  const [user, setUser] = useState(() => apiClient.getUser());
  const [currentPage, setCurrentPage] = useState(() => {
    return apiClient.isAuthenticated() ? 'actividades' : 'login';
  });
  const [selectedActividadId, setSelectedActividadId] = useState(null);
  const [sessionExpired, setSessionExpired] = useState(false);

  // Cargar info extendida de /me cuando esté autenticado
  const fetchUserInfo = useCallback(async () => {
    if (!apiClient.isAuthenticated()) return;
    try {
      const data = await apiClient.getMe(() => {
        handleUnauthorized();
      });
      if (data) {
        setUser((prev) => ({
          ...(prev || {}),
          ...data.user,
          socio: data.socio,
          deportista: data.deportista,
        }));
      }
    } catch (e) {
      console.warn('No se pudo cargar /me:', e);
    }
  }, []);

  useEffect(() => {
    if (apiClient.isAuthenticated()) {
      fetchUserInfo();
    }
  }, [fetchUserInfo]);

  const handleUnauthorized = useCallback(() => {
    apiClient.clearSession();
    setUser(null);
    setSessionExpired(true);
    setCurrentPage('login');
  }, []);

  const handleLoginSuccess = async (email, password) => {
    const data = await apiClient.login(email, password);
    setSessionExpired(false);
    setUser(data.user);
    await fetchUserInfo();
    setCurrentPage('actividades');
  };

  const handleLogout = async () => {
    await apiClient.logout();
    setUser(null);
    setSessionExpired(false);
    setCurrentPage('login');
  };

  const handleNavigate = (page) => {
    // Protección de rutas: si no está autenticado, solo puede ir a login
    if (!apiClient.isAuthenticated() && page !== 'login') {
      setCurrentPage('login');
      return;
    }

    // Si está autenticado e intenta ir a login, redirigir a actividades
    if (apiClient.isAuthenticated() && page === 'login') {
      setCurrentPage('actividades');
      return;
    }

    setCurrentPage(page);
  };

  const handleSelectActividad = (id) => {
    setSelectedActividadId(id);
    setCurrentPage('actividad-detalle');
  };

  const handleBackToActividades = () => {
    setSelectedActividadId(null);
    setCurrentPage('actividades');
  };

  return (
    <div className="frontend-wrapper">
      <Navbar
        user={user}
        onNavigate={handleNavigate}
        activePage={currentPage}
        onLogout={handleLogout}
      />

      <main className="club-main">
        {currentPage === 'login' && (
          <Login
            onLoginSuccess={handleLoginSuccess}
            sessionExpired={sessionExpired}
          />
        )}

        {currentPage === 'actividades' && (
          <Actividades
            onSelectActividad={handleSelectActividad}
            onNavigate={handleNavigate}
            onUnauthorized={handleUnauthorized}
          />
        )}

        {currentPage === 'actividad-detalle' && (
          <ActividadDetalle
            actividadId={selectedActividadId}
            onBack={handleBackToActividades}
            onNavigate={handleNavigate}
            onUnauthorized={handleUnauthorized}
          />
        )}

        {currentPage === 'mis-inscripciones' && (
          <MisInscripciones
            onNavigate={handleNavigate}
            onUnauthorized={handleUnauthorized}
          />
        )}
      </main>

      <footer className="club-footer">
        <p>Ruby Club — Aplicación de gestión deportiva para clubes de barrio · Programación IV</p>
      </footer>
    </div>
  );
}
