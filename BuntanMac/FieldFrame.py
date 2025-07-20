import tkinter as tk
from tkinter import ttk

class FieldFrame(ttk.Frame):
    def __init__(self, container, dao):
        super().__init__(container)
        self.dao = dao
        # setup the grid layout manager
        #self.rowconfigure(0, weight=1)
        #self.columnconfigure(0, weight=1)   # Word
        #self.columnconfigure(1, weight=1)   #
        self.columnconfigure(2, weight=1)   # Line
        self.columnconfigure(3, weight=1)   #
        self.columnconfigure(4, weight=1)   # Page
        self.columnconfigure(5, weight=1)   #
        self.columnconfigure(6, weight=1)   # Title
        self.columnconfigure(7, weight=1)   #
        self.columnconfigure(8, weight=1)   # Topic
        self.columnconfigure(9, weight=1)   #
        self.columnconfigure(10, weight=1)   # Field
        self.columnconfigure(11, weight=1)   #
        self.columnconfigure(12, weight=1)  # Book
        self.columnconfigure(13, weight=1)  #

        self.__create_widgets()

    def __create_widgets(self):
        '''
        w=8
        ttk.Label(self, text=u'単熟語', width=w).grid(column=0, row=1)
        w=10
        self.word = ttk.Entry(self, width=w)
        self.word.grid(column=1, row=1)
        '''
        w=4
        ttk.Label(self, text=u'行', width=w).grid(column=2, row=1)
        w=4
        self.line = ttk.Entry(self, width=w)
        self.line.grid(column=3, row=1)
        w=4
        ttk.Label(self, text=u'頁', width=w).grid(column=4, row=1)
        w=6
        self.page = ttk.Entry(self, width=w)
        self.page.grid(column=5, row=1)
        w=8
        ttk.Label(self, text=u'タイトル', width=w).grid(column=6, row=1)
        w=15
        self.title = ttk.Entry(self, width=w)
        self.title.grid(column=7, row=1)
        w=8
        ttk.Label(self, text=u'トピック', width=w).grid(column=8, row=1)
        #ttk.Combobox(self, justify="left", height=1, width=w, state='readonly').grid(column=9, row=1)
        w=15
        self.topic = ttk.Entry(self, width=w)
        self.topic.grid(column=9, row=1)
        w=5
        ttk.Label(self, text=u'分野', width=w).grid(column=10, row=1)
        #ttk.Combobox(self, justify="left", height=1, width=w, state='readonly').grid(column=11, row=1)
        w=17
        self.field = ttk.Entry(self, width=w)
        self.field.grid(column=11, row=1)
        w=4
        ttk.Label(self, text=u'本', width=w).grid(column=12, row=1)
        w=19
        self.booklist = ttk.Combobox(self, justify="left", height=3, width=w, state='normal')
        self.booklist.grid(column=13, row=1)

    def destroybook(self):
        self.booklist.destroy()
        w=18
        self.booklist = ttk.Entry(self, width=w)
        self.booklist.grid(column=13, row=1)
        #self.booklist.pack()
    def buildbook(self, book):
        self.booklist.destroy()
        w = 18
        self.booklist = ttk.Combobox(self, justify="left", height=3, width=w, state='normal')
        self.booklist.grid(column=13, row=1)
        blist = self.dao.distinct('book')
        list = []
        num = -1
        for i, v in enumerate(blist):
            list.append(v[0])
            if v[0]==book:
                num = i
        self.setbooklist(list, num)
        #self.booklist.pack()
    def setbook(self, text):
        self.booklist.delete(0, tk.END)
        self.booklist.insert(0, text)
    def getbook(self):
        return self.booklist.get()
    def setbooklist(self, list, num):
        self.booklist['values'] = list
        self.booklist.config()
        self.booklist.current(num)

    def getword(self):
        return self.word.get()
    def setline(self, text):
        self.line.delete(0, tk.END)
        self.line.insert(0, text)
    def getline(self):
        return self.line.get()
    def setpage(self, text):
        self.page.delete(0, tk.END)
        self.page.insert(0, text)
    def getpage(self):
        return self.page.get()
    def settitle(self, text):
        self.title.delete(0, tk.END)
        self.title.insert(0, text)
    def gettitle(self):
        return self.title.get()
    def settopic(self, text):
        self.topic.delete(0, tk.END)
        self.topic.insert(0, text)
    def gettopic(self):
        return self.topic.get()
    def setfield(self, text):
        self.field.delete(0, tk.END)
        self.field.insert(0, text)
    def getfield(self):
        return self.field.get()
    def setfieldframe(self, data):
        self.setline(data[3])
        self.setpage(data[4])
        self.settitle(data[5])
        self.settopic(data[6])
        self.setfield(data[7])
    def setfieldframe_null(self):
        self.line.delete(0, tk.END)
        self.page.delete(0, tk.END)
        self.title.delete(0, tk.END)
        self.topic.delete(0, tk.END)
        self.field.delete(0, tk.END)
