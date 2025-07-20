#from App import App
from DAO import DAO
import csv
if __name__ == "__main__":
    dao = DAO()
    # ID, 英文, 和文, 行, 頁, 題目, 主題, 分野, 本, 備考
    # ID, 英文, 和文, ヒント, 行, 頁, 章, 題目, 主題, 分野, 本, 備考
    """
    sql = "select * from ecompo0 order by book asc, page asc, line asc, id asc"
    list = []
    for i, v in enumerate(dao.cur.execute(sql)):
        list.append(v)
    """
    """
    with open('db/sample2_writer.csv', 'w') as f:
        writer = csv.writer(f)
        # writer.writerows(list)
        lst = []
        for i, v in enumerate(list):
            print(i,v)
            if i<3:
                lst.append(v[i])
            elif i==3:
                lst.append("")
                lst.append(v[i])
            elif i==4:
                lst.append(v[i])
                lst.append("")
            else:
                lst.append(v[i])
            writer.writerow(v)
    """
    
    dao.cur.execute("DROP table ecompo1")
    sql = ("CREATE TABLE ecompo1(id integer primary key autoincrement unique,"
           "eibun text,wabun text,hint text, line integer,page integer,chap integer,"
           "title text,topic text,field text,book text,description text)")
    dao.cur.execute(sql)
    i0 = 0
    with open('db/sample_writer.csv', 'r', encoding='utf-8') as f:
        for i, k in enumerate(csv.reader(f)):
            if 0 < i:
                i0 = i0 + 1
                if k[8] == '準1級：英作文完全制覇':
                    #        ID, 英文,  和文, ,    , 行, 頁, , ,  題目,  主題, 分野,     本,           備考
                    #        ID, 英文,  和文, ヒント, 行, 頁, 章,   題目,  主題, 分野,     本,           備考
                    data = [(i0, k[1], k[2], k[9], k[3], k[4], "0", k[5], k[6], k[7], '準1級：完全制覇', "")]
                    #print(data)
                    dao.cur.executemany("INSERT INTO ecompo1 VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", data)
                elif k[8] == '入試：基礎英作文問題精講':
                    data = [(i0, k[1], k[2], k[9], k[3], k[4], "0", k[5], k[6], k[7], '入試：基礎精講', "")]
                    dao.cur.executemany("INSERT INTO ecompo1 VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", data)
                elif k[8] == '準1級：文単':
                    data = [(i0, k[1], k[2], k[9], k[3], k[4], "0", k[5], k[6], k[7], '準1級：文単', "")]
                    dao.cur.executemany("INSERT INTO ecompo1 VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", data)

    sql = "select * from ecompo1 order by book asc, page asc, line asc, id asc"
    list = []
    for i, v in enumerate(dao.cur.execute(sql)):
        list.append(v)
    print("list:",list)
    """
    """
    with open('db/sample2_writer.csv', 'w') as f:
        writer = csv.writer(f)
        writer.writerows(list)

    """
    #print(len(list))
    #for v in list:
    #    print(v)
    #app = App()
    #app.mainloop()
    """