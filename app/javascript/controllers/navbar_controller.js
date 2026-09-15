// app/javascript/controllers/navbar_controller.js
import { Controller } from "@hotwired/stimulus";
import { apiClient } from "api_client";

export default class extends Controller {
  static targets = [
    "authLinks",
    "guestLinks",
    "userBadge",
    "userName",
    "logoutBtn",
    "navLink"
  ];

  connect() {
    this.updateState();
  }

  updateState() {
    const isAuth = apiClient.isAuthenticated();

    if (isAuth) {
      if (this.hasAuthLinksTarget) this.authLinksTarget.style.display = "flex";
      if (this.hasGuestLinksTarget) this.guestLinksTarget.style.display = "none";
      if (this.hasLogoutBtnTarget) this.logoutBtnTarget.style.display = "inline-flex";

      this.highlightActiveLink();
      this.loadUserInfo();
    } else {
      if (this.hasAuthLinksTarget) this.authLinksTarget.style.display = "none";
      if (this.hasGuestLinksTarget) this.guestLinksTarget.style.display = "flex";
      if (this.hasLogoutBtnTarget) this.logoutBtnTarget.style.display = "none";
      if (this.hasUserBadgeTarget) this.userBadgeTarget.style.display = "none";
    }
  }

  highlightActiveLink() {
    if (!this.hasNavLinkTargets) return;
    const currentPath = window.location.pathname;

    this.navLinkTargets.forEach(link => {
      const href = link.getAttribute("href");
      if (href === currentPath || (href !== "/" && currentPath.startsWith(href))) {
        link.classList.add("active");
      } else {
        link.classList.remove("active");
      }
    });
  }

  async loadUserInfo() {
    // Primero intentar con el user en cache
    const cachedUser = apiClient.getUser();
    if (cachedUser && this.hasUserNameTarget) {
      this.userNameTarget.textContent = cachedUser.email;
      if (this.hasUserBadgeTarget) this.userBadgeTarget.style.display = "inline-flex";
    }

    try {
      const data = await apiClient.getMe();
      if (!data) return;

      const nombre = data.socio ? `${data.socio.nombre} ${data.socio.apellido}` : (data.user?.email || "Socio");
      if (this.hasUserNameTarget) {
        this.userNameTarget.textContent = nombre;
      }
      if (this.hasUserBadgeTarget) {
        this.userBadgeTarget.style.display = "inline-flex";
      }
    } catch (e) {
      console.warn("No se pudo cargar la información del usuario en navbar:", e);
    }
  }

  async logout(event) {
    if (event) event.preventDefault();

    if (this.hasLogoutBtnTarget) {
      this.logoutBtnTarget.disabled = true;
      this.logoutBtnTarget.textContent = "Saliendo...";
    }

    await apiClient.logout();
  }
}
