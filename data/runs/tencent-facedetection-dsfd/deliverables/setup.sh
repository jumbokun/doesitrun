#!/usr/bin/env bash
# Reproduce CPU-only setup of Tencent/FaceDetection-DSFD for `python demo.py`.
set -euo pipefail
cd /work
REPO=/work/FaceDetection-DSFD
VENV=/work/venv

if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/Tencent/FaceDetection-DSFD "$REPO"
fi

# Python env (README's torch 0.3.1 / py3.6 is unobtainable; use modern CPU torch)
[ -x "$VENV/bin/python" ] || uv venv -p 3.11 "$VENV"
uv pip install -p "$VENV/bin/python" --index-url https://download.pytorch.org/whl/cpu torch==2.5.1 torchvision==0.20.1
uv pip install -p "$VENV/bin/python" "numpy<2" opencv-python-headless matplotlib scipy pillow gdown

# Weights (Google Drive)
mkdir -p "$REPO/weights"
W="$REPO/weights/WIDERFace_DSFD_RES152.pth"
if [ ! -s "$W" ] || [ "$(stat -c %s "$W")" -lt 400000000 ]; then
  "$VENV/bin/gdown" 1WeXlNYsM6dMP3xQQELI-4gxhwKUQxc3- -O "$W"
fi

# face_ssd.py builds torchvision resnet152(pretrained=True) before loading the checkpoint; prefetch it
"$VENV/bin/python" -c "import torchvision; torchvision.models.resnet152(weights='IMAGENET1K_V1')"

# CPU / modern-PyTorch compatibility patch
cd "$REPO"
cat > /tmp/dsfd_cpu.patch <<'PATCH'
diff --git a/demo.py b/demo.py
index 69ecc6a..7a135b9 100755
--- a/demo.py
+++ b/demo.py
@@ -25,7 +25,6 @@ from data import WIDERFace_CLASSES as labelmap
 from data import (WIDERFace_ROOT, WIDERFaceAnnotationTransform,
                   WIDERFaceDetection)
 from face_ssd import build_ssd
-from widerface_val import bbox_vote
 
 plt.switch_backend('agg')
 
@@ -41,6 +40,7 @@ parser.add_argument('--cuda', default=True, type=bool,
 parser.add_argument('--img_root', default='./data/worlds-largest-selfie.jpg', help='Location of test images directory')
 parser.add_argument('--widerface_root', default=WIDERFace_ROOT, help='Location of WIDERFACE root directory')
 args = parser.parse_args()
+args.cuda = args.cuda and torch.cuda.is_available()
 
 if args.cuda and torch.cuda.is_available():
     torch.set_default_tensor_type('torch.cuda.FloatTensor')
@@ -49,6 +49,43 @@ else:
 if not os.path.exists(args.save_folder):
     os.mkdir(args.save_folder)
 
+def bbox_vote(det):
+    order = det[:, 4].ravel().argsort()[::-1]
+    det = det[order, :]
+    dets = np.zeros((0, 5),dtype=np.float32)
+    while det.shape[0] > 0:
+        # IOU
+        area = (det[:, 2] - det[:, 0] + 1) * (det[:, 3] - det[:, 1] + 1)
+        xx1 = np.maximum(det[0, 0], det[:, 0])
+        yy1 = np.maximum(det[0, 1], det[:, 1])
+        xx2 = np.minimum(det[0, 2], det[:, 2])
+        yy2 = np.minimum(det[0, 3], det[:, 3])
+        w = np.maximum(0.0, xx2 - xx1 + 1)
+        h = np.maximum(0.0, yy2 - yy1 + 1)
+        inter = w * h
+        o = inter / (area[0] + area[:] - inter)
+
+        # get needed merge det and delete these det
+        merge_index = np.where(o >= 0.3)[0]
+        det_accu = det[merge_index, :]
+        det = np.delete(det, merge_index, 0)
+
+        if merge_index.shape[0] <= 1:
+            continue
+        det_accu[:, 0:4] = det_accu[:, 0:4] * np.tile(det_accu[:, -1:], (1, 4))
+        max_score = np.max(det_accu[:, 4])
+        det_accu_sum = np.zeros((1, 5))
+        det_accu_sum[:, 0:4] = np.sum(det_accu[:, 0:4], axis=0) / np.sum(det_accu[:, -1:])
+        det_accu_sum[:, 4] = max_score
+        try:
+            dets = np.row_stack((dets, det_accu_sum))
+        except:
+            dets = det_accu_sum
+
+    dets = dets[0:750, :]
+    return dets
+
+
 def write_to_txt(f, det , event , im_name):
     f.write('{:s}\n'.format(event + '/' + im_name))
     f.write('{:d}\n'.format(det.shape[0]))
@@ -65,11 +102,12 @@ def infer(net , img , transform , thresh , cuda , shrink):
     if shrink != 1:
         img = cv2.resize(img, None, None, fx=shrink, fy=shrink, interpolation=cv2.INTER_LINEAR)
     x = torch.from_numpy(transform(img)[0]).permute(2, 0, 1)
-    x = Variable(x.unsqueeze(0) , volatile=True)
+    x = x.unsqueeze(0)
     if cuda:
         x = x.cuda()
     #print (shrink , x.shape)
-    y = net(x)      # forward pass
+    with torch.no_grad():
+        y = net(x)      # forward pass
     detections = y.data
     # scale each detection back up to the image
     scale = torch.Tensor([ img.shape[1]/shrink, img.shape[0]/shrink,
@@ -168,8 +206,9 @@ def test_oneimage():
     cfg = widerface_640
     num_classes = len(WIDERFace_CLASSES) + 1 # +1 background
     net = build_ssd('test', cfg['min_dim'], num_classes) # initialize SSD
-    net.load_state_dict(torch.load(args.trained_model))
-    net.cuda()
+    net.load_state_dict(torch.load(args.trained_model, map_location='cpu'))
+    if args.cuda:
+        net.cuda()
     net.eval()
     print('Finished loading model!')
 
diff --git a/face_ssd.py b/face_ssd.py
index 8321ea6..5884e65 100755
--- a/face_ssd.py
+++ b/face_ssd.py
@@ -188,7 +188,7 @@ class SSD(nn.Module):
     
     def init_priors(self ,cfg , min_size=cfg['min_sizes'], max_size=cfg['max_sizes']):
         priorbox = PriorBox(cfg , min_size, max_size)
-        prior = Variable( priorbox.forward() , volatile=True)
+        prior = priorbox.forward()
         return prior
         
     def forward(self, x):
diff --git a/layers/box_utils.py b/layers/box_utils.py
index e9f0669..f13c415 100755
--- a/layers/box_utils.py
+++ b/layers/box_utils.py
@@ -347,10 +347,10 @@ def nms(boxes, scores, overlap=0.5, top_k=200):
             break
         idx = idx[:-1]  # remove kept element from view
         # load bboxes of next highest vals
-        torch.index_select(x1, 0, idx, out=xx1)
-        torch.index_select(y1, 0, idx, out=yy1)
-        torch.index_select(x2, 0, idx, out=xx2)
-        torch.index_select(y2, 0, idx, out=yy2)
+        xx1 = torch.index_select(x1, 0, idx)
+        yy1 = torch.index_select(y1, 0, idx)
+        xx2 = torch.index_select(x2, 0, idx)
+        yy2 = torch.index_select(y2, 0, idx)
         # store element-wise max with next highest score
         xx1 = torch.clamp(xx1, min=x1[i])
         yy1 = torch.clamp(yy1, min=y1[i])
diff --git a/layers/functions/detection.py b/layers/functions/detection.py
index 4a6c146..ed193da 100755
--- a/layers/functions/detection.py
+++ b/layers/functions/detection.py
@@ -10,7 +10,7 @@ from data import widerface_640 as cfg
 from ..box_utils import center_size, decode, nms
 
 
-class Detect(Function):
+class Detect(object):
     '''At test time, Detect is the final layer of SSD.  Decode location preds,
     apply non-maximum suppression to location predictions based on conf
     scores and threshold to a top_k number of output predictions for both
@@ -27,6 +27,9 @@ class Detect(Function):
         self.conf_thresh = conf_thresh
         self.variance = cfg['variance']
 
+    def __call__(self, *args):
+        return self.forward(*args)
+
     def forward(self, loc_data, conf_data, prior_data, arm_loc_data=None , arm_conf_data=None):
         '''
         Args:
@@ -67,7 +70,7 @@ class Detect(Function):
            for cl in range(1, self.num_classes):
                 c_mask = conf_scores[cl].gt(self.conf_thresh)
                 scores = conf_scores[cl][c_mask]
-                if scores.dim() == 0:
+                if scores.numel() == 0:
                     continue
                 l_mask = c_mask.unsqueeze(1).expand_as(decoded_boxes)
                 boxes = decoded_boxes[l_mask].view(-1, 4)
diff --git a/layers/modules/__init__.py b/layers/modules/__init__.py
index 07bf120..20851d2 100755
--- a/layers/modules/__init__.py
+++ b/layers/modules/__init__.py
@@ -1,4 +1,3 @@
 from .l2norm import L2Norm
-from .multibox_loss import MultiBoxLoss, focalLoss
 
-__all__ = ['L2Norm', 'MultiBoxLoss' , 'focalLoss']
+__all__ = ['L2Norm']
PATCH
if git apply --check /tmp/dsfd_cpu.patch 2>/dev/null; then
  git apply /tmp/dsfd_cpu.patch
else
  git apply --reverse --check /tmp/dsfd_cpu.patch  # already applied
fi
echo "setup complete"
