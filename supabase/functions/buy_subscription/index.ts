import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@12";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2022-11-15",
});

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { user_id } = await req.json();

    if (!user_id) {
      return new Response(JSON.stringify({ error: "Missing user_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 1️⃣ Create PaymentIntent for 5 EUR
    const paymentIntent = await stripe.paymentIntents.create({
      amount: 500,          // 5 EUR in cents
      currency: "eur",      // fixed currency
      payment_method_types: ["card"],
    });

    // 2️⃣ Store pending subscription in Supabase
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + 30);

    const { data, error } = await supabase
      .from("subscriptions")
      .upsert(
        [
          {
            user_id,
            subscription_id: paymentIntent.id,
            subscription_expiry: expiryDate.toISOString(),
            expired: false,
            status: "Active",
          },
        ],
        { onConflict: "user_id" }
      );

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Return client_secret to Flutter to open PaymentSheet
    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        subscription: data,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    const errorMessage =
      typeof err === "object" && err !== null && "message" in err
        ? (err as { message: string }).message
        : String(err);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
