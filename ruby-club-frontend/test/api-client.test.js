// test/api-client.test.js
// Pruebas unitarias para el cliente API utilizando Vitest

import { describe, it, expect, beforeEach } from 'vitest';
import { apiClient } from '../src/api/client.js';

describe('Cliente API (apiClient)', () => {
  beforeEach(() => {
    sessionStorage.clear();
  });

  it('Validación y almacenamiento de sesión: login exitoso', async () => {
    // Simular respuesta exitosa de la API
    globalThis.fetch = async (url, options) => {
      expect(url).toBe('/api/v1/login');
      expect(options.method).toBe('POST');
      const body = JSON.parse(options.body);
      expect(body.email).toBe('socio@club.com');
      expect(body.password).toBe('password123');

      return {
        ok: true,
        status: 200,
        json: async () => ({
          token: 'mock-jwt-token-xyz',
          user: { id: 1, email: 'socio@club.com', role: 'user' }
        })
      };
    };

    const response = await apiClient.login('socio@club.com', 'password123');
    expect(response.token).toBe('mock-jwt-token-xyz');
    expect(apiClient.getToken()).toBe('mock-jwt-token-xyz');
    expect(apiClient.isAuthenticated()).toBe(true);
    expect(apiClient.getUser()?.email).toBe('socio@club.com');
  });

  it('Tratamiento de error: login con credenciales inválidas (HTTP 401)', async () => {
    globalThis.fetch = async () => {
      return {
        ok: false,
        status: 401,
        json: async () => ({
          error: { code: 'invalid_credentials', message: 'Email o contraseña inválidos.' }
        })
      };
    };

    await expect(apiClient.login('invalido@club.com', 'wrongpassword')).rejects.toMatchObject({
      status: 401,
      code: 'invalid_credentials',
      message: 'Email o contraseña inválidos.'
    });

    // Asegurar que la sesión queda limpia
    expect(apiClient.isAuthenticated()).toBe(false);
    expect(apiClient.getToken()).toBeNull();
  });

  it('Manejo de errores de validación de negocio (HTTP 422 con detalles)', async () => {
    apiClient.setToken('test-token');

    globalThis.fetch = async (url, options) => {
      expect(options.headers.Authorization).toMatch(/^Bearer test-token$/);
      return {
        ok: false,
        status: 422,
        json: async () => ({
          error: {
            code: 'validation_error',
            message: 'No se pudo crear la inscripción.',
            details: [
              'Ya tenés una inscripción activa para esta actividad',
              'El cupo de la actividad está completo'
            ]
          }
        })
      };
    };

    await expect(apiClient.createInscripcion(99)).rejects.toMatchObject({
      status: 422,
      code: 'validation_error',
      message: 'No se pudo crear la inscripción.',
      details: [
        'Ya tenés una inscripción activa para esta actividad',
        'El cupo de la actividad está completo'
      ]
    });
  });

  it('Tratamiento de fallas de conexión / red', async () => {
    globalThis.fetch = async () => {
      throw new TypeError('Failed to fetch');
    };

    await expect(apiClient.getActividades()).rejects.toMatchObject({
      network: true,
      message: 'No se pudo conectar con el servidor. Comprobá tu conexión.'
    });
  });

  it('Cierre de sesión: logout revoca y limpia almacenamiento', async () => {
    apiClient.setToken('token-para-revocar');
    apiClient.setUser({ id: 1, email: 'socio@club.com' });

    let logoutEndpointCalled = false;
    globalThis.fetch = async (url, options) => {
      if (url === '/api/v1/logout') {
        logoutEndpointCalled = true;
        expect(options.method).toBe('POST');
        expect(options.headers.Authorization).toBe('Bearer token-para-revocar');
        return {
          ok: true,
          status: 204
        };
      }
    };

    await apiClient.logout();
    expect(logoutEndpointCalled).toBe(true);
    expect(apiClient.isAuthenticated()).toBe(false);
    expect(apiClient.getToken()).toBeNull();
    expect(apiClient.getUser()).toBeNull();
  });
});
