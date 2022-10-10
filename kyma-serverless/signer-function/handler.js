const jwt = require("jsonwebtoken");

module.exports = {
  main: function (event, context) {
    const privateKeyId = process.env.JWT_BACKEND_KEY_ID;
    const clientEmail = process.env.JWT_BACKEND_CLIENT_EMAIL;
    let privateKey = process.env.JWT_BACKEND_PRIVATE_KEY;

    if (!privateKey || !clientEmail || !privateKeyId) {
      event.extensions.response.status(500);
      return;
    } else {
      privateKey = privateKey.replace(/\\n/gm, "\n");

      const payload = {
        iss: clientEmail,
        sub: clientEmail,
        aud: event.extensions.request.query.endpoint,
      };

      const signed = jwt.sign(payload, privateKey, {
        algorithm: "RS256",
        expiresIn: 3600,
        keyid: privateKeyId,
      });

      event.extensions.response.status(200).send(signed);
    }
  },
};
