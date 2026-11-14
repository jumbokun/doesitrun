# Notes
- README only documents `pip install app-store-server-library` (PyPI); the task requires installing the clone, so setup.sh does `uv venv --python 3.12 /work/venv` + `uv pip install /work/app-store-server-library-python`. No dependency pins or code patches needed.
- `SignedDataVerifier([testCA.der], False, Environment.SANDBOX, "com.example", 1234)` fails with
  `VERIFICATION_FAILURE` on the bundled testNotification with default settings, because the test certs have no
  authority key identifiers. The repo's own tests (tests/util.py) get around this by setting
  `verifier._chain_verifier.enable_strict_checks = False`. Once that's set, the notification decodes as `NotificationTypeV2.TEST`. The README doesn't mention this.
- PromotionalOfferSignatureCreator works with testSigningKey.p8 as-is. The signature verifies with ECDSA-SHA256 against the key's public key, over the fields joined by U+2063.
