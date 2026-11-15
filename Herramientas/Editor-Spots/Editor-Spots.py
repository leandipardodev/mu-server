import os
import re
import shutil
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog, filedialog
from datetime import datetime

try:
    from PIL import Image, ImageTk
    HAS_PIL = True
except Exception:
    HAS_PIL = False

# ---------- paths ----------
def detect_mu_root():
    here = os.path.dirname(os.path.abspath(__file__))
    cfg = os.path.join(here, 'mu_path.txt')
    if os.path.exists(cfg):
        try:
            with open(cfg, 'r', encoding='utf-8-sig') as f:
                p = f.read().strip().strip('"')
            if p and os.path.isdir(os.path.join(p, 'MuServer')):
                return p
        except Exception:
            pass
    cur = here
    for _ in range(6):
        if os.path.isdir(os.path.join(cur, 'MuServer')) and os.path.isdir(os.path.join(cur, 'Cliente')):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            break
        cur = parent
    return here

ROOT = detect_mu_root()
SERVER = os.path.join(ROOT, 'MuServer')
DATA_MONSTER = os.path.join(SERVER, 'Data', 'Monster')
IMAGES_DIR = os.path.join(SERVER, 'Tools', 'MonsterSpawnEditorV1.01', 'MonsterSpawnEditor', 'Images')

SPAWN_FILES = ['MonsterSetBase.txt', 'MonsterSetBaseCS.txt']

# map number -> (name, image filename candidates)
MAP_INFO = {
    0: ('Lorencia', ['Lorencia.png']),
    1: ('Dungeon', ['Dungeon.png']),
    2: ('Devias', ['Devias.png']),
    3: ('Noria', ['Noria.png']),
    4: ('Lost Tower', ['Lost_Tower.png']),
    6: ('Arena/Stadium', ['Stadium.png']),
    7: ('Atlans', ['Atlans.png']),
    8: ('Tarkan', ['Tarkan.png']),
    10: ('Icarus', ['Icarus.png']),
    30: ('Valley of Loren', ['Valley_of_Loren.png', 'Lorencia.png']),
    31: ('Land of Trials', ['Land_of_Trials.png']),
    33: ('Aida', ['Aida.png']),
    34: ('Crywolf Fortress', ['Crywolf.png']),
    37: ('Kanturu 1', ['Kanturu_1.png']),
    38: ('Kanturu 2', ['Kanturu_2.png']),
    39: ('Kanturu 3', ['Kanturu_3.png']),
    41: ('Barracks', ['Barracks_of_Balgass.png', 'Barracks.png']),
    42: ('Refuge', ['Balgass_Refuge.png', 'Refuge.png']),
    51: ('Elbeland', ['Elbeland.png']),
    56: ('Swamp of Calmness', ['Swamp_of_Peace.png', 'Swamp_of_Calmness.png']),
    57: ('Raklion', ['Raklion_1.png']),
    58: ('Raklion Boss', ['Raklion_2.png']),
    63: ('Vulcanus', ['Vulcanus.png']),
    64: ('Duel Arena', ['Duel_Arena.png']),
    80: ('Karutan 1', ['Karutan_1.png']),
    81: ('Karutan 2', ['Karutan_2.png']),
}

def map_name(m):
    if m in MAP_INFO: return MAP_INFO[m][0]
    return f'Mapa {m}'

def find_map_image(map_no):
    if not os.path.isdir(IMAGES_DIR): return None
    cands = []
    if map_no in MAP_INFO:
        cands.extend(MAP_INFO[map_no][1])
    # generic guesses
    cands.extend([f'{map_no}.png', f'Map{map_no}.png'])
    for c in cands:
        p = os.path.join(IMAGES_DIR, c)
        if os.path.exists(p): return p
    # try contains map name
    name = MAP_INFO.get(map_no, (str(map_no),))[0].lower().replace(' ', '_')
    try:
        for f in os.listdir(IMAGES_DIR):
            if f.lower().endswith('.png') and name.split('_')[0] in f.lower():
                return os.path.join(IMAGES_DIR, f)
    except Exception:
        pass
    return None

# ---------- data ----------
class Spawn:
    __slots__ = ('block','monster','map','range_','x','y','dir','comment','uid')
    def __init__(self, block, monster, map_, range_, x, y, dir_, comment, uid):
        self.block=block; self.monster=monster; self.map=map_; self.range_=range_
        self.x=x; self.y=y; self.dir=dir_; self.comment=comment; self.uid=uid

class BlockMeta:
    # preserve non-spawn lines inside block? easier: store list of (kind, data)
    # kind 'c' = comment/raw line, 's' = spawn
    def __init__(self, index, items):
        self.index = index
        self.items = items  # list of tuples ('c', line) or ('s', Spawn)

_uid_counter = 0
def next_uid():
    global _uid_counter; _uid_counter += 1; return _uid_counter

SPAWN_RE = re.compile(r'^\s*(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)(.*)$')

def parse_spawn_file(path):
    blocks = []
    if not os.path.exists(path):
        return blocks
    with open(path,'r',encoding='latin-1',errors='replace') as f:
        lines = f.read().splitlines()
    i=0; n=len(lines)
    while i<n:
        line = lines[i].strip()
        if re.fullmatch(r'-?\d+', line):
            bidx = int(line); i+=1
            items=[]
            while i<n and lines[i].strip().lower()!='end':
                raw = lines[i]
                s = raw.strip()
                if s=='' or s.startswith('//'):
                    items.append(('c', raw))
                else:
                    m = SPAWN_RE.match(raw)
                    if m:
                        comment = m.group(7).strip()
                        if comment.startswith('//'): comment = comment[2:].strip()
                        sp = Spawn(bidx, int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4)), int(m.group(5)), int(m.group(6)), comment, next_uid())
                        items.append(('s', sp))
                    else:
                        items.append(('c', raw))
                i+=1
            # consume end
            if i<n and lines[i].strip().lower()=='end':
                i+=1
            blocks.append(BlockMeta(bidx, items))
        else:
            # orphan/comment outside block - store as special block?
            # accumulate until next block index
            # but easier to attach to a pseudo block not saved; try to skip
            # Better: keep as a raw block with index None
            # gather
            raw_items=[]
            # but if it's a comment at top, handle
            # detect: if next meaningful is number maybe; easier approach: treat standalone // as ignored preamble not in block
            # For simplicity, ignore preamble lines before first block; but file starts with comments then 0
            if line=='' or line.startswith('//'):
                i+=1; continue
            i+=1
    return blocks

def format_spawn(sp):
    c = (' //'+sp.comment) if sp.comment else ''
    return f"{sp.monster:<14} {sp.map:<14} {sp.range_:<10} {sp.x:<14} {sp.y:<14} {sp.dir:<14}{c}"

def write_spawn_file(path, blocks):
    if os.path.exists(path):
        stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        shutil.copy2(path, path + '.bak-spots-' + stamp)
    out = []
    for b in blocks:
        out.append(str(b.index))
        for kind, data in b.items:
            if kind=='c':
                out.append(data)
            else:
                out.append(format_spawn(data))
        out.append('end')
        out.append('')
    # remove trailing extra blank line
    text = '\n'.join(out).rstrip('\n') + '\n'
    with open(path,'w',encoding='latin-1',errors='replace',newline='\r\n') as f:
        f.write(text)

def load_monsters(path):
    names = {}
    if not os.path.exists(path): return names
    with open(path,'r',encoding='latin-1',errors='replace') as f:
        for line in f:
            if not line.strip() or line.strip().startswith('//'): continue
            m = re.match(r'^\s*(\d+)\s+\d+\s+"([^"]*)"', line)
            if m:
                names[int(m.group(1))] = m.group(2)
    return names

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('MU - Editor de Spots (Spawns)')
        self.geometry('1400x860')
        self.minsize(1100,700)

        self.spawn_file = SPAWN_FILES[0]
        self.blocks = []
        self.spawns = [] # flat refs
        self.monsters = {}
        self.filtered = []
        self.selected_uid = None
        self.map_no = 0
        self.zoom = 2.0
        self.pan = [20,20]
        self.dragging = None
        self.pan_start = None
        self.img_orig = None
        self.img_tk = None
        self.invert_x = tk.BooleanVar(value=False)
        self.invert_y = tk.BooleanVar(value=True)
        self.swap_xy = tk.BooleanVar(value=False)
        self.off_x = tk.DoubleVar(value=0.0)
        self.off_y = tk.DoubleVar(value=0.0)

        self.build_ui()
        self.load_all()

    def build_ui(self):
        top = ttk.Frame(self); top.pack(fill='x', padx=8, pady=6)
        ttk.Label(top, text=f'MU: {ROOT}').pack(side='left')
        self.status = ttk.Label(top, text=''); self.status.pack(side='right')

        bar = ttk.Frame(self); bar.pack(fill='x', padx=8, pady=2)
        ttk.Label(bar, text='Archivo:').pack(side='left')
        self.file_var = tk.StringVar(value=self.spawn_file)
        cbf = ttk.Combobox(bar, textvariable=self.file_var, values=SPAWN_FILES, state='readonly', width=22)
        cbf.pack(side='left', padx=4); cbf.bind('<<ComboboxSelected>>', lambda e:self.change_file())
        ttk.Button(bar, text='Recargar', command=self.load_all).pack(side='left', padx=4)
        ttk.Button(bar, text='Guardar', command=self.save).pack(side='left', padx=4)
        ttk.Separator(bar, orient='vertical').pack(side='left', fill='y', padx=6)
        ttk.Label(bar, text='Mapa:').pack(side='left')
        self.map_var = tk.StringVar(value='0 - Lorencia')
        self.map_cb = ttk.Combobox(bar, textvariable=self.map_var, width=28)
        self.map_cb.pack(side='left', padx=4); self.map_cb.bind('<<ComboboxSelected>>', lambda e:self.on_map_change())
        ttk.Label(bar, text='Buscar:').pack(side='left', padx=(8,2))
        self.search_var = tk.StringVar(); self.search_var.trace_add('write', lambda *a:self.refresh_list())
        ttk.Entry(bar, textvariable=self.search_var, width=18).pack(side='left')
        ttk.Button(bar, text='Zoom +', command=lambda:self.set_zoom(self.zoom*1.25)).pack(side='left', padx=3)
        ttk.Button(bar, text='Zoom -', command=lambda:self.set_zoom(self.zoom/1.25)).pack(side='left', padx=2)
        ttk.Button(bar, text='Ajustar', command=self.fit_map).pack(side='left', padx=2)
        ttk.Separator(bar, orient='vertical').pack(side='left', fill='y', padx=6)
        ttk.Checkbutton(bar, text='Invertir Y', variable=self.invert_y, command=self.redraw).pack(side='left')
        ttk.Checkbutton(bar, text='Invertir X', variable=self.invert_x, command=self.redraw).pack(side='left')
        ttk.Checkbutton(bar, text='Intercambiar X/Y', variable=self.swap_xy, command=self.redraw).pack(side='left')
        ttk.Label(bar, text='Desplazar X:').pack(side='left', padx=(6,2))
        tk.Spinbox(bar, from_=-50, to=50, increment=0.5, textvariable=self.off_x, width=5, command=self.redraw).pack(side='left')
        ttk.Label(bar, text='Y:').pack(side='left', padx=(4,2))
        tk.Spinbox(bar, from_=-50, to=50, increment=0.5, textvariable=self.off_y, width=5, command=self.redraw).pack(side='left')

        main = ttk.Panedwindow(self, orient='horizontal'); main.pack(fill='both', expand=True, padx=8, pady=6)
        left = ttk.Frame(main); right = ttk.Frame(main)
        main.add(left, weight=3); main.add(right, weight=2)

        # canvas
        self.canvas = tk.Canvas(left, background='#1a1a1a', highlightthickness=0)
        self.canvas.pack(fill='both', expand=True)
        self.canvas.bind('<Configure>', lambda e:self.redraw())
        self.canvas.bind('<Button-1>', self.on_click)
        self.canvas.bind('<B1-Motion>', self.on_drag)
        self.canvas.bind('<ButtonRelease-1>', self.on_release)
        self.canvas.bind('<Double-Button-1>', self.on_double_click)
        self.canvas.bind('<Button-3>', self.on_right_pan_start)
        self.canvas.bind('<B3-Motion>', self.on_right_pan)
        self.canvas.bind('<MouseWheel>', self.on_wheel)
        self.coord_lbl = ttk.Label(left, text='Coords: -  |  Clic izq: seleccionar/mover  |  Clic der: mover mapa  |  Rueda: zoom')
        self.coord_lbl.pack(fill='x')

        # right: list and editor
        rtop = ttk.Frame(right); rtop.pack(fill='x')
        ttk.Button(rtop, text='Nuevo spot', command=self.new_spawn).pack(side='left', padx=2)
        ttk.Button(rtop, text='Duplicar', command=self.dup_spawn).pack(side='left', padx=2)
        ttk.Button(rtop, text='Eliminar', command=self.delete_spawn).pack(side='left', padx=2)

        cols=('uid','mon','nombre','x','y','range','dir','blk','com')
        self.tree = ttk.Treeview(right, columns=cols, show='headings', height=18)
        for c,t,w in [('uid','ID',40),('mon','Mon',45),('nombre','Nombre',130),('x','X',40),('y','Y',40),('range','Rango',45),('dir','Dir',40),('blk','Bloque',45),('com','Comentario',140)]:
            self.tree.heading(c,text=t); self.tree.column(c,width=w,anchor='w')
        vsb = ttk.Scrollbar(right, orient='vertical', command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        self.tree.pack(fill='both', expand=True, side='left')
        vsb.pack(fill='y', side='left')
        self.tree.bind('<<TreeviewSelect>>', lambda e:self.on_select())

        form = ttk.LabelFrame(right, text='Editar spot seleccionado'); form.pack(fill='x', pady=6)
        self.fvars = {}
        fields = [
            ('Monstruo/NPC (ID)','monster','ID del monstruo o NPC (según Monster.txt). Usá "Buscar" para elegir por nombre.'),
            ('Mapa','map','Número de mapa donde aparece (ej. 0=Lorencia, 2=Devias, 3=Noria).'),
            ('Rango / Área','range_','Radio/área de aparición alrededor del punto. 0 = posición fija. Valores mayores = aparece en un área más amplia (dispersión).'),
            ('Posición X','x','Coordenada X en el mapa (0 a 255).'),
            ('Posición Y','y','Coordenada Y en el mapa (0 a 255).'),
            ('Dirección','dir','Orientación del NPC/monstruo (0-7). Para monstruos suele usarse -1 (aleatoria).'),
            ('Bloque (grupo)','block','Grupo interno del archivo MonsterSetBase (0,1,2,3,4...). Define cómo se carga el spawn. Si no sabés, dejá el valor que tenía.'),
            ('Comentario','comment','Nota para identificar el spawn (ej. nombre del NPC/monstruo). No afecta al juego.'),
        ]
        def show_field_help(title,text):
            messagebox.showinfo(title,text,parent=self)
        for i,(lab,key,helptext) in enumerate(fields):
            ttk.Label(form,text=lab).grid(row=i,column=0,sticky='w',padx=4,pady=2)
            v=tk.StringVar(); self.fvars[key]=v
            e=ttk.Entry(form,textvariable=v,width=22); e.grid(row=i,column=1,sticky='w',padx=4,pady=2)
            ttk.Button(form,text='?',width=2,command=lambda t=lab,h=helptext: show_field_help(t,h)).grid(row=i,column=2,padx=2)
            if key=='monster':
                ttk.Button(form,text='Buscar',command=self.pick_monster,width=7).grid(row=i,column=3,padx=2)
        self.mon_name_lbl = ttk.Label(form,text='',foreground='#444'); self.mon_name_lbl.grid(row=0,column=4,sticky='w',padx=4)
        ttk.Button(form,text='Aplicar cambios al spot',command=self.apply_form).grid(row=len(fields),column=0,columnspan=4,pady=6,padx=4,sticky='w')
        self.fvars['monster'].trace_add('write', lambda *a:self.update_mon_label())

        tips = (
            "Cómo usar:\n"
            "• Elegí archivo/mapa, seleccioná un spot en la lista o en el mapa. Arrastrá el punto para moverlo.\n"
            "• \"Nuevo spot\" crea un spot en el mapa actual (ajustá sus datos y aplicá). \"Duplicar\" copia el seleccionado.\n"
            "• Si los puntos no coinciden con la imagen: usá Invertir X/Y, Intercambiar X/Y y Desplazar X/Y arriba.\n\n"
            "Sobre cantidad/densidad:\n"
            "• En este formato (MonsterSetBase) no hay una columna de \"cantidad\". Para más monstruos en un lugar: duplicá/agregá más líneas de spawn del mismo monstruo o ajustá el Rango/área.\n"
            "• Rango 0 = posición fija; rango mayor = aparece dentro de un área.\n\n"
            "Guardá y reiniciá el GameServer para aplicar."
        )
        help_txt = ttk.Label(right, text=tips, wraplength=420, justify='left', foreground='#333')
        help_txt.pack(fill='x', pady=4)
        if not HAS_PIL:
            ttk.Label(right, text='Nota: instalá Pillow (pip install pillow) para ver imágenes de mapas. Sin eso el mapa se muestra como grilla.', foreground='#a40', wraplength=380).pack(fill='x')

    def change_file(self):
        self.spawn_file = self.file_var.get()
        self.load_all()

    def load_all(self):
        try:
            self.monsters = load_monsters(os.path.join(DATA_MONSTER, 'Monster.txt'))
            path = os.path.join(DATA_MONSTER, self.spawn_file)
            self.blocks = parse_spawn_file(path)
            self.rebuild_flat()
            self.refresh_maps()
            self.refresh_list()
            self.status.config(text=f'Cargado {os.path.basename(path)} - {len(self.spawns)} spawns')
        except Exception as e:
            messagebox.showerror('Error', str(e))

    def rebuild_flat(self):
        self.spawns = []
        for b in self.blocks:
            for kind,data in b.items:
                if kind=='s': self.spawns.append(data)

    def refresh_maps(self):
        maps = sorted(set(s.map for s in self.spawns))
        # ensure common maps present
        for m in [0,1,2,3,4,6,7,8,10]: 
            if m not in maps: maps.append(m)
        maps = sorted(set(maps))
        vals = [f'{m} - {map_name(m)}' for m in maps]
        self.map_cb['values'] = vals
        # keep current if possible
        cur = f'{self.map_no} - {map_name(self.map_no)}'
        if cur in vals: self.map_var.set(cur)
        else: self.map_no = maps[0]; self.map_var.set(vals[0])
        self.load_map_image()

    def on_map_change(self):
        try:
            self.map_no = int(self.map_var.get().split('-')[0].strip())
        except Exception: self.map_no = 0
        self.selected_uid = None
        self.load_map_image(); self.refresh_list(); self.redraw()

    def load_map_image(self):
        self.img_orig = None; self.img_tk=None
        p = find_map_image(self.map_no)
        if HAS_PIL and p and os.path.exists(p):
            try:
                self.img_orig = Image.open(p).convert('RGB')
            except Exception:
                self.img_orig = None
        self.fit_map()

    def set_zoom(self,z):
        self.zoom = max(0.5, min(12.0, z)); self.redraw()
    def fit_map(self):
        w = max(200, self.canvas.winfo_width()-40); h = max(200, self.canvas.winfo_height()-40)
        self.zoom = min(w/256.0, h/256.0)
        self.zoom = max(0.5, min(12.0, self.zoom))
        self.pan = [20,20]; self.redraw()

    def world_to_screen(self,x,y):
        # MU coords: 0-255. La orientación depende de la imagen del mapa; se puede ajustar.
        try: ox = float(self.off_x.get())
        except Exception: ox = 0.0
        try: oy = float(self.off_y.get())
        except Exception: oy = 0.0
        mx, my = float(x) + ox, float(y) + oy
        if self.swap_xy.get():
            mx, my = my, mx
        dx = (255 - mx) if self.invert_x.get() else mx
        dy = (255 - my) if self.invert_y.get() else my
        # +0.5 para centrar en la celda/coordenada
        sx = self.pan[0] + (dx + 0.5) * self.zoom
        sy = self.pan[1] + (dy + 0.5) * self.zoom
        return sx,sy
    def screen_to_world(self,sx,sy):
        try: ox = float(self.off_x.get())
        except Exception: ox = 0.0
        try: oy = float(self.off_y.get())
        except Exception: oy = 0.0
        dx = (sx - self.pan[0]) / self.zoom - 0.5
        dy = (sy - self.pan[1]) / self.zoom - 0.5
        mx = (255 - dx) if self.invert_x.get() else dx
        my = (255 - dy) if self.invert_y.get() else dy
        if self.swap_xy.get():
            mx, my = my, mx
        return mx - ox, my - oy

    def current_spawns(self):
        q = self.search_var.get().lower().strip()
        res = [s for s in self.spawns if s.map==self.map_no]
        if q:
            def ok(s):
                name = self.monsters.get(s.monster,'').lower()
                return q in str(s.monster) or q in name or q in (s.comment or '').lower() or q in str(s.x) or q in str(s.y)
            res = [s for s in res if ok(s)]
        return res

    def refresh_list(self):
        self.filtered = self.current_spawns()
        for i in self.tree.get_children(): self.tree.delete(i)
        for s in self.filtered:
            name = self.monsters.get(s.monster,'')
            self.tree.insert('', 'end', iid=str(s.uid), values=(s.uid,s.monster,name,s.x,s.y,s.range_,s.dir,s.block,s.comment))
        self.redraw()

    def redraw(self):
        c = self.canvas; c.delete('all')
        w = c.winfo_width(); h = c.winfo_height()
        # draw map
        x0,y0 = self.world_to_screen(0,0); x1,y1 = self.world_to_screen(256,256)
        if self.img_orig and HAS_PIL:
            try:
                zw = max(1,int(256*self.zoom)); zh = max(1,int(256*self.zoom))
                img = self.img_orig.resize((zw,zh), Image.NEAREST)
                self.img_tk = ImageTk.PhotoImage(img)
                c.create_image(x0,y0, image=self.img_tk, anchor='nw')
            except Exception:
                c.create_rectangle(x0,y0,x1,y1,fill='#223',outline='#555')
        else:
            c.create_rectangle(x0,y0,x1,y1,fill='#223',outline='#555')
            # grid
            step = 32
            for g in range(0,257,step):
                gx,gy = self.world_to_screen(g,0); _,gy2 = self.world_to_screen(g,256)
                c.create_line(gx,gy,gx,gy2,fill='#334')
                gx,gy = self.world_to_screen(0,g); gx2,_ = self.world_to_screen(256,g)
                c.create_line(gx,gy,gx2,gy,fill='#334')
        c.create_rectangle(x0,y0,x1,y1,outline='#888')
        # spawns
        for s in self.filtered:
            sx,sy = self.world_to_screen(s.x, s.y)
            r = max(3, min(8, self.zoom*1.2))
            color = '#ffcc00' if s.uid==self.selected_uid else '#00d0ff'
            c.create_oval(sx-r,sy-r,sx+r,sy+r, fill=color, outline='#000')
            if self.zoom >= 2.0 or s.uid==self.selected_uid:
                label = f"{s.monster}"
                c.create_text(sx+r+3, sy-r-3, text=label, anchor='sw', fill='#fff', font=('Segoe UI',8))
        # border info
        c.create_text(10,10,anchor='nw', fill='#ddd', text=f'{self.map_no} - {map_name(self.map_no)}  ({len(self.filtered)} spots)')

    def on_click(self,e):
        # check hit
        wx,wy = self.screen_to_world(e.x,e.y)
        hit = None
        best = 999
        for s in self.filtered:
            d = ((s.x-wx)**2 + (s.y-wy)**2)**0.5
            thr = max(2.5, 6/self.zoom)
            if d < thr and d < best:
                best=d; hit=s
        if hit:
            self.selected_uid = hit.uid
            self.dragging = hit
            self.select_in_tree(hit.uid)
            self.load_form(hit)
        else:
            self.selected_uid = None
            self.dragging = None
        self.redraw()
    def on_drag(self,e):
        if self.dragging:
            wx,wy = self.screen_to_world(e.x,e.y)
            wx = int(max(0,min(255,round(wx)))); wy = int(max(0,min(255,round(wy))))
            self.dragging.x=wx; self.dragging.y=wy
            self.coord_lbl.config(text=f'Coords: {wx}, {wy}')
            self.load_form(self.dragging); self.refresh_list_preserve()
            self.redraw()
        else:
            wx,wy = self.screen_to_world(e.x,e.y)
            self.coord_lbl.config(text=f'Coords: {int(round(wx))}, {int(round(wy))}')
    def on_release(self,e):
        self.dragging = None
    def on_right_pan_start(self,e): self.pan_start=(e.x,e.y, self.pan[0], self.pan[1])
    def on_right_pan(self,e):
        if not self.pan_start: return
        dx=e.x-self.pan_start[0]; dy=e.y-self.pan_start[1]
        self.pan=[self.pan_start[2]+dx, self.pan_start[3]+dy]; self.redraw()
    def on_wheel(self,e):
        factor = 1.1 if e.delta>0 else 1/1.1
        # zoom around cursor
        wx,wy = self.screen_to_world(e.x,e.y)
        self.zoom = max(0.5,min(12.0,self.zoom*factor))
        sx,sy = self.world_to_screen(wx,wy)
        self.pan[0] += (e.x - sx); self.pan[1] += (e.y - sy)
        self.redraw()

    def on_double_click(self,e):
        wx,wy = self.screen_to_world(e.x,e.y)
        x = int(max(0,min(255,round(wx)))); y = int(max(0,min(255,round(wy))))
        self.new_spawn(x,y)

    def select_in_tree(self,uid):
        try: self.tree.selection_set(str(uid)); self.tree.see(str(uid))
        except Exception: pass
    def on_select(self):
        sel = self.tree.selection()
        if not sel: return
        uid = int(sel[0]); self.selected_uid=uid
        sp = next((s for s in self.spawns if s.uid==uid), None)
        if sp: self.load_form(sp)
        self.redraw()

    def load_form(self, sp):
        for k,v in [('monster',sp.monster),('map',sp.map),('range_',sp.range_),('x',sp.x),('y',sp.y),('dir',sp.dir),('block',sp.block),('comment',sp.comment)]:
            self.fvars[k].set(str(v))
        self.update_mon_label()
    def update_mon_label(self):
        try: mid=int(self.fvars['monster'].get()); self.mon_name_lbl.config(text=self.monsters.get(mid,'(desconocido)'))
        except Exception: self.mon_name_lbl.config(text='')

    def apply_form(self):
        sp = next((s for s in self.spawns if s.uid==self.selected_uid), None)
        if not sp: messagebox.showinfo('Info','Seleccioná un spot.'); return
        try:
            sp.monster=int(self.fvars['monster'].get()); sp.map=int(self.fvars['map'].get())
            sp.range_=int(self.fvars['range_'].get()); sp.x=int(self.fvars['x'].get()); sp.y=int(self.fvars['y'].get())
            sp.dir=int(self.fvars['dir'].get()); sp.comment=self.fvars['comment'].get()
            newb=int(self.fvars['block'].get())
            if newb!=sp.block: self.move_spawn_block(sp,newb)
        except Exception as e:
            messagebox.showerror('Error','Valores inválidos: '+str(e)); return
        self.refresh_maps(); self.refresh_list(); self.select_in_tree(sp.uid)

    def move_spawn_block(self, sp, newb):
        # remove from old
        for b in self.blocks:
            b.items = [(k,d) for (k,d) in b.items if not (k=='s' and d.uid==sp.uid)]
        # add to existing block with index or create
        target = None
        for b in self.blocks:
            if b.index==newb: target=b; break
        if target is None:
            target = BlockMeta(newb, [('c','//Monster      MapNumber      Range      PositionX      PositionY      Direction      Comment')])
            self.blocks.append(target)
        sp.block=newb
        target.items.append(('s', sp))

    def new_spawn(self, wx=None, wy=None):
        if wx is None: wx = 125
        if wy is None: wy = 125
        wx = int(max(0,min(255,round(wx)))); wy = int(max(0,min(255,round(wy))))
        sp = Spawn(0,0,self.map_no,0,wx,wy,-1,'',next_uid())
        # add to block 0 by default
        target = next((b for b in self.blocks if b.index==0), None)
        if target is None:
            target = BlockMeta(0, [('c','//Monster      MapNumber      Range      PositionX      PositionY      Direction      Comment')])
            self.blocks.insert(0,target)
        target.items.append(('s', sp))
        self.rebuild_flat(); self.refresh_maps(); self.refresh_list()
        self.selected_uid=sp.uid; self.select_in_tree(sp.uid); self.load_form(sp); self.redraw()

    def dup_spawn(self):
        sp = next((s for s in self.spawns if s.uid==self.selected_uid), None)
        if not sp: return
        ns = Spawn(sp.block, sp.monster, sp.map, sp.range_, min(255,sp.x+1), min(255,sp.y+1), sp.dir, sp.comment, next_uid())
        for b in self.blocks:
            if b.index==sp.block:
                b.items.append(('s', ns)); break
        self.rebuild_flat(); self.refresh_list(); self.selected_uid=ns.uid; self.select_in_tree(ns.uid); self.load_form(ns); self.redraw()

    def delete_spawn(self):
        sp = next((s for s in self.spawns if s.uid==self.selected_uid), None)
        if not sp: return
        if not messagebox.askyesno('Eliminar', f'¿Eliminar spot (Mon {sp.monster} en {sp.x},{sp.y})?'): return
        for b in self.blocks:
            b.items = [(k,d) for (k,d) in b.items if not (k=='s' and d.uid==sp.uid)]
        self.selected_uid=None; self.rebuild_flat(); self.refresh_maps(); self.refresh_list()

    def refresh_list_preserve(self):
        sel=self.selected_uid; self.refresh_list(); 
        if sel: self.selected_uid=sel; self.select_in_tree(sel)

    def pick_monster(self):
        q = simpledialog.askstring('Buscar monstruo', 'ID o nombre:', parent=self)
        if not q: return
        ql=q.lower()
        matches=[]
        for mid,name in self.monsters.items():
            if ql==str(mid) or ql in name.lower():
                matches.append((mid,name))
        if not matches: messagebox.showinfo('Buscar','No encontrado'); return
        if len(matches)==1:
            self.fvars['monster'].set(str(matches[0][0])); return
        # choose
        win=tk.Toplevel(self); win.title('Elegir monstruo'); win.geometry('420x400')
        lb=tk.Listbox(win); lb.pack(fill='both',expand=True,padx=6,pady=6)
        for mid,name in sorted(matches)[:500]: lb.insert('end', f'{mid} - {name}')
        def ok():
            s=lb.curselection(); 
            if not s: return
            val=lb.get(s[0]).split('-')[0].strip(); self.fvars['monster'].set(val); win.destroy()
        ttk.Button(win,text='Seleccionar',command=ok).pack(pady=4)

    def save(self):
        try:
            path = os.path.join(DATA_MONSTER, self.spawn_file)
            write_spawn_file(path, self.blocks)
            self.status.config(text='Guardado: '+path)
            messagebox.showinfo('Guardado', f'Guardado en:\n{path}\n\nSe creó backup .bak-spots-*. Reiniciá GameServer para aplicar.')
        except Exception as e:
            messagebox.showerror('Error al guardar', str(e))

if __name__ == '__main__':
    app = App()
    app.mainloop()
