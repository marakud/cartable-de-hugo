// Donne à la page l'adresse Supabase et la clé publique (anon). La clé anon est faite pour être publique :
// la sécurité vient des règles RLS de supabase/schema.sql.
export default function handler(req, res) {
  res.setHeader("cache-control", "no-store");
  res.status(200).json({
    supabaseUrl: process.env.SUPABASE_URL || "",
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY || "",
    // Le compte unique du cartable : la page ne demande que son mot de passe (le « code secret »).
    appEmail: process.env.APP_EMAIL || ""
  });
}
