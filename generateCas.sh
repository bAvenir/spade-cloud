#!/bin/bash

# Default values
OUTPUT_DIR="certs"
PASSWORD_FILE="$OUTPUT_DIR/passwords.txt"
ROOT_CA_NAME="rootCA"
SUB_CA_NAME="subCA"
KEY_SIZE=4096
ROOT_VALIDITY=3650   # 10 years
SUB_VALIDITY=1825    # 5 years
ENCRYPTION_ALG=aes256

# Create output directory
mkdir -p "$OUTPUT_DIR"

# remove old files if exist
rm "$OUTPUT_DIR/$ROOT_CA_NAME.key" "$OUTPUT_DIR/$SUB_CA_NAME.key" "$OUTPUT_DIR/$SUB_CA_NAME.csr" "$OUTPUT_DIR/$ROOT_CA_NAME.crt" "$OUTPUT_DIR/$SUB_CA_NAME.crt" "$OUTPUT_DIR/$ROOT_CA_NAME.srl" "$OUTPUT_DIR/$ROOT_CA_NAME.p12" "$OUTPUT_DIR/$SUB_CA_NAME.p12" 2> /dev/null

#generate random passwords
rootPass=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')
subPass=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')

# Clear password file
> "$PASSWORD_FILE"
# store passwords in password file
echo "Root CA: $rootPass" >> "$PASSWORD_FILE"
echo "SUB CA: $subPass" >> "$PASSWORD_FILE"

# Generate Root CA
echo "Generating Root CA..."
openssl genpkey -$ENCRYPTION_ALG -algorithm RSA -out "$OUTPUT_DIR/$ROOT_CA_NAME.key" -pkeyopt rsa_keygen_bits:$KEY_SIZE -pass pass:"$rootPass"
openssl req -x509 -new -key "$OUTPUT_DIR/$ROOT_CA_NAME.key" -sha256 -days $ROOT_VALIDITY -out "$OUTPUT_DIR/$ROOT_CA_NAME.crt" -passin pass:"$rootPass" -subj "/CN=$ROOT_CA_NAME"

# Generate Subordinate CA
echo "Generating Subordinate CA..."
openssl genpkey -$ENCRYPTION_ALG -algorithm RSA -out "$OUTPUT_DIR/$SUB_CA_NAME.key" -pkeyopt rsa_keygen_bits:$KEY_SIZE -pass pass:"$subPass"
openssl req -new -key "$OUTPUT_DIR/$SUB_CA_NAME.key" -out "$OUTPUT_DIR/$SUB_CA_NAME.csr" -passin pass:"$subPass" -subj "/CN=$SUB_CA_NAME"
openssl x509 -req -in "$OUTPUT_DIR/$SUB_CA_NAME.csr" -CA "$OUTPUT_DIR/$ROOT_CA_NAME.crt" -CAkey "$OUTPUT_DIR/$ROOT_CA_NAME.key" -CAcreateserial -out "$OUTPUT_DIR/$SUB_CA_NAME.crt" -days $SUB_VALIDITY -sha256 -passin pass:"$rootPass"

# Store keys in PKCS#12 format
openssl pkcs12 -export -out "$OUTPUT_DIR/$ROOT_CA_NAME.p12" -inkey "$OUTPUT_DIR/$ROOT_CA_NAME.key" -in "$OUTPUT_DIR/$ROOT_CA_NAME.crt" -passin pass:"$rootPass" -passout pass:"$rootPass"

openssl pkcs12 -export -out "$OUTPUT_DIR/$SUB_CA_NAME.p12" -inkey "$OUTPUT_DIR/$SUB_CA_NAME.key" -in "$OUTPUT_DIR/$SUB_CA_NAME.crt" -passin pass:"$subPass" -passout pass:"$subPass"

# rm  key and csr files
rm "$OUTPUT_DIR/$ROOT_CA_NAME.key" "$OUTPUT_DIR/$SUB_CA_NAME.key" "$OUTPUT_DIR/$SUB_CA_NAME.csr" "$OUTPUT_DIR/$ROOT_CA_NAME.crt" "$OUTPUT_DIR/$SUB_CA_NAME.crt" "$OUTPUT_DIR/$ROOT_CA_NAME.srl"
echo "Root CA and Subordinate CA generated successfully in $OUTPUT_DIR. Passwords saved in $PASSWORD_FILE."
echo "Copy the subCA password from $PASSWORD_FILE into CA_SUBCA_KEY in your .env file."
echo "Do not forget to remove the password file after importing the certificates in your application."
