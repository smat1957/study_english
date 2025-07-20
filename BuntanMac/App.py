import tkinter as tk
from SearchFrame import SearchFrame
from FieldFrame import FieldFrame
from TextBoxFrame import TextBoxFrame
from DAO import DAO

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        #self.title('英語学習ノート')
        self.title('ガツガツ、ダラダラ ではなく、コツコツと（English）')
        #size = self.maxsize()
        #self.geometry('{}x{} + 0 + 0'.format(*m))
        self.geometry('860x445+100+100')
        self.state('zoomed')
        #self.resizable(0, 0)
        # windows only (remove the minimize/maximize button)
        #self.attributes('-toolwindow', True)

        # layout on the root window
        self.columnconfigure(0, weight=1)
        #self.rowconfigure(0, weight=1)

        self.dao = DAO()
        self.__create_widgets()
        self.__setup()

    def __create_widgets(self):
        # create the field frame
        self.field_frame = FieldFrame(self, self.dao)
        self.field_frame.grid(column=0, row=1)

        # create the textbox frame
        self.textbox_frame = TextBoxFrame(self)
        self.textbox_frame.grid(column=0, row=2)

        # create the search frame
        self.search_frame = SearchFrame(self, self.dao, self.field_frame, self.textbox_frame)
        self.search_frame.grid(column=0, row=0)

        # create the input frame
        ##input_frame = InputFrame(self)
        ##input_frame.grid(column=0, row=0)

        # create the button frame
        ##button_frame = ButtonFrame(self)
        ##button_frame.grid(column=1, row=0)

    def __setup(self):
        booklist = self.dao.distinct('book')
        list = []
        for v in booklist:
            list.append(v[0])
        self.field_frame.setbooklist(list, 0)

