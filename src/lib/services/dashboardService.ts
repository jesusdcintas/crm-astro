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
  },

  /**
   * Obtener estadísticas de ventas con intervalo personalizable
   * @param interval - '7d' | '30d' | '3m' | '6m' | '12m'
   */
  async getSalesData(interval: string = '6m') {
    const now = new Date();
    const startDate = new Date();
    let groupBy: 'day' | 'month' = 'month';
    let periods = 6;

    // Determinar el rango de fechas según el intervalo
    switch (interval) {
      case '7d':
        startDate.setDate(now.getDate() - 7);
        groupBy = 'day';
        periods = 7;
        break;
      case '30d':
        startDate.setDate(now.getDate() - 30);
        groupBy = 'day';
        periods = 30;
        break;
      case '3m':
        startDate.setMonth(now.getMonth() - 3);
        groupBy = 'month';
        periods = 3;
        break;
      case '6m':
        startDate.setMonth(now.getMonth() - 6);
        groupBy = 'month';
        periods = 6;
        break;
      case '12m':
        startDate.setMonth(now.getMonth() - 12);
        groupBy = 'month';
        periods = 12;
        break;
      default:
        startDate.setMonth(now.getMonth() - 6);
        groupBy = 'month';
        periods = 6;
    }

    console.log('Consultando pagos desde:', startDate.toISOString(), 'Intervalo:', interval);

    const { data, error } = await supabase
      .from('payments')
      .select('created_at, amount')
      .gte('created_at', startDate.toISOString())
      .order('created_at', { ascending: true });

    if (error) {
      console.error('Error al obtener datos de ventas:', error);
      return { labels: [], data: [] };
    }

    if (!data || data.length === 0) {
      console.warn('No hay pagos en el período seleccionado');
      return { labels: [], data: [] };
    }

    // Agrupar ventas según el tipo de período
    const salesByPeriod: { [key: string]: number } = {};
    const monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    data?.forEach((payment: any) => {
      const date = new Date(payment.created_at);
      let periodKey: string;
      
      if (groupBy === 'day') {
        // Formato: "14 Dic"
        periodKey = `${date.getDate()} ${monthNames[date.getMonth()]}`;
      } else {
        // Formato: "Dic 2025"
        periodKey = `${monthNames[date.getMonth()]} ${date.getFullYear()}`;
      }
      
      salesByPeriod[periodKey] = (salesByPeriod[periodKey] || 0) + (payment.amount || 0);
    });

    console.log('Ventas agrupadas:', salesByPeriod);

    // Generar labels y datos para el período seleccionado
    const labels: string[] = [];
    const salesData: number[] = [];
    
    if (groupBy === 'day') {
      // Generar días
      for (let i = periods - 1; i >= 0; i--) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        const dayKey = `${date.getDate()} ${monthNames[date.getMonth()]}`;
        labels.push(dayKey);
        salesData.push(salesByPeriod[dayKey] || 0);
      }
    } else {
      // Generar meses
      for (let i = periods - 1; i >= 0; i--) {
        const date = new Date();
        date.setMonth(date.getMonth() - i);
        const monthKey = `${monthNames[date.getMonth()]} ${date.getFullYear()}`;
        labels.push(monthKey);
        salesData.push(salesByPeriod[monthKey] || 0);
      }
    }

    console.log('Labels:', labels);
    console.log('Sales data:', salesData);

    return { labels, data: salesData };
  }
};
