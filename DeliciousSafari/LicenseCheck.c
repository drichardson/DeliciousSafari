#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <openssl/bio.h>

#include <string.h>
#include <stdint.h>

#include "LicenseCheck.h"

LICENSE_CHECK_STATUS DXCheckLicense(const char* userLicenseData,
									const char* base64EncryptedLicenseKey,
									const char* publicKey)
{
	LICENSE_CHECK_STATUS result = LICENSE_BAD;
	
	BIO *bio_in, *bio_out, *bio_pub_key;
	bio_in = bio_out = bio_pub_key = NULL;
	
	RSA* rsa_key = 0;
	
	if(userLicenseData == NULL || base64EncryptedLicenseKey == NULL)
		goto bail;

	// SHA1 the userLicenseData. We will compare this after we
	// unencrypt base64LicenseKey later.
	uint8_t md[SHA_DIGEST_LENGTH];
	SHA1((uint8_t*)userLicenseData, strlen(userLicenseData), md);
	
	// Base64 decode the message.	
	BIO *b64 = BIO_new(BIO_f_base64()); // Build a filter to process base 64 encoded data.
	if(b64 == NULL)
		goto bail;
	
	// Create a memory based BIO for input. Cast away const - this is okay because
	// we are only using this as input BIO (i.e. we are not going to call a write function on it).
	bio_in = BIO_new_mem_buf((void*)base64EncryptedLicenseKey, strlen(base64EncryptedLicenseKey));
	if(bio_in == NULL)
		goto bail;
	
	bio_in = BIO_push(b64, bio_in); // Chain the input BIO to the base 64 filter.
	if(bio_in == NULL)
		goto bail;
	
	bio_out = BIO_new(BIO_s_mem()); // Create a memory based BIO for output.
	if(bio_out == NULL)
		goto bail;

	char inbuf[1024];
	int inlen;
	while((inlen = BIO_read(bio_in, inbuf, sizeof(inbuf))) > 0)
		BIO_write(bio_out, inbuf, inlen);
	
	// Get a pointer to the data that has been base 64 decoded.
	void *encryptedLicenseKey = NULL;
	long encryptedLicenseKeySize = BIO_get_mem_data(bio_out, &encryptedLicenseKey);
	
	// Read the public key from memory.
	bio_pub_key = BIO_new_mem_buf((char*)publicKey, strlen(publicKey));
	if(bio_pub_key == NULL)
		goto bail;
	
	if(PEM_read_bio_RSA_PUBKEY(bio_pub_key, &rsa_key, NULL, NULL))
	{
		int dst_size = RSA_size(rsa_key);
		uint8_t* dst = malloc(dst_size);
		RSA_public_decrypt(encryptedLicenseKeySize, encryptedLicenseKey,
						   dst, rsa_key, RSA_PKCS1_PADDING);
		
		if(memcmp(dst, md, SHA_DIGEST_LENGTH) == 0)
			result = LICENSE_OK;
		
		free(dst);
	}
	
bail:
	if(bio_in)
		BIO_free_all(bio_in); // Free the entire input chain.
	if(bio_out)
		BIO_free(bio_out);
	if(bio_pub_key)
		BIO_free(bio_pub_key);
	if(rsa_key)
		RSA_free(rsa_key);
	
	return result;
}
