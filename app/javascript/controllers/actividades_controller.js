// app/javascript/controllers/actividades_controller.js
import { Controller } from "@hotwired/stimulus";
import { apiClient } from "api_client";

export default class extends Controller {
  static targets = [
    "grid",
    "loading",
    "empty",
    "error",
    "errorMessage",
    "filterContainer",
    "totalCount"
  ];

  connect() {
    this.actividades = [];
    this.userInscriptionsByActividadId = new Map();
    this.selectedSport = "todos";
    this.loadData();
  }

  async loadData() {
    this.showLoading(true);
    this.hideError();

    try {
      // Cargar actividades e inscripciones en paralelo
      const [actividadesRes, inscripcionesRes] = await Promise.all([
        apiClient.getActividades(),
        apiClient.getInscripciones().catch(err => {
          console.warn("No se pudieron cargar inscripciones previas:", err);
          return { inscripciones: [] };
        })
      ]);

      this.actividades = actividadesRes?.actividades || [];

      // Mapear inscripciones activas por ID de actividad
      this.userInscriptionsByActividadId.clear();
      const inscripciones = inscripcionesRes?.inscripciones || [];
      inscripciones.forEach(ins => {
        if (ins.estado !== "cancelada" && ins.actividad?.id) {
          this.userInscriptionsByActividadId.set(ins.actividad.id, ins);
        }
      });

      this.renderFilters();
      this.renderCards();
    } catch (err) {
      console.error("Error al cargar actividades:", err);
      this.showError(err.message || "No se pudieron cargar las actividades.");
    } finally {
      this.showLoading(false);
    }
  }

  renderFilters() {
    if (!this.hasFilterContainerTarget) return;

    // Obtener lista única de deportes
    const deportes = Array.from(
      new Set(this.actividades.map(a => a.deporte?.nombre).filter(Boolean))
    ).sort();

    let html = `
      <button type="button"
              class="filter-pill ${this.selectedSport === 'todos' ? 'active' : ''}"
              data-action="click->actividades#filterBySport"
              data-sport="todos">
        Todos (${this.actividades.length})
      </button>
    `;

    deportes.forEach(deporte => {
      const count = this.actividades.filter(a => a.deporte?.nombre === deporte).length;
      const isActive = this.selectedSport === deporte ? "active" : "";
      html += `
        <button type="button"
                class="filter-pill ${isActive}"
                data-action="click->actividades#filterBySport"
                data-sport="${deporte}">
          ${deporte} (${count})
        </button>
      `;
    });

    this.filterContainerTarget.innerHTML = html;
  }

  filterBySport(event) {
    const sport = event.currentTarget.dataset.sport;
    this.selectedSport = sport;

    // Actualizar clase activa en pills
    const pills = this.filterContainerTarget.querySelectorAll(".filter-pill");
    pills.forEach(p => p.classList.toggle("active", p.dataset.sport === sport));

    this.renderCards();
  }

  renderCards() {
    if (!this.hasGridTarget) return;

    const filtered = this.selectedSport === "todos"
      ? this.actividades
      : this.actividades.filter(a => a.deporte?.nombre === this.selectedSport);

    if (this.hasTotalCountTarget) {
      this.totalCountTarget.textContent = `${filtered.length} actividad${filtered.length === 1 ? '' : 'es'}`;
    }

    if (filtered.length === 0) {
      this.gridTarget.innerHTML = "";
      if (this.hasEmptyTarget) this.emptyTarget.style.display = "block";
      return;
    }

    if (this.hasEmptyTarget) this.emptyTarget.style.display = "none";

    const cardsHtml = filtered.map(actividad => this.buildCardHtml(actividad)).join("");
    this.gridTarget.innerHTML = cardsHtml;
  }

  buildCardHtml(actividad) {
    const yaInscripto = this.userInscriptionsByActividadId.has(actividad.id);
    const inscripcionActiva = yaInscripto ? this.userInscriptionsByActividadId.get(actividad.id) : null;
    const sinCupo = actividad.cupo_disponible <= 0;

    const fechaFormateada = this.formatDate(actividad.fecha);
    const horario = actividad.horario || "--:--";

    // Badges de estado
    let badgeHtml = "";
    let actionBtnHtml = "";

    if (yaInscripto) {
      const estadoLabel = inscripcionActiva?.estado === "confirmada" ? "Confirmada" : "Pendiente";
      badgeHtml = `
        <span class="badge badge-enrolled">
          <span class="badge-dot"></span> Inscripto (${estadoLabel})
        </span>
      `;
      actionBtnHtml = `
        <a href="/mis-inscripciones" class="btn btn-outline btn-sm">
          Ver mi inscripción
        </a>
      `;
    } else if (sinCupo) {
      badgeHtml = `
        <span class="badge badge-full">
          <span class="badge-dot"></span> Cupo completo
        </span>
      `;
      actionBtnHtml = `
        <a href="/actividades/${actividad.id}" class="btn btn-secondary btn-sm">
          Ver detalle
        </a>
      `;
    } else {
      badgeHtml = `
        <span class="badge badge-available">
          <span class="badge-dot"></span> ${actividad.cupo_disponible} cupo${actividad.cupo_disponible === 1 ? '' : 's'} disponible${actividad.cupo_disponible === 1 ? '' : 's'}
        </span>
      `;
      actionBtnHtml = `
        <a href="/actividades/${actividad.id}" class="btn btn-primary btn-sm">
          Ver actividad
        </a>
      `;
    }

    return `
      <article class="activity-card ${yaInscripto ? 'is-enrolled' : ''} ${sinCupo && !yaInscripto ? 'is-full' : ''}">
        <div class="activity-card-header">
          <span class="sport-tag">${actividad.deporte?.nombre || "Deporte"}</span>
          ${badgeHtml}
        </div>

        <h3 class="activity-title">${actividad.nombre}</h3>

        <div class="activity-metadata">
          <div class="metadata-item">
            <span class="metadata-icon">📅</span>
            <span>${fechaFormateada}</span>
          </div>
          <div class="metadata-item">
            <span class="metadata-icon">🕒</span>
            <span>${horario} hs</span>
          </div>
          <div class="metadata-item">
            <span class="metadata-icon">👥</span>
            <span>Cupo total: ${actividad.cupo}</span>
          </div>
        </div>

        <div class="activity-card-footer">
          ${actionBtnHtml}
        </div>
      </article>
    `;
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
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = isLoading ? "flex" : "none";
    }
    if (this.hasGridTarget && isLoading) {
      this.gridTarget.innerHTML = "";
    }
  }

  showError(message) {
    if (this.hasErrorTarget && this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message;
      this.errorTarget.style.display = "flex";
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.style.display = "none";
    }
  }

  retry() {
    this.loadData();
  }
}
