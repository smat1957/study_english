import json
import sys
import subprocess

def json_load(path, fname):
    with open(path+fname, 'r', encoding='utf-8') as f:
        books = json.load(f)
    return books

if __name__ == '__main__':
    path = '/Users/mat/Documents/'
    fname = 'output.json'
    books = json_load(path, fname)
    # 'numb'フィールドの値だけを取り出す
    numb_values = [item['numb'] for item in books if 'numb' in item and isinstance(item['numb'], int)]
    # 最小値と最大値を求める
    min_numb = str(min(numb_values))
    max_numb = str(max(numb_values))
    if numb_values:
        print(f"最小値: {min(numb_values)}, 最大値: {max(numb_values)}")
    else:
        print("有効な 'numb' フィールドが見つかりませんでした。")
    #
    encode = '% latex uft-8'
    header = '\\documentclass[uplatex,dvipdfmx,a4paper,10pt,oneside,openany]{jsarticle}'
    package = '\\usepackage{fancyhdr}'
    begin = '\\begin{document}'
    bk = books[0]['book']
    sg = books[0]['stage']
    #tp = books[0]['numb']
    #tt = books[0]['title']
    fancy1 = '\\pagestyle{fancy}'
    fancy2 = '\\fancyhf{'+bk+'}'
    fancy3 = '\\fancyhead[L]{Unit：'+sg+'}'
    fancy4 = '\\fancyhead[R]{'+min_numb+'〜'+max_numb+"}"
    fancy5 = '\\fancyfoot[L]{\\thepage}'
    fancy6 = '\\fancyfoot[R]{\\today}'
    end = '\\end{document}'
    vfill = '\\vfill'
    newpage = '\\newpage'
    path = '/Users/mat/Documents/PycharmProjects/json2tex4EWord/'
    fname = sys.argv[1]+".tex"
    try:
        with open(path+fname, 'w', encoding='utf-8') as f:
            f.write(encode + '\n')
            f.write(header + '\n')
            f.write(package + '\n')
            f.write(begin + '\n')
            f.write(fancy1 + '\n')
            f.write(fancy2 + '\n')
            f.write(fancy3 + '\n')
            f.write(fancy4 + '\n')
            f.write(fancy5 + '\n')
            f.write(fancy6 + '\n')
            i = 1
            for item in books:
                f.write("(P." + str(item['page']) + ", L." + str(item['numb']) + ")" + item['wabun'] + '\n')
                f.write(vfill + '\n')
                if i%(len(books)//2)==0:
                    f.write(newpage + '\n')
                i += 1
            f.write(end + '\n')
            f.close()
    except IOError as e:
        print("ファイル書き込みエラー", e)
    #path = '/Users/mat/Documents/PycharmProjects/json2tex4EWord/'
    #result = subprocess.run('sh '+path+'do1.sh eitango', shell=True, capture_output=True, text=True)
    #print(result.stdout)
    #result = subprocess.run('sh '+path+'do2.sh eitango', shell=True, capture_output=True, text=True)