# DETR CPU hub inference – notes

Nothing actually broke. `torch.hub.load(..., 'detr_resnet50', pretrained=True)` works unmodified
with current torch 2.8.0 / torchvision 0.23.0 (CPU wheels) on Python 3.12. The only output is deprecation
warnings about torchvision's `pretrained=` argument.

What I did differently from the README:
- The README's install path is conda plus the full `requirements.txt`, which includes cocoapi/panopticapi
  git builds, onnx and submitit. I used a uv venv at /work/venv instead and installed only what
  hub inference needs: CPU torch/torchvision, scipy, packaging and pillow.
- I loaded the hub model from the local clone (`source='local'`) rather than `facebookresearch/detr:main`.
- setup.sh pre-downloads the DETR checkpoint and the ImageNet ResNet-50 weights (the backbone
  constructor still fetches the ResNet-50 weights) into TORCH_HOME=/work/torch_home. It also downloads
  COCO val image 39769 (the cats photo) to /work/data/cats.jpg.

Result: logits are (1,100,92) and boxes (1,100,4). Detections above 0.9 are 2 cats (0.999),
2 remotes (0.998, 0.996) and the couch (0.995).
