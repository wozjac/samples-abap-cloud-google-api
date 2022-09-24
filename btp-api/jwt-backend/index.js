const express = require("express");
const jwt = require("jsonwebtoken");
const passport = require("passport");
const { JWTStrategy } = require("@sap/xssec");
const xsenv = require("@sap/xsenv");

let PORT = process.env.PORT || 5000;
passport.use(new JWTStrategy(xsenv.getServices({ uaa: { tag: "xsuaa" } }).uaa));

const app = express();
app.use(express.json());
app.use(passport.initialize());
app.use(passport.authenticate("JWT", { session: false }));
app.get("/sign", sign);

function sign(req, res, next) {
  const privateKeyId = process.env.JWT_BACKEND_KEY_ID;
  const clientEmail = process.env.JWT_BACKEND_CLIENT_EMAIL;
  const privateKey = process.env.JWT_BACKEND_PRIVATE_KEY.replace(/\\n/gm, "\n");

  if (!privateKey || !clientEmail || !privateKeyId) {
    console.error(error);
    res.status(500).send("Missing values from environment variables");
  } else {
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
