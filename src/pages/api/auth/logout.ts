import type { APIRoute } from 'astro';
import { supabase } from '../../../lib/database/supabase';

export const POST: APIRoute = async ({ cookies, redirect }) => {
  try {
    // Cerrar sesión en Supabase
    await supabase.auth.signOut();

    // Eliminar cookies
    cookies.delete('sb-access-token', { path: '/' });
    cookies.delete('sb-refresh-token', { path: '/' });

    return redirect('/auth/login');
  } catch (error) {
    console.error('Error en logout:', error);
    // Aunque haya error, eliminar cookies y redirigir
    cookies.delete('sb-access-token', { path: '/' });
    cookies.delete('sb-refresh-token', { path: '/' });
    return redirect('/auth/login');
  }
};
