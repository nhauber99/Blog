---
title: "Local Linear Regression Extrapolation for Convolutions"
date: 2023-08-26
redirect_to:
  - https://www.photometric.io/blog/?p=35
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
When applying high-pass filters to images, such as height maps, a common issue is edge artifacts. These are caused by having to extrapolate pixels. 

Even Photoshop suffers from the same issue as shown below:

Input Image: Simple Linear Gradient
<img src="/Blog/assets/convolution/ps_input.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />

High-Pass Filtered Image with Enhanced Contrast
<img src="/Blog/assets/convolution/ps_output.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />


Ideally, the high-pass filter should produce a uniform output. However, the edge pixels show a gradient. This is caused by having to extrapolate pixels outside the image when convolving it, which is often achieved using replicate or reflection padding.
This would be a plot of the pixel intensities for the same example:

<img src="/Blog/assets/convolution/linear_no_extrapolation.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />


## The Solution
I've developed a method to solve this issue. A naive implementation for 1 dimension would look like this:
1. Calculate the slope $$ b $$ and intercept $$ a $$ of the neighborhood of each pixel weighted by the convolution kernel using linear regression
2. Apply the kernel to the image and extrapolate missing samples by $$ a + b*d_{ij} $$. Here $$d_{ij}$$ is the distance from the current pixel to the pixel being extrapolated.

This means that pixels outside of the boundary are extrapolated using the slope of the local neighborhood of each pixel. The only challenge remaining is to find an algorithm which can do this in a single pass, otherwise the memory accesses would need to be doubled or tripled, which would significantly affect the performance of a GPU implementation. Luckily, this is possible.

Finding the local slope requires calculating a weighted linear regression for the neighborhood of each pixel. I got the formulas for single-pass weighted linear regression from ChatGPT. Unfortunately, I could not find the original reference for these formulas. However, I've compared it to the Matlab implementation of weighted linear regression and the results match up perfectly - that's basically a valid proof of correctness for a software developer. 

This is the formula I used for calculating the slope, it needs the implementation to maintain 5 running sums:

1. Calculate weighted sums:

	$$ S_w = \sum{w_i} $$\\
	$$ S_x = \sum{w_i \cdot x_i} $$\\
	$$ S_y = \sum{w_i \cdot y_i} $$\\
	$$ S_{xx} = \sum{w_i \cdot x_i^2} $$\\
	$$ S_{xy} = \sum{w_i \cdot x_i \cdot y_i} $$

2. Compute the slope $$ b $$ and intercept $$ a $$ using:

$$ b = \frac{S_w \cdot S_{xy} - S_x \cdot S_y}{S_w \cdot S_{xx} - S_x^2} $$

$$ a = \frac{S_y - b \cdot S_x}{S_w} $$

## Results

With the extrapolation applied to the same linear gradient, the blurred version perfectly matches the original and the difference is zero:

<img src="/Blog/assets/convolution/linear_extrapolation.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />

Here is a more complex example with random noise added to a sine wave:

<img src="/Blog/assets/convolution/sine_extrapolation.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />

The same example without extrapolation yields the following result:

<img src="/Blog/assets/convolution/sine_no_extrapolation.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 100%" />

This improvement is particularly noticeable in high-pass filtered data.

The Matlab implementation of this method in one dimension can be downloaded [here](/Blog/assets/convolution/slopeExtrapolation.m).