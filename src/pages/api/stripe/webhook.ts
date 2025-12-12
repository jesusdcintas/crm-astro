/**
 * Webhook de Stripe para recibir eventos de pago
 */
import type { APIRoute } from 'astro';
import { constructWebhookEvent } from '../../../lib/services/stripeService';
import { licenseService } from '../../../lib/services/licenseService';

export const POST: APIRoute = async ({ request }) => {
    try {
        const signature = request.headers.get('stripe-signature');

        if (!signature) {
            return new Response('No signature', { status: 400 });
        }

        const payload = await request.text();
        const result = await constructWebhookEvent(payload, signature);

        if (!result.success || !result.event) {
            return new Response('Webhook verification failed', { status: 400 });
        }

        const event = result.event;

        // Manejar diferentes tipos de eventos
        switch (event.type) {
            case 'checkout.session.completed': {
                const session = event.data.object as any;
                const licenseId = session.metadata?.license_id;

                if (licenseId) {
                    // Actualizar licencia a activa
                    await licenseService.update(licenseId, {
                        status: 'activa',
                    });

                    console.log(`Licencia ${licenseId} marcada como activa`);
                }
                break;
            }

            case 'invoice.payment_succeeded': {
                const invoice = event.data.object as any;
                const subscriptionId = invoice.subscription;

                // Aquí podrías actualizar la fecha de próximo pago
                console.log(`Pago exitoso para suscripción ${subscriptionId}`);
                break;
            }

            case 'invoice.payment_failed': {
                const invoice = event.data.object as any;
                const subscriptionId = invoice.subscription;

                // Marcar licencia como pendiente de pago
                console.log(`Pago fallido para suscripción ${subscriptionId}`);
                break;
            }

            case 'customer.subscription.deleted': {
                const subscription = event.data.object as any;

                // Marcar licencia como inactiva
                console.log(`Suscripción cancelada: ${subscription.id}`);
                break;
            }

            default:
                console.log(`Evento no manejado: ${event.type}`);
        }

        return new Response(JSON.stringify({ received: true }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        });

    } catch (error) {
        console.error('Error en webhook:', error);
        return new Response('Webhook error', { status: 400 });
    }
};
