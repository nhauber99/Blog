---
title: "Fast Normal Map Integration"
date: 2023-01-17
---

<script type="text/x-mathjax-config">
MathJax.Hub.Config({
  tex2jax: {
    inlineMath: [['$','$'], ['\\(','\\)']],
    processEscapes: true
  }
});
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>

## Introduction
In my [last post](https://nhauber99.github.io/Blog/2023/01/08/MaterialScanner.html) I gave a somewhat brief overview of my material scanner prototype. One of the topics was obtaining a normal map by applying the photometric stereo technique on images representing the diffuse reflection of a surface. Today we'll be looking at how to transform this normal map into a height map and the challenges associated with it.

## Two dimensions
For simplicity, let's assume our problem is two dimensional. The illustration below shows a surface defined by the function $h(x)$ as well as the normal vector $\vec{n}$, the gradient $\Delta h$ and the height $h$ of several points. 
<img src="/Blog/assets/normal_gradient_height.jpg" style="width: 100%" />

When using photometric stereo we only get the normal vector for every point we measure (in our case every pixel of the camera). We can easily calculate the gradient of such a normal vector as $-n_y/n_x$. If we then integrate all gradients represented by $\Delta h$, we get the height $h$ itself. In the two dimensional case this is quite trivial. When adding another dimension we get a problem...

## Three dimensions

To illustrate the problem, let's look at the Penrose stairs (aka. impossible staircase). These stairs just go up in a continuous loop. Constructing a normal map doing the same is rather easy as seen in the image next to the stairs. The trouble begins when we want a height map too.

<img src="/Blog/assets/penrose_stairs.png" style="width: 48%" />
<img src="/Blog/assets/penrose_normal.jpg" style="width: 48%" />

Of course it is unlikely that we will scan an impossible staircase, but when doing photometric stereo we will almost certainly end up with an impossible normal map. This is caused by noise, interreflection, shadows, subsurface scattering, numerical errors and so on.

So how do we get a height map from an impossible normal map? We just try to find a height map that fits the normals as good as possible. Easier said than done.

There are plenty of studies that try to solve this problem. My work is based on two of them. The first one can be found [here](http://hvrl.ics.keio.ac.jp/paper/pdf/international_Conference/2008/ICAT2008_vincent.pdf) and another one which builds upon this algorithm and speeds it up can be found [here](https://hal.science/hal-00733377/file/nozick_EAM_2010.pdf). What's great about the method presented in these studies is that it's really simple, intuitive and FAST.

The general idea is that we use an iterative solver, which just calculates the height of one pixel based on the heights of its neighbors calculated by the previous iteration. So the height $h$ of a pixel $i,j$ and iteration $k$ is calculated by:

$$h_{i,j}^{k}=\frac{1}{4}((h_{i+1,j}^{k-1}-\Delta x_{i,j})+(h_{i-1,j}^{k-1}+\Delta x_{i-1,j})+(h_{i,j+1}^{k-1}-\Delta y_{i,j})+(h_{i,j-1}^{k-1}+\Delta y_{i,j-1}))$$

But this has one problem: it takes a huge amount of iterations for larger structures to form in the height map. Below is the result of integrating a 512x512 normal map using 100 iterations. 

<img src="/Blog/assets/sphere_normals.jpg" style="width: 48%" />
<img src="/Blog/assets/height_nonpyramidal.jpg" style="width: 48%" />
*left: normal map, right: height map*

<img src="/Blog/assets/height_nonpyramidal_3d.jpg" style="width: 96.5%" />
*render of height map*


But there is an easy fix: scale down the normal map to something like 16x16 pixels, integrate this smaller map to obtain a small height map, then scale up this height map and use it as a starting point for integrating a 32x32 normal map. Repeat these steps until the wanted resolution is reached.

While this caused the runtime to quadrouple for this example, the result turned out to be a lot better:
<img src="/Blog/assets/height_pyramidal_3d.jpg" style="width: 100%" />

And sure, this method may not be as mathematically accurate as others, but it is able to integrate a 16MP normal map in under a second on an RTX 3070. And given the inaccurate nature of normals obtained by photometric stereo, using more sophisticated algorithms may not even make a noticable difference.

## More details on the implementation

As I mentioned before, my method is only based on the mentioned studies, but is not a 1:1 implementation. For one I've changed how the height samples are positioned, which is illustrated in the image below. The gradients / normals are positioned in a grid and the height samples are inbetween those gradients. This means that the height map is more of a checkerboard pattern in an image twice the size as the normal map. The missing cells are interpolated from their neighboring cells in the end.

<img src="/Blog/assets/gradient_height_pattern.jpg" style="width: 100%" />

This means that during the calculations half the cells of the height map would be empty. Luckily there is a good way to make use of this, which is extending the iterative algorithm to also use momentum, a method typically used in machine learning and gradient descent. More information on momentum can be found [here](https://optimization.cbe.cornell.edu/index.php?title=Momentum). Implementing this method further decreases the necessary iterations.

<script async src="//static.getclicky.com/101393239.js"></script>