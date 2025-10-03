import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

serve(async (_req) => {
  try {
    const now = new Date().toISOString();

    // Update subscriptions that have expired
    const { error } = await supabase
      .from("subscriptions")
      .update({ status: "expired" })
      .lt("subscription_expiry", now)
      .eq("status", "active");

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ message: "Expired subscriptions updated" }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: err }), { status: 500 });
  }
});
