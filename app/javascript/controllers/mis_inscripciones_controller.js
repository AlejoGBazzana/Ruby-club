// app/javascript/controllers/mis_inscripciones_controller.js
import { Controller } from "@hotwired/stimulus";
import { apiClient } from "api_client";

export default class extends Controller {
  static targets = [
    "loading",
    "content",
    "error",
    "errorMessage",
    "feedbackAlert",
    "feedbackAlertText",
    "activasContainer",
    "canceladasContainer",
    "activasEmpty",
    "canceladasEmpty",
    "cancelModal",
    "cancelModalText",
    "confirmCancelBtn"
  ];

  connect() {
    this.cancellingInscripcionId = null;
    this.loadInscripciones();
  }

  async loadInscripciones() {
    this.showLoading(true);
    this.hideError();

    try {
      const res = await apiClient.getInscripciones();
      const inscripciones = res?.inscripciones || [];

      this.renderLists(inscripciones);
    } catch (err) {
      console.error("Error al cargar inscripciones:", err);
      this.showError(err.message || "No se pudieron obtener tus inscripciones.");
    } finally {
      this.showLoading(false);
    }
  }

  renderLists(inscripciones) {
    const activas = inscripciones.filter(i => i.estado === "pendiente" || i.estado === "confirmada");
    const canceladas = inscripciones.filter(i => i.estado === "cancelada");

    // Renderizar Activas
    if (this.hasActivasContainerTarget) {
      if (activas.length === 0) {
        this.activasContainerTarget.innerHTML = "";
        if (this.hasActivasEmptyTarget) this.activasEmptyTarget.style.display = "block";
      } else {
        if (this.hasActivasEmptyTarget) this.activasEmptyTarget.style.display = "none";
        this.activasContainerTarget.innerHTML = activas.map(ins => this.buildActivaCard(ins)).join("");
      }
    }

    // Renderizar Canceladas
    if (this.hasCanceladasContainerTarget) {
      if (canceladas.length === 0) {
        this.canceladasContainerTarget.innerHTML = "";
        if (this.hasCanceladasEmptyTarget) this.canceladasEmptyTarget.style.display = "block";
      } else {
        if (this.hasCanceladasEmptyTarget) this.canceladasEmptyTarget.style.display = "none";
        this.canceladasContainerTarget.innerHTML = canceladas.map(ins => this.buildCanceladaCard(ins)).join("");
      }
    }
  }

  buildActivaCard(inscripcion) {
    const act = inscripcion.actividad || {};
    const deporte = act.deporte?.nombre || "Deporte";
    const fecha = this.formatDate(act.fecha);
    const horario = act.horario || "--:--";
    const esConfirmada = inscripcion.estado === "confirmada";

    const badgeClass = esConfirmada ? "badge-enrolled" : "badge-pending";
    const badgeText = esConfirmada ? "Confirmada" : "Pendiente";

    return `
      <article class="inscription-card" id="inscripcion-${inscripcion.id}">
        <div class="inscription-header">
          <div class="inscription-sport">
            <span class="sport-tag">${deporte}</span>
            <span class="badge ${badgeClass}">
              <span class="badge-dot"></span> ${badgeText}
            </span>
          </div>
          <button type="button"
                  class="btn btn-danger-outline btn-sm"
                  data-action="click->mis-inscripciones#promptCancel"
                  data-id="${inscripcion.id}"
                  data-nombre="${this.escapeHtml(act.nombre || '')}">
            Cancelar inscripción
          </button>
        </div>

        <h4 class="inscription-title">${this.escapeHtml(act.nombre || 'Actividad')}</h4>

        <div class="activity-metadata">
          <div class="metadata-item">
            <span class="metadata-icon">📅</span>
            <span>${fecha}</span>
          </div>
          <div class="metadata-item">
            <span class="metadata-icon">🕒</span>
            <span>${horario} hs</span>
          </div>
          <div class="metadata-item">
            <span class="metadata-icon">📝</span>
            <span>Inscripción: ${this.formatDate(inscripcion.fecha_inscripcion)}</span>
          </div>
        </div>
      </article>
    `;
  }

  buildCanceladaCard(inscripcion) {
    const act = inscripcion.actividad || {};
    const deporte = act.deporte?.nombre || "Deporte";
    const fecha = this.formatDate(act.fecha);
    const horario = act.horario || "--:--";

    return `
      <article class="inscription-card is-canceled" id="inscripcion-${inscripcion.id}">
        <div class="inscription-header">
          <div class="inscription-sport">
            <span class="sport-tag">${deporte}</span>
            <span class="badge badge-canceled">
              <span class="badge-dot"></span> Cancelada
            </span>
          </div>
          ${act.id ? `
            <button type="button"
                    class="btn btn-primary btn-sm"
                    data-action="click->mis-inscripciones#reinscribe"
                    data-actividad-id="${act.id}"
                    data-nombre="${this.escapeHtml(act.nombre || '')}">
              Volver a inscribirme
            </button>
          ` : ''}
        </div>

        <h4 class="inscription-title">${this.escapeHtml(act.nombre || 'Actividad')}</h4>

        <div class="activity-metadata">
          <div class="metadata-item">
            <span class="metadata-icon">📅</span>
            <span>${fecha}</span>
          </div>
          <div class="metadata-item">
            <span class="metadata-icon">🕒</span>
            <span>${horario} hs</span>
          </div>
        </div>
      </article>
    `;
  }

  // Confirmar cancelación modal
  promptCancel(event) {
    const btn = event.currentTarget;
    this.cancellingInscripcionId = btn.dataset.id;
    const nombre = btn.dataset.nombre;

    if (this.hasCancelModalTextTarget) {
      this.cancelModalTextTarget.textContent = `¿Estás seguro de cancelar tu inscripción a "${nombre}"? Se liberará tu cupo para otro deportista.`;
    }

    if (this.hasCancelModalTarget) {
      this.cancelModalTarget.style.display = "flex";
    }
  }

  closeCancelModal() {
    this.cancellingInscripcionId = null;
    if (this.hasCancelModalTarget) {
      this.cancelModalTarget.style.display = "none";
    }
  }

  async confirmCancel() {
    if (!this.cancellingInscripcionId) return;

    if (this.hasConfirmCancelBtnTarget) {
      this.confirmCancelBtnTarget.disabled = true;
      this.confirmCancelBtnTarget.textContent = "Cancelando...";
    }

    try {
      await apiClient.cancelInscripcion(this.cancellingInscripcionId);
      this.closeCancelModal();
      this.showFeedback("Tu inscripción fue cancelada correctamente. El cupo ha sido liberado.", "success");
      await this.loadInscripciones();
    } catch (err) {
      console.error("Error al cancelar:", err);
      this.closeCancelModal();
      this.showFeedback(err.message || "No se pudo cancelar la inscripción.", "danger");
    } finally {
      if (this.hasConfirmCancelBtnTarget) {
        this.confirmCancelBtnTarget.disabled = false;
        this.confirmCancelBtnTarget.textContent = "Sí, cancelar";
      }
    }
  }

  // Reinscribirse después de cancelar
  async reinscribe(event) {
    const btn = event.currentTarget;
    const actividadId = btn.dataset.actividadId;
    const nombre = btn.dataset.nombre;

    btn.disabled = true;
    btn.textContent = "Inscribiendo...";

    try {
      await apiClient.createInscripcion(actividadId);
      this.showFeedback(`¡Reinscripción confirmada para "${nombre}"! Tu inscripción vuelve a estar activa.`, "success");
      await this.loadInscripciones();
    } catch (err) {
      console.error("Error en reinscripción:", err);
      btn.disabled = false;
      btn.textContent = "Volver a inscribirme";

      let msg = "No pudimos completar la reinscripción.";
      if (err.details && Array.isArray(err.details) && err.details.length > 0) {
        msg = err.details.join(". ");
      } else if (err.message) {
        msg = err.message;
      }
      this.showFeedback(msg, "danger");
    }
  }

  showFeedback(message, type = "info") {
    if (this.hasFeedbackAlertTarget && this.hasFeedbackAlertTextTarget) {
      this.feedbackAlertTextTarget.textContent = message;
      this.feedbackAlertTarget.className = `alert alert-${type}`;
      this.feedbackAlertTarget.style.display = "flex";
      this.feedbackAlertTarget.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }

  hideFeedback() {
    if (this.hasFeedbackAlertTarget) {
      this.feedbackAlertTarget.style.display = "none";
    }
  }

  formatDate(dateStr) {
    if (!dateStr) return "--/--/----";
    const parts = dateStr.split("-");
    if (parts.length === 3) {
      return `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
    return dateStr;
  }

  escapeHtml(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  }

  showLoading(isLoading) {
    if (this.hasLoadingTarget) this.loadingTarget.style.display = isLoading ? "flex" : "none";
    if (this.hasContentTarget) this.contentTarget.style.display = isLoading ? "none" : "block";
  }

  showError(message) {
    if (this.hasErrorTarget && this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message;
      this.errorTarget.style.display = "flex";
    }
  }

  hideError() {
    if (this.hasErrorTarget) this.errorTarget.style.display = "none";
  }
}
