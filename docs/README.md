---
layout: home
permalink: index.html

# Please update this with your repository name and title
repository-name: e19-co227-Developing-image-capturing-and-analysing-system-using-FPGA
title: Developing image capturing and analysing system using FPGA
---

[comment]: # "This is the standard layout for the project, but you can clean this and use your own template"

# Developing image capturing and analysing system using FPGA

---

<!-- 
This is a sample image, to show how to add images to your page. To learn more options, please refer [this](https://projects.ce.pdn.ac.lk/docs/faq/how-to-add-an-image/)

![Sample Image](./images/sample.png)
 -->

## Team-23
-  E/19/423, Weerasingha W.A.C.J, [e19423@eng.pdn.ac.lk](mailto:name@email.com)
-  E/17/083, Ekanayake E.M.M.U.B, [e17083@eng,pdn.ac,lk](mailto:name@email.com)

## Table of Contents
1. [Introduction](#introduction)
2. [Image processing](#Image-processing)
3. [FPGA](#FPGA)
4. [Solution](#Solution)
5. [Technology](#Technology)
6. [Links](#links)

---

## Introduction

The image processing is used to extract useful information from images. This information can be used for a variety of purposes, such as object recognition,space explotation, medical diagnosis, and quality control.Due to GPUs and CPUs are general purpose processers  parallelism is limited. GPUs and CPUs typically have latency  because they have to fetch instructions and data from memory, which can add a significant delay.ASIC is not reprogramble so new a update must done with new chip implementation.So to overcome that problems FPGAs are better choice for image processing applications. They offer better performance by highly parallelism, lower latency, lower power consumption, and easier programming.So the goal of the project is implement a simple image processing system in a FPGA.

## Image processing

Image processing used to extract useful information from images.This information can be used for a variety of purposes:
				
    				Object recognition
				Medical imaging
				Quality control
				Space exploration
  				Multimedia
				Image restoration
				Image enchance
				Noice cancelling
				Scientafic images

## Some of the most common image processing applications include:

Computer vision: 
This is the field of artificial intelligence that deals with the automatic interpretation of images. Computer vision techniques are used in a wide variety of applications, such as self-driving cars, facial recognition, and medical image analysis.

Medical imaging: 
Image processing techniques are used to improve the quality of medical images, such as X-rays, MRI scans, and ultrasound images. This can help doctors to diagnose diseases more accurately.

Quality control: 
Image processing techniques are used to inspect products for defects. This is done by automatically scanning the images of products for any abnormalities.

Multimedia: 
Image processing techniques are used to enhance the quality of multimedia content, such as videos and images. This can be done by removing noise, sharpening the images, and adjusting the colors

## Image processing three different levels :

Low level: 
	Image processing(input and output is an image)
		
Mid level: 
	Image analysis(input is an image and the output is attributes extact from the image)

High level:
	Computer vission(making sense of recognized objects(AI))


## image processing techniques:

Noise removal: This involves removing unwanted noise from an image, such as Gaussian noise or salt and pepper noise.
Sharpening: This involves improving the clarity of an image by increasing the contrast between adjacent pixels.
Contrast enhancement: This involves adjusting the contrast of an image to make it easier to see.
Edge detection: This involves identifying the edges in an image.
Object segmentation: This involves dividing an image into different objects.
Shape analysis: This involves extracting the shape of objects in an image.
Color manipulation: This involves changing the color of an image.
Image compression: This involves reducing the size of an image without losing too much information.
Image restoration: This involves restoring an image that has been corrupted by noise or other artifacts.

## benefits of image processing:

It can be used to improve the quality of images, such as by removing noise or enhancing the contrast.
It can be used to extract useful information from images, such as the location of objects or the characteristics of a scene.
It can be used to automate tasks that are currently done manually, such as image classification or object detection.
It can be used to create new applications, such as virtual reality or augmented reality.
Image processing is a powerful tool that can be used to solve a wide variety of problems. As the field continues to grow, we can expect to see even more innovative applications of image processing in the future.

## FPGA
## Solution
## Technology

.....

## Links

- [Project Repository](https://github.com/cepdnaclk/{{ page.repository-name }}){:target="_blank"}
- [Project Page](https://cepdnaclk.github.io/{{ page.repository-name}}){:target="_blank"}
- [Department of Computer Engineering](http://www.ce.pdn.ac.lk/)
- [University of Peradeniya](https://eng.pdn.ac.lk/)


[//]: # (Please refer this to learn more about Markdown syntax)
[//]: # (https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
