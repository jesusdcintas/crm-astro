// ============================================
// SERVICIO DE CLIENTES - MINI-CRM SOFTCONTROL
// ============================================

import { supabase } from '../database/supabase';
import type { Client, CreateClientDTO, UpdateClientDTO, ClientWithLicenses } from '../../types/crm';

/**
 * Servicio para gestión de clientes
 */
export const clientService = {
    /**
     * Obtener todos los clientes
     */
    async getAll(): Promise<Client[]> {
        const { data, error } = await supabase
            .from('clients')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error al obtener clientes:', error);
            throw new Error(error.message);
        }

        return data || [];
    },

    /**
     * Obtener un cliente por ID
     */
    async getById(id: string): Promise<Client | null> {
        const { data, error } = await supabase
            .from('clients')
            .select('*')
            .eq('id', id)
            .single();

        if (error) {
            console.error('Error al obtener cliente:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Obtener un cliente con sus licencias
     */
    async getWithLicenses(id: string): Promise<ClientWithLicenses | null> {
        // Obtener cliente
        const client = await this.getById(id);
        if (!client) return null;

        // Obtener licencias del cliente usando la vista
        const { data: licenses, error } = await supabase
            .from('licenses_full')
            .select('*')
            .eq('client_id', id)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error al obtener licencias del cliente:', error);
            throw new Error(error.message);
        }

        return {
            ...client,
            licenses: licenses || []
        };
    },

    /**
     * Crear un nuevo cliente
     */
    async create(clientData: CreateClientDTO): Promise<Client> {
        // Obtener el usuario actual
        const { data: { user } } = await supabase.auth.getUser();

        if (!user) {
            throw new Error('Usuario no autenticado');
        }

        const { data, error } = await supabase
            .from('clients')
            .insert({
                ...clientData,
                created_by: user.id
            })
            .select()
            .single();

        if (error) {
            console.error('Error al crear cliente:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Actualizar un cliente
     */
    async update(id: string, clientData: UpdateClientDTO): Promise<Client> {
        const { data, error } = await supabase
            .from('clients')
            .update(clientData)
            .eq('id', id)
            .select()
            .single();

        if (error) {
            console.error('Error al actualizar cliente:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Eliminar un cliente
     */
    async delete(id: string): Promise<void> {
        const { error } = await supabase
            .from('clients')
            .delete()
            .eq('id', id);

        if (error) {
            console.error('Error al eliminar cliente:', error);
            throw new Error(error.message);
        }
    },

    /**
     * Buscar clientes por nombre o email
     */
    async search(query: string): Promise<Client[]> {
        const { data, error } = await supabase
            .from('clients')
            .select('*')
            .or(`name.ilike.%${query}%,email.ilike.%${query}%,company.ilike.%${query}%`)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error al buscar clientes:', error);
            throw new Error(error.message);
        }

        return data || [];
    }
};
