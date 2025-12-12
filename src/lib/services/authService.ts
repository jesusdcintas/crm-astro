// ============================================
// SERVICIO DE AUTENTICACIÓN - MINI-CRM SOFTCONTROL
// ============================================

import { supabase } from '../database/supabase';
import type { Profile, UserRole } from '../../types/crm';

/**
 * Servicio para autenticación y gestión de perfiles
 */
export const authService = {
  /**
   * Iniciar sesión con email y contraseña
   */
  async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      console.error('Error al iniciar sesión:', error);
      throw new Error(error.message);
    }

    return data;
  },

  /**
   * Cerrar sesión
   */
  async signOut() {
    const { error } = await supabase.auth.signOut();

    if (error) {
      console.error('Error al cerrar sesión:', error);
      throw new Error(error.message);
    }
  },

  /**
   * Obtener el usuario actual
   */
  async getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();

    if (error) {
      console.error('Error al obtener usuario:', error);
      throw new Error(error.message);
    }

    return user;
  },

  /**
   * Obtener el perfil del usuario actual
   */
  async getCurrentProfile(): Promise<Profile | null> {
    const user = await this.getCurrentUser();

    if (!user) return null;

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (error) {
      console.error('Error al obtener perfil:', error);
      return null;
    }

    return data;
  },

  /**
   * Verificar si el usuario actual es administrador
   */
  async isAdmin(): Promise<boolean> {
    const profile = await this.getCurrentProfile();
    return profile?.role === 'admin';
  },

  /**
   * Verificar si el usuario actual es staff
   */
  async isStaff(): Promise<boolean> {
    const profile = await this.getCurrentProfile();
    return profile?.role === 'staff';
  },

  /**
   * Obtener el rol del usuario actual
   */
  async getCurrentRole(): Promise<UserRole | null> {
    const profile = await this.getCurrentProfile();
    return profile?.role || null;
  },

  /**
   * Registrar un nuevo usuario (solo para admin)
   */
  async signUp(email: string, password: string, fullName: string, role: UserRole = 'staff') {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role: role
        }
      }
    });

    if (error) {
      console.error('Error al registrar usuario:', error);
      throw new Error(error.message);
    }

    return data;
  },

  /**
   * Actualizar el perfil del usuario actual
   */
  async updateProfile(fullName: string): Promise<Profile> {
    const user = await this.getCurrentUser();

    if (!user) {
      throw new Error('Usuario no autenticado');
    }

    const { data, error } = await supabase
      .from('profiles')
      .update({ full_name: fullName })
      .eq('id', user.id)
      .select()
      .single();

    if (error) {
      console.error('Error al actualizar perfil:', error);
      throw new Error(error.message);
    }

    return data;
  },

  /**
   * Verificar si hay una sesión activa
   */
  async hasSession(): Promise<boolean> {
    const { data: { session } } = await supabase.auth.getSession();
    return session !== null;
  }
};
