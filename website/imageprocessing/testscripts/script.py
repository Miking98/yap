#!/usr/bin/env python
'''
    Usage:
    ./script.py path/to/image.jpg

    Places processed image in: 
    path/to/image.crop.png.

    Credit:
    http://www.danvk.org/2015/01/07/finding-blocks-of-text-in-an-image-using-python-opencv-and-numpy.html
'''

import glob
import os
import random
import sys
import random
import math
import json
import subprocess
from collections import defaultdict
from skew_detect import SkewDetect
from deskew import Deskew

import cv2
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
from scipy.ndimage.filters import rank_filter
from skimage.transform import radon
import matplotlib.pyplot as plt
from matplotlib.mlab import rms_flat
import imutils

#File commands
def mkdir(folder):
    os.makedirs(folder, exist_ok=True)
def rmdir(path):
    shutil.rmtree(path)
def cd(path):
    os.chdir(path)

def dilate(ary, N, iterations): 
    """Dilate using an NxN '+' sign shape. ary is np.uint8."""
    
    kernel = np.zeros((N,N), dtype=np.uint8)
    kernel[(N-1)//2,:] = 1  # Bug solved with // (integer division)
    
    dilated_image = cv2.dilate(ary / 255, kernel, iterations=iterations)
    
    kernel = np.zeros((N,N), dtype=np.uint8)
    kernel[:,(N-1)//2] = 1  # Bug solved with // (integer division)
    dilated_image = cv2.dilate(dilated_image, kernel, iterations=iterations)
    return dilated_image


def props_for_contours(contours, ary):
    """Calculate bounding box & the number of set pixels for each contour."""
    c_info = []
    for c in contours:
        x,y,w,h = cv2.boundingRect(c)
        c_im = np.zeros(ary.shape)
        cv2.drawContours(c_im, [c], 0, 255, -1)
        c_info.append({
            'x1': x,
            'y1': y,
            'x2': x + w - 1,
            'y2': y + h - 1,
            'sum': np.sum(ary * (c_im > 0))/255
        })
    return c_info


def union_crops(crop1, crop2):
    """Union two (x1, y1, x2, y2) rects."""
    x11, y11, x21, y21 = crop1
    x12, y12, x22, y22 = crop2
    return min(x11, x12), min(y11, y12), max(x21, x22), max(y21, y22)


def intersect_crops(crop1, crop2):
    x11, y11, x21, y21 = crop1
    x12, y12, x22, y22 = crop2
    return max(x11, x12), max(y11, y12), min(x21, x22), min(y21, y22)


def crop_area(crop):
    x1, y1, x2, y2 = crop
    return max(0, x2 - x1) * max(0, y2 - y1)


def find_border_components(contours, ary):
    borders = []
    area = ary.shape[0] * ary.shape[1]
    for i, c in enumerate(contours):
        x,y,w,h = cv2.boundingRect(c)
        if w * h > 0.5 * area:
            borders.append((i, x, y, x + w - 1, y + h - 1))
    return borders


def angle_from_right(deg):
    return min(deg % 90, 90 - (deg % 90))


def remove_border(contour, ary):
    """Remove everything outside a border contour."""
    # Use a rotated rectangle (should be a good approximation of a border).
    # If it's far from a right angle, it's probably two sides of a border and
    # we should use the bounding box instead.
    c_im = np.zeros(ary.shape)
    r = cv2.minAreaRect(contour)
    degs = r[2]
    if angle_from_right(degs) <= 10.0:
        box = cv2.boxPoints(r)
        box = np.int0(box)
        cv2.drawContours(c_im, [box], 0, 255, -1)
        cv2.drawContours(c_im, [box], 0, 0, 4)
    else:
        x1, y1, x2, y2 = cv2.boundingRect(contour)
        cv2.rectangle(c_im, (x1, y1), (x2, y2), 255, -1)
        cv2.rectangle(c_im, (x1, y1), (x2, y2), 0, 4)

    return np.minimum(c_im, ary)


def find_components(edges, max_components=16):
    """Dilate the image until there are just a few connected components.

    Returns contours for these components."""
    # Perform increasingly aggressive dilation until there are just a few
    # connected components.
    
    count = 21
    dilation = 5
    n = 1
    while count > 16:
        n += 1
        dilated_image = dilate(edges, N=3, iterations=n)
        dilated_image = np.uint8(dilated_image)
        _, contours, hierarchy = cv2.findContours(dilated_image, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        count = len(contours)
    #print dilation
    #Image.fromarray(edges).show()
    #Image.fromarray(255 * dilated_image).show()
    return contours


def find_optimal_components_subset(contours, edges):
    """Find a crop which strikes a good balance of coverage/compactness.

    Returns an (x1, y1, x2, y2) tuple.
    """
    c_info = props_for_contours(contours, edges)
    c_info.sort(key=lambda x: -x['sum'])
    total = np.sum(edges) / 255
    area = edges.shape[0] * edges.shape[1]

    c = c_info[0]
    del c_info[0]
    this_crop = c['x1'], c['y1'], c['x2'], c['y2']
    crop = this_crop
    covered_sum = c['sum']

    while covered_sum < total:
        changed = False
        recall = 1.0 * covered_sum / total
        prec = 1 - 1.0 * crop_area(crop) / area
        f1 = 2 * (prec * recall / (prec + recall))
        for i, c in enumerate(c_info):
            this_crop = c['x1'], c['y1'], c['x2'], c['y2']
            new_crop = union_crops(crop, this_crop)
            new_sum = covered_sum + c['sum']
            new_recall = 1.0 * new_sum / total
            new_prec = 1 - 1.0 * crop_area(new_crop) / area
            new_f1 = 2 * new_prec * new_recall / (new_prec + new_recall)

            # Add this crop if it improves f1 score,
            # _or_ if the % of remaining pixels it adds is proportional (within 40%) of remaining area it adds
            # ^^^ very ad-hoc! make this smoother
            remaining_frac = c['sum'] / (total - covered_sum)
            new_area_frac = 1.0 * crop_area(new_crop) / crop_area(crop) - 1
            if new_f1 > f1 or (abs(remaining_frac - new_area_frac)<=0.4):
                # print('%d %s -> %s / %s (%s), %s -> %s / %s (%s), %s -> %s' % (
                        # i, covered_sum, new_sum, total, remaining_frac,
                        # crop_area(crop), crop_area(new_crop), area, new_area_frac,
                        # f1, new_f1))
                crop = new_crop
                covered_sum = new_sum
                del c_info[i]
                changed = True
                break

        if not changed:
            break

    return crop


def pad_crop(crop, contours, edges, border_contour, pad_px=15):
    """Slightly expand the crop to get full contours.

    This will expand to include any contours it currently intersects, but will
    not expand past a border.
    """
    bx1, by1, bx2, by2 = 0, 0, edges.shape[0], edges.shape[1]
    if border_contour is not None and len(border_contour) > 0:
        c = props_for_contours([border_contour], edges)[0]
        bx1, by1, bx2, by2 = c['x1'] + 5, c['y1'] + 5, c['x2'] - 5, c['y2'] - 5

    def crop_in_border(crop):
        x1, y1, x2, y2 = crop
        x1 = max(x1 - pad_px, bx1)
        y1 = max(y1 - pad_px, by1)
        x2 = min(x2 + pad_px, bx2)
        y2 = min(y2 + pad_px, by2)
        return crop
    
    crop = crop_in_border(crop)

    c_info = props_for_contours(contours, edges)
    changed = False
    for c in c_info:
        this_crop = c['x1'], c['y1'], c['x2'], c['y2']
        this_area = crop_area(this_crop)
        int_area = crop_area(intersect_crops(crop, this_crop))
        new_crop = crop_in_border(union_crops(crop, this_crop))
        if 0 < int_area < this_area and crop != new_crop:
            # print('%s -> %s' % (str(crop), str(new_crop)))
            changed = True
            crop = new_crop

    if changed:
        return pad_crop(crop, contours, edges, border_contour, pad_px)
    else:
        return crop


def downscale_image(im, max_dim=2048):
    """Shrink im until its longest dimension is <= max_dim.

    Returns new_image, scale (where scale <= 1).
    """
    a, b = im.size
    if max(a, b) <= max_dim:
        return 1.0, im

    scale = 1.0 * max_dim / max(a, b)
    new_im = im.resize((int(a * scale), int(b * scale)), Image.ANTIALIAS)
    return scale, new_im


def cropImage(originalImage, out_path):

    scale, im = downscale_image(convertOpenCVtoPillow(originalImage))
    edges = cv2.Canny(np.asarray(im), 100, 200)

    # TODO: dilate image _before_ finding a border. This is crazy sensitive!
    __, contours, hierarchy = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    borders = find_border_components(contours, edges)
    borders.sort(key=lambda i_x1_y1_x2_y2: (i_x1_y1_x2_y2[3] - i_x1_y1_x2_y2[1]) * (i_x1_y1_x2_y2[4] - i_x1_y1_x2_y2[2]))

    border_contour = None
    if len(borders):
        border_contour = contours[borders[0][0]]
        edges = remove_border(border_contour, edges)

    edges = 255 * (edges > 0).astype(np.uint8)

    # Remove ~1px borders using a rank filter.
    maxed_rows = rank_filter(edges, -4, size=(1, 20))
    maxed_cols = rank_filter(edges, -4, size=(20, 1))
    debordered = np.minimum(np.minimum(edges, maxed_rows), maxed_cols)
    edges = debordered

    contours = find_components(edges)
    if len(contours) == 0:
        print('No text!')
        return

    crop = find_optimal_components_subset(contours, edges)
    crop = pad_crop(crop, contours, edges, border_contour)

    crop = [int(x / scale) for x in crop]  # upscale to the original image size.

    draw = ImageDraw.Draw(im)
    c_info = props_for_contours(contours, edges)
    for c in c_info:
       this_crop = c['x1'], c['y1'], c['x2'], c['y2']
       draw.rectangle(this_crop, outline='blue')
    draw.rectangle(crop, outline='red')
    im.save(out_path)
    orig_im = convertOpenCVtoPillow(originalImage)
    orig_im.save(out_path)
    # im.show()
    text_im = orig_im.crop(crop)
    text_im.save(out_path)

def openCVSkewDetect(originalImage):
    # convert the image to grayscale and flip the foreground
    # and background to ensure foreground is now "white" and
    # the background is "black"
    gray = cv2.cvtColor(originalImage, cv2.COLOR_BGR2GRAY)
    gray = cv2.bitwise_not(gray)
    # threshold the image, setting all foreground pixels to
    # 255 and all background pixels to 0
    thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
    # grab the (x, y) coordinates of all pixel values that
    # are greater than zero, then use these coordinates to
    # compute a rotated bounding box that contains all
    # coordinates
    coords = np.column_stack(np.where(thresh > 0))
    angle = cv2.minAreaRect(coords)[-1]
    # the `cv2.minAreaRect` function returns values in the
    # range [-90, 0); as the rectangle rotates clockwise the
    # returned angle trends to 0 -- in this special case we
    # need to add 90 degrees to the angle
    if angle < -45:
        angle = -(90 + angle)
    # otherwise, just take the inverse of the angle to make
    # it positive
    else:
        angle = -angle
    return angle

def alynSkewDetect(imagePath):
    sd = SkewDetect(
        input_file=imagePath,
        display_output='No',)
    rotation = sd.run()['Estimated Angle']
    return rotation

def pillowSkewDetect(originalImage):
    # Load file, converting to grayscale
    I = np.asarray(convertOpenCVtoPillow(originalImage).convert('L').filter(ImageFilter.GaussianBlur(radius=2)))
    I = I - np.mean(I)  # Demean; make the brightness extend above and below zero
    # Do the radon transform and display the result
    sinogram = radon(I, circle = False)
    # Find the RMS value of each row and find "busiest" rotation,
    # where the transform is lined up perfectly with the alternating dark
    # text and white lines
    r = np.array([rms_flat(line) for line in sinogram.transpose()])
    rotation = -(np.argmax(r)%90)
    return rotation

def rotate(imagePath):
    originalImage = cv2.imread(imagePath)
    rotatedImages = []
    rotations = []
    rotations.append(openCVSkewDetect(originalImage))
    rotations.append(alynSkewDetect(imagePath))
    rotations.append(pillowSkewDetect(originalImage))
    for r in rotations:
        if abs(r) > 85:
            r = 0
        rotatedImages.append(imutils.rotate(originalImage, angle=r))
    return rotatedImages

def addQualifierToFile(path, qualifier, extensionLength = 4):
    return path[:-extensionLength] + "." + qualifier + path[-extensionLength:]

def convertOpenCVtoPillow(image):
    return Image.fromarray(cv2.cvtColor(image,cv2.COLOR_BGR2RGB))

def textCleaner(imagePath, defaultOutputPath):
    params = [
                    { 'enhance' : "-contrast-stretch 0", "filterSize" : 25,  "offsetAmount" : 10 },
                    { 'enhance' : "-normalize", "filterSize" : 10, "offsetAmount" : 5 },
                    { 'enhance' : "-contrast-stretch 0", "filterSize" : 20,  "offsetAmount" : 5 },
                    { 'enhance' : "-contrast-stretch 0", "filterSize" : 30,  "offsetAmount" : 5 },
                    { 'enhance' : "-contrast-stretch 0", "filterSize" : 40,  "offsetAmount" : 5 },
                    { 'enhance' : "-contrast-stretch 0", "filterSize" : 50,  "offsetAmount" : 5 },
            ]
    for idx, p in enumerate(params):
        # Add qualifier to image path
        outputPath = addQualifierToFile(defaultOutputPath, str(idx))
        # Variables
        enhancing = p['enhance']
        filterSize = str(p['filterSize'])
        offset = str(p["offsetAmount"])
        thresholdAmount = False
        sharpenAmount = 1
        padAmount = False
        hdri = False

        # Set up command
        bgColor = "white" # Color for background after it has been cleaned up
        makegray = "-colorspace gray -type grayscale"
        blurring = "-blur 1x65535 -level "+str(thresholdAmount)+"x100%" if thresholdAmount else "" # 0<=x<=100, nominally 50, usually 0
        sharpening = "-sharpen "+str(sharpenAmount*16) # x >= 0 (floats), usually max of 1, default 0; (0x because expects hex number)
        trimming = "-white-threshold 99.9% -trim +repage " if hdri else "-trim +repage "
        padding = "-compose over -bordercolor "+bgColor+" -border "+padAmount if padAmount else ""
        command = "magick convert -respect-parenthesis \( "+imagePath+" "+makegray+" "+enhancing+" -depth 8 \) "+ \
                    "\( -clone 0 -colorspace gray -negate -lat "+filterSize+"x"+filterSize+"+"+offset+"% -contrast-stretch 0 "+blurring+" -depth 8 \) "+ \
                    "-compose copy_opacity -composite -fill "+bgColor+" -opaque none -alpha off "+ \
                    sharpening+" "+trimming+" "+padding+ \
                    outputPath
        subprocess.call(command, shell = True)

if __name__ == '__main__':
    if len(sys.argv) == 3:
        inputType = sys.argv[1]

        #
        # Option 1:
        # If user specifies a folder (with the -m tag)
        if inputType == "-m":
            ## Get FOLDER command line arg, and remove trailing / if present
            FOLDER = sys.argv[2]
            if FOLDER[-1:] == "/":
                FOLDER = FOLDER[:-1]
            ### If FOLDER is valid...
            if os.path.isdir(FOLDER):
                #### Get all files in FOLDER
                files = [f for f in os.listdir(FOLDER) if os.path.isfile(os.path.join(FOLDER, f))]
                #### Create folders for rotated/ and cleaned/ images
                mkdir(FOLDER+"/rotated")
                mkdir(FOLDER+"/cleaned")
                #### For each file in FOLDER...
                for file in files:
                    ##### Ignore hidden files
                    if file[0] == ".":
                        continue
                    try:
                        ##### Create qualified paths for .rotated and .cleaned versions of image
                        FILEPATH = FOLDER + "/" + file
                        defaultRotatedImagePath = os.path.dirname(FILEPATH) + "/rotated/" + addQualifierToFile(os.path.basename(FILEPATH), "rotated")
                        defaultTextCleanerImagePath = os.path.dirname(FILEPATH) + "/cleaned/" + addQualifierToFile(os.path.basename(FILEPATH), "cleaned")
                        ##### Run pipeline
                        print("---- "+FILEPATH+" ----")
                        rotatedImages = rotate(FILEPATH)
                        for idx, rotatedImage in enumerate(rotatedImages):
                            rotatedImagePath = addQualifierToFile(defaultRotatedImagePath, str(idx))
                            cv2.imwrite(rotatedImagePath, rotatedImage)
                            # croppedImagePath = addQualifierToFile(defaultCroppedImagePath, str(idx))
                            # croppedImage = cropImage(rotatedImage, croppedImagePath)
                            textCleanerImagePath = addQualifierToFile(defaultTextCleanerImagePath, str(idx))
                            textCleaner(rotatedImages, textCleanerImagePath)
                    except Exception as e:
                        print(str(e))
            else:
                print("Invalid directory")
        #
        # Option 2:
        # If user specifies a single file (with the -s tag)
        elif inputType == "-s":
            ## Get filename as FILEPATH
            FILEPATH = os.path.abspath(sys.argv[2])
            ## If FILEPATH is valid...
            if os.path.isfile(FILEPATH):
                ### Create fiolders for cropped/ and cleaned/ images
                FOLDER = os.path.dirname(FILEPATH)
                mkdir(FOLDER+"/cropped")
                mkdir(FOLDER+"/cleaned")
                try:
                    ##### Create qualified paths for .cropped and .cleaned versions of image
                    croppedImagePath = FOLDER + "/cropped/" + addQualifierToFile(os.path.basename(FILEPATH), "cropped")
                    textCleanerImagePath = FOLDER + "/cleaned/" + addQualifierToFile(os.path.basename(FILEPATH), "cleaned")
                    ##### Run pipeline
                    originalImage = cv2.imread(FILEPATH)
                    rotatedImage = rotate(originalImage)
                    croppedImage = cropImage(rotatedImage, croppedImagePath)
                    textCleaner(croppedImagePath, textCleanerImagePath)
                except Exception as e:
                    print(str(e))
            else:
                print("Invalid file")
    else:
        print("Invalid arguments - must specify input directory of images")
    