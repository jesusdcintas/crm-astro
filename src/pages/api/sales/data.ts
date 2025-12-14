import type { APIRoute } from 'astro';
import { dashboardService } from '../../../lib/services/dashboardService';

export const GET: APIRoute = async ({ request, url }) => {
  try {
    // Obtener el intervalo de los parámetros de consulta (default: 6m)
    const interval = url.searchParams.get('interval') || '6m';
    
    // Validar que el intervalo sea válido
    const validIntervals = ['7d', '30d', '3m', '6m', '12m'];
    if (!validIntervals.includes(interval)) {
      return new Response(
        JSON.stringify({ error: 'Intervalo inválido. Usa: 7d, 30d, 3m, 6m, 12m' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Obtener datos de ventas con el intervalo especificado
    const salesData = await dashboardService.getSalesData(interval);

    return new Response(
      JSON.stringify(salesData),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error en API de ventas:', error);
    return new Response(
      JSON.stringify({ error: 'Error al obtener datos de ventas' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};
