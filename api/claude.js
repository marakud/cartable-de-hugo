// Fonction Vercel : la page lui envoie une consigne (et parfois une capture Pronote),
// elle vérifie que c'est bien Harry qui est connecté, puis demande à Claude.
// La clé ANTHROPIC_API_KEY reste ici, sur le serveur, jamais dans la page.
import Anthropic from "@anthropic-ai/sdk";
import { createClient } from "@supabase/supabase-js";

const anthropic = new Anthropic(); // lit ANTHROPIC_API_KEY
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
const ALLOWED = (process.env.ALLOWED_EMAILS || "").split(",").map(s => s.trim().toLowerCase()).filter(Boolean);
const MODEL = process.env.CLAUDE_MODEL || "claude-opus-5-5";

export const config = { maxDuration: 60 };

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).json({ code: "invalid_request" });

  const token = (req.headers.authorization || "").replace(/^Bearer /, "");
  const { data: { user } = {}, error } = await supabase.auth.getUser(token);
  if (error || !user) return res.status(401).json({ code: "not_granted" });
  if (!ALLOWED.includes((user.email || "").toLowerCase())) return res.status(403).json({ code: "not_granted" });

  const { prompt, images = [] } = req.body || {};
  if (typeof prompt !== "string" || !prompt.trim() || prompt.length > 20000) return res.status(400).json({ code: "invalid_request" });
  if (!Array.isArray(images) || images.length > 1) return res.status(400).json({ code: "image_rejected" });

  const content = [
    ...images.map(data => ({ type: "image", source: { type: "base64", media_type: "image/jpeg", data } })),
    { type: "text", text: prompt }
  ];

  try {
    const msg = await anthropic.beta.messages.create({
      model: MODEL,
      max_tokens: 16000,
      output_config: { effort: process.env.CLAUDE_EFFORT || "medium" },
      // Si Claude refuse une demande pour raison de sécurité, l'API essaie automatiquement un autre modèle.
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: "Tu aides Harry, un élève de 6e en France, à s'organiser et à réviser. Réponds en français simple et bienveillant.",
      messages: [{ role: "user", content }]
    });
    if (msg.stop_reason === "refusal") return res.status(422).json({ code: "refused" });
    const text = msg.content.filter(b => b.type === "text").map(b => b.text).join("").trim();
    if (!text) return res.status(502).json({ code: "empty_completion" });
    return res.status(200).json({ text });
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) return res.status(429).json({ code: "rate_limited" });
    if (e instanceof Anthropic.APIError) return res.status(502).json({ code: "upstream_error", message: e.message });
    return res.status(500).json({ code: "upstream_error" });
  }
}
