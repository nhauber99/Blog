---
title: "Material Scanner"
date: 2023-01-08
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
Hi! I'm Niklas and for the last one and a half years I've been developing my material scanner in my spare time. As this is my first blog post about this topic, here is a quick rundown of what happened in that time:

My current version is far from the first. There was a simple first prototype (results can be found [here](https://www.reddit.com/r/photogrammetry/comments/n1ejxm/first_result_of_my_custom_texture_scanning/)), which lasted a day before ditching it for a great new plan. It turned out that this great new plan wasn't as great as I had anticipated, so off I went building the third version which can be found [here](https://www.reddit.com/r/photogrammetry/comments/ojph2p/capture_process_of_my_pbr_material_scanner/). Back then I was still using my DSLR and the sound of the shutter synchronized with the LEDs was fairly satisfying. This got me my first good results and served well as a proof of concept. 

Then I might have strayed from my path a bit by working on other interesting projects which I told myself were absolutely necessary for this scanner, like building a [CNC router](https://www.reddit.com/r/hobbycnc/comments/tnp28a/printnc_build_in_my_small_apartment_the_enclosure/) and a [spectrometer](https://www.reddit.com/r/Optics/comments/z9zxde/my_cheap_diy_spectrometer_sharpest_peak_has_a/). In hindsight I could have just used the Datron CNC of the local maker space, but that didn't have the same appeal as building a way worse version of it myself.

At this point I was rather happy with the general design and it was time to make it into a more polished prototype. So after building a CNC, building a spectrometer, machining/3D printing all necessary parts, designing custom PCBs and finally putting it all together, I ended up with the current version.

## Why?
Now that you know how I got here, I should probably explain why I'm doing all of this:

The goal of this scanner is to be able to calculate the visual properties of a material. These properties then allow me to render images of the same material under different lighting conditions. So a typical application would be computer games for example. 

To better understand this you might want to look up the [birirectional reflectance distribution function (BRDF)](https://en.wikipedia.org/wiki/Bidirectional_reflectance_distribution_function). This is basically a function describing how light is reflected from a surface. It depends on the direction of incoming light and the direction of outgoing light and returns the amount of reflected light. This enables us to calculate how some material would look when viewed from a certain position and illuminated from another.

<img src="https://upload.wikimedia.org/wikipedia/commons/e/ed/BRDF_Diagram.svg" alt="brdf_diagram" style="display: block;  margin-left: auto;  margin-right: auto;  width: 70%" /> 


There are plenty of different BRDFs out there, all with their advantages and disadvantages, but the most commonly used is probably the [Disney BRDF](https://media.disneyanimation.com/uploads/production/publication_asset/48/asset/s2012_pbs_disney_brdf_notes_v3.pdf). This is also the BRDF that I'm using, and the goal is to calculate all variables used in this function to represent the appearance of a material.
This means I want to get the albedo, normal map, metalness, roughness and specularity of a material. A very good explanation of this can be found [here](https://learnopengl.com/PBR/Theory).
<img src="https://learnopengl.com/img/pbr/textures.png" alt="pbr" style="display: block;  margin-left: auto;  margin-right: auto;  width: 70%" /> 


## How?
Now, you might ask: how do you calculate this?

This is done by taking many images of the material under different lighting. In my case each image corresponds to one of the light sources which are arranged around the material. This means that for each pixel, we get several measurements consisting of the direction of incoming light, the direction of outgoing light (simply the direction of the camera as seen from the material), and how much light is reflected. With this information it is possible to calculate the parameters describing the appearance of the material. Of course I wasn't the first to have this idea, and this technique was first proposed over 40 years ago (see: [Photometric Stereo](https://en.wikipedia.org/wiki/Photometric_stereo)). Since then there has been a lot of research on this topic, a good survey on photometric stereo techniques can be found [here](http://mesh.brown.edu/3DP-2018/refs/Ackermann-now2015.pdf).
<img src="https://upload.wikimedia.org/wikipedia/commons/b/b5/Photometric_stereo.png" alt="photometric stereo" style="display: block;  margin-left: auto;  margin-right: auto;  width: 70%" /> 

*This is an illustration from the photometric stereo wikipedia article. The colorful image represents the normal map.*

## The juicy details

**Software implementation**

I implemented pretty much all of the software for acquisition, solving and visualizing myself. The technologies used are C and C++ for acquisition, C++ and CUDA for solving and C++ with DirectX for visualizing the results.

**Overview of the scanner itself**

For the scanner I'm using 63 white LEDs and 8 color LEDs in combination with a 16MP monochrome camera. Additionally a motor can rotate a linear polarizer in front of the camera lens. This allows me to separate the specular and diffuse reflections (more on this later). For switching the LEDs on and off I've designed some simple PCBs which are basically just daisy chained shift registers connected to mosfets. The scanner is capable of taking 11 images per second, but this is mainly limited by my camera, which is an ASI 1600MM Pro that I normally use for astrophotography. But the wishlist for my next birthday already contains a [Basler boA8100-16cm](https://www.baslerweb.com/en/products/cameras/coaxpress-2-0-cameras/cxp-12-evaluation-kit/cxp-12-evaluation-kit-boa8100-16cm-1c/), now I just need to find someone willing to buy it, which I'm guessing is unfortunately going to be me.

**Separating diffuse and specular reflection**

There are two different types of reflections, [diffuse reflection](https://en.wikipedia.org/wiki/Diffuse_reflection) and [specular reflection](https://en.wikipedia.org/wiki/Specular_reflection). Specular reflection is the one we learned about in school, light hits mirror, mirror reflects light as expected with the angle of reflection being the angle of incidence. 

The diffuse reflection however, is due to the light entering the material, getting scattered around and at some point coming out of the material again. An ideal case of this is [Lambertian reflection](https://en.wikipedia.org/wiki/Lambertian_reflectance) where light enters and exits the surface at the same point and is reflected in all directions equally.
<img src="https://upload.wikimedia.org/wikipedia/commons/b/bd/Lambert2.gif" style="display: block;  margin-left: auto;  margin-right: auto;  width: 70%" /> 

An interesting difference between these is that if you [polarize](https://en.wikipedia.org/wiki/Polarization_(waves)) light before it hits the surface, the specular reflection will maintain the same polarization while the light of the diffuse reflection will become unpolarized. This means that we can use two polarization filters (one in front of the light source and one in front of the camera) to either filter out the specular reflection or not. Technically this isn't needed, but it surely makes the problem a lot easier, because now we have two smaller problems to solve instead of one really big one.

**Solving the diffuse render equation**

Lets tackle the easier problem first. For simplicity we assume that our material has lambertian reflection and does not reflect any light specularily, which is close enough for most materials. This means that the function we need to solve looks like this:

$$ I_D=L\cdot NCI_L $$

where $$I_D$$ is the intensity of the diffusely reflected light, $$L$$ is the light vector, $$N$$ is the normal vector, $$C$$ is the color (=albedo) and $$I_L$$ is the intensity of the incoming light. In simpler terms this means that the intensity of one rendered pixel is the albedo multiplied by the cosine of the angle between the light and normal vector. We now know $$I_D$$ (which is the brightness of one pixel in an image of our scan), $$I_L$$ and also $$L$$. Using this information we can find an optimal $C$ and $N$ with the method of our choice. I opted to use an iterative algorithm, which is essentially just [gradient descent](https://en.wikipedia.org/wiki/Gradient_descent), but with a few custom features added to it.

**Getting a color image**

Those who have been closely paying attention will have noticed that I'm using a monochrome camera. So all I get are grayscale images.
The normal process to get an colored image is to just use a color camera. These cameras have a [color filter array (CFA)](https://en.wikipedia.org/wiki/Color_filter_array) in front of the sensor. The values of neighboring pixels can then be merged into a single colored one.
<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Bayer_pattern_on_sensor.svg/1920px-Bayer_pattern_on_sensor.svg.png" style="display: block;  margin-left: auto;  margin-right: auto;  width: 50%" /> 

But such a CFA lowers the effective resolution of a camera and is generally not too suitable for photometric stereo. So instead I'm using a monochrome camera paired with color leds. After taking an image for each led, I have 8 color measurements per pixel. These need to be mapped to 3 values representing red, green and blue, which is done via a simple matrix multiplication. The matrix is first calculated by a calibration routine, that takes images of a color checker and finds the optimal mapping matrix. 

Here are the specral response curves of my LEDs, camera and the theoretical spectral response of the rgb values (the dotted line). The solid line in the bottom plot is the ideal spectral response curve of sRGB.

<img src="/Blog/assets/colors2xyz.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 80%" />

This is how an image of my color checker looks, with the ideal colors as overlay in the small rectangles (sometimes difficult to see).

<img src="/Blog/assets/colors.jpg" style="display: block;  margin-left: auto;  margin-right: auto;  width: 80%" />

A video of the color capture process can be found [here](https://www.reddit.com/r/photogrammetry/comments/zwl79t/process_of_accurately_capturing_color_with_my/). If someone wants do do further reading on color accuracy, [this](https://www.strollswithmydog.com/perfect-color-filter-array/) is a great blog post about it.

**First results**

These are the first results I got with my current version of the scanner, and yes, this is my floor. For now I'm only solving for the diffuse reflection, which means that the output is an albedo and a normal texture.

<img src="/Blog/assets/albedo.jpg" style="width: 45%" />
<img src="/Blog/assets/normal.jpg" style="width: 45%" />

It was also really interesting to see how well the lambertiant diffuse model compares to measured values. The measured diffuse reflection is red and the calculated values in green. These are only the measurements of one pixel, x and y represent the position of the light source and z is luminance). However, this is probably an extreme example, because my floor seems to have quite complex subsurface scattering depending on the grain direction.
<iframe width="640" height="360" src="https://www.youtube.com/embed/CAKBOubk8wg" title="Diffuse Reflection" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

That's it for my first post, as this already took me a while to write. I'll be back with more!

<script async src="//static.getclicky.com/101393239.js"></script>