import { defineMiddleware } from 'astro:middleware';

export const onRequest = defineMiddleware(async ({ cookies, url, redirect }, next) => {
  // Rutas públicas que no requieren autenticación
  const publicPaths = ['/auth/login', '/api/auth/login', '/api/auth/logout'];

  // Permitir acceso a rutas públicas
  if (publicPaths.includes(url.pathname)) {
    return next();
  }

  // Verificar si hay token de acceso
  const accessToken = cookies.get('sb-access-token')?.value;

  if (!accessToken) {
    // Solo redirigir si no estamos ya en la página de login
    if (url.pathname !== '/auth/login') {
      return redirect('/auth/login');
    }
  }

  // Si hay token, continuar con la petición
  return next();
});
