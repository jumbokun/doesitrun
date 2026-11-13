set -e
source /work/env.sh
cd /work/app-store-server-library-python
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'PY'
import base64, uuid, sys
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ec import ECDSA
from cryptography.hazmat.primitives.hashes import SHA256
from appstoreserverlibrary.promotional_offer import PromotionalOfferSignatureCreator
from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier
from appstoreserverlibrary.models.Environment import Environment
from appstoreserverlibrary.models.NotificationHistoryRequest import NotificationTypeV2
from appstoreserverlibrary.receipt_utility import ReceiptUtility
key = open('tests/resources/certs/testSigningKey.p8','rb').read()
n = uuid.uuid4()
sig = PromotionalOfferSignatureCreator(key,'KEYID','com.example').create_signature('prod','offer','user',n,1698148900000)
payload = '⁣'.join(['com.example','KEYID','prod','offer','user',str(n),'1698148900000'])
pub = serialization.load_pem_private_key(key, password=None).public_key()
pub.verify(base64.b64decode(sig), payload.encode(), ECDSA(SHA256()))
print("signature ok")
ca = open('tests/resources/certs/testCA.der','rb').read()
v = SignedDataVerifier([ca], False, Environment.SANDBOX, 'com.example', 1234)
tok = open('tests/resources/mock_signed_data/testNotification').read().strip()
d = v.verify_and_decode_notification(tok)
assert d.notificationType == NotificationTypeV2.TEST, d
print("notification decoded", d.notificationType)
PY
timeout 300 python $OUT/t.py | tee $OUT/out.txt
grep -q "signature ok" $OUT/out.txt
grep -q "notification decoded" $OUT/out.txt
echo "ORACLE PASS"
