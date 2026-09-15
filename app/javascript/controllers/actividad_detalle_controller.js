// app/javascript/controllers/actividad_detalle_controller.js
import { Controller } from "@hotwired/stimulus";
import { apiClient } from "api_client";

export default class extends Controller {
  static values = {
    id: Number
  };

  static targets = [
    "loading",
    "content",
    "error",
    "errorMessage",
    "sportTag",
    "title",
    "fecha",
    "horario",
    "cupoTotal",
    "cupoDisponible",
    "quotaBar",
    "statusBanner",
    "statusBannerText",
    "actionsContainer",
    "feedbackAlert",
    "feedbackAlertText"
  ];

  connect() {
    this.actividad = null;
    this.inscripcionActiva = null;
    this.loadDetail();
  }

  async loadDetail() {
    this.showLoading(true);
    this.hideError();

    try {
      // Obtener actividades e inscripciones del usuario
      const [actividadesRes, inscripcionesRes] = await Promise.all([
        apiClient.getActividades(),
        apiClient.getInscripciones().catch(() => ({ inscripciones: [] }))
      ]);

      const actividades = actividadesRes?.actividades || [];
      this.actividad = actividades.find(a => a.id === this.idValue);

      if (!this.actividad) {
        throw new Error("No se encontró la actividad solicitada.");
      }

      // Buscar si el usuario ya tiene inscripción activa para esta actividad
      const inscripciones = inscripcionesRes?.inscripciones || [];
      this.inscripcionActiva = inscripciones.find(
        ins => ins.actividad?.id === this.idValue && ins.estado !== "cancelada"
      );

      this.renderData();
    } catch (err) {
      console.error("Error al cargar detalle de actividad:", err);
      this.showError(err.message || "Error al cargar los datos de la actividad.");
    } finally {
      this.showLoading(false);
    }
  }

  renderData() {
    if (!this.actividad) return;

    if (this.hasSportTagTarget) this.sportTagTarget.textContent = this.actividad.deporte?.nombre || "Deporte";
    if (this.hasTitleTarget) this.titleTarget.textContent = this.actividad.nombre;
    if (this.hasFechaTarget) this.fechaTarget.textContent = this.formatDate(this.actividad.fecha);
    if (this.hasHorarioTarget) this.horarioTarget.textContent = `${this.actividad.horario || "--:--"} hs`;
    if (this.hasCupoTotalTarget) this.cupoTotalTarget.textContent = this.actividad.cupo;
    if (this.hasCupoDisponibleTarget) this.cupoDisponibleTarget.textContent = this.actividad.cupo_disponible;

    // Barra de progreso de cupos
    if (this.hasQuotaBarTarget) {
      const ocupados = Math.max(0, this.actividad.cupo - this.actividad.cupo_disponible);
      const porcentaje = Math.min(100, Math.round((ocupados / this.actividad.cupo) * 100));
      this.quotaBarTarget.style.width = `${porcentaje}%`;
      this.quotaBarTarget.className = `quota-fill ${porcentaje >= 100 ? 'is-full' : (porcentaje > 75 ? 'is-warning' : '')}`;
    }

    this.renderActionArea();
  }

  renderActionArea() {
    if (!this.hasActionsContainerTarget) return;

    // Caso 1: Usuario ya está inscripto activamente
    if (this.inscripcionActiva) {
      const estado = this.inscripcionActiva.estado === "confirmada" ? "Confirmada" : "Pendiente";
      if (this.hasStatusBannerTarget) {
        this.statusBannerTextTarget.textContent = `Ya contás con una inscripción activa en esta actividad (Estado: ${estado}).`;
        this.statusBannerTarget.className = "alert alert-info";
        this.statusBannerTarget.style.display = "flex";
      }

      this.actionsContainerTarget.innerHTML = `
        <a href="/mis-inscripciones" class="btn btn-primary btn-lg">
          Ver mi inscripción
        </a>
        <a href="/actividades" class="btn btn-outline btn-lg">
          Volver a actividades
        </a>
      `;
      return;
    }

    // Caso 2: Actividad sin cupo
    if (this.actividad.cupo_disponible <= 0) {
      if (this.hasStatusBannerTarget) {
        this.statusBannerTextTarget.textContent = "Esta actividad ha alcanzado el cupo máximo de participantes.";
        this.statusBannerTarget.className = "alert alert-warning";
        this.statusBannerTarget.style.display = "flex";
      }

      this.actionsContainerTarget.innerHTML = `
        <button type="button" class="btn btn-secondary btn-lg" disabled>
          Cupo completo
        </button>
        <a href="/actividades" class="btn btn-outline btn-lg">
          Volver a actividades
        </a>
      `;
      return;
    }

    // Caso 3: Disponible para inscribirse
    if (this.hasStatusBannerTarget) {
      this.statusBannerTarget.style.display = "none";
    }

    this.actionsContainerTarget.innerHTML = `
      <button type="button"
              class="btn btn-primary btn-lg"
              data-action="click->actividad-detalle#enroll"
              id="enroll-btn">
        Inscribirme a esta actividad
      </button>
      <a href="/actividades" class="btn btn-outline btn-lg">
        Volver
      </a>
    `;
  }

  async enroll(event) {
    if (event) event.preventDefault();

    const enrollBtn = document.getElementById("enroll-btn");
    if (enrollBtn) {
      enrollBtn.disabled = true;
      enrollBtn.textContent = "Procesando inscripción...";
    }

    this.hideFeedback();

    try {
      const res = await apiClient.createInscripcion(this.idValue);
      const nuevaInscripcion = res?.inscripcion;

      // Éxito: actualizar estado local
      this.inscripcionActiva = nuevaInscripcion;
      if (this.actividad.cupo_disponible > 0) {
        this.actividad.cupo_disponible -= 1;
      }
      this.renderData();

      this.showFeedback(
        "¡Inscripción registrada con éxito! Podés consultar o gestionar tu estado en Mis Inscripciones.",
        "success"
      );
    } catch (err) {
      console.error("Error en inscripción:", err);

      if (enrollBtn) {
        enrollBtn.disabled = false;
        enrollBtn.textContent = "Inscribirme a esta actividad";
      }

      let userMsg = "No pudimos realizar la inscripción.";
      if (err.details && Array.isArray(err.details) && err.details.length > 0) {
        userMsg = err.details.join(". ");
      } else if (err.code === "deportista_required") {
        userMsg = "Tu usuario no cuenta con un perfil de deportista asociado. Contactá a la administración del club.";
      } else if (err.message) {
        userMsg = err.message;
      }

      this.showFeedback(userMsg, "danger");
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
