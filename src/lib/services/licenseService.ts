// ============================================
// SERVICIO DE LICENCIAS - MINI-CRM SOFTCONTROL
// ============================================

import { supabase } from '../database/supabase';
import type {
    License,
    LicenseFull,
    CreateLicenseDTO,
    UpdateLicenseDTO,
    LicenseFilters,
    LicenseStatus
} from '../../types/crm';

/**
 * Servicio para gestión de licencias
 */
export const licenseService = {
    /**
     * Obtener todas las licencias con información completa
     */
    async getAll(): Promise<LicenseFull[]> {
        const { data, error } = await supabase
            .from('licenses_full')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error al obtener licencias:', error);
            throw new Error(error.message);
        }

        return data || [];
    },

    /**
     * Obtener una licencia por ID
     */
    async getById(id: string): Promise<License | null> {
        const { data, error } = await supabase
            .from('licenses')
            .select('*')
            .eq('id', id)
            .single();

        if (error) {
            console.error('Error al obtener licencia:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Obtener una licencia completa por ID
     */
    async getFullById(id: string): Promise<LicenseFull | null> {
        const { data, error } = await supabase
            .from('licenses_full')
            .select('*')
            .eq('id', id)
            .single();

        if (error) {
            console.error('Error al obtener licencia completa:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Obtener licencias filtradas
     */
    async getFiltered(filters: LicenseFilters): Promise<LicenseFull[]> {
        let query = supabase
            .from('licenses_full')
            .select('*');

        // Aplicar filtros
        if (filters.status) {
            query = query.eq('status', filters.status);
        }

        if (filters.type) {
            query = query.eq('type', filters.type);
        }

        if (filters.client_id) {
            query = query.eq('client_id', filters.client_id);
        }

        if (filters.product_id) {
            query = query.eq('product_id', filters.product_id);
        }

        if (filters.expired !== undefined) {
            if (filters.expired) {
                query = query.eq('is_expired', true);
            } else {
                query = query.eq('is_expired', false);
            }
        }

        query = query.order('created_at', { ascending: false });

        const { data, error } = await query;

        if (error) {
            console.error('Error al obtener licencias filtradas:', error);
            throw new Error(error.message);
        }

        return data || [];
    },

    /**
     * Obtener licencias por estado
     */
    async getByStatus(status: LicenseStatus): Promise<LicenseFull[]> {
        return this.getFiltered({ status });
    },

    /**
     * Obtener licencias vencidas
     */
    async getExpired(): Promise<LicenseFull[]> {
        return this.getFiltered({ expired: true });
    },

    /**
     * Obtener licencias activas
     */
    async getActive(): Promise<LicenseFull[]> {
        return this.getFiltered({ status: 'activa', expired: false });
    },

    /**
     * Obtener licencias de un cliente
     */
    async getByClient(clientId: string): Promise<LicenseFull[]> {
        return this.getFiltered({ client_id: clientId });
    },

    /**
     * Crear una nueva licencia
     */
    async create(licenseData: CreateLicenseDTO): Promise<License> {
        const { data, error } = await supabase
            .from('licenses')
            .insert({
                ...licenseData,
                status: licenseData.status || 'activa'
            })
            .select()
            .single();

        if (error) {
            console.error('Error al crear licencia:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Actualizar una licencia
     */
    async update(id: string, licenseData: UpdateLicenseDTO): Promise<License> {
        const { data, error } = await supabase
            .from('licenses')
            .update(licenseData)
            .eq('id', id)
            .select()
            .single();

        if (error) {
            console.error('Error al actualizar licencia:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Cambiar el estado de una licencia
     */
    async updateStatus(id: string, status: LicenseStatus): Promise<License> {
        return this.update(id, { status });
    },

    /**
     * Eliminar una licencia
     */
    async delete(id: string): Promise<void> {
        const { error } = await supabase
            .from('licenses')
            .delete()
            .eq('id', id);

        if (error) {
            console.error('Error al eliminar licencia:', error);
            throw new Error(error.message);
        }
    },

    /**
     * Contar licencias por estado
     */
    async countByStatus(): Promise<Record<LicenseStatus, number>> {
        const { data, error } = await supabase
            .from('licenses')
            .select('status');

        if (error) {
            console.error('Error al contar licencias:', error);
            throw new Error(error.message);
        }

        const counts: Record<LicenseStatus, number> = {
            activa: 0,
            inactiva: 0,
            pendiente_pago: 0
        };

        data?.forEach(license => {
            counts[license.status as LicenseStatus]++;
        });

        return counts;
    }
};
