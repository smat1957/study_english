from tkinter import ttk

class SearchFrame(ttk.Frame):
    def __init__(self, container, dao, fieldframe, textboxframe):
        super().__init__(container)
        self.dao = dao
        self.field_frame = fieldframe
        self.textbox_frame = textboxframe
        self.current = 0
        self.size = 0
        self.current_id = -1
        # setup the grid layout manager
        self.columnconfigure(0, weight=1)  # Rand/Sorted, Checkbutton
        self.columnconfigure(1, weight=1)   # :
        self.columnconfigure(2, weight=1)   # First
        self.columnconfigure(3, weight=1)   # Prev
        self.columnconfigure(4, weight=1)   # curr/total
        self.columnconfigure(5, weight=1)   # Next
        self.columnconfigure(6, weight=1)   # Last
        self.columnconfigure(7, weight=1)   # :
        self.columnconfigure(8, weight=1)  # Search
        self.columnconfigure(9, weight=1)  # Combobox
        self.columnconfigure(10, weight=1)  # :
        self.columnconfigure(11, weight=1)  # New/Save
        self.columnconfigure(12, weight=1)  # Edit/Update
        self.columnconfigure(13, weight=1)  # Delete
        self.__create_widgets()

    def __create_widgets(self):
        ttk.Checkbutton(self, text=u'乱/順', variable=[False, True]).grid(column=0, row=0)
        ttk.Label(self, text=u'：').grid(column=1, row=0)
        fstbutton=ttk.Button(self, text=u'First', width=3)
        fstbutton.grid(column=2, row=0)
        fstbutton.bind('<Button-1>', self.__func1)
        prvbutton=ttk.Button(self, text=u'Prev', width=3)
        prvbutton.grid(column=3, row=0)
        prvbutton.bind('<Button-1>', self.__func2)
        self.locate = ttk.Label(self, text=u'999/999')
        self.locate.grid(column=4, row=0)
        nxtbutton=ttk.Button(self, text=u'Next', width=3)
        nxtbutton.grid(column=5, row=0)
        nxtbutton.bind('<Button-1>', self.__func3)
        lstbutton=ttk.Button(self, text=u'Last', width=3)
        lstbutton.grid(column=6, row=0)
        lstbutton.bind('<Button-1>', self.__func4)
        ttk.Label(self, text=u'：').grid(column=7, row=0)
        searchbutton = ttk.Button(self, text=u'Search', width=5)
        searchbutton.grid(column=8, row=0)
        searchbutton.bind('<Button-1>', self.__func0)
        self.stype = ['Book', 'Field&Book', 'Topic&Book', 'Title&Book', 'Page&Book']
        self.searchbox = ttk.Combobox(self, values=self.stype, justify="left", height=1, width=16, state='readonly')
        self.searchbox.grid(column=9, row=0)
        self.searchbox.current(0)
        ttk.Label(self, text=u'：').grid(column=10, row=0)
        self.newbutton = ttk.Button(self, text=u'New', width=3)
        self.newbutton.grid(column=11, row=0)
        self.newbutton.bind('<Button-1>', self.__funcnew)
        self.editbutton = ttk.Button(self, text=u'Edit', width=3)
        self.editbutton.grid(column=12, row=0)
        self.editbutton.bind('<Button-1>', self.__funcedit)
        self.delbutton = ttk.Button(self, text=u'Del', width=3)
        self.delbutton.grid(column=13, row=0)
        self.delbutton.bind('<Button-1>', self.__funcdel)

    def __funcdel(self, event):
        self.dao.delete(self.current_id)
    def __funcedit(self, event):
        if event.widget['text']==u'Edit':
            book = self.field_frame.booklist.get()
            self.field_frame.destroybook()
            self.field_frame.setbook(book)
            self.editbutton.configure(text="Update")
            self.newbutton.configure(text="Save")
        elif event.widget['text']==u'Update':
            et = self.textbox_frame.getetbox()
            wt = self.textbox_frame.getwtbox()
            ht = self.textbox_frame.gethtbox()
            ln = self.field_frame.getline()
            pg = self.field_frame.getpage()
            tl = self.field_frame.gettitle()
            tc = self.field_frame.gettopic()
            fd = self.field_frame.getfield()
            book = self.field_frame.booklist.get()
            self.dao.update(self.current_id, et,wt,ln,pg,tl,tc,fd,book,ht)
            self.field_frame.buildbook(book)
            self.editbutton.configure(text="Edit")
            self.newbutton.configure(text="New")
    def __funcnew(self, event):
        if event.widget['text']==u'New':
            self.current=0
            self.size = 0
            self.current_collection = []
            self.locate['text'] = str(self.current + 1) + '/' + str(self.size)
            self.textbox_frame.settextboxframe_null()
            self.field_frame.setfieldframe_null()
            self.field_frame.destroybook()
            self.newbutton.configure(text="Save")
        elif event.widget['text'] == u'Save':
            et = self.textbox_frame.getetbox()
            wt = self.textbox_frame.getwtbox()
            ht = self.textbox_frame.gethtbox()
            ln = self.field_frame.getline()
            pg = self.field_frame.getpage()
            tl = self.field_frame.gettitle()
            tc = self.field_frame.gettopic()
            fd = self.field_frame.getfield()
            book = self.field_frame.getbook()
            self.dao.newrec(et,wt,ln,pg,tl,tc,fd,book,ht)
            #self.searchbox.current()
            self.do_search(self.searchbox.get())
            self.__setevery(self.current_collection[self.current])
            self.field_frame.buildbook(book)
            self.newbutton.configure(text="New")
            self.editbutton.configure(text="Edit")
            self.textbox_frame.wtbutton.configure(text="Hide")
            self.textbox_frame.etbutton.configure(text="Hide")
            self.textbox_frame.htbutton.configure(text="Hide")
    def __func0(self, event):
        self.do_search(self.searchbox.get())
        self.__setevery(self.current_collection[self.current])

    def __func1(self, event):
        self.current=0
        self.__setevery(self.current_collection[self.current])

    def __func2(self, event):
        if self.current>0:
            self.current -= 1
            self.__setevery(self.current_collection[self.current])

    def __func3(self, event):
        if self.current<self.size-1:
            self.current += 1
            self.__setevery(self.current_collection[self.current])

    def __func4(self, event):
        self.current = self.size-1
        self.__setevery(self.current_collection[self.current])

    def do_search(self, stype):
        book = self.field_frame.booklist.get()
        num = -1
        for i, v in enumerate(self.stype):
            if v==stype:
                num = i
                break
        if num == 0:
            self.current_collection = self.dao.all(book)
        elif num == 1:
            field = self.field_frame.getfield()
            self.current_collection = self.dao.withfield(book, field)
        elif num == 2:
            topic = self.field_frame.gettopic()
            self.current_collection = self.dao.withtopic(book, topic)
        elif num == 3:
            title = self.field_frame.gettitle()
            self.current_collection = self.dao.withtitle(book, title)
        elif num == 4:
            page = self.field_frame.getpage()
            self.current_collection = self.dao.withpage(book, page)
        #elif num == 5:
        #    word = self.field_frame.getword()
        #    self.current_collection = self.dao.withword(book, word)
        self.current = 0
        self.size = len(self.current_collection)
        self.locate['text']=str(self.current+1)+'/'+str(self.size)

    def getcurrentcollection(self):
        return self.current_collection

    def __setevery(self, data):
        self.locate['text'] = str(self.current + 1) + '/' + str(self.size)
        self.current_id = data[0]
        self.textbox_frame.settextboxframe(data)
        self.field_frame.setfieldframe(data)
