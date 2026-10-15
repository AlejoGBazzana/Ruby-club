import { useState, useEffect, useCallback } from 'react';
import { apiClient } from '../api/client';

export default function MisInscripciones({ onNavigate, onUnauthorized }) {
  const [inscripciones, setInscripciones] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState('');
  const [feedback, setFeedback] = useState(null); // { type: 'success' | 'danger', message: string }

  // Modal de cancelación
  const [cancelModalData, setCancelModalData] = useState(null); // { id: number, nombre: string } | null
  const [isCancelling, setIsCancelling] = useState(false);
  const [reinsribingId, setReinscribingId] = useState(null);

  const loadInscripciones = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage('');

    try {
      const res = await apiClient.getInscripciones(onUnauthorized);
      setInscripciones(res?.inscripciones || []);
    } catch (err) {
      console.error('Error al cargar inscripciones:', err);
      setErrorMessage(err.message || 'No se pudieron obtener tus inscripciones.');
    } finally {
      setIsLoading(false);
    }
  }, [onUnauthorized]);

  useEffect(() => {
    const timeoutId = window.setTimeout(() => {
      void loadInscripciones();
    }, 0);

    return () => window.clearTimeout(timeoutId);
  }, [loadInscripciones]);

  const activas = inscripciones.filter(
    (i) => i.estado === 'pendiente' || i.estado === 'confirmada'
  );
  const canceladas = inscripciones.filter((i) => i.estado === 'cancelada');

  const handlePromptCancel = (inscripcion) => {
    setCancelModalData({
      id: inscripcion.id,
      nombre: inscripcion.actividad?.nombre || 'esta actividad',
    });
  };

  const handleCloseCancelModal = () => {
    if (isCancelling) return;
    setCancelModalData(null);
  };

  const handleConfirmCancel = async () => {
    if (!cancelModalData) return;

    setIsCancelling(true);
    try {
      await apiClient.cancelInscripcion(cancelModalData.id, onUnauthorized);
      setCancelModalData(null);
      setFeedback({
        type: 'success',
        message: 'Tu inscripción fue cancelada correctamente. El cupo ha sido liberado.',
      });
      await loadInscripciones();
    } catch (err) {
      console.error('Error al cancelar inscripción:', err);
      setCancelModalData(null);
      setFeedback({
        type: 'danger',
        message: err.message || 'No se pudo cancelar la inscripción.',
      });
    } finally {
      setIsCancelling(false);
    }
  };

  const handleReinscribe = async (actividadId, nombre) => {
    setReinscribingId(actividadId);
    setFeedback(null);

    try {
      await apiClient.createInscripcion(actividadId, onUnauthorized);
      setFeedback({
        type: 'success',
        message: `¡Reinscripción confirmada para "${nombre}"! Tu inscripción vuelve a estar activa.`,
      });
      await loadInscripciones();
    } catch (err) {
      console.error('Error en reinscripción:', err);
      let msg = 'No pudimos completar la reinscripción.';
      if (err.details && Array.isArray(err.details) && err.details.length > 0) {
        msg = err.details.join('. ');
      } else if (err.message) {
        msg = err.message;
      }
      setFeedback({
        type: 'danger',
        message: msg,
      });
    } finally {
      setReinscribingId(null);
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

  return (
    <div className="club-container">
      <div className="page-header">
        <h1 className="page-title">Mis Inscripciones</h1>
        <p className="page-subtitle">
          Gestioná tus inscripciones a las actividades del club. Podés cancelar en caso de no poder
          asistir o volver a inscribirte.
        </p>
      </div>

      {/* Alerta de Feedback (éxito de cancelación o reinscripción) */}
      {feedback && (
        <div className={`alert alert-${feedback.type}`}>
          <span>{feedback.type === 'success' ? '✅' : '⚠️'}</span>
          <span>{feedback.message}</span>
        </div>
      )}

      {/* Alerta de Error de carga */}
      {errorMessage && (
        <div className="alert alert-danger">
          <span>⚠️</span>
          <span>{errorMessage}</span>
        </div>
      )}

      {/* Indicador de Carga */}
      {isLoading && (
        <div className="loading-state">
          <div className="spinner"></div>
          <p>Cargando tus inscripciones...</p>
        </div>
      )}

      {/* Contenido principal */}
      {!isLoading && !errorMessage && (
        <div>
          {/* Sección de Inscripciones Activas */}
          <section className="inscriptions-section">
            <h2 className="section-heading">
              <span>🟢</span> Inscripciones Activas
            </h2>

            {activas.length > 0 ? (
              <div className="inscriptions-list">
                {activas.map((ins) => {
                  const act = ins.actividad || {};
                  const deporte = act.deporte?.nombre || 'Deporte';
                  const fecha = formatDate(act.fecha);
                  const horario = act.horario || '--:--';
                  const esConfirmada = ins.estado === 'confirmada';

                  return (
                    <article key={ins.id} className="inscription-card" id={`inscripcion-${ins.id}`}>
                      <div className="inscription-header">
                        <div className="inscription-sport">
                          <span className="sport-tag">{deporte}</span>
                          <span className={`badge ${esConfirmada ? 'badge-enrolled' : 'badge-pending'}`}>
                            <span className="badge-dot"></span>{' '}
                            {esConfirmada ? 'Confirmada' : 'Pendiente'}
                          </span>
                        </div>
                        <button
                          type="button"
                          className="btn btn-danger-outline btn-sm"
                          onClick={() => handlePromptCancel(ins)}
                          disabled={isCancelling}
                        >
                          Cancelar inscripción
                        </button>
                      </div>

                      <h4 className="inscription-title">{act.nombre || 'Actividad'}</h4>

                      <div className="activity-metadata">
                        <div className="metadata-item">
                          <span className="metadata-icon">📅</span>
                          <span>{fecha}</span>
                        </div>
                        <div className="metadata-item">
                          <span className="metadata-icon">🕒</span>
                          <span>{horario} hs</span>
                        </div>
                        <div className="metadata-item">
                          <span className="metadata-icon">📝</span>
                          <span>Inscripción: {formatDate(ins.fecha_inscripcion)}</span>
                        </div>
                      </div>
                    </article>
                  );
                })}
              </div>
            ) : (
              <div className="empty-state">
                <span className="empty-state-icon">📋</span>
                <h3 className="empty-state-title">No tenés inscripciones activas</h3>
                <p className="empty-state-text">Actualmente no estás inscripto en ninguna actividad.</p>
                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={() => onNavigate('actividades')}
                >
                  Ver actividades disponibles
                </button>
              </div>
            )}
          </section>

          {/* Sección de Inscripciones Canceladas */}
          <section className="inscriptions-section">
            <h2 className="section-heading">
              <span>⚪</span> Historial de Inscripciones Canceladas
            </h2>

            {canceladas.length > 0 ? (
              <div className="inscriptions-list">
                {canceladas.map((ins) => {
                  const act = ins.actividad || {};
                  const deporte = act.deporte?.nombre || 'Deporte';
                  const fecha = formatDate(act.fecha);
                  const horario = act.horario || '--:--';
                  const isReinscribing = reinsribingId === act.id;

                  return (
                    <article
                      key={ins.id}
                      className="inscription-card is-canceled"
                      id={`inscripcion-${ins.id}`}
                    >
                      <div className="inscription-header">
                        <div className="inscription-sport">
                          <span className="sport-tag">{deporte}</span>
                          <span className="badge badge-canceled">
                            <span className="badge-dot"></span> Cancelada
                          </span>
                        </div>
                        {act.id && (
                          <button
                            type="button"
                            className="btn btn-primary btn-sm"
                            onClick={() => handleReinscribe(act.id, act.nombre)}
                            disabled={isReinscribing}
                          >
                            {isReinscribing ? 'Inscribiendo...' : 'Volver a inscribirme'}
                          </button>
                        )}
                      </div>

                      <h4 className="inscription-title">{act.nombre || 'Actividad'}</h4>

                      <div className="activity-metadata">
                        <div className="metadata-item">
                          <span className="metadata-icon">📅</span>
                          <span>{fecha}</span>
                        </div>
                        <div className="metadata-item">
                          <span className="metadata-icon">🕒</span>
                          <span>{horario} hs</span>
                        </div>
                      </div>
                    </article>
                  );
                })}
              </div>
            ) : (
              <div className="empty-state">
                <span className="empty-state-icon">👌</span>
                <h3 className="empty-state-title">No hay inscripciones canceladas</h3>
                <p className="empty-state-text">No has cancelado ninguna inscripción.</p>
              </div>
            )}
          </section>
        </div>
      )}

      {/* Modal de confirmación para Cancelar Inscripción */}
      {cancelModalData && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <h3 className="modal-title">¿Cancelar inscripción?</h3>
            <p className="modal-text">
              ¿Estás seguro de cancelar tu inscripción a &quot;{cancelModalData.nombre}&quot;? Se liberará tu
              cupo para otro deportista.
            </p>
            <div className="modal-actions">
              <button
                type="button"
                className="btn btn-outline"
                onClick={handleCloseCancelModal}
                disabled={isCancelling}
              >
                Volver
              </button>
              <button
                type="button"
                className="btn btn-danger"
                onClick={handleConfirmCancel}
                disabled={isCancelling}
              >
                {isCancelling ? 'Cancelando...' : 'Sí, cancelar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
