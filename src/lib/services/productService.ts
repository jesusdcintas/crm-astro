// ============================================
// SERVICIO DE PRODUCTOS - MINI-CRM SOFTCONTROL
// ============================================

import { supabase } from '../database/supabase';
import type { Product, CreateProductDTO, UpdateProductDTO } from '../../types/crm';

/**
 * Servicio para gestión de productos
 */
export const productService = {
    /**
     * Obtener todos los productos
     */
    async getAll(): Promise<Product[]> {
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .order('name', { ascending: true });

        if (error) {
            console.error('Error al obtener productos:', error);
            throw new Error(error.message);
        }

        return data || [];
    },

    /**
     * Obtener un producto por ID
     */
    async getById(id: string): Promise<Product | null> {
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .eq('id', id)
            .single();

        if (error) {
            console.error('Error al obtener producto:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Crear un nuevo producto
     */
    async create(productData: CreateProductDTO): Promise<Product> {
        const { data, error } = await supabase
            .from('products')
            .insert(productData)
            .select()
            .single();

        if (error) {
            console.error('Error al crear producto:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Actualizar un producto
     */
    async update(id: string, productData: UpdateProductDTO): Promise<Product> {
        const { data, error } = await supabase
            .from('products')
            .update(productData)
            .eq('id', id)
            .select()
            .single();

        if (error) {
            console.error('Error al actualizar producto:', error);
            throw new Error(error.message);
        }

        return data;
    },

    /**
     * Eliminar un producto
     */
    async delete(id: string): Promise<void> {
        const { error } = await supabase
            .from('products')
            .delete()
            .eq('id', id);

        if (error) {
            console.error('Error al eliminar producto:', error);
            throw new Error(error.message);
        }
    },

    /**
     * Buscar productos por nombre
     */
    async search(query: string): Promise<Product[]> {
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .ilike('name', `%${query}%`)
            .order('name', { ascending: true });

        if (error) {
            console.error('Error al buscar productos:', error);
            throw new Error(error.message);
        }

        return data || [];
    }
};
