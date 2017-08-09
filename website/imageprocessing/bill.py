import json

class Bill(object):

    def __init__(self, name = None):
        self.name = name
        self.location = None
        self.items = []
        self.tax = None
        self.tip = None
        self.subtotal = None
        self.total = None
        self.totalGuess = None # Sum of prices of items, should match self.total if everything parsed correctly

    def setName(self, val):
        self.name = val
    def setLocation(self, val):
        self.location = val
    def setTax(self, val):
        self.tax = val
    def setTip(self, val):
        self.tip = val
    def setSubtotal(self, val):
        self.subtotal = val
    def setTotal(self, val):
        self.total = val
    def setTotalGuess(self, val):
        self.totalGuess = val
    def setItems(self, val):
        self.items = val
    def addItem(self, val):
        self.items.append(val)

    def getScore(self):
        # Return score for bill based on its quality
        ## 1. Count items read
        nItems = len(self.items)
        ## 2. Count chars read
        nChars = 0
        for i in self.items:
            nChars += len(i.name) + len(str(i.price))
        ## 3. Count special items (total, subtotal, tip, tax)
        nSpecial = 0
        for i in [ self.tax, self.subtotal, self.tip, self.total ]:
            nSpecial += 1 if i is not None else 0

        # Weight all values and sum together
        score = nSpecial * 100 + nItems * 10 + nChars
        return score

    def display(self):
        print("----------")
        print("Store: " + self.name)
        print("Location: " + self.location)
        for i in self.items:
            print(i.name + ", " + str(i.price))
        print("Subtotal: " + str(self.subtotal))
        print("Tax: " + str(self.tax))
        print("Tip: " + str(self.tip))
        print("Total: " + str(self.total))
        print("Total Guess: " + str(self.totalGuess))
        print("----------")

    def serialize(self):
        return {
            'name' : self.name,
            'location' : self.location,
            'total' : self.total,
            'tip' : self.tip,
            'tax' : self.tax,
            'totalGuess' : self.totalGuess,
            'items' : [ i.serialize() for i in self.items ]
        }

class BillItem(object):

    def __init__(self, name = None, price = None, quantity = None, unitPrice = None):
        self.name = name
        self.price = price
        self.quantity = quantity
        self.unitPrice = unitPrice

    def serialize(self):
        return {
            'name' : self.name,
            'price' : self.price,
            'quantity' : self.quantity,
            'unitPrice' : self.unitPrice,
        }
