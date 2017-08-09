from flask import Flask, render_template, request, jsonify
from datetime import datetime
import time
# from memory_profiler import profile
from imageprocessing.receipt import Receipt

app = Flask(__name__)

VALID_API_KEY = '21da54f1-7f14-4847-b093-a2420007b34d'
ALLOWED_IMAGE_EXTENSIONS = ['png',]

def allowedUploadImage(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_IMAGE_EXTENSIONS

def endClock(start, name):
    end = time.time()
    print(name + ': '+str(end-start))
    return time.time()

@app.route('/getReceiptItems', methods=['POST', 'GET'])
def getReceiptItems():
    '''
        Input: PNG image, APIKey
        Returns: JSON-encoded List of items in bill, Error status, Error message
    '''
    error = False
    errorMessage = None
    bill = None
    start = time.time()
    if request.method == 'POST':
        print("getReceiptItems POST request received")
        endClock(start, 'postRequestReceived')
        parameters = request.values
        if "APIKey" in parameters:
            apiKey = parameters["APIKey"]
            if apiKey == VALID_API_KEY:
                print("Valid API key")
                endClock(start, 'validAPIKey')
                if 'receipt' in request.files:
                    receiptFile = request.files['receipt']
                    if allowedUploadImage(receiptFile.filename):
                        print("Successfully uploaded image")
                        endClock(start, 'SuccessfullyUploadedImage')
                        receiptImage = receiptFile.read()
                        receipt = Receipt(receiptImage)
                        bill = receipt.generateBill()
                        bill.display()
                    else:
                        error = True
                        errorMessage = "Invalid receipt, file extension is not allowed (must be "+','.join(ALLOWED_IMAGE_EXTENSIONS)+")"
                else:
                    error = True
                    errorMessage = "No receipt was uploaded."
            else:
                error = True
                errorMessage = "Invalid API key."
        else:
            error = True
            errorMessage = "No API key specified."
    else:
        error = True
        errorMessage = "Cannot use GET to access this URL. Please use POST."

    results = { "error" : error, "errorMessage" : errorMessage, "bill" : bill.serialize() }
    print("Response: " + str(results))
    return jsonify(results)

@app.route('/test')
def test():
    with open('/Users/miking98/desktop/test.png', 'rb') as image:
        receiptImage = image.read()
        receipt = Receipt(receiptImage)
        bill = receipt.generateBill()
        bill.display()
    return "Hi"

@app.route('/')
def index():
    the_time = datetime.now().strftime("%A, %d %b %Y %l:%M %p")
    
    return """
        <h1>Python server for Accountabill</h1>
        <p>It is currently {time}.</p>
        <p>Use me for image processing</p>
        """.format(time=the_time)

if __name__ == '__main__':
    app.run(debug=True, use_reloader=True, host= '0.0.0.0:5000')
