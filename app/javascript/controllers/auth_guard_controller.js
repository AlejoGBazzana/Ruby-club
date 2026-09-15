// app/javascript/controllers/auth_guard_controller.js
import { Controller } from "@hotwired/stimulus";
import { apiClient } from "api_client";

export default class extends Controller {
  static values = {
    redirectIfLoggedIn: { type: Boolean, default: false }
  };

  connect() {
    const isAuth = apiClient.isAuthenticated();

    if (this.redirectIfLoggedInValue) {
      if (isAuth) {
        window.location.href = "/actividades";
      }
    } else {
      if (!isAuth) {
        window.location.href = "/login";
      }
    }
  }
}
