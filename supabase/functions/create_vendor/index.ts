import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@12";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
});

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

serve(async (req) => {
  try {
    const { user_id, email, country } = await req.json();

    if (!user_id || !email || !country) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400 }
      );
    }

    // 1️⃣ Create Stripe Connect account
    const account = await stripe.accounts.create({
      type: "standard",
      country,
      email,
      capabilities: {
        transfers: { requested: true },
        card_payments: { requested: true },
      },
      business_type: "individual",
      metadata: { user_id },
    });

    // 2️⃣ Create Stripe onboarding link with deep links
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: "beautyconnect://stripe-reauth",           // deep link for retry
      return_url: "beautyconnect://stripe-onboarding-done",  // deep link after success
      type: "account_onboarding",
    });

    // 3️⃣ Upsert into Supabase
    const { error } = await supabase
      .from("accounts")
      .upsert(
        {
          user_id,
          email,
          country,
          account_id: account.id,
        },
        { onConflict: "user_id" } // update if exists
      );

    if (error) throw error;

    // 4️⃣ Respond with Stripe account ID and onboarding link
    return new Response(
      JSON.stringify({
        stripe_account_id: account.id,
        onboarding_url: accountLink.url,
      }),
      { headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error(err);
    const message =
      typeof err === "object" && err && "message" in err
        ? (err as { message?: string }).message ?? "Unknown error"
        : "Unknown error";
    return new Response(JSON.stringify({ error: message }), { status: 500 });
  }
});
