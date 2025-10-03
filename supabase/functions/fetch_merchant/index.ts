import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
});

serve(async (req) => {
  try {
    const { merchant_account_id } = await req.json();
    if (!merchant_account_id) {
      return new Response(JSON.stringify({ error: "Missing account id" }), { status: 400 });
    }

    // Full account object: includes individual/business details, requirements, etc.
    const account = await stripe.accounts.retrieve(merchant_account_id);

    // Connected account’s current balance (available, pending, etc.)
    const balance = await stripe.balance.retrieve({ stripeAccount: merchant_account_id });

    // Package only the fields you truly need
    const payload = {
      id: account.id,
      email: account.email,
      businessType: account.business_type,
      country: account.country,
      payoutsEnabled: account.payouts_enabled,
      chargesEnabled: account.charges_enabled,
      capabilities: account.capabilities,
      requirements: account.requirements,       // shows any outstanding KYC tasks
      company: account.company,                 // may include address
      individual: account.individual,           // may include address/DOB
      balance: balance,                         // available & pending amounts
    };

    return new Response(JSON.stringify(payload), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    const errorMessage = typeof err === "object" && err !== null && "message" in err
      ? (err as { message: string }).message
      : String(err);
    return new Response(JSON.stringify({ error: errorMessage }), { status: 500 });
  }
});
