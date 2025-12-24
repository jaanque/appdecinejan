# Configuración de Supabase - Solución de Problemas

## Error: "Error sending confirmation email"

Si al registrarte recibes el error **"Error sending confirmation email"**, significa que el servicio de envío de correos de tu proyecto de Supabase no está configurado correctamente o ha alcanzado su límite gratuito.

### Solución Rápida (Para Desarrollo)

Para solucionar esto inmediatamente y permitir el registro de usuarios sin enviar correos:

1. Ve a tu [Panel de Control de Supabase](https://supabase.com/dashboard).
2. Selecciona tu proyecto.
3. En el menú lateral izquierdo, ve a **Authentication**.
4. Selecciona **Providers**.
5. Haz clic en **Email** (debería estar desplegado).
6. **DESACTIVA** la opción que dice **"Confirm email"** (Confirmar correo electrónico).
7. Haz clic en **Save** (Guardar).

Una vez hecho esto:
- Los nuevos usuarios que se registren tendrán su correo verificado automáticamente.
- Ya no se intentará enviar el correo de confirmación, evitando el error.
- Podrás iniciar sesión inmediatamente después de registrarte.

### Solución Definitiva (Para Producción)

Si necesitas enviar correos de confirmación en producción:
1. Configura un servicio SMTP personalizado (como Resend, SendGrid, AWS SES) en la configuración de Supabase (Settings -> SMTP Settings).
2. El servicio de correo por defecto de Supabase tiene límites muy estrictos (aprox 3 correos por hora) y es solo para pruebas.
