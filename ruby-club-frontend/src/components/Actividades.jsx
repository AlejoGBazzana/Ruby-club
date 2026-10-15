import { useState, useEffect, useMemo, useCallback } from 'react';
import { apiClient } from '../api/client';

export default function Actividades({ onSelectActividad, onNavigate, onUnauthorized }) {
  const [actividades, setActividades] = useState([]);
  const [inscripciones, setInscripciones] = useState([]);
  const [selectedSport, setSelectedSport] = useState('todos');
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState('');

  const loadData = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage('');

    try {
      const [actividadesRes, inscripcionesRes] = await Promise.all([
        apiClient.getActividades(onUnauthorized),
        apiClient.getInscripciones(onUnauthorized).catch((err) => {
          console.warn('No se pudieron cargar inscripciones previas:', err);
          return { inscripciones: [] };
        }),
      ]);

      setActividades(actividadesRes?.actividades || []);
      setInscripciones(inscripcionesRes?.inscripciones || []);
    } catch (err) {
      console.error('Error al cargar actividades:', err);
      setErrorMessage(err.message || 'No se pudieron cargar las actividades.');
    } finally {
      setIsLoading(false);
    }
  }, [onUnauthorized]);

  useEffect(() => {
    const timeoutId = window.setTimeout(() => {
      void loadData();
    }, 0);

    return () => window.clearTimeout(timeoutId);
  }, [loadData]);

  // Mapa de inscripciones activas por ID de actividad
  const userInscriptionsMap = useMemo(() => {
    const map = new Map();
    inscripciones.forEach((ins) => {
      if (ins.estado !== 'cancelada' && ins.actividad?.id) {
        map.set(ins.actividad.id, ins);
      }
    });
    return map;
  }, [inscripciones]);

  // Lista de deportes disponibles para filtros
  const deportes = useMemo(() => {
    return Array.from(
      new Set(actividades.map((a) => a.deporte?.nombre).filter(Boolean))
    ).sort();
  }, [actividades]);

  // Actividades filtradas
  const filteredActividades = useMemo(() => {
    if (selectedSport === 'todos') {
      return actividades;
    }
    return actividades.filter((a) => a.deporte?.nombre === selectedSport);
  }, [actividades, selectedSport]);

  const formatDate = (dateStr) => {
    if (!dateStr) return '--/--/----';
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      return `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
    return dateStr;
  };

  return (
    <div className="club-container">
      <div className="page-header">
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', flexWrap: 'wrap', gap: '0.5rem' }}>
          <h1 className="page-title">Actividades Deportivas</h1>
          {!isLoading && (
            <span className="text-muted" style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>
              {filteredActividades.length} actividad{filteredActividades.length === 1 ? '' : 'es'}
            </span>
          )}
        </div>
        <p className="page-subtitle">
          Explorá las actividades del club y reservá tu lugar en entrenamientos y torneos.
        </p>
      </div>

      {/* Alerta de Error con botón de reintento */}
      {errorMessage && (
        <div className="alert alert-danger" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <span>⚠️</span> <span>{errorMessage}</span>
          </div>
          <button type="button" className="btn btn-outline btn-sm" onClick={loadData}>
            Reintentar
          </button>
        </div>
      )}

      {/* Filtros por Deporte */}
      {!isLoading && actividades.length > 0 && (
        <div className="filter-bar">
          <button
            type="button"
            className={`filter-pill ${selectedSport === 'todos' ? 'active' : ''}`}
            onClick={() => setSelectedSport('todos')}
          >
            Todos ({actividades.length})
          </button>
          {deportes.map((deporte) => {
            const count = actividades.filter((a) => a.deporte?.nombre === deporte).length;
            return (
              <button
                key={deporte}
                type="button"
                className={`filter-pill ${selectedSport === deporte ? 'active' : ''}`}
                onClick={() => setSelectedSport(deporte)}
              >
                {deporte} ({count})
              </button>
            );
          })}
        </div>
      )}

      {/* Indicador de Carga */}
      {isLoading && (
        <div className="loading-state">
          <div className="spinner"></div>
          <p>Cargando actividades disponibles...</p>
        </div>
      )}

      {/* Grid de Tarjetas de Actividad */}
      {!isLoading && !errorMessage && filteredActividades.length > 0 && (
        <div className="activities-grid">
          {filteredActividades.map((actividad) => {
            const yaInscripto = userInscriptionsMap.has(actividad.id);
            const inscripcionActiva = yaInscripto ? userInscriptionsMap.get(actividad.id) : null;
            const sinCupo = actividad.cupo_disponible <= 0;
            const fechaFormateada = formatDate(actividad.fecha);
            const horario = actividad.horario || '--:--';

            return (
              <article
                key={actividad.id}
                className={`activity-card ${yaInscripto ? 'is-enrolled' : ''} ${sinCupo && !yaInscripto ? 'is-full' : ''}`}
              >
                <div className="activity-card-header">
                  <span className="sport-tag">{actividad.deporte?.nombre || 'Deporte'}</span>
                  {yaInscripto ? (
                    <span className="badge badge-enrolled">
                      <span className="badge-dot"></span> Inscripto ({inscripcionActiva?.estado === 'confirmada' ? 'Confirmada' : 'Pendiente'})
                    </span>
                  ) : sinCupo ? (
                    <span className="badge badge-full">
                      <span className="badge-dot"></span> Cupo completo
                    </span>
                  ) : (
                    <span className="badge badge-available">
                      <span className="badge-dot"></span> {actividad.cupo_disponible} cupo{actividad.cupo_disponible === 1 ? '' : 's'} disponible{actividad.cupo_disponible === 1 ? '' : 's'}
                    </span>
                  )}
                </div>

                <h3 className="activity-title">{actividad.nombre}</h3>

                <div className="activity-metadata">
                  <div className="metadata-item">
                    <span className="metadata-icon">📅</span>
                    <span>{fechaFormateada}</span>
                  </div>
                  <div className="metadata-item">
                    <span className="metadata-icon">🕒</span>
                    <span>{horario} hs</span>
                  </div>
                  <div className="metadata-item">
                    <span className="metadata-icon">👥</span>
                    <span>Cupo total: {actividad.cupo}</span>
                  </div>
                </div>

                <div className="activity-card-footer">
                  {yaInscripto ? (
                    <button
                      type="button"
                      className="btn btn-outline btn-sm"
                      onClick={() => onNavigate('mis-inscripciones')}
                    >
                      Ver mi inscripción
                    </button>
                  ) : sinCupo ? (
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      onClick={() => onSelectActividad(actividad.id)}
                    >
                      Ver detalle
                    </button>
                  ) : (
                    <button
                      type="button"
                      className="btn btn-primary btn-sm"
                      onClick={() => onSelectActividad(actividad.id)}
                    >
                      Ver actividad
                    </button>
                  )}
                </div>
              </article>
            );
          })}
        </div>
      )}

      {/* Estado Vacío */}
      {!isLoading && !errorMessage && filteredActividades.length === 0 && (
        <div className="empty-state">
          <span className="empty-state-icon">⚽</span>
          <h3 className="empty-state-title">No hay actividades disponibles</h3>
          <p className="empty-state-text">
            No se encontraron actividades programadas para el deporte seleccionado.
          </p>
        </div>
      )}
    </div>
  );
}
