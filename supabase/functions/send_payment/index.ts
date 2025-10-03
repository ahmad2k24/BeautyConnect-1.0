// supabase/functions/send_payment/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
});

serve(async (req) => {
  try {
    const { amount, currency, merchant_account_id } = await req.json();

    // Direct charge with platform fee
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      on_behalf_of: merchant_account_id,         // ✅ settle in merchant’s country
      application_fee_amount: Math.round(amount * 0.15), // 15% fee to platform
      transfer_data: {
        destination: merchant_account_id,        // ✅ merchant gets 85%
      },
      automatic_payment_methods: { enabled: true },
    });

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    );
  } catch (err) {
    const errorMessage = typeof err === "object" && err !== null && "message" in err
      ? (err as { message: string }).message
      : String(err);
    return new Response(JSON.stringify({ error: errorMessage }), { status: 400 });
  }
});
