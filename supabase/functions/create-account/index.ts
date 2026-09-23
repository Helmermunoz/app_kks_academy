import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (status: number, data: unknown) => new Response(JSON.stringify(data), {
  status, headers: { ...cors, "Content-Type": "application/json" },
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply(405, { error: "Método no permitido" });
  try {
    const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
    if (!token) return reply(401, { error: "Inicia sesión" });
    const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: { user }, error: authError } = await admin.auth.getUser(token);
    if (authError || !user) return reply(401, { error: "Sesión inválida" });
    const { data: caller } = await admin.from("profiles").select("role,must_change_password").eq("id", user.id).single();
    if (caller?.role !== "admin" || caller.must_change_password) return reply(403, { error: "Acceso denegado" });
    const { name, email, password, role } = await req.json();
    if (typeof name !== "string" || !name.trim() || name.trim().length > 100 ||
        typeof email !== "string" || !email.includes("@") || email.length > 254 ||
        typeof password !== "string" || password.length < 12 || password.length > 128 ||
        !["athlete", "coach"].includes(role)) return reply(400, { error: "Revisa los datos y usa una contraseña de al menos 12 caracteres" });
    const { data, error } = await admin.auth.admin.createUser({
      email: email.trim(), password, email_confirm: true,
    });
    if (error || !data.user) return reply(400, { error: "No se pudo crear la cuenta. Revisa si el correo ya existe y la política de contraseñas." });
    const { error: profileError } = await admin.from("profiles").insert({
      id: data.user.id, name: name.trim(), role,
    });
    if (profileError) {
      const { error: cleanupError } = await admin.auth.admin.deleteUser(data.user.id);
      return reply(500, { error: cleanupError
        ? "Perfil incompleto: revisa la cuenta en el panel de Supabase antes de reintentar."
        : "No se pudo crear el perfil. Intenta de nuevo." });
    }
    return reply(201, { id: data.user.id });
  } catch {
    return reply(400, { error: "No se pudo procesar la solicitud" });
  }
});
