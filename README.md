# _sketchPro_: Identifying top-k items based on probabilistic update

## Overview
_sketchPro_ is a novel sketch-based solution with a probabilistic update scheme, which can identify top-k items precisely with low memory consumption.

sketchPro is a sketch-based method that does not insert the items into sketch (i.e., Chief) directly when hash collision occurs, instead, it calculates the probability based on the recorded item size and the frequency of hash collisions. Besides, sketchPro uses a one-dimensional array (i.e., Auxiliary) to preserve the large items that are accidentally evicted from Chief. Through dynamically adjusting the probability, sketchPro can mitigate the effect of hash collisions, so large items have a greater chance of retention. Therefore, sketchPro can achieve high accuracy while reducing memory consumption.

The code is written by P4_16 running in programmable software switches (i.e., BMv2).



## Citations

If you find this code useful in your research, please cite the following papers:

* Keke Zheng, Mai Zhang, Mimi Qian, WaiMing Lau and Lin Cui, "_sketchPro_: Identifying top-𝑘 items based on probabilistic update", _IEEE Transactions on Network and Service Management_, 2025 (Under review).
