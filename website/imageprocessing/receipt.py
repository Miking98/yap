import subprocess
import time
import io
import cv2
import copy
import numpy as np
from PIL import Image, ImageFilter, ExifTags
from scipy.ndimage import interpolation as inter
from skimage.transform import radon
from matplotlib.mlab import rms_flat
# from memory_profiler import profile

#
# Production server:
from imageprocessing.skewDetect import SkewDetect
from imageprocessing.ocrspace import OCRSpaceImage
from imageprocessing.bill import Bill, BillItem
#
# Local testing:
# from skewDetect import SkewDetect
# from ocrspace import OCRSpaceImage
# from bill import Bill, BillItem
 
class Receipt(object):

    def __init__(self, originalImage):
        self.originalImageFileSize = len(originalImage)
        # Compress image into JPEG
        self.originalImageStream = io.BytesIO()
        pilImage = Receipt.convertBytesIOToPillow(io.BytesIO(originalImage)).convert('L')
        pilImage.save(self.originalImageStream, format='JPEG', quality = 50)
        # Get different image formats for different Python libraries
        self.originalImageOpenCV = Receipt.convertBytesIOToOpenCV(self.originalImageStream)
        self.originalImagePIL = Receipt.convertBytesIOToPillow(self.originalImageStream)
        self.originalImageOpenCVToBeRotated = self.originalImageOpenCV if self.originalImageFileSize > 400000 else Receipt.convertBytesIOToOpenCV(io.BytesIO(originalImage)) # If image is greater than 400KB, compress
        self.preprocessedImages = [] # BytesIO files
        self.items = []

    def endClock(self, start, name):
        end = time.time()
        print(name + ': '+str(end-start))
        return time.time()
    #
    # Given a receipt, returns a Bill object with BillItems and total price info 
    #
    def generateBill(self):
        items = []
        start = time.time()
        # Preprocess and clean receipt
        self.preprocessImage()
        start = self.endClock(start, 'all_preprocessing')
        # Send receipt to OCRSpace and parse items
        OCRSpace = OCRSpaceImage(self.preprocessedImages)
        bill = OCRSpace.generateBill()
        return bill

    #
    # Clean image before sending to OCRSpace
    #
    def preprocessImage(self):
        start = time.time()
        rotatedImages = self.rotateImage()
        start = self.endClock(start, 'all_rotations')
        # for idx, rotatedImage in enumerate(rotatedImages):
        #     self.textCleaner(rotatedImages, textCleanerImagePath)
        #     start = self.endClock(start, 'textcleaner #'+str(idx))
        self.preprocessedImages = rotatedImages

    #
    # Generate 3 rotated versions of image
    #
    SIMILARITY_DEGREE_THRESHOLD = 1 # Minimum degrees that two rotations can be separated to generate different images
    def rotateImage(self):
        rotatedImages = []
        start = time.time()
        rot1 = 0 # self.houghSkewDetect() # MEMORY: 0 MB, TIME: 47% (5 seconds, 12 seconds)
        start = self.endClock(start, 'rot1')
        rot2 = self.openCVSkewDetect() # MEMORY: 0 MB, TIME: 2% (1 second)
        start = self.endClock(start, 'rot2')
        rot3 = self.alynSkewDetect() # MEMORY: 52 MB, TIME: 44% (4 seconds, 14 seconds)
        start = self.endClock(start, 'rot3')
        rotations = [ rot1, rot2, rot3 ]
        print("Rotations: " + str(rot1) + ', ' + str(rot2) + ', ' + str(rot3))
        for idx, r in enumerate(rotations): # MEMORY: 34 MB
            ignoreThisRotation = False
            # 2. Ignore is angle is same as another rotation utility function
            if idx != 0: # Always do first angle - don't let them all cancel each other out
                for other_idx, other_r in enumerate(rotations):
                    if idx == other_idx:
                        continue
                    elif abs(r - other_r) < self.SIMILARITY_DEGREE_THRESHOLD:
                        ignoreThisRotation = True
            if not ignoreThisRotation:
                rotatedImages.append(Receipt.convertOpenCVToBytesIO(self.rotateBound(self.originalImageOpenCVToBeRotated, r)))
                start = self.endClock(start, 'imutil rotation #' + str(idx) + " by "+str(r)+ " degrees")
            else:
                start = self.endClock(start, 'imutil rotation #' + str(idx) + " by "+str(r)+ " degrees " + ' - ignored')
        return rotatedImages
    #
    # Rotation utility functions
    #
    def openCVSkewDetect(self):
        # Grayscale image and flip foreground (foreground is now "white", background is "black")
        gray = cv2.bitwise_not(self.originalImageOpenCV) # TIME: 14%
        # Threshold the image, setting all foreground pixels to 255 and background pixels to 0
        thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
        del gray
        # Grab the (x, y) coordinates of all pixel values > 0, then use these coordinates to compute a rotated bounding box that contains all coordinates
        coords = np.column_stack(np.where(thresh > 0)) # MEMORY: 70 MB, TIME: 48%
        del thresh
        angle = copy.copy(cv2.minAreaRect(coords)[-1]) # TIME: 33%
        # The `cv2.minAreaRect` function returns values in the range [-90, 0); as the rectangle rotates clockwise the returned angle trends to 0 -- in this special case we need to add 90 degrees to the angle
        if angle < -45:
            angle = -(90 + angle)
        # Otherwise, just take the inverse of the angle to make it positive
        else:
            angle = -angle
        return angle
    def projectionSkewDetect(self):
        wd, ht = self.originalImagePIL.size
        pix = np.array(self.originalImagePIL.convert('1').getdata(), np.uint8)
        bin_img = 1 - (pix.reshape((ht, wd)) / 255.0)
        def find_score(arr, angle):
            data = inter.rotate(arr, angle, reshape=False, order=0)
            hist = np.sum(data, axis=1)
            score = np.sum((hist[1:] - hist[:-1]) ** 2)
            return hist, score
        delta = 1
        limit = 5
        angles = np.arange(-limit, limit+delta, delta)
        scores = []
        for angle in angles:
            hist, score = find_score(bin_img, angle)
            scores.append(score)
        best_score = max(scores)
        best_angle = angles[scores.index(best_score)]
        return best_angle
    def alynSkewDetect(self):
        sd = SkewDetect(image=self.originalImageOpenCV, sigma = 3)
        rotation = sd.run() # MEMORY: 50 MB
        return rotation
    def houghSkewDetect(self):
        # Same as AlynSkewDetect, but written purely in OpenCV
        edges = cv2.Canny(self.originalImageOpenCV,50,150,apertureSize = 3) # MEMORY: 70 MB (about)
        lines = cv2.HoughLinesP(edges,1,np.pi/180,200, 100, 20) # TIME: 96%
        ap = []
        for x1,y1,x2,y2 in lines[0]:
            if x2-x1 != 0:
                m = (y2 - y1)/(x2-x1)
                theta = np.arctan(m)
                ap.append(theta)
        if len(ap) == 0:
            return 0
        absolute_deviations = [self.calculate_deviation(k) for k in ap]
        average_deviation = np.mean(np.rad2deg(absolute_deviations))
        ap_deg = [np.rad2deg(x) for x in ap]
        # Create bins of angles
        bin_0_45 = []
        bin_45_90 = []
        bin_0_45n = []
        bin_45_90n = []
        for ang in ap_deg:
            deviation_sum = int(90 - ang + average_deviation)
            if self.compare_sum(deviation_sum):
                bin_45_90.append(ang)
                continue
            deviation_sum = int(ang + average_deviation)
            if self.compare_sum(deviation_sum):
                bin_0_45.append(ang)
                continue
            deviation_sum = int(-ang + average_deviation)
            if self.compare_sum(deviation_sum):
                bin_0_45n.append(ang)
                continue
            deviation_sum = int(90 + ang + average_deviation)
            if self.compare_sum(deviation_sum):
                bin_45_90n.append(ang)
        angles = [bin_0_45, bin_45_90, bin_0_45n, bin_45_90n]
        # Find rotation
        lmax = 0
        for j in range(len(angles)):
            l = len(angles[j])
            if l > lmax:
                lmax = l
                maxi = j
        if lmax:
            ans_arr = self.get_max_freq_elem(angles[maxi])
            rotation = np.mean(ans_arr)
        else:
            ans_arr = self.get_max_freq_elem(ap_deg)
            rotation = np.mean(ans_arr)
        return rotation
    def pillowSkewDetect(self): # Takes too much time
        # Load file, converting to grayscale
        image = Receipt.convertBytesIOToPillow(self.originalImageStream)
        I = np.asarray(image.convert('L').filter(ImageFilter.GaussianBlur(radius=2)))
        I = I - np.mean(I)  # Demean; make the brightness extend above and below zero
        # Do radon transform
        sinogram = radon(I, circle = False)
        # Find the RMS value of each row and find "busiest" rotation, where the transform is lined up perfectly with the alternating dark text and white lines
        r = np.array([rms_flat(line) for line in sinogram.transpose()])
        rotation = -(np.argmax(r)%90)
        return rotation
    def fftSkewDetect(self):
        # Binarized (1-bit image)
        data = np.array(self.originalImagePIL)
        fft = np.fft.fft2(data)
        max_peak = np.max(np.abs(fft))
        # Threshold the lower 25% of the peak
        fft[fft < (max_peak * 0.25)] = 0
        # Log-scale the data
        abs_data = 1 + np.abs(fft)
        c = 255.0 / np.log(1 + max_peak)
        log_data = c * np.log(abs_data)
        # Find two points within 90% of the max peak of the scaled image
        max_scaled_peak = np.max(log_data)
        # Determine the angle of two high-peak points in the image
        rows, cols = np.where(log_data > (max_scaled_peak * 0.90))
        min_col, max_col = np.min(cols), np.max(cols)
        min_row, max_row = np.min(rows), np.max(rows)
        dy, dx = max_col - min_col, max_row - min_row
        rotation = np.arctan(dy / float(dx))
        return rotation

    #
    # Make text clearer in image using ImageMagick 
    #
    def textCleaner(self, image):
        params = [
                        { 'enhance' : "-contrast-stretch 0", "filterSize" : 25,  "offsetAmount" : 10 },
                        { 'enhance' : "-normalize", "filterSize" : 10, "offsetAmount" : 5 },
                        { 'enhance' : "-contrast-stretch 0", "filterSize" : 20,  "offsetAmount" : 5 },
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
    #
    # Actually rotate image in memory
    #
    def rotateBound(self, image, angle):
        # Determine dimensions of image and of center
        (h, w) = image.shape[:2]
        (cX, cY) = (w // 2, h // 2)
        # grab the rotation matrix (applying the negative of the
        # angle to rotate clockwise), then grab the sine and cosine
        # (i.e., the rotation components of the matrix)
        M = cv2.getRotationMatrix2D((cX, cY), -angle, 1.0)
        cos = np.abs(M[0, 0])
        sin = np.abs(M[0, 1])
        # compute the new bounding dimensions of the image
        nW = int((h * sin) + (w * cos))
        nH = int((h * cos) + (w * sin))
        # adjust the rotation matrix to take into account translation
        M[0, 2] += (nW / 2) - cX
        M[1, 2] += (nH / 2) - cY
        # perform the actual rotation and return the image
        return cv2.warpAffine(image, M, (nW, nH))

    #
    # Utility functions for converting between library image formats
    #
    @classmethod
    def convertBytesIOToOpenCV(cls, originalImageStream):
        originalImageStream.seek(0)
        return cv2.imdecode(np.fromstring(originalImageStream.read(), dtype='uint8'), cv2.IMREAD_UNCHANGED)
    @classmethod
    def convertOpenCVToBytesIO(cls, openCVImage):
        return io.BytesIO(cv2.imencode('.png', openCVImage)[1].tobytes())
    @classmethod
    def convertFileStreamToOpenCV(cls, imageFileStream):
        return cv2.imdecode(np.fromstring(imageFileStream, dtype='uint8'), cv2.IMREAD_UNCHANGED)
    @classmethod
    def convertBytesIOToPillow(cls, originalImageStream):
        originalImageStream.seek(0)
        im = Image.open(originalImageStream)
        return Receipt.pillowEXIFAdjust(im)
    @classmethod
    def convertOpenCVToPillow(cls, image):
        return Image.fromarray(cv2.cvtColor(image,cv2.COLOR_BGR2RGB))


    #
    # Function for perserving EXIF data when saving Pillow image - https://stackoverflow.com/a/11543365/2415992
    #
    @classmethod
    def pillowEXIFAdjust(self, image):
        try:
            if hasattr(image, '_getexif'): # only present in JPEGs
                print("Adjust EXIF")
                for orientation in ExifTags.TAGS.keys(): 
                    if ExifTags.TAGS[orientation]=='Orientation':
                        break 
                e = image._getexif()       # returns None if no EXIF data
                if e is not None:
                    exif=dict(e.items())
                    orientation = exif[orientation] 
                    if orientation == 3:   image = image.transpose(Image.ROTATE_180)
                    elif orientation == 6: image = image.transpose(Image.ROTATE_270)
                    elif orientation == 8: image = image.transpose(Image.ROTATE_90)
                else:
                    print("No EXIF data")
            else:
                print("Image has no _getexif attribute")
            return image
        except Exception as e:
            print(str(e))

    #
    # Utility math functions for Hough transform
    #
    def calculate_deviation(self, angle):
        angle_in_degrees = np.abs(angle)
        deviation = np.abs(SkewDetect.piby4 - angle_in_degrees)
        return deviation
    def compare_sum(self, value):
        if value >= 44 and value <= 46:
            return True
        else:
            return False
    def get_max_freq_elem(self, arr):
        max_arr = []
        freqs = {}
        for i in arr:
            if i in freqs:
                freqs[i] += 1
            else:
                freqs[i] = 1
        sorted_keys = sorted(freqs, key=freqs.get, reverse=True)
        max_freq = freqs[sorted_keys[0]]
        for k in sorted_keys:
            if freqs[k] == max_freq:
                max_arr.append(k)
        return max_arr


# Test
def func():
    with open('/Users/miking98/desktop/small.jpg', 'rb') as image:
        data = image.read()
        test = Receipt(data)
        bill = test.generateBill()
        bill.display()

if __name__ == "__main__":
    func()





