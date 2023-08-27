---
title: "Fast Slope Based Extrapolation for Convolutions"
date: 2023-08-26
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

## The Problem 
When applying high-pass filters to images, such as height maps, a common issue is edge artifacts. These are caused by having to extrapolate pixels and finding a good solution to this is actually not that trivial. 

Even Photoshop suffers from the same issue as shown below:

Input Image: Simple Linear Gradient
<img src="/Blog/assets/convolution/ps_input.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />

High-Pass Filtered Image with Enhanced Contrast
<img src="/Blog/assets/convolution/ps_output.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />


Ideally, the high-pass filter should produce a uniform output. However, the edge pixels show a gradient. This is caused by having to extrapolate pixels outside the image when convolving it, which is often done with a replicate or reflection padding.
This would be a plot of the pixel intensities for the same example:

<img src="/Blog/assets/convolution/linear_no_extrapolation.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />


## The Solution
I've developed a method to solve this issue. A naive implementation for 1 dimension would look like this:
1. Calculate the slope $$s$$ of the neighborhood of each pixel weighted by the convolution kernel
2. Apply the kernel to the image and extrapolate missing samples by $$ v_i + d_{ij} * s $$. Here $$v_i$$ is the value of the current pixel and $$d_{ij}$$ is the distance to the pixel being extrapolated.

This means that pixels outside of the boundary are extrapolated using the slope of the local neighborhood of each pixel. The only challenge remaining is to find an algorithm which can do this in a single pass, otherwise the memory accesses would need to be doubled or tripled, which would significantly affect the performance of a GPU implementation. Luckily, this is possible.

Firstly, finding the local slope requires calculating a weighted linear regression for the neighborhood of each pixel. I got the algorithm for the single pass weighted linear regression from ChatGPT and sadly can't find the where it supposedly got this from. However, I've compared it to the Matlab implementation of weighted linear regression and the results match up perfectly.

This is the formula I used for calculating the slope, it needs the implementation to maintain 5 running sums:

$$ s = \frac{\sum w_ix_iy_i-\frac{(\sum w_ix_i)(\sum w_iy_i)}{\sum w_i}}{\sum w_ix_i^2-\frac{(\sum w_ix_i)^2}{\sum w_i}} $$

With the extrapolation applied to the same linear gradient, the blurred version is a perfect match of the original and the difference is zero:

<img src="/Blog/assets/convolution/linear_extrapolation.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />

Here is a more complex example with random noise added to a sine wave:

<img src="/Blog/assets/convolution/sine_extrapolation.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />

The same convolution without extrapolation would result in this:

<img src="/Blog/assets/convolution/sine_no_extrapolation.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />

This improvement is particularly noticeable in high-pass filtered data.

The Matlab implementation of this method in one dimension can be downloaded [here](/Blog/assets/convolution/slopeExtrapolation.m).