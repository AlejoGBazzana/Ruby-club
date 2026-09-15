// app/javascript/controllers/login_controller.js
import { Controller } from "@hotwired/stimulus";
import { apiClient } from "api_client";

export default class extends Controller {
  static targets = [
    "email",
    "password",
    "submitBtn",
    "errorContainer",
    "errorMessage",
    "noticeContainer",
    "noticeMessage"
  ];

  connect() {
    // Si ya está autenticado, redirigir directo a actividades
    if (apiClient.isAuthenticated()) {
      window.location.href = "/actividades";
      return;
    }

    // Verificar si vino por sesión expirada
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get("expired") === "1" && this.hasNoticeContainerTarget) {
      this.noticeMessageTarget.textContent = "Tu sesión ha expirado. Por favor, volvé a iniciar sesión.";
      this.noticeContainerTarget.style.display = "flex";
    }
  }

  async submit(event) {
    event.preventDefault();

    this.hideError();
    if (this.hasNoticeContainerTarget) {
      this.noticeContainerTarget.style.display = "none";
    }

    const email = this.emailTarget.value.trim();
    const password = this.passwordTarget.value;

    if (!email || !password) {
      this.showError("Por favor, completá tu email y contraseña.");
      return;
    }

    this.setLoading(true);

    try {
      await apiClient.login(email, password);
      // Login exitoso -> redirigir a actividades
      window.location.href = "/actividades";
    } catch (err) {
      this.setLoading(false);
      if (err.code === "invalid_credentials" || err.status === 401) {
        this.showError("Email o contraseña inválidos. Verificá tus datos.");
      } else if (err.network) {
        this.showError("No se pudo conectar con el servidor. Comprobá que la aplicación esté activa.");
      } else {
        this.showError(err.message || "Ocurrió un error al intentar iniciar sesión.");
      }
    }
  }

  showError(message) {
    if (this.hasErrorMessageTarget && this.hasErrorContainerTarget) {
      this.errorMessageTarget.textContent = message;
      this.errorContainerTarget.style.display = "flex";
    }
  }

  hideError() {
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.style.display = "none";
    }
  }

  setLoading(isLoading) {
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = isLoading;
      this.submitBtnTarget.textContent = isLoading ? "Ingresando..." : "Ingresar";
    }
  }
}
