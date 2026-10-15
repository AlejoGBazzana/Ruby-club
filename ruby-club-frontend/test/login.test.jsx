import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import Login from '../src/components/Login';

describe('Componente Login (Pruebas de interacción UI)', () => {
  it('Flujo exitoso: el usuario completa sus credenciales y se envía el formulario', async () => {
    const onLoginSuccessMock = vi.fn().mockResolvedValue({ success: true });

    render(<Login onLoginSuccess={onLoginSuccessMock} sessionExpired={false} />);

    // Verificar que los campos y el botón existan
    const emailInput = screen.getByLabelText(/correo electrónico/i);
    const passwordInput = screen.getByLabelText(/contraseña/i);
    const submitButton = screen.getByRole('button', { name: /ingresar/i });

    expect(emailInput).toBeDefined();
    expect(passwordInput).toBeDefined();

    // Completar credenciales válidas
    fireEvent.change(emailInput, { target: { value: 'socio@club.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });

    // Enviar el formulario
    fireEvent.click(submitButton);

    // Verificar que mientras procesa el botón muestra estado de carga
    expect(submitButton.textContent).toBe('Ingresando...');
    expect(submitButton.disabled).toBe(true);

    // Esperar a que se complete el callback
    await waitFor(() => {
      expect(onLoginSuccessMock).toHaveBeenCalledTimes(1);
      expect(onLoginSuccessMock).toHaveBeenCalledWith('socio@club.com', 'password123');
    });

    // Verificar que no se muestre mensaje de error
    const errorAlert = screen.queryByText(/Email o contraseña inválidos/i);
    expect(errorAlert).toBeNull();
  });

  it('Flujo de error: credenciales inválidas muestra mensaje de error visible y rehabilita el botón', async () => {
    const invalidCredentialsError = new Error('Email o contraseña inválidos. Verificá tus datos.');
    invalidCredentialsError.code = 'invalid_credentials';
    invalidCredentialsError.status = 401;

    const onLoginSuccessMock = vi.fn().mockRejectedValue(invalidCredentialsError);

    render(<Login onLoginSuccess={onLoginSuccessMock} sessionExpired={false} />);

    const emailInput = screen.getByLabelText(/correo electrónico/i);
    const passwordInput = screen.getByLabelText(/contraseña/i);
    const submitButton = screen.getByRole('button', { name: /ingresar/i });

    // Ingresar credenciales que fallarán
    fireEvent.change(emailInput, { target: { value: 'socio@club.com' } });
    fireEvent.change(passwordInput, { target: { value: 'erronea' } });

    fireEvent.click(submitButton);

    // Verificar que se llame a la función
    await waitFor(() => {
      expect(onLoginSuccessMock).toHaveBeenCalledTimes(1);
    });

    // Verificar que el mensaje de error exacto aparezca en pantalla
    const errorMessage = await screen.findByText('Email o contraseña inválidos. Verificá tus datos.');
    expect(errorMessage).toBeDefined();

    // Verificar que el botón se rehabilite para un nuevo intento
    expect(submitButton.disabled).toBe(false);
    expect(submitButton.textContent).toBe('Ingresar');
  });
});
