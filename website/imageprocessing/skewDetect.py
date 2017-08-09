""" Calculates skew angle """
''' https://raw.githubusercontent.com/Python3pkg/Alyn/master/alyn/skew_detect.py '''
import numpy as np
import cv2
from skimage.transform import hough_line, hough_line_peaks
# from memory_profiler import profile

class SkewDetect:

    piby4 = np.pi / 4

    def __init__(self, image=None, sigma=3.0, num_peaks=20):
        self.image = image
        self.sigma = sigma
        self.num_peaks = num_peaks

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

    def compare_sum(self, value):
        if value >= 44 and value <= 46:
            return True
        else:
            return False

    def calculate_deviation(self, angle):
        angle_in_degrees = np.abs(angle)
        deviation = np.abs(SkewDetect.piby4 - angle_in_degrees)
        return deviation

    def run(self):
        res = self.determine_skew()
        return res["angle"]

    def determine_skew(self):
        edges = cv2.Canny(self.image, 100, 250, apertureSize = 3) # MEMORY: 55 MB
        h, a, d = hough_line(edges) # TIME: 53%
        _, ap, _ = hough_line_peaks(h, a, d, num_peaks=self.num_peaks) # TIME: 34%
        if len(ap) == 0:
            return { "angle" : 0 }
        absolute_deviations = [self.calculate_deviation(k) for k in ap]
        average_deviation = np.mean(np.rad2deg(absolute_deviations))
        ap_deg = [np.rad2deg(x) for x in ap]

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
        
        lmax = 0
        for j in range(len(angles)):
            l = len(angles[j])
            if l > lmax:
                lmax = l
                maxi = j
        if lmax:
            ans_arr = self.get_max_freq_elem(angles[maxi])
            ans_res = np.mean(ans_arr)
        else:
            ans_arr = self.get_max_freq_elem(ap_deg)
            ans_res = np.mean(ans_arr)

        data = {
            "averageDeviation": average_deviation,
            "angle": ans_res,
            "angleBins": angles
            }
        return data