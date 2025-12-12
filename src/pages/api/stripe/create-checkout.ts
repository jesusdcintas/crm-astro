/**
 * API endpoint para crear sesión de Stripe Checkout
 */
import type { APIRoute } from 'astro';
import { createCheckoutSession } from '../../../lib/services/stripeService';
import { licenseService } from '../../../lib/services/licenseService';

export const POST: APIRoute = async ({ request, url }) => {
    try {
        const body = await request.json();
        const { licenseId } = body;

        if (!licenseId) {
            return new Response(JSON.stringify({ error: 'License ID requerido' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        // Obtener información de la licencia
        const license = await licenseService.getFullById(licenseId);

        if (!license) {
            return new Response(JSON.stringify({ error: 'Licencia no encontrada' }), {
                status: 404,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        // Validar que el precio exista y sea válido
        if (!license.price || isNaN(license.price) || license.price <= 0) {
            console.error('Invalid price for license:', license.id, 'price:', license.price);
            return new Response(JSON.stringify({
                error: `El producto "${license.product_name}" no tiene un precio configurado para el tipo de licencia "${license.type}". Por favor, edita el producto y configura el precio correspondiente.`
            }), {
                status: 400,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        // Crear sesión de checkout
        const result = await createCheckoutSession({
            licenseId: license.id,
            clientEmail: license.client_email,
            productName: license.product_name,
            amount: license.price,
            type: license.type === 'licencia_unica' ? 'one_time' : 'subscription',
            successUrl: `${url.origin}/licenses/${licenseId}/payment-success?session_id={CHECKOUT_SESSION_ID}`,
            cancelUrl: `${url.origin}/licenses/${licenseId}/payment-cancel`
        });

        if (!result.success) {
            return new Response(JSON.stringify({ error: result.error }), {
                status: 500,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        return new Response(JSON.stringify({
            sessionId: result.sessionId,
            url: result.url
        }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        });

    } catch (error) {
        console.error('Error en create-checkout:', error);
        return new Response(JSON.stringify({ error: 'Error interno del servidor' }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        });
    }
};
