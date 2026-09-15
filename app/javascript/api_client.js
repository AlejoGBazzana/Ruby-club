// app/javascript/api_client.js
// Cliente HTTP centralizado para consumir la API REST /api/v1 de Ruby Club

const TOKEN_KEY = "ruby_club_token";
const USER_KEY = "ruby_club_user";

export const apiClient = {
  getToken() {
    return sessionStorage.getItem(TOKEN_KEY);
  },

  setToken(token) {
    if (token) {
      sessionStorage.setItem(TOKEN_KEY, token);
    } else {
      sessionStorage.removeItem(TOKEN_KEY);
    }
  },

  getUser() {
    try {
      const raw = sessionStorage.getItem(USER_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  },

  setUser(user) {
    if (user) {
      sessionStorage.setItem(USER_KEY, JSON.stringify(user));
    } else {
      sessionStorage.removeItem(USER_KEY);
    }
  },

  clearSession() {
    sessionStorage.removeItem(TOKEN_KEY);
    sessionStorage.removeItem(USER_KEY);
  },

  isAuthenticated() {
    return !!this.getToken();
  },

  async request(endpoint, options = {}) {
    const cleanEndpoint = endpoint.startsWith("/") ? endpoint : `/${endpoint}`;
    const url = `/api/v1${cleanEndpoint}`;

    const headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      ...(options.headers || {})
    };

    const token = this.getToken();
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }

    let response;
    try {
      response = await fetch(url, {
        ...options,
        headers
      });
    } catch (networkError) {
      console.error(`[API Network Error] ${options.method || "GET"} ${url}:`, networkError);
      const err = new Error("No se pudo conectar con el servidor. Comprobá tu conexión.");
      err.network = true;
      throw err;
    }

    // 401 Unauthorized: token inválido, expirado o ausente
    if (response.status === 401) {
      this.clearSession();
      if (!window.location.pathname.startsWith("/login")) {
        window.location.href = "/login?expired=1";
      }
      const data = await response.json().catch(() => ({}));
      const msg = data.error?.message || "Sesión expirada o no autorizada.";
      const err = new Error(msg);
      err.status = 401;
      err.code = data.error?.code || "unauthorized";
      throw err;
    }

    // 204 No Content (logout, destroy exitoso)
    if (response.status === 204) {
      return null;
    }

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const err = new Error(data.error?.message || `Error del servidor (${response.status})`);
      err.status = response.status;
      err.code = data.error?.code;
      err.details = data.error?.details;
      throw err;
    }

    return data;
  },

  // Iniciar sesión
  async login(email, password) {
    const data = await this.request("/login", {
      method: "POST",
      body: JSON.stringify({ email, password })
    });

    if (data?.token) {
      this.setToken(data.token);
      if (data.user) {
        this.setUser(data.user);
      }
    }

    return data;
  },

  // Cerrar sesión
  async logout() {
    try {
      if (this.isAuthenticated()) {
        await this.request("/logout", { method: "POST" });
      }
    } catch (e) {
      console.warn("Aviso en logout (token posiblemente expirado):", e);
    } finally {
      this.clearSession();
      window.location.href = "/login";
    }
  },

  // Obtener datos del usuario actual, socio y deportista
  async getMe() {
    return this.request("/me");
  },

  // Obtener listado de actividades
  async getActividades() {
    return this.request("/actividades");
  },

  // Obtener mis inscripciones
  async getInscripciones() {
    return this.request("/inscripciones");
  },

  // Crear inscripción a una actividad
  async createInscripcion(actividadId) {
    return this.request("/inscripciones", {
      method: "POST",
      body: JSON.stringify({ actividad_id: actividadId })
    });
  },

  // Cancelar una inscripción existente
  async cancelInscripcion(inscripcionId) {
    return this.request(`/inscripciones/${inscripcionId}`, {
      method: "DELETE"
    });
  }
};

// Disponible globalmente para debugging
if (typeof window !== "undefined") {
  window.apiClient = apiClient;
}
