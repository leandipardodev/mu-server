import os
import re
import shutil
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
from datetime import datetime

# --- paths: auto-detect MU root (folder that contains MuServer and Cliente) ---
def detect_mu_root():
    # 1) explicit config file next to script: mu_path.txt with a single line path
    here = os.path.dirname(os.path.abspath(__file__))
    cfg = os.path.join(here, 'mu_path.txt')
    if os.path.exists(cfg):
        try:
            with open(cfg, 'r', encoding='utf-8-sig') as f:
                p = f.read().strip().strip('"')
            if p and os.path.isdir(os.path.join(p, 'MuServer')) and os.path.isdir(os.path.join(p, 'Cliente')):
                return p
        except Exception:
            pass
    # 2) walk up from script location
    cur = here
    for _ in range(6):
        if os.path.isdir(os.path.join(cur, 'MuServer')) and os.path.isdir(os.path.join(cur, 'Cliente')):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            break
        cur = parent
    # 3) fallback: script folder
    return here

ROOT = detect_mu_root()
SERVER = os.path.join(ROOT, 'MuServer')
CLIENT = os.path.join(ROOT, 'Cliente')

KEY = [0xFC, 0xCF, 0xAB]

def backup(path):
    if os.path.exists(path):
        stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        try:
            shutil.copy2(path, path + '.bak-editor-' + stamp)
        except Exception:
            pass

def read_latin(path):
    with open(path, 'r', encoding='latin-1', errors='replace') as f:
        return f.read()

def write_latin(path, text):
    backup(path)
    with open(path, 'w', encoding='latin-1', errors='replace', newline='\r\n') as f:
        f.write(text)

# --- BMD helpers (XOR whole buffer) ---
def read_bmd(path):
    with open(path, 'rb') as f:
        data = bytearray(f.read())
    for i in range(len(data)):
        data[i] ^= KEY[i % 3]
    return data

def write_bmd(path, dec):
    backup(path)
    out = bytearray(dec)
    for i in range(len(out)):
        out[i] ^= KEY[i % 3]
    with open(path, 'wb') as f:
        f.write(out)

# --- Message.txt ---
def load_messages(path):
    rows = []
    if not os.path.exists(path):
        return rows
    for line in read_latin(path).splitlines():
        m = re.match(r'^\s*(\d+)\s+"([\s\S]*)"\s*$', line)
        if m:
            rows.append({'id': int(m.group(1)), 'text': m.group(2)})
    rows.sort(key=lambda x: x['id'])
    return rows

def save_messages(path, rows):
    rows = sorted(rows, key=lambda x: int(x['id']))
    out = ['//Index\tMessage']
    for r in rows:
        out.append(f"{int(r['id']):<9} \"{r['text']}\"")
    write_latin(path, '\n'.join(out) + '\n')

# --- Notice.txt ---
def load_notice(path):
    rows = []
    if not os.path.exists(path):
        return rows
    for line in read_latin(path).splitlines():
        t = line.strip()
        if not t or t == 'end' or t.startswith('//'):
            continue
        m = re.match(r'^\s*"([\s\S]*?)"\s*(.*)$', line)
        if m:
            params = m.group(2).strip().split()
            rows.append({'message': m.group(1), 'params': params})
    return rows

def save_notice(path, rows):
    out = ['//Message\t\t\t\t\t\t\t\t\t\t\t\t\tType\tCount\tOpacity\tDelay\tRed\tGreen\tBlue\tSpeed\tRepeatTime']
    for r in rows:
        p = r.get('params') or ['10','1','255','0','255','255','255','10','20']
        out.append('"' + r.get('message','') + '"\t' + '\t'.join(p))
    out.append('end')
    write_latin(path, '\n'.join(out) + '\n')

# --- Monster.txt ---
def load_monsters(path):
    rows = []
    if not os.path.exists(path):
        return rows
    for line in read_latin(path).splitlines():
        if not line.strip() or line.strip().startswith('//'):
            continue
        m = re.match(r'^(\s*\d+\s+\d+\s+)"([^"]*)"(.*)$', line)
        if m:
            idx_m = re.match(r'^\s*(\d+)', line)
            idx = int(idx_m.group(1)) if idx_m else -1
            rows.append({'index': idx, 'name': m.group(2), 'prefix': m.group(1), 'suffix': m.group(3), 'raw': line})
    return rows

def save_monsters(path, rows_by_index):
    if not os.path.exists(path):
        return
    lines = read_latin(path).splitlines()
    new_lines = []
    for line in lines:
        m = re.match(r'^(\s*)(\d+)(\s+\d+\s+)"([^"]*)"(.*)$', line)
        if m:
            idx = int(m.group(2))
            if idx in rows_by_index:
                line = m.group(1) + m.group(2) + m.group(3) + '"' + rows_by_index[idx] + '"' + m.group(5)
        new_lines.append(line)
    write_latin(path, '\n'.join(new_lines) + '\n')

# --- Dialog.bmd ---
def load_dialog(path):
    rows = []
    if not os.path.exists(path):
        return rows
    dec = read_bmd(path)
    rec = 1024
    total = len(dec) // rec
    for i in range(total):
        chunk = dec[i*rec:(i+1)*rec]
        end = chunk.find(b'\x00')
        if end == -1:
            end = rec
        text = chunk[:end].decode('latin-1', errors='replace')
        rows.append({'index': i, 'text': text})
    return rows

def save_dialog(path, rows_map):
    if not os.path.exists(path):
        return
    dec = read_bmd(path)
    rec = 1024
    total = len(dec) // rec
    for idx, text in rows_map.items():
        if idx < 0 or idx >= total:
            continue
        b = text.encode('latin-1', errors='replace')
        if len(b) >= rec:
            b = b[:rec-1]
        off = idx * rec
        for j in range(rec):
            dec[off+j] = 0
        dec[off:off+len(b)] = b
    write_bmd(path, dec)

# --- Slide.bmd ---
def load_slide(path):
    rows = []
    if not os.path.exists(path):
        return rows
    dec = read_bmd(path)
    for r in range(32):
        off = 16 + 256 * r
        if off + 256 > len(dec):
            break
        chunk = dec[off:off+256]
        end = chunk.find(b'\x00')
        if end == -1: end = 256
        rows.append({'index': r, 'text': chunk[:end].decode('latin-1', errors='replace')})
    return rows

def save_slide(path, rows_map):
    if not os.path.exists(path):
        return
    dec = read_bmd(path)
    for idx, text in rows_map.items():
        off = 16 + 256 * idx
        if off + 256 > len(dec):
            continue
        b = text.encode('latin-1', errors='replace')
        if len(b) >= 256:
            b = b[:255]
        dec[off:off+256] = b'\x00' * 256
        dec[off:off+len(b)] = b
    write_bmd(path, dec)

# --- Text.bmd ---
def load_textbmd(path):
    rows = []
    if not os.path.exists(path):
        return rows, 0
    dec = read_bmd(path)
    rec = 300
    total = len(dec) // rec
    for i in range(total):
        off = i*rec
        chunk = dec[off:off+rec]
        end = chunk.find(b'\x00')
        if end == -1: end = rec
        text = chunk[:end].decode('latin-1', errors='replace')
        if text:
            rows.append({'index': i, 'text': text})
    return rows, total

def save_textbmd(path, rows_map):
    if not os.path.exists(path):
        return
    dec = read_bmd(path)
    rec = 300
    total = len(dec) // rec
    for idx, text in rows_map.items():
        if idx < 0 or idx >= total:
            continue
        b = text.encode('latin-1', errors='replace')
        if len(b) >= rec:
            b = b[:rec-1]
        off = idx*rec
        dec[off:off+rec] = b'\x00'*rec
        dec[off:off+len(b)] = b
    write_bmd(path, dec)


TABS = [
    ('Servidor: Message.txt', 'message'),
    ('Servidor: Notice.txt', 'notice'),
    ('Servidor: Monster.txt', 'monster'),
    ('Cliente: Dialog.bmd (NPC)', 'dialog'),
    ('Cliente: Slide.bmd (tips)', 'slide'),
    ('Cliente: Text.bmd', 'textbmd'),
]

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('MU Text Editor - Local')
        self.geometry('1100x700')
        self.current = 'message'
        self.rows = []
        self.all_rows = []
        self.path = ''
        self.edits = {}

        top = ttk.Frame(self)
        top.pack(fill='x', padx=8, pady=6)
        ttk.Label(top, text=f'Carpeta MU: {ROOT}').pack(side='left')
        self.status = ttk.Label(top, text='')
        self.status.pack(side='right')

        nb = ttk.Frame(self)
        nb.pack(fill='x', padx=8)
        for name, key in TABS:
            ttk.Button(nb, text=name, command=lambda k=key: self.switch(k)).pack(side='left', padx=2, pady=2)

        bar = ttk.Frame(self)
        bar.pack(fill='x', padx=8, pady=4)
        ttk.Label(bar, text='Buscar:').pack(side='left')
        self.search_var = tk.StringVar()
        self.search_var.trace_add('write', lambda *a: self.apply_filter())
        ttk.Entry(bar, textvariable=self.search_var, width=30).pack(side='left', padx=4)
        ttk.Button(bar, text='Recargar', command=self.load).pack(side='left', padx=4)
        ttk.Button(bar, text='Guardar', command=self.save).pack(side='left', padx=4)
        self.path_lbl = ttk.Label(bar, text='')
        self.path_lbl.pack(side='left', padx=10)

        self.info = ttk.Label(self, text='', foreground='#444')
        self.info.pack(fill='x', padx=8)

        cols = ('id', 'text')
        self.tree = ttk.Treeview(self, columns=cols, show='headings', selectmode='browse')
        self.tree.heading('id', text='ID/Index')
        self.tree.heading('text', text='Texto')
        self.tree.column('id', width=80, anchor='w')
        self.tree.column('text', width=900, anchor='w')
        vsb = ttk.Scrollbar(self, orient='vertical', command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        self.tree.pack(side='left', fill='both', expand=True, padx=(8,0), pady=8)
        vsb.pack(side='left', fill='y', pady=8)
        self.tree.bind('<Double-1>', self.edit_cell)

        right = ttk.Frame(self)
        right.pack(side='right', fill='y', padx=8, pady=8)
        ttk.Button(right, text='Editar seleccionado', command=self.edit_cell).pack(fill='x', pady=2)
        ttk.Button(right, text='Agregar mensaje (ID)', command=self.add_message).pack(fill='x', pady=2)
        ttk.Label(right, text='Doble clic para editar.\n\nServidor: reiniciar\nGameServer tras guardar.\n\nCliente: cerrar y abrir\nel juego tras guardar.', justify='left').pack(pady=10)

        self.switch('message')

    def switch(self, key):
        self.current = key
        self.edits = {}
        self.search_var.set('')
        notes = {
            'message': 'Mensajes del servidor al usuario. Requiere reiniciar GameServer.',
            'notice': 'Avisos rotativos. Params: Type Count Opacity Delay R G B Speed RepeatTime. Requiere reiniciar GameServer.',
            'monster': 'Nombres de monstruos. Requiere reiniciar GameServer.',
            'dialog': 'Diálogos de NPC en cliente (Dialog.bmd). Reiniciar cliente.',
            'slide': 'Tips de pantalla de carga (Slide.bmd). Reiniciar cliente.',
            'textbmd': 'Descripciones de items/textos (Text.bmd, solo no vacíos). Reiniciar cliente.',
        }
        self.info.config(text=notes.get(key,''))
        self.load()

    def load(self):
        try:
            if self.current == 'message':
                self.path = os.path.join(SERVER, 'Data', 'Message.txt')
                self.all_rows = load_messages(self.path)
            elif self.current == 'notice':
                self.path = os.path.join(SERVER, 'Data', 'Util', 'Notice.txt')
                self.all_rows = load_notice(self.path)
            elif self.current == 'monster':
                self.path = os.path.join(SERVER, 'Data', 'Monster', 'Monster.txt')
                self.all_rows = load_monsters(self.path)
            elif self.current == 'dialog':
                self.path = os.path.join(CLIENT, 'Data', 'Local', 'Dialog.bmd')
                self.all_rows = load_dialog(self.path)
            elif self.current == 'slide':
                self.path = os.path.join(CLIENT, 'Data', 'Local', 'Slide.bmd')
                self.all_rows = load_slide(self.path)
            elif self.current == 'textbmd':
                self.path = os.path.join(CLIENT, 'Data', 'Local', 'Text.bmd')
                self.all_rows, total = load_textbmd(self.path)
            else:
                self.all_rows = []
                self.path = ''
            self.edits = {}
            self.path_lbl.config(text=f'Archivo: {self.path}' if self.path else '')
            self.apply_filter()
            exists = os.path.exists(self.path) if self.path else False
            self.status.config(text=f'{len(self.all_rows)} filas' + ('' if exists else ' (archivo no encontrado)'))
            if self.path and not exists:
                messagebox.showwarning('No encontrado', f'No se encontró el archivo:\n{self.path}')
        except Exception as e:
            messagebox.showerror('Error al cargar', str(e))

    def row_id(self, r):
        if self.current in ('message',): return r['id']
        if self.current in ('monster','dialog','slide','textbmd'): return r['index']
        return ''

    def row_text(self, r):
        if self.current == 'notice': return r.get('message','')
        if self.current == 'monster': return r.get('name','')
        return r.get('text','')

    def apply_filter(self):
        q = self.search_var.get().lower().strip()
        for i in self.tree.get_children():
            self.tree.delete(i)
        for idx, r in enumerate(self.all_rows):
            rid = str(self.row_id(r))
            txt = self.row_text(r)
            if q and q not in rid.lower() and q not in txt.lower():
                continue
            display = txt
            if self.current == 'notice':
                display = txt + '    | params: ' + ' '.join(r.get('params',[]))
            self.tree.insert('', 'end', iid=str(idx), values=(rid, display))

    def selected_index(self):
        sel = self.tree.selection()
        if not sel:
            return None
        return int(sel[0])

    def edit_cell(self, event=None):
        i = self.selected_index()
        if i is None:
            return
        r = self.all_rows[i]
        if self.current == 'notice':
            msg = simpledialog.askstring('Editar mensaje', 'Mensaje:', initialvalue=r.get('message',''), parent=self)
            if msg is None: return
            params = simpledialog.askstring('Editar parámetros', 'Parámetros (separados por espacio/tab):', initialvalue=' '.join(r.get('params',[])), parent=self)
            if params is None: return
            r['message'] = msg
            r['params'] = params.strip().split()
            self.edits[i] = True
        else:
            label = 'Nombre' if self.current=='monster' else 'Texto'
            init = self.row_text(r)
            # multiline dialog
            win = tk.Toplevel(self)
            win.title(f'Editar {label} (ID {self.row_id(r)})')
            win.geometry('700x300')
            txtw = tk.Text(win, wrap='word')
            txtw.pack(fill='both', expand=True, padx=8, pady=8)
            txtw.insert('1.0', init)
            def ok():
                val = txtw.get('1.0', 'end-1c')
                if self.current == 'monster': r['name'] = val
                else: r['text'] = val
                self.edits[i] = True
                win.destroy()
                self.apply_filter()
            def cancel(): win.destroy()
            bf = ttk.Frame(win); bf.pack(pady=4)
            ttk.Button(bf, text='Aceptar', command=ok).pack(side='left', padx=4)
            ttk.Button(bf, text='Cancelar', command=cancel).pack(side='left', padx=4)
            win.transient(self); win.grab_set(); self.wait_window(win)
            return
        self.apply_filter()

    def add_message(self):
        if self.current != 'message':
            messagebox.showinfo('Info', 'Agregar ID nuevo solo aplica a Message.txt')
            return
        sid = simpledialog.askstring('Nuevo mensaje', 'ID (número):', parent=self)
        if not sid: return
        try:
            mid = int(sid)
        except: 
            messagebox.showerror('Error','ID inválido'); return
        text = simpledialog.askstring('Nuevo mensaje', f'Texto para ID {mid}:', parent=self)
        if text is None: return
        # replace if exists
        for r in self.all_rows:
            if r['id'] == mid:
                r['text'] = text
                self.edits['x'] = True
                self.apply_filter(); return
        self.all_rows.append({'id': mid, 'text': text})
        self.all_rows.sort(key=lambda x:x['id'])
        self.edits['x'] = True
        self.apply_filter()

    def save(self):
        try:
            if not self.path or not os.path.exists(self.path):
                messagebox.showerror('Error', 'Archivo no encontrado.'); return
            if self.current == 'message':
                save_messages(self.path, self.all_rows)
            elif self.current == 'notice':
                save_notice(self.path, self.all_rows)
            elif self.current == 'monster':
                m = {r['index']: r['name'] for r in self.all_rows}
                save_monsters(self.path, m)
            elif self.current == 'dialog':
                m = {r['index']: r.get('text','') for r in self.all_rows}
                save_dialog(self.path, m)
            elif self.current == 'slide':
                m = {r['index']: r.get('text','') for r in self.all_rows}
                save_slide(self.path, m)
            elif self.current == 'textbmd':
                m = {r['index']: r.get('text','') for r in self.all_rows}
                save_textbmd(self.path, m)
            self.edits = {}
            messagebox.showinfo('Guardado', f'Guardado en:\n{self.path}\n\nSe creó backup .bak-editor-*')
            self.status.config(text='Guardado OK')
        except Exception as e:
            messagebox.showerror('Error al guardar', str(e))

if __name__ == '__main__':
    app = App()
    app.mainloop()
