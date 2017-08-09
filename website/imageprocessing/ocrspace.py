import requests
import io
import re
import copy
import Levenshtein
from operator import itemgetter
from PIL import Image
# from memory_profiler import profile

#
# Production server:
from imageprocessing.fpdf import FPDFs
from imageprocessing.bill import Bill, BillItem
#
# Local testing:
# from fpdf import FPDF
# from bill import Bill, BillItem

class OCRSpaceImage(object):
    # Class variables
    ## OCRSpace API info
    API_KEY = "webocr3" # "a96a3547c188957"
    URL_ENDPOINT = "https://api.ocr.space/parse/image"
    ## PDF constants
    PDF_MAX_WIDTH = 180
    PDF_MAX_HEIGHT = 270
    ## Special item keywords
    TOTAL_KEYWORDS = ['total', 'total due', 'balance due', 'grand total', 'amount', 'amount due', 'bal', 'balance', 'bill total', 'total price', 'g.total',]
    SUBTOTAL_KEYWORDS = ['subtotal',]
    TAX_KEYWORDS = ['tax', 'vat', 'sales tax', 'tax( %)', 'tax(1 %)', 'tax(2 %)', 'total taxes',]
    TIP_KEYWORDS = ['tip', 'gratituity', 'service',]
    SKIP_LIST = ['change', 'discount', 'cash', 'visa', 'card', 'tax', 'vat', 'sales tax', 'tax( %)', 'tax(1 %)', 'tax(2 %)', 'tip', 'gratuity', 'acct', 'date', 'time', 'table', 'cashier', 'server', 'guest', 'guests', 'gst', 'member', 'off', 'tare', 'tel', 'regprice', 'cardsav', 'savings', 'save', 'saved', 'subtotal', 'loyalty','total', 'total due', 'balance due', 'grand total', 'amount', 'amount due', 'bal', 'balance', 'bill total', 'total price',]
    SKIP_LIST_SPECIAL = ['change', 'discount', 'visa', 'card', 'acct', 'date', 'time', 'table', 'cashier', 'server', 'guest', 'guests', 'gst', 'member', 'off', 'tare', 'tel', 'regprice', 'cardsav', 'savings', 'save', 'saved', 'loyalty',]
    REMOVE_SIGNS = ['$', ':']

    def __init__(self, images):
        self.images = images # Images is an array of io.BytesIO() objects
        self.overallExitCode = None # 1 = full success, 2 = partial success, 3 = failed parsing, 4 = fatal internal error
        self.overallErrorMessage = None
        self.overallProcessingTime = None
        self.overallResponse = None
        self.pdfFile = None
        self.bills = []

    def generateBill(self):
        # Compile images into one PDF
        self.generatePDF()
        # Send request to OCRSpace server
        self.sendPDFRequest()
        # Parse results into bills
        self.parseResults()
        # Determine highest scoring bill and return it
        return self.getBestBill()

    def generatePDF(self):
        pdf = FPDF()
        for idx, image in enumerate(self.images):
            ## Aspect fit image onto PDF
            ### 1. Find width, height of image
            pilImage = OCRSpaceImage.convertBytesIOToPillow(image)
            width, height = pilImage.size
            ### 2. Check if width or height is greater than max allowed, and if so scale down
            if width > OCRSpaceImage.PDF_MAX_WIDTH:
                widthDiff = width - OCRSpaceImage.PDF_MAX_WIDTH
                scalePercentage = 1 - widthDiff/width
                width *= scalePercentage
                height *= scalePercentage
            if height > OCRSpaceImage.PDF_MAX_HEIGHT:
                heightDiff = height - OCRSpaceImage.PDF_MAX_HEIGHT
                scalePercentage = 1 - heightDiff/height
                height *= scalePercentage
                width *= scalePercentage
            width = int(width)
            height = int(height)
            ### 3. Reduce image size
            reducedImage = io.BytesIO()
            pilImage.save(reducedImage, format='JPEG', quality = 50)
            ### 4. Add scaled image to PDF
            pdf.add_page()
            pdf.image('receipt'+str(idx), 10, 10, width, height, type='jpg', file=reducedImage)
        self.pdfFile = io.BytesIO(pdf.output(dest = 'S'))
        pdf.output(name = 'testpdf.pdf', dest = 'F')

    def sendPDFRequest(self):
        params = {
                    'isOverlayRequired': True,
                    'apikey': OCRSpaceImage.API_KEY,
                    'language': 'eng',
                }
        fileInfo = { 'file.pdf': self.pdfFile }
        r = requests.post(OCRSpaceImage.URL_ENDPOINT, files=fileInfo, data=params)
        self.overallResponse = r.json()

    def getBestBill(self):
        bestBill = None
        for b in self.bills:
            if bestBill is None or b.getScore() > bestBill.getScore():
                bestBill = b
        return bestBill

    def parseResults(self):
        # Metadata on parsing
        info = self.overallResponse
        self.overallExitCode = info["OCRExitCode"] # 1 = full success, 2 = partial success, 3 = failed parsing, 4 = fatal internal error
        self.overallErrorMessage = info["ErrorMessage"]
        self.overallErrorDetails = info["ErrorDetails"]
        self.overallProcessingTime = info["ProcessingTimeInMilliseconds"]

        # At least one image was successfully parsed
        if self.overallExitCode < 3:
            ## Loop through array of parsed results for each image
            parsedResults = info["ParsedResults"]
            for results in parsedResults:
                ### Get text with coordinates
                textOverlay = results["TextOverlay"]
                lines = textOverlay["Lines"]

                ### Get an array of cleaned lines, where each line is an array of words on that line sorted from left -> right
                cleanedLines = self.generateCleanedLines(lines)

                ### Read bill items from receipt
                storeName, storeLine = self.getStoreName(cleanedLines)
                totalPrice, totalPriceLine = self.getTotal(cleanedLines)
                subtotal, subtotalLine = self.getSubtotal(cleanedLines)
                tax, taxLine = self.getTax(cleanedLines)
                tip, tipLine = self.getTip(cleanedLines)
                location = self.getLocation(cleanedLines)
                items, totalPriceGuess = self.getItems(cleanedLines, [storeLine, totalPriceLine, subtotalLine, taxLine, tipLine])
                ### Create Bill object
                bill = Bill(storeName)
                bill.setLocation(location)
                bill.setItems(items)
                bill.setSubtotal(subtotal)
                bill.setTax(tax)
                bill.setTip(tip)
                bill.setTotal(totalPrice)
                bill.setTotalGuess(totalPriceGuess)
                self.bills.append(bill)
        # No parsing succeeded
        else:
            print("Error, no parsing succeeded. Error code: #" + str(self.overallExitCode)+". Error message: " + str(self.overallErrorMessage) + ". Error details: " + str(self.overallErrorDetails))
            return None

    def generateCleanedLines(self, lines):
        ### Generate list of all words, and metadata on their coordinates in image
        words = []
        for l in lines:
            w = l["Words"]
            words.extend(w)

        ### Sort words by y-coordinates
        words.sort(key=itemgetter("Top"))

        ### Break up words into ordered lines based on y-coordinates and word height
        orderedLines = []
        currentLine = []
        for x in range(len(words)):
            #### If this is the first word on the receipt, initialize a line with it and continue
            currentWord = words[x]
            if x == 0:
                currentLine.append(currentWord)
                continue

            #### We're past the first word in the receipt
            #### Now get info on current word A and previous word B, where B_yValue<=A_yVal and there is no other word C where B_yValue<=C_yValue<=A_yValue
            prevWord = words[x-1]
            yVal = currentWord["Top"]
            heightVal = currentWord["Height"]
            prevYVal = prevWord["Top"]
            marginOfError = 0.50*(prevWord["Height"]) # How many pixels of leniance we'll give this line (i.e. in case they are skewed or paper is crinkled)

            #### If the difference in y-coordinates between current and previous words is > the margin of error, then start a new line (or, if this is the last word, flush out this current line)
            if yVal-prevYVal > marginOfError:
                ##### Sort words on current line by x-coordinate
                currentLine.sort(key=itemgetter("Left"))
                ##### Write current line to array
                orderedLines.append(currentLine)
                ##### Restart current line
                currentLine = [ currentWord ]
            else:
                ##### Add word to current line
               currentLine.append(currentWord)
        ### Flush out last current line
        currentLine.sort(key=itemgetter("Left"))
        orderedLines.append(currentLine)

        ### Remove all metadata and have array of just words split into lines
        cleanedLines = []
        for line in orderedLines:
            cleanedLines.append([ w["WordText"].lower() for w in line ])
        return cleanedLines


    #
    # Parsing functions for itemization of bill
    #
    def getItems(self, cleanedLines, avoidLines):
        # Find price for each item
        items = []
        totalPriceGuess = 0.0
        for idx, line in enumerate(cleanedLines):
            ## Skip useless info
            if self.shouldSkipLine(line, self.SKIP_LIST):
                continue
            ## Avoid lines with special items (e.g. total, subtotal)
            if idx in avoidLines:
                continue
            
            ## This line is a potential item
            ## 1. Join words of line together
            content = ' '.join(line) # Separate each distinctly parsed word with a space
            ## 2. Find price
            if re.search(r'\d+\. *\d\d', content) is None:
                ### No price found, this isn't an item
                continue
            itemPrice = 0.0
            while re.search(r'\d+\. *\d\d', content) is not None:
                price = re.search(r'\d+\. *\d\d', content).group()
                content = content.replace(price, '') # Remove price from content
                content = self.removeSignInName(content) # Remove special signs is there's any
                price = float(price.replace(' ', ''))
                if price > itemPrice:
                    itemPrice = price
            itemName = content.strip()
            itemName = itemName.title()
            ## 3. Create BillItem object
            items.append(BillItem(itemName, itemPrice))
            #print('item:', itemName, itemPrice)
            totalPriceGuess += itemPrice
        return (items, totalPriceGuess)
    
    def shouldSkipLine(self, line, skipList):
        for keyword in skipList:
            ## exact match
            if keyword in line:
                return True
            ## fuzzy match
            for word in line:
                word = self.removeSignInName(word) # Remove special signs if there's any
                word = word.strip()
                if word == keyword:
                    return True
                if len(keyword) > 4 and Levenshtein.distance(keyword, word) < 3:
                    return True
        return False

    def removeSignInName(self, name):
        for sign in self.REMOVE_SIGNS:
            if sign in name:
                name = name.replace(sign, '')
        return name


    def getSpecialItem(self, cleanedLines, keywords):
        totalPrice = 0.0
        lineNumber = None
        for idx, line in enumerate(cleanedLines):
            ## Skip useless info
            if self.shouldSkipLine(line, self.SKIP_LIST_SPECIAL):
                continue
            
            ## This line is a potential total
            ## 1. Join words of line together
            content = ' '.join(line) # Separate each distinctly parsed word with a space
            ## 2. Find price
            if re.search(r'\d+\. *\d\d', content) is not None: # Need space because OCRSpace might parse price as two words, e.g. "2.03" as "2." and "03"
                itemPrice = re.search(r'\d+\. *\d\d', content).group()
                contentWithoutPrice = content.replace(itemPrice, '') # Remove price from content
                contentWithoutPrice = self.removeSignInName(contentWithoutPrice) # Remove special signs if there's any
                itemPrice = float(itemPrice.replace(' ', '')) # Strip out whitespace and convert to float()
            else:
                ### No price found, this isn't an item
                continue
            itemName = contentWithoutPrice.strip()
            ## 3. Check if itemName matches a valid keyword
            ## exact match
            if itemName in keywords:
                totalPrice = itemPrice
                lineNumber = len(cleanedLines) - 1 - idx
                break
            findItem = False
            ## fuzzy match
            for keyword in keywords:
                if len(keyword) < 5:
                    continue
                #print('distance:', Levenshtein.distance(itemName, keyword), itemName, keyword)
                if Levenshtein.distance(itemName, keyword) < 3:
                    totalPrice = itemPrice
                    lineNumber = len(cleanedLines) - 1 - idx
                    findItem = True
                    break
            if findItem:
                break
        return (totalPrice, lineNumber)

    # Find store location
    def getLocation(self, cleanedLines):
        for idx, line in enumerate(cleanedLines):
            ## 1. Join words of line together
            content = ' '.join(line) # Separate each distinctly parsed word with a space
            ## 2. Find location
            if re.search(r'[a-zA-Z][a-zA-Z] +\d\d\d\d\d', content) is not None:
                content = content.title()
                stateAndZip = re.search(r'[a-zA-Z][a-zA-Z] +\d\d\d\d\d', content).group()
                content = content.replace(stateAndZip, stateAndZip.upper()[:2])
                #print('location:', content)
                return content
        return 'Menlo Park, CA'

    # Find total price
    def getTotal(self, cleanedLines):
        return self.getSpecialItem(cleanedLines, self.TOTAL_KEYWORDS)
    # Find subtotal
    def getSubtotal(self, cleanedLines):
        return self.getSpecialItem(cleanedLines, self.SUBTOTAL_KEYWORDS)
    # Find tax
    def getTax(self, cleanedLines):
        return self.getSpecialItem(cleanedLines, self.TAX_KEYWORDS)
    # Find tip
    def getTip(self, cleanedLines):
        return self.getSpecialItem(cleanedLines, self.TIP_KEYWORDS)
    # Find store name
    def getStoreName(self, cleanedLines):
        line = cleanedLines[0]
        name = ' '.join(line)
        name = name.title()
        return (name, 0)

    @classmethod
    def convertBytesIOToPillow(cls, originalImageStream):
        originalImageStream.seek(0)
        return Image.open(originalImageStream)
