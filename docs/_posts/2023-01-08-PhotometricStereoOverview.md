---
title: "Material Scanner Overview"
date: 2023-01-08
---
# Some introductory rambling
Hi! I'm Niklas and for the last one and a half years I've been developing my material scanner in my spare time. 

Although I might have strayed from my path a bit by working on other interesting projects which I told myself were absolutely needed for this scanner, like building a [CNC router](https://www.reddit.com/r/hobbycnc/comments/tnp28a/printnc_build_in_my_small_apartment_the_enclosure/) and a [spectrometer](https://www.reddit.com/r/Optics/comments/z9zxde/my_cheap_diy_spectrometer_sharpest_peak_has_a/). In hindsight I could have just used the Datron CNC of the local maker space, but that didn't have the same appeal as building a way worse version of it.

Also, my current version is far from the first. There has been a simple first prototype (results can be found [here](https://www.reddit.com/r/photogrammetry/comments/n1ejxm/first_result_of_my_custom_texture_scanning/)), which lasted a day before ditching it for a great new plan. It turned out that this great new plan wasn't as great as I have anticipated, so off I go building the third version which can be found [here](https://www.reddit.com/r/photogrammetry/comments/ojph2p/capture_process_of_my_pbr_material_scanner/). Back then I was still using my DSLR and the sound of the shutter synchronized with the LEDs was fairly satisfying. This got me my first good results and served well as a proof of concept. 

At this point I was rather happy with the general design and it was time to make it into a more polished prototype. So after building a CNC, building a spectrometer, machining/3D printing all needed parts, designing custom PCBs and finally putting it all together, I ended up with the current version.

# Motivation
Now that you know how I got here, I should probably explain why I'm doing all of this:

The goal of this scanner is, that it should be able to calculate the visual properties of a material. These properties then allow me to render images of the same material under different lighting conditions. So a typical application would be computer games for example. 

To better understand this you might want to look up the [birirectional reflectance distribution function (BRDF)](https://en.wikipedia.org/wiki/Bidirectional_reflectance_distribution_function). This is basically a function describing how light is reflected from a surface. It depends on the direction of the incoming light and the direction of the outgoing light and returns the amount of reflected light. This enables us to calculate how some material would look when viewed from a certain position and illuminated from another.

![brdf_diagram](https://upload.wikimedia.org/wikipedia/commons/e/ed/BRDF_Diagram.svg)

There are plenty of different BRDFs out there, all with their advantages and disadvantages, but the most commonly used is probably the [Disney BRDF](https://media.disneyanimation.com/uploads/production/publication_asset/48/asset/s2012_pbs_disney_brdf_notes_v3.pdf). This is also the BRDF which I'm using and the goal is to calculate all variables used in this function to represent the appearance of a material.

This means I want to get the albedo, normal map, metalness, roughness and specularity of a material. A very good explanation of this can be found [here](https://learnopengl.com/PBR/Theory).
![pbr](https://learnopengl.com/img/pbr/textures.png)

# The Scanner
For the scanner I'm using 63 white leds and 8 color leds in combination with a 16MP monochrome camera (it does have a filter wheel in case I'll need it). Additionally a motor can rotate a linear polarizer in front of the camera lens which enables me to separate the specular and diffuse reflections (the light of the leds is also polarized). I'm trying to solve for the disney brdf with a custom solver written in C++/CUDA. For switching the leds I've designed some simple PCBs which are basically just daisy chained shift registers connected to mosfets. The speed seen in the video will also roughly be the capture speed (11fps). So this will capture about 150 images for one scan within 14 seconds, being just under 5GB of data.


Test:
![test](/Blog/assets/colors2xyz.jpg)



