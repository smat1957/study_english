import sqlite3
import csv

class DAO:
    def __init__(self):
        self.con = sqlite3.connect("db/ecompo_alt_sqlite3.db", isolation_level=None)
        self.cur = self.con.cursor()

    def create_db(self):
        self.cur.execute("DROP table ecompo0")
        sql = ("CREATE TABLE ecompo0(id integer primary key autoincrement unique,"
               "eibun text,wabun text,line integer,page integer,title text,topic text,field text,book text,description text)")
        self.cur.execute(sql)
        i0 = 1
        with open('db/ecompo.csv', 'r', encoding='utf-8') as f:
            for i, k in enumerate(csv.reader(f)):
                if 0 < i:
                    i0 = i0 + 1
                    if k[7] == '準1級完全制覇':
                        data = [(i0, k[1], k[2], 1, k[3], k[4], k[5], k[6], '準1級：英作文完全制覇', k[8])]
                        self.cur.executemany("INSERT INTO ecompo0 VALUES(?,?,?,?,?,?,?,?,?,?)", data)
                    elif k[7] == '基礎英作文問題精講':
                        data = [(i0, k[1], k[2], 1, k[3], k[4], k[5], k[6], '入試：基礎英作文問題精講', k[8])]
                        self.cur.executemany("INSERT INTO ecompo0 VALUES(?,?,?,?,?,?,?,?,?,?)", data)
        for row in self.cur.execute(
                "SELECT id, eibun, wabun, line, page, title, topic, field, book, description from ecompo0"):
            print(row)
        self.con.close()

    def distinct(self, field):
        sql = 'SELECT DISTINCT ' + field + ' FROM ecompo0'
        return self.cur.execute(sql)
    def all(self, bk):
        sql = 'SELECT id, eibun, wabun, line, page, title, topic, field, description from ecompo0'
        sql += ' where book="' +  bk + '"'
        sql += " order by page asc, line asc"
        list=[]
        for v in self.cur.execute(sql):
            list.append(v)
        return list
    def withfield(self, bk, fld):
        sql = 'SELECT id, eibun, wabun, line, page, title, topic, field, description from ecompo0'
        sql += ' where book="' +  bk + '" and field="' + fld + '"'
        sql += " order by page asc, line asc"
        list=[]
        for v in self.cur.execute(sql):
            list.append(v)
        return list
    def withtopic(self, bk, tpc):
        sql = 'SELECT id, eibun, wabun, line, page, title, topic, field, description from ecompo0'
        sql += ' where book="' +  bk + '" and topic="' + tpc + '"'
        sql += " order by page asc, line asc"
        list=[]
        for v in self.cur.execute(sql):
            list.append(v)
        return list
    def withtitle(self, bk, ttl):
        sql = 'SELECT id, eibun, wabun, line, page, title, topic, field, description from ecompo0'
        sql += ' where book="' +  bk + '" and title="' + ttl + '"'
        sql += " order by page asc, line asc"
        list=[]
        for v in self.cur.execute(sql):
            list.append(v)
        return list
    def withpage(self, bk, pg):
        sql = 'SELECT id, eibun, wabun, line, page, title, topic, field, description from ecompo0'
        sql += ' where book="' +  bk + '" and page=' + pg
        sql += " order by page asc, line asc"
        list=[]
        for v in self.cur.execute(sql):
            list.append(v)
        return list
    def withword(self, bk, wrd):
        sql = "SELECT id, eibun, wabun, line, page, title, topic, field, description from ecompo0"
        sql += " where book='" +  bk + "' and eibun LIKE '%" + wrd + "%'"
        sql += " order by page asc, line asc"
        list=[]
        for v in self.cur.execute(sql):
            list.append(v)
        return list
    def newrec(self, et, wt, ln, pg, tl, tc, fd, bk, ds):
        data = [(et, wt, ln, pg, tl, tc, fd, bk, ds)]
        sql = 'INSERT INTO ecompo0(eibun,wabun,line,page,title,topic,field,book,description) VALUES(?,?,?,?,?,?,?,?,?)'
        self.cur.executemany(sql, data)
    def update(self, id, et, wt, ln, pg, tl, tc, fd, bk, ds):
        sql = 'update ecompo0 SET eibun=?,wabun=?,line=?,page=?,title=?,topic=?,field=?,book=?,description=? WHERE id=?'
        self.cur.execute(sql, (et, wt, ln, pg, tl, tc, fd, bk, ds, id))
    def delete(self, id):
        sql = 'DELETE FROM ecompo0 WHERE id=?'
        self.cur.execute(sql, id)