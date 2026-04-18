require("dotenv").config();

const express = require("express");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const twilio = require("twilio");

const app = express();
app.use(cors());
app.use(express.json());

// IMPORTANT : Utiliser 0.0.0.0 pour que le serveur soit visible hors du localhost du Codespace
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; 
const JWT_SECRET = process.env.JWT_SECRET || "art_euro_secret_2026";

// Initialisation Twilio avec vérification des variables d'environnement
const client = (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) 
    ? twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN)
    : null;

function normalizePhone(phone) {
  // Nettoyage pour s'assurer que le format international passe bien
  return String(phone || "").replace(/[^\d+]/g, "").trim();
}

app.get("/health", (_, res) => {
  res.json({ 
    ok: true, 
    status: "online",
    message: "Serveur Aʀᴛㅤᴇᴜʀᴏㅤ❕ opérationnel",
    timestamp: new Date().toISOString()
  });
});

app.post("/auth/send-code", async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);

    if (!phone) {
      return res.status(400).json({ ok: false, message: "Numéro requis" });
    }

    // Mode "Développement" si Twilio n'est pas configuré
    if (!client || !process.env.TWILIO_VERIFY_SERVICE_SID) {
        console.log(`[DEV MODE] Code OTP demandé pour : ${phone}. (Code simulé: 123456)`);
        return res.json({ ok: true, message: "Mode DEV: Utilisez 123456", devMode: true });
    }

    await client.verify.v2
      .services(process.env.TWILIO_VERIFY_SERVICE_SID)
      .verifications.create({ to: phone, channel: "sms" });

    return res.json({ ok: true, message: "Code envoyé" });
  } catch (error) {
    console.error("Erreur Twilio Send:", error.message);
    return res.status(500).json({ ok: false, message: "Erreur lors de l'envoi" });
  }
});

app.post("/auth/verify-code", async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    const code = String(req.body.code || "").trim();

    // Simulation pour le mode développement
    if ((!client || !process.env.TWILIO_VERIFY_SERVICE_SID) && code === "123456") {
        const token = jwt.sign({ phone }, JWT_SECRET, { expiresIn: "30d" });
        return res.json({ ok: true, token, user: { phone } });
    }

    const check = await client.verify.v2
      .services(process.env.TWILIO_VERIFY_SERVICE_SID)
      .verificationChecks.create({ to: phone, code });

    if (check.status !== "approved") {
      return res.status(401).json({ ok: false, message: "Code invalide" });
    }

    const token = jwt.sign({ phone }, JWT_SECRET, { expiresIn: "30d" });

    return res.json({ ok: true, token, user: { phone } });
  } catch (error) {
    return res.status(500).json({ ok: false, message: "Erreur de validation" });
  }
});

app.listen(PORT, HOST, () => {
  console.log(`
  🚀 Serveur démarré !
  Local: http://localhost:${PORT}
  Network: http://${HOST}:${PORT}
  `);
});
