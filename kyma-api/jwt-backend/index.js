const express = require("express");
const jwt = require("jsonwebtoken");

let PORT = process.env.PORT || 5000;

const app = express();
app.use(express.json());
app.get("/sign", sign);

function sign(req, res, next) {
  const privateKeyId = process.env.JWT_BACKEND_KEY_ID;
  const clientEmail = process.env.JWT_BACKEND_CLIENT_EMAIL;
  let privateKey = process.env.JWT_BACKEND_PRIVATE_KEY;

  if (!privateKey || !clientEmail || !privateKeyId) {
    res.status(500).send("Missing values from environment variables");
  } else {
    privateKey = privateKey.replace(/\\n/gm, "\n");

    const payload = {
      iss: clientEmail,
      sub: clientEmail,
      aud: req.body.endpoint,
    };

    const signed = jwt.sign(payload, privateKey, {
      algorithm: "RS256",
      expiresIn: 3600,
      keyid: privateKeyId,
    });

    res.status(200).send(signed);
  }
}

app.listen(PORT, () => {
  console.log(`Server is up and running on ${PORT} ...`);
});
