set -e
source /work/env.sh
# cwd = repo root so the bundled test resources resolve; the script lives in $OUT, so sys.path[0] is $OUT
# and the installed appstoreserverlibrary is imported, not the source tree.
cd /work/app-store-server-library-python
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > "$OUT/t.py" <<'PY'
import base64, uuid
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ec import ECDSA
from cryptography.hazmat.primitives.hashes import SHA256
from appstoreserverlibrary.promotional_offer import PromotionalOfferSignatureCreator
from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier, VerificationException, VerificationStatus
from appstoreserverlibrary.models.Environment import Environment
from appstoreserverlibrary.models.NotificationTypeV2 import NotificationTypeV2
from appstoreserverlibrary.receipt_utility import ReceiptUtility

# 1) README "Promotional Offer Signature Creation"; payload layout from promotional_offer.py:32-38
key = open('tests/resources/certs/testSigningKey.p8', 'rb').read()
n = uuid.uuid4()
sig = PromotionalOfferSignatureCreator(key, 'KEYID', 'com.example').create_signature('prod', 'offer', 'user', n, 1698148900000)
payload = '⁣'.join(['com.example', 'KEYID', 'prod', 'offer', 'user', str(n), '1698148900000'])
pub = serialization.load_pem_private_key(key, password=None).public_key()
pub.verify(base64.b64decode(sig), payload.encode('utf-8'), ECDSA(SHA256()))
print("signature ok")

# 2) README "Verification Usage". The bundled test certs have no authority key identifiers, so the repo's
# own tests turn strict X509 checks off (tests/util.py:36-39); real Apple roots do not need this.
ca = open('tests/resources/certs/testCA.der', 'rb').read()
def verifier(env, bundle):
    v = SignedDataVerifier([ca], False, env, bundle, 1234)
    v._chain_verifier.enable_strict_checks = False
    return v
tok = open('tests/resources/mock_signed_data/testNotification').read().strip()
d = verifier(Environment.SANDBOX, 'com.example').verify_and_decode_notification(tok)
assert d.notificationType == NotificationTypeV2.TEST, d          # tests/test_payload_verification.py:34-38
print("notification decoded", d.notificationType)
tx = open('tests/resources/mock_signed_data/transactionInfo').read().strip()
t = verifier(Environment.SANDBOX, 'com.example').verify_and_decode_transaction(tx)
assert t.environment == Environment.SANDBOX and t.bundleId == 'com.example', t   # test_payload_verification.py:74-78
# the verifier must actually reject: wrong bundle id -> INVALID_APP_IDENTIFIER (test_payload_verification.py:80-85)
try:
    verifier(Environment.SANDBOX, 'com.examplex').verify_and_decode_transaction(tx)
    raise SystemExit("wrong bundle id was accepted")
except VerificationException as e:
    assert e.status == VerificationStatus.INVALID_APP_IDENTIFIER, e.status
print("transaction decoded")

# 3) README "Receipt Usage": ReceiptUtility on the bundled Xcode receipt (tests/test_receipt_utility.py:25-31)
r = open('tests/resources/xcode/xcode-app-receipt-with-transaction').read()
assert ReceiptUtility().extract_transaction_id_from_app_receipt(r) == "0"
print("receipt ok")
PY
timeout 300 python "$OUT/t.py" | tee "$OUT/out.txt"
grep -q "signature ok" "$OUT/out.txt"
grep -q "notification decoded" "$OUT/out.txt"
grep -q "transaction decoded" "$OUT/out.txt"
grep -q "receipt ok" "$OUT/out.txt"
echo "ORACLE PASS"
