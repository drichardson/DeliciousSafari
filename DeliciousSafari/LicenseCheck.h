#ifndef _LICENSECHECK_H_
#define _LICENSECHECK_H_

typedef enum {
	LICENSE_OK,
	LICENSE_BAD
} LICENSE_CHECK_STATUS;

// Example:
// userLicenseData = "user@example.com"
// base64LicenseKey = "dR/F6Y30l+dyB9XVwgVXTgnxmp9EusEnPkgXuIabTw==\n"
// publicKey // public key stored in PEM format.
//   "-----BEGIN PUBLIC KEY-----\n"
//   "aZswdQYJKoZIhvcNAQEBBQADKgxwJw3gAM1ggo5+mB3D1H92vaMuUM8FjieUFo0l\n"
//   "Que2cnaoIjf78wEAAQ==\n"
//   "-----END PUBLIC KEY-----\n";
// The base64EncryptedLicenseKey must be PEM format. For PEM, the newlines
// are important because there must be exactly 64 characters per line.
LICENSE_CHECK_STATUS DXCheckLicense(const char* userLicenseData,
									const char* base64EncryptedLicenseKey,
									const char* publicKey);

#endif
