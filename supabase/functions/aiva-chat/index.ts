import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const defaultCorsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-api-version",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
};

function corsHeadersFor(req: Request) {
  const requestedHeaders = req.headers.get("access-control-request-headers");

  return {
    ...defaultCorsHeaders,
    ...(requestedHeaders
      ? { "Access-Control-Allow-Headers": requestedHeaders }
      : {}),
  };
}

serve(async (req: Request) => {
  const corsHeaders = corsHeadersFor(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { messages, temperature, max_tokens, tools, tool_choice, model } =
      await req.json();

    const nvidiaKey = Deno.env.get("NVIDIA_API_KEY");
    if (!nvidiaKey) {
      return new Response(
        JSON.stringify({ error: "NVIDIA_API_KEY not configured on server" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const response = await fetch(
      "https://integrate.api.nvidia.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${nvidiaKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: model ?? "meta/llama-3.1-8b-instruct",
          messages,
          temperature: temperature ?? 0.7,
          max_tokens: max_tokens ?? 512,
          ...(tools ? { tools } : {}),
          ...(tool_choice ? { tool_choice } : {}),
        }),
      }
    );

    const data = await response.json();

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: response.status,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
