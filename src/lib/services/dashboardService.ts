// ============================================
// SERVICIO DE DASHBOARD - MINI-CRM SOFTCONTROL
// ============================================

import { supabase } from '../database/supabase';
import type { DashboardStats } from '../../types/crm';

/**
 * Servicio para obtener estadísticas del dashboard
 */
export const dashboardService = {
  /**
   * Obtener todas las estadísticas del dashboard
   */
  async getStats(): Promise<DashboardStats> {
    // Usar la función SQL que creamos
    const { data, error } = await supabase.rpc('get_dashboard_stats');

    if (error) {
      console.error('Error al obtener estadísticas:', error);
      // Si falla, calcular manualmente
      return this.getStatsManual();
    }

    return data as DashboardStats;
  },

  /**
   * Obtener estadísticas manualmente (fallback)
   */
  async getStatsManual(): Promise<DashboardStats> {
    // Contar clientes
    const { count: totalClients } = await supabase
      .from('clients')
      .select('*', { count: 'exact', head: true });

    // Contar productos
    const { count: totalProducts } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true });

    // Contar licencias totales
    const { count: totalLicenses } = await supabase
      .from('licenses')
      .select('*', { count: 'exact', head: true });

    // Contar licencias activas
    const { count: activeLicenses } = await supabase
      .from('licenses')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'activa');

    // Contar licencias inactivas
    const { count: inactiveLicenses } = await supabase
      .from('licenses')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'inactiva');

    // Contar licencias pendientes de pago
    const { count: pendingPaymentLicenses } = await supabase
      .from('licenses')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'pendiente_pago');

    // Contar licencias vencidas
    const { count: expiredLicenses } = await supabase
      .from('licenses')
      .select('*', { count: 'exact', head: true })
      .lt('end_date', new Date().toISOString().split('T')[0])
      .not('end_date', 'is', null);

    return {
      total_clients: totalClients || 0,
      total_products: totalProducts || 0,
      total_licenses: totalLicenses || 0,
      active_licenses: activeLicenses || 0,
      inactive_licenses: inactiveLicenses || 0,
      pending_payment_licenses: pendingPaymentLicenses || 0,
      expired_licenses: expiredLicenses || 0
    };
  }
};
