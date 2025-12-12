/**
 * Servicio de Stripe para procesamiento de pagos
 */
import Stripe from 'stripe';

// Inicializar Stripe con la clave secreta
const stripe = new Stripe(import.meta.env.STRIPE_SECRET_KEY || '', {
    apiVersion: '2024-11-20.acacia',
});

export interface CreateCheckoutSessionParams {
    licenseId: string;
    clientEmail: string;
    productName: string;
    amount: number;
    type: 'one_time' | 'subscription';
    successUrl: string;
    cancelUrl: string;
}

/**
 * Crear sesión de Stripe Checkout
 */
export async function createCheckoutSession(params: CreateCheckoutSessionParams) {
    const {
        licenseId,
        clientEmail,
        productName,
        amount,
        type,
        successUrl,
        cancelUrl
    } = params;

    try {
        // Validar que el precio sea un número válido
        if (isNaN(amount) || amount <= 0) {
            console.error('Invalid amount:', amount);
            return { success: false, error: 'Precio inválido. Verifica que el producto tenga un precio configurado.' };
        }

        const sessionParams: Stripe.Checkout.SessionCreateParams = {
            payment_method_types: ['card'],
            customer_email: clientEmail,
            line_items: [
                {
                    price_data: {
                        currency: 'eur',
                        product_data: {
                            name: productName,
                            description: type === 'one_time' ? 'Licencia única' : 'Suscripción mensual',
                        },
                        unit_amount: Math.round(amount * 100), // Stripe usa centavos
                        ...(type === 'subscription' && {
                            recurring: {
                                interval: 'month',
                            },
                        }),
                    },
                    quantity: 1,
                },
            ],
            mode: type === 'one_time' ? 'payment' : 'subscription',
            success_url: successUrl,
            cancel_url: cancelUrl,
            metadata: {
                license_id: licenseId,
                payment_type: type,
            },
        };

        const session = await stripe.checkout.sessions.create(sessionParams);
        return { success: true, sessionId: session.id, url: session.url };
    } catch (error) {
        console.error('Error creating checkout session:', error);
        return { success: false, error: 'Error al crear sesión de pago' };
    }
}

/**
 * Verificar estado de una sesión de checkout
 */
export async function getCheckoutSession(sessionId: string) {
    try {
        const session = await stripe.checkout.sessions.retrieve(sessionId);
        return { success: true, session };
    } catch (error) {
        console.error('Error retrieving session:', error);
        return { success: false, error: 'Error al obtener sesión' };
    }
}

/**
 * Cancelar una suscripción
 */
export async function cancelSubscription(subscriptionId: string) {
    try {
        const subscription = await stripe.subscriptions.cancel(subscriptionId);
        return { success: true, subscription };
    } catch (error) {
        console.error('Error canceling subscription:', error);
        return { success: false, error: 'Error al cancelar suscripción' };
    }
}

/**
 * Verificar webhook de Stripe
 */
export async function constructWebhookEvent(
    payload: string | Buffer,
    signature: string
) {
    const webhookSecret = import.meta.env.STRIPE_WEBHOOK_SECRET;

    if (!webhookSecret) {
        throw new Error('Webhook secret not configured');
    }

    try {
        const event = stripe.webhooks.constructEvent(
            payload,
            signature,
            webhookSecret
        );
        return { success: true, event };
    } catch (error) {
        console.error('Webhook verification failed:', error);
        return { success: false, error: 'Verificación de webhook fallida' };
    }
}

export { stripe };
