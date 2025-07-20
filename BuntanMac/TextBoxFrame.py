import tkinter as tk
from tkinter import ttk
from tkinter import scrolledtext
import tkinter.font as tkFont
import textwrap

class TextBoxFrame(ttk.Frame):
    def __init__(self, container):
        super().__init__(container)
        self.charcters = 80
        # setup the grid layout manager
        self.columnconfigure(0, weight=1)   #
        self.columnconfigure(1, weight=1)   #
        #self.columnconfigure(2, weight=1)   #
        self.rowconfigure(0, weight=1)  #
        self.rowconfigure(1, weight=1)  #
        self.rowconfigure(2, weight=1)  #
        self.__create_widgets()

    def __create_widgets(self):
        font = tkFont.Font(family="Courier", size=14, weight="normal", slant="roman")
        rlf = [tk.FLAT,tk.RAISED,tk.SUNKEN,tk.GROOVE,tk.RIDGE]
        ttk.Label(self, text=u'和文', width=10).grid(column=0, row=2)
        self.wtbutton = ttk.Button(self, text=u'Hide', width=6)
        self.wtbutton.grid(column=0, row=3)
        self.wtbutton.bind('<Button-1>', self.__funcwt)
        self.wt = scrolledtext.ScrolledText(self,width=100,height=8,relief=rlf[1])
        self.wt.insert('1.0', 'テストテスト')
        self.wt.grid(rowspan=2, column=1, row=2, padx=5, pady=5)
        self.wt.configure(font=font)
        ttk.Label(self, text=u'英文', width=10).grid(column=0, row=4)
        self.etbutton = ttk.Button(self, text=u'Hide', width=6)
        self.etbutton.grid(column=0, row=5)
        self.etbutton.bind('<Button-1>', self.__funcet)
        self.et = scrolledtext.ScrolledText(self,width=100,height=8,relief=rlf[1])
        self.et.insert('1.0', 'テストテスト')
        self.et.grid(rowspan=2, column=1, row=4, padx=5, pady=5)
        self.et.configure(font=font)
        ttk.Label(self, text=u'ヒント', width=10).grid(column=0, row=6)
        self.htbutton = ttk.Button(self, text=u'Hide', width=6)
        self.htbutton.grid(column=0, row=7)
        self.htbutton.bind('<Button-1>', self.__funcht)
        self.ht = scrolledtext.ScrolledText(self,width=100,height=8,relief=rlf[1])
        self.ht.insert('1.0', 'テストテスト')
        self.ht.grid(rowspan=2, column=1, row=6, padx=5, pady=5)
        self.ht.configure(font=font)

    def __funcwt(self, event):
        if event.widget['text'] == u'Hide':
            self.wt.delete(0., tk.END)
            self.wtbutton.configure(text="Show")
        elif event.widget['text'] == u'Show':
            self.insert_wtbox(self.current_data[2])
            self.wtbutton.configure(text="Hide")
    def __funcet(self, event):
        if event.widget['text'] == u'Hide':
            self.et.delete(0., tk.END)
            self.etbutton.configure(text="Show")
        elif event.widget['text'] == u'Show':
            self.insert_etbox(self.current_data[1])
            self.etbutton.configure(text="Hide")
    def __funcht(self, event):
        if event.widget['text'] == u'Hide':
            self.ht.delete(0., tk.END)
            self.htbutton.configure(text="Show")
        elif event.widget['text'] == u'Show':
            self.insert_htbox(self.current_data[8])
            self.htbutton.configure(text="Hide")
    def insert_etbox(self, text):
        self.et.delete(0., tk.END)
        #self.et.insert(0., textwrap.fill(text, self.charcters+10))
        self.et.insert(0., text)
    def getetbox(self):
        return self.et.get(0., tk.END)
    def insert_wtbox(self, text):
        self.wt.delete(0., tk.END)
        #self.wt.insert(0., textwrap.fill(text, self.charcters-13))
        self.wt.insert(0., text)
    def getwtbox(self):
        return self.wt.get(0., tk.END)
    def insert_htbox(self, text):
        self.ht.delete(0., tk.END)
        #self.ht.insert(0., textwrap.fill(text, self.charcters))
        self.ht.insert(0., text)
    def gethtbox(self):
        return self.ht.get(0., tk.END)

    def settextboxframe(self, data):
        self.current_data = data
        if self.etbutton['text']=='Hide':
            self.insert_etbox(data[1])
        if self.wtbutton['text']=='Hide':
            self.insert_wtbox(data[2])
        if self.htbutton['text']=='Hide':
            self.insert_htbox(data[8])
    def settextboxframe_null(self):
        self.et.delete(0., tk.END)
        self.wt.delete(0., tk.END)
        self.ht.delete(0., tk.END)
