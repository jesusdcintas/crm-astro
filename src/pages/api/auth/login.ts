import type { APIRoute } from 'astro';
import { supabase } from '../../../lib/database/supabase';

export const POST: APIRoute = async ({ request, cookies, redirect }) => {
  const formData = await request.formData();
  const email = formData.get('email')?.toString();
  const password = formData.get('password')?.toString();

  if (!email || !password) {
    return redirect('/auth/login?error=invalid');
  }

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error || !data.session) {
      console.error('Error en login:', error);
      return redirect('/auth/login?error=invalid');
    }

    // Verificar que el usuario tenga perfil
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', data.user.id)
      .single();

    if (profileError || !profile) {
      console.error('Usuario sin perfil:', profileError);
      return redirect('/auth/login?error=unauthorized');
    }

    // Guardar tokens en cookies
    cookies.set('sb-access-token', data.session.access_token, {
      path: '/',
      httpOnly: true,
      secure: import.meta.env.PROD,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7 // 7 días
    });

    cookies.set('sb-refresh-token', data.session.refresh_token, {
      path: '/',
      httpOnly: true,
      secure: import.meta.env.PROD,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 30 // 30 días
    });

    return redirect('/dashboard');
  } catch (error) {
    console.error('Error en login:', error);
    return redirect('/auth/login?error=invalid');
  }
};
