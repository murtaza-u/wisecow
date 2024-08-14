# Cow wisdom web server

## Generating self-signed certificates

```
cd certs

# generate CA cert and private key
cfssl genkey -initca csr/ca-csr.json | cfssljson -bare ca

# generate wisecow tls cert and private key
cfssl gencert -ca ca.pem -ca-key ca-key.pem csr/wisecow.json | cfssljson -bare wisecow
```
