#!/bin/bash

# Define directories
CERT_DIR="/sslcerts"  # Change this to your desired output directory
CA_CERT="$CERT_DIR/ca.crt"
CA_KEY="$CERT_DIR/ca.key"

# Function to generate a self-signed CA certificate
generate_ca () {
  ca_subject="/C=TN/ST=YourState/L=YourCity/O=YourOrganization/CN=HRMS Local CA/OU=OU"
  
  # Check if CA files already exist
  if [ ! -f "$CA_CERT" -o ! -f "$CA_KEY" ]; then
  cat >$CERT_DIR/ca.conf <<EOL
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]
C=US
ST=Your State
L=Your Locality
O=Your Organization
CN=hrmsbe.local
OU=OU

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = hrmsbe.local
DNS.2 = *.hrmsbe.local
EOL

cat >$CERT_DIR/ca.ext <<EOL
basicConstraints        = critical, CA:TRUE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, cRLSign, digitalSignature, keyCertSign

subjectAltName = @alt_names

[alt_names]
DNS.1 = hrmsbe.local
EOL
    # Generate CA private key
    openssl genrsa -out "$CA_KEY" 4096

    # Generate CA certificate signing request (CSR)
    openssl req -new -key "$CA_KEY" -subj "$ca_subject" -out ca.csr -config $CERT_DIR/ca.conf

    # Sign the CSR (self-signed)
    openssl x509 -req -in ca.csr -signkey "$CA_KEY" -out "$CA_CERT" -days 3650 -sha256 -extfile $CERT_DIR/ca.ext


    # Clean up CSR
    rm -f ca.csr

    echo "Generated Self-Signed CA Certificate"
  fi
}

# Function to generate certificate for a domain
generate_cert () {
	domain="$1"
	short_domain=$domain
	if [[ "${short_domain:0:2}" == "*." ]]; then
	  short_domain="wildcard${short_domain:1}"
	fi
	key_file="$CERT_DIR/$short_domain.key"
	crt_file="$CERT_DIR/$short_domain.crt"
	subject="/C=TN/ST=YourState/L=YourCity/O=YourOrganization/CN=$domain/OU=OU"
	
	# Check if certificate already exists
	if [ ! -f "$crt_file" ]; then
  cat >$CERT_DIR/$short_domain-v3.conf <<EOL
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]
C=TN
ST=YourState
L=YourCity
O=YourOrganization
CN=$domain
OU=OU

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $short_domain
DNS.2 = *.$short_domain
EOL

cat >$CERT_DIR/$short_domain-v3.ext <<EOL
basicConstraints        = critical, CA:FALSE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, digitalSignature, keyEncipherment, keyAgreement 
extendedKeyUsage        = critical, serverAuth, clientAuth

subjectAltName = @alt_names

[alt_names]
DNS.1 = $short_domain
DNS.2 = *.$short_domain
EOL
		# Generate private key
		openssl genrsa -out "$key_file" 2048

		# Generate certificate signing request (CSR)
		openssl req -new -key "$key_file" -subj "$subject" -out "$short_domain.csr" -config $CERT_DIR/$short_domain-v3.conf

		# Sign the CSR with CA
		openssl x509 -req -in "$short_domain.csr" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "$crt_file" -days 3650 -sha256 -extfile $CERT_DIR/$short_domain-v3.ext

		# Clean up CSR
		rm -f "$short_domain.csr"
	fi
}

# Generate or use existing CA certificate
generate_ca

# Loop through domain list
for domain in "hrmsbe.local" "*.hrms.local"; do
  generate_cert "$domain"
done

# Set permissions
chown -R www-data:www-data "$CERT_DIR"
chmod -R 600 "$CERT_DIR"/*.key

echo "SSL certificates generated and permissions set!"
