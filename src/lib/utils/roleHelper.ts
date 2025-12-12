/**
 * Helper para verificar el rol del usuario actual
 */
import { supabase } from '../database/supabase';

export interface UserProfile {
    id: string;
    email: string;
    role: 'admin' | 'staff';
    created_at: string;
}

/**
 * Obtener el perfil del usuario actual desde las cookies
 */
export async function getCurrentUserProfile(accessToken: string): Promise<UserProfile | null> {
    try {
        // Obtener usuario de Supabase
        const { data: { user }, error: userError } = await supabase.auth.getUser(accessToken);

        if (userError || !user) {
            return null;
        }

        // Obtener perfil del usuario
        const { data: profile, error: profileError } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single();

        if (profileError || !profile) {
            return null;
        }

        return {
            id: profile.id as string,
            email: user.email || '',
            role: profile.role as 'admin' | 'staff',
            created_at: profile.created_at as string
        };
    } catch (error) {
        console.error('Error getting user profile:', error);
        return null;
    }
}

/**
 * Verificar si el usuario es admin
 */
export function isAdmin(profile: UserProfile | null): boolean {
    return profile?.role === 'admin';
}

/**
 * Verificar si el usuario es staff
 */
export function isStaff(profile: UserProfile | null): boolean {
    return profile?.role === 'staff';
}
