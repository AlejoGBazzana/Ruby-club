import React, { useState, useEffect, useCallback } from 'react';
import { apiClient } from '../api/client';

export default function ActividadDetalle({ actividadId, onBack, onNavigate, onUnauthorized }) {
  const [actividad, setActividad] = useState(null);
  const [inscripcionActiva, setInscripcionActiva] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState('');
  const [feedback, setFeedback] = useState(null); // { type: 'success' | 'danger', message: string }
  const [isEnrolling, setIsEnrolling] = useState(false);

  const loadDetail = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage('');

    try {
      const [actividadesRes, inscripcionesRes] = await Promise.all([
        apiClient.getActividades(onUnauthorized),
        apiClient.getInscripciones(onUnauthorized).catch(() => ({ inscripciones: [] })),
      ]);

      const actividades = actividadesRes?.actividades || [];
      const foundActividad = actividades.find((a) => a.id === actividadId);

      if (!foundActividad) {
        throw new Error('No se encontró la actividad solicitada.');
      }

      setActividad(foundActividad);

      const inscripciones = inscripcionesRes?.inscripciones || [];
      const foundInscripcion = inscripciones.find(
        (ins) => ins.actividad?.id === actividadId && ins.estado !== 'cancelada'
      );
      setInscripcionActiva(foundInscripcion || null);
    } catch (err) {
      console.error('Error al cargar detalle de actividad:', err);
      setErrorMessage(err.message || 'Error al cargar los datos de la actividad.');
    } finally {
      setIsLoading(false);
    }
  }, [actividadId, onUnauthorized]);

  useEffect(() => {
    loadDetail();
  }, [loadDetail]);

  const handleEnroll = async () => {
    setIsEnrolling(true);
    setFeedback(null);

    try {
      const res = await apiClient.createInscripcion(actividadId, onUnauthorized);
      const nuevaInscripcion = res?.inscripcion;

      setInscripcionActiva(nuevaInscripcion);
      setActividad((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          cupo_disponible: Math.max(0, prev.cupo_disponible - 1),
        };
      });

      setFeedback({
        type: 'success',
        message: '¡Inscripción registrada con éxito! Podés consultar o gestionar tu estado en Mis Inscripciones.',
      });
    } catch (err) {
      console.error('Error en inscripción:', err);
      let userMsg = 'No pudimos realizar la inscripción.';
      if (err.details && Array.isArray(err.details) && err.details.length > 0) {
        userMsg = err.details.join('. ');
      } else if (err.code === 'deportista_required') {
        userMsg = 'Tu usuario no cuenta con un perfil de deportista asociado. Contactá a la administración del club.';
      } else if (err.message) {
        userMsg = err.message;
      }

      setFeedback({
        type: 'danger',
        message: userMsg,
      });
    } finally {
      setIsEnrolling(false);
    }
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return '--/--/----';
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      return `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
    return dateStr;
  };

  const calculateQuotaPercentage = () => {
    if (!actividad || actividad.cupo <= 0) return 0;
    const ocupados = Math.max(0, actividad.cupo - actividad.cupo_disponible);
    return Math.min(100, Math.round((ocupados / actividad.cupo) * 100));
  };

  const quotaPercentage = calculateQuotaPercentage();

  return (
    <div className="club-container">
      <div>
        <button type="button" onClick={onBack} className="back-link">
          <span>←</span> Volver a Actividades
        </button>
      </div>

      {/* Indicador de Carga */}
      {isLoading && (
        <div className="loading-state">
          <div className="spinner"></div>
          <p>Cargando información de la actividad...</p>
        </div>
      )}

      {/* Alerta de Error de carga */}
      {errorMessage && (
        <div className="alert alert-danger" style={{ marginTop: '1.5rem' }}>
          <span>⚠️</span>
          <span>{errorMessage}</span>
        </div>
      )}

      {/* Alerta de Feedback de Inscripción (éxito o error) */}
      {feedback && (
        <div className={`alert alert-${feedback.type}`} style={{ marginTop: '1.5rem' }}>
          <span>{feedback.type === 'success' ? '✅' : '⚠️'}</span>
          <span>{feedback.message}</span>
        </div>
      )}

      {/* Tarjeta de Detalle */}
      {!isLoading && actividad && (
        <div className="detail-card">
          <div className="detail-header">
            <span className="sport-tag">{actividad.deporte?.nombre || 'Deporte'}</span>
            <h1 className="detail-title">{actividad.nombre}</h1>
          </div>

          {/* Banner de Estado (Ya inscripto / Cupo completo) */}
          {inscripcionActiva && (
            <div className="alert alert-info">
              <span>ℹ️</span>
              <span>
                Ya contás con una inscripción activa en esta actividad (Estado:{' '}
                {inscripcionActiva.estado === 'confirmada' ? 'Confirmada' : 'Pendiente'}).
              </span>
            </div>
          )}

          {!inscripcionActiva && actividad.cupo_disponible <= 0 && (
            <div className="alert alert-warning">
              <span>⚠️</span>
              <span>Esta actividad ha alcanzado el cupo máximo de participantes.</span>
            </div>
          )}

          {/* Grilla de Estadísticas */}
          <div className="detail-grid">
            <div>
              <div className="detail-stat-label">Fecha</div>
              <div className="detail-stat-value">{formatDate(actividad.fecha)}</div>
            </div>
            <div>
              <div className="detail-stat-label">Horario</div>
              <div className="detail-stat-value">{actividad.horario || '--:--'} hs</div>
            </div>
            <div>
              <div className="detail-stat-label">Cupo Total</div>
              <div className="detail-stat-value">{actividad.cupo}</div>
            </div>
            <div>
              <div className="detail-stat-label">Cupos Disponibles</div>
              <div className="detail-stat-value">{actividad.cupo_disponible}</div>
            </div>
          </div>

          {/* Barra de progreso de cupos */}
          <div className="quota-progress">
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                fontSize: '0.82rem',
                color: 'var(--text-muted)',
                marginBottom: '0.4rem',
              }}
            >
              <span>Ocupación de la actividad</span>
              <span>{quotaPercentage}%</span>
            </div>
            <div className="quota-bar-bg">
              <div
                className={`quota-fill ${
                  quotaPercentage >= 100 ? 'is-full' : quotaPercentage > 75 ? 'is-warning' : ''
                }`}
                style={{ width: `${quotaPercentage}%` }}
              ></div>
            </div>
          </div>

          {/* Acciones */}
          <div className="detail-actions">
            {inscripcionActiva ? (
              <>
                <button
                  type="button"
                  className="btn btn-primary btn-lg"
                  onClick={() => onNavigate('mis-inscripciones')}
                >
                  Ver mi inscripción
                </button>
                <button type="button" className="btn btn-outline btn-lg" onClick={onBack}>
                  Volver a actividades
                </button>
              </>
            ) : actividad.cupo_disponible <= 0 ? (
              <>
                <button type="button" className="btn btn-secondary btn-lg" disabled>
                  Cupo completo
                </button>
                <button type="button" className="btn btn-outline btn-lg" onClick={onBack}>
                  Volver a actividades
                </button>
              </>
            ) : (
              <>
                <button
                  type="button"
                  className="btn btn-primary btn-lg"
                  onClick={handleEnroll}
                  disabled={isEnrolling}
                >
                  {isEnrolling ? 'Procesando inscripción...' : 'Inscribirme a esta actividad'}
                </button>
                <button type="button" className="btn btn-outline btn-lg" onClick={onBack}>
                  Volver
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
