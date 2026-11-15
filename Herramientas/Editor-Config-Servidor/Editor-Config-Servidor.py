import os
import re
import shutil
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
from datetime import datetime

class ToolTip:
    def __init__(self, widget, text):
        self.widget = widget
        self.text = text
        self.tip = None
        widget.bind('<Enter>', self.show)
        widget.bind('<Leave>', self.hide)
    def show(self, _=None):
        if not self.text or self.tip:
            return
        x = self.widget.winfo_rootx() + 20
        y = self.widget.winfo_rooty() + self.widget.winfo_height() + 5
        self.tip = tw = tk.Toplevel(self.widget)
        tw.wm_overrideredirect(True)
        tw.wm_geometry(f"+{x}+{y}")
        lbl = tk.Label(tw, text=self.text, justify='left', background='#ffffe0', relief='solid', borderwidth=1, padx=6, pady=4, wraplength=420)
        lbl.pack()
    def hide(self, _=None):
        if self.tip:
            self.tip.destroy()
            self.tip = None


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
DATA_DIR = os.path.join(ROOT, 'MuServer', 'GameServer', 'DATA')

def backup(path):
    if os.path.exists(path):
        stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        try:
            shutil.copy2(path, path + '.bak-editorcfg-' + stamp)
        except Exception:
            pass

def read_text(path):
    with open(path, 'r', encoding='latin-1', errors='replace') as f:
        return f.read()

def write_text(path, text):
    backup(path)
    with open(path, 'w', encoding='latin-1', errors='replace', newline='\r\n') as f:
        f.write(text)

def parse_kv(text):
    # returns dict key->value (last wins) and list of (key, value, line_index)
    kv = {}
    for i, line in enumerate(text.splitlines()):
        s = line.strip()
        if not s or s.startswith(';') or s.startswith('['):
            continue
        if '=' in line:
            k, v = line.split('=', 1)
            k = k.strip()
            v = v.strip()
            if k:
                kv[k] = v
    return kv

def set_key(text, key, value):
    lines = text.splitlines()
    found = False
    pat = re.compile(r'^(\s*' + re.escape(key) + r'\s*=\s*)(.*)$', re.IGNORECASE)
    for i, line in enumerate(lines):
        m = pat.match(line)
        if m:
            lines[i] = m.group(1) + str(value)
            found = True
    if not found:
        lines.append(f'{key} = {value}')
    return '\n'.join(lines) + '\n'

FILES = [
    'GameServerInfo - Common.dat',
    'GameServerInfo - Command.dat',
    'GameServerInfo - Custom.dat',
    'GameServerInfo - Event.dat',
    'GameServerInfo - Character.dat',
    'GameServerInfo - ChaosMix.dat',
    'GameServerInfo - Skill.dat',
]

AL_HELP = (
    "Tipos de cuenta (AL = Account Level):\n"
    "• AL0 = Cuenta normal (la mayoría de jugadores)\n"
    "• AL1 = Cuenta VIP nivel 1\n"
    "• AL2 = Cuenta VIP nivel 2\n"
    "• AL3 = Cuenta VIP nivel 3 (el más alto)\n\n"
    "Cada tipo puede tener valores distintos (experiencia, costos, etc.)."
)

# (section_title, section_help, [ (label, key, file, type, help) ])
SCHEMA = [
    ('Servidor (datos básicos)', 'Configuración general del servidor de juego.', [
        ('Nombre del servidor', 'ServerName', 'GameServerInfo - Common.dat', 'str',
         'Nombre que identifica a este servidor dentro de la configuración.'),
        ('Código del servidor', 'ServerCode', 'GameServerInfo - Common.dat', 'int',
         'Número interno del servidor (normalmente 0 para el servidor principal).'),
        ('Puerto del servidor de juego', 'ServerPort', 'GameServerInfo - Common.dat', 'int',
         'Puerto donde se conecta el juego (GameServer). En tu configuración suele ser 55901.'),
        ('Versión del servidor', 'ServerVersion', 'GameServerInfo - Common.dat', 'str',
         'Versión/protocolo (ej. 1.02.44). Normalmente no hace falta cambiarlo.'),
        ('Cantidad máxima de jugadores conectados', 'ServerMaxUserNumber', 'GameServerInfo - Common.dat', 'int',
         'Límite de usuarios que pueden estar conectados al mismo tiempo.'),
    ]),
    ('Conexiones entre componentes (IPs y puertos)', 'Direcciones para que los componentes del servidor se comuniquen entre sí. Al migrar a otra PC, estas IPs suelen cambiar.', [
        ('IP del DataServer (base de datos)', 'DataServerAddress', 'GameServerInfo - Common.dat', 'str',
         'IP del componente que guarda/carga datos. Si todo corre en la misma PC: 127.0.0.1.'),
        ('Puerto del DataServer', 'DataServerPort', 'GameServerInfo - Common.dat', 'int',
         'Puerto del DataServer (ej. 55960).'),
        ('IP del JoinServer (login)', 'JoinServerAddress', 'GameServerInfo - Common.dat', 'str',
         'IP del componente que maneja el inicio de sesión.'),
        ('Puerto del JoinServer', 'JoinServerPort', 'GameServerInfo - Common.dat', 'int',
         'Puerto del JoinServer (ej. 55970).'),
        ('IP del ConnectServer', 'ConnectServerAddress', 'GameServerInfo - Common.dat', 'str',
         'IP del ConnectServer (el que indica al cliente a dónde conectarse).'),
        ('Puerto del ConnectServer', 'ConnectServerPort', 'GameServerInfo - Common.dat', 'int',
         'Puerto interno de comunicación con el ConnectServer (ej. 55557).'),
    ]),
    ('Experiencia, vida de monstruos y drops', 'Controla qué tan rápido se sube de nivel, cuánta vida tienen los monstruos y qué tanto sueltan.\n\n' + AL_HELP, [
        ('Experiencia - Cuenta normal (AL0)', 'AddExperienceRate_AL0', 'GameServerInfo - Common.dat', 'int',
         'Multiplicador de experiencia para cuentas normales.\n100 = x1 (normal). Ejemplos: 1000 = x10, 10000 = x100, 300000 = x3000.'),
        ('Experiencia - Cuenta VIP 1 (AL1)', 'AddExperienceRate_AL1', 'GameServerInfo - Common.dat', 'int',
         'Multiplicador de experiencia para cuentas VIP nivel 1. (100 = x1).'),
        ('Experiencia - Cuenta VIP 2 (AL2)', 'AddExperienceRate_AL2', 'GameServerInfo - Common.dat', 'int',
         'Multiplicador de experiencia para cuentas VIP nivel 2. (100 = x1).'),
        ('Experiencia - Cuenta VIP 3 (AL3)', 'AddExperienceRate_AL3', 'GameServerInfo - Common.dat', 'int',
         'Multiplicador de experiencia para cuentas VIP nivel 3. (100 = x1).'),
        ('Vida de los monstruos (%)', 'MonsterLifeRate', 'GameServerInfo - Common.dat', 'int',
         'Porcentaje de vida de los monstruos.\n100 = vida normal, 200 = el doble de vida, 500 = 5 veces más vida (más difíciles).'),
        ('Probabilidad de soltar ítems - Cuenta normal (AL0)', 'ItemDropRate_AL0', 'GameServerInfo - Common.dat', 'int',
         'Multiplicador de probabilidad de que los monstruos suelten ítems para cuentas normales.'),
        ('Cantidad de zen que sueltan (AL0)', 'MoneyAmountDropRate_AL0', 'GameServerInfo - Common.dat', 'int',
         'Factor de cantidad de zen que cae de los monstruos (cuenta normal).'),
        ('Valor del zen que sueltan (AL0)', 'MoneyValue_AL0', 'GameServerInfo - Common.dat', 'int',
         'Factor de valor del zen que cae de los monstruos (cuenta normal). Afecta cuánto zen da cada caída.'),
    ]),
    ('Reset (/reset)', 'Configura el comando /reset: nivel requerido, costo, puntos que otorga y comportamiento.\n\n' + AL_HELP, [
        ('Habilitar comando /reset', 'CommandResetSwitch', 'GameServerInfo - Command.dat', 'bool',
         '1 = el comando /reset está disponible. 0 = desactivado.'),
        ('Nivel necesario para resetear', 'CommandResetLevel', 'GameServerInfo - Command.dat', 'int',
         'Nivel que debe alcanzar el personaje para poder usar /reset (ej. 400).'),
        ('Puntos que otorga cada reset', 'CommandResetPoint', 'GameServerInfo - Command.dat', 'int',
         'Cantidad de puntos extra que recibe el personaje al hacer un reset (ej. 1000).'),
        ('Tipo de reset (¿mantiene stats?)', 'CommandResetType', 'GameServerInfo - Command.dat', 'int',
         '0 = mantiene los puntos/stats al resetear. 1 = reinicia los stats (comportamiento depende del servidor).'),
        ('Costo en zen - Cuenta normal (AL0)', 'CommandResetMoney_AL0', 'GameServerInfo - Command.dat', 'int',
         'Zen que cuesta hacer /reset para una cuenta normal.'),
        ('Costo en zen - VIP 1 (AL1)', 'CommandResetMoney_AL1', 'GameServerInfo - Command.dat', 'int',
         'Zen que cuesta hacer /reset para cuenta VIP 1.'),
        ('Costo en zen - VIP 2 (AL2)', 'CommandResetMoney_AL2', 'GameServerInfo - Command.dat', 'int',
         'Zen que cuesta hacer /reset para cuenta VIP 2.'),
        ('Costo en zen - VIP 3 (AL3)', 'CommandResetMoney_AL3', 'GameServerInfo - Command.dat', 'int',
         'Zen que cuesta hacer /reset para cuenta VIP 3.'),
        ('Reset automático - Cuenta normal', 'CommandResetAutoEnable_AL0', 'GameServerInfo - Command.dat', 'bool',
         '1 = intenta resetear automáticamente al cumplir condiciones. 0 = solo manual con /reset.'),
        ('Mover al personaje al resetear (AL0)', 'CommandResetMove_AL0', 'GameServerInfo - Command.dat', 'bool',
         '1 = al resetear lo envía al pueblo/mapa inicial. 0 = lo deja donde está.'),
        ('Límite máximo de resets', 'CommandResetLimit', 'GameServerInfo - Command.dat', 'int',
         'Cantidad máxima de resets que puede tener un personaje.'),
    ]),
    ('Comandos: PK, baúles y chat', 'Ajustes de comandos comunes del juego.\n\n' + AL_HELP, [
        ('Habilitar /pk (limpiar asesino)', 'CommandPKClearSwitch', 'GameServerInfo - Command.dat', 'bool',
         '1 = permite usar /pk para quitar el estado de asesino. 0 = desactivado.'),
        ('Costo /pk - Cuenta normal (AL0)', 'CommandPKClearMoney_AL0', 'GameServerInfo - Command.dat', 'int',
         'Zen que cuesta limpiar PK para cuenta normal.'),
        ('Costo /pk - VIP 3 (AL3)', 'CommandPKClearMoney_AL3', 'GameServerInfo - Command.dat', 'int',
         'Zen que cuesta limpiar PK para cuenta VIP 3.'),
        ('Habilitar /ware o /bau (cambiar baúl)', 'CommandWareSwitch', 'GameServerInfo - Command.dat', 'bool',
         '1 = permite cambiar entre baúles con el comando. 0 = desactivado.'),
        ('Cantidad de baúles - Cuenta normal (AL0)', 'CommandWareNumber_AL0', 'GameServerInfo - Command.dat', 'int',
         'Número de baúles disponibles para cuenta normal (ej. 2).'),
        ('Cantidad de baúles - VIP 3 (AL3)', 'CommandWareNumber_AL3', 'GameServerInfo - Command.dat', 'int',
         'Número de baúles disponibles para cuenta VIP 3 (ej. 50).'),
        ('Habilitar /post (mensaje global)', 'CommandPostSwitch', 'GameServerInfo - Command.dat', 'bool',
         '1 = permite enviar mensajes globales con /post. 0 = desactivado.'),
        ('Habilitar agregar puntos por comando', 'CommandAddPointSwitch', 'GameServerInfo - Command.dat', 'bool',
         '1 = permite usar comandos para agregar puntos (fuerza, agilidad, etc.). 0 = desactivado.'),
    ]),
    ('Tienda personal y ataque automático', 'Funciones especiales: tienda, tienda offline y ataque automático/offline.\n\n' + AL_HELP, [
        ('Habilitar tienda personal (/store)', 'CustomStoreSwitch', 'GameServerInfo - Custom.dat', 'bool',
         '1 = los jugadores pueden abrir tienda personal con /store.'),
        ('Nivel mínimo para /store (AL0)', 'CustomStoreRequireLevel_AL0', 'GameServerInfo - Custom.dat', 'int',
         'Nivel que debe tener el personaje para poder abrir tienda.'),
        ('Habilitar tienda offline (/offstore)', 'CustomStoreOfflineSwitch', 'GameServerInfo - Custom.dat', 'bool',
         '1 = permite dejar la tienda abierta aunque el jugador se desconecte.'),
        ('Nivel mínimo para /offstore (AL0)', 'CustomStoreOfflineRequireLevel_AL0', 'GameServerInfo - Custom.dat', 'int',
         'Nivel requerido para usar /offstore (suele ser alto, ej. 250).'),
        ('Habilitar ataque automático (/attack)', 'CustomAttackSwitch', 'GameServerInfo - Custom.dat', 'bool',
         '1 = permite activar el ataque automático con /attack.'),
        ('Habilitar ataque offline (/offattack)', 'CustomAttackOfflineSwitch', 'GameServerInfo - Custom.dat', 'bool',
         '1 = permite que el personaje siga peleando estando desconectado.'),
        ('Nivel mínimo para /offattack (AL0)', 'CustomAttackOfflineRequireLevel_AL0', 'GameServerInfo - Custom.dat', 'int',
         'Nivel requerido para usar /offattack.'),
        ('Costo en zen de /offattack (AL0)', 'CustomAttackOfflineRequireMoney_AL0', 'GameServerInfo - Custom.dat', 'int',
         'Zen que consume/requiere usar /offattack para cuenta normal.'),
    ]),
    ('Eventos (prender o apagar)', 'Activa (1) o desactiva (0) eventos del servidor. Los horarios se configuran en otros archivos (modo avanzado).', [
        ('Blood Castle', 'BloodCastleEvent', 'GameServerInfo - Event.dat', 'bool',
         'Evento Blood Castle: 1 = activo, 0 = desactivado.'),
        ('Devil Square', 'DevilSquareEvent', 'GameServerInfo - Event.dat', 'bool',
         'Evento Devil Square: 1 = activo, 0 = desactivado.'),
        ('Chaos Castle', 'ChaosCastleEvent', 'GameServerInfo - Event.dat', 'bool',
         'Evento Chaos Castle: 1 = activo, 0 = desactivado.'),
        ('Invasiones de monstruos', 'InvasionManagerSwitch', 'GameServerInfo - Event.dat', 'bool',
         'Activa las invasiones programadas (monstruos dorados, etc.).'),
        ('Bonus de experiencia/eventos extra', 'BonusManagerSwitch', 'GameServerInfo - Event.dat', 'bool',
         'Activa los bonus programados (ej. experiencia extra en fechas).'),
        ('Castle Siege (asedio)', 'CastleSiegeEvent', 'GameServerInfo - Event.dat', 'bool',
         'Evento Castle Siege. 0 = apagado (recomendado si no está configurado).'),
        ('Crywolf', 'CrywolfEvent', 'GameServerInfo - Event.dat', 'bool',
         'Evento Crywolf: 1 = activo, 0 = desactivado.'),
        ('Kanturu', 'KanturuEvent', 'GameServerInfo - Event.dat', 'bool',
         'Evento Kanturu: 1 = activo, 0 = desactivado.'),
        ('Raklion', 'RaklionEvent', 'GameServerInfo - Event.dat', 'bool',
         'Evento Raklion: 1 = activo, 0 = desactivado.'),
        ('Illusion Temple', 'IllusionTempleEvent', 'GameServerInfo - Event.dat', 'bool',
         'Evento Illusion Temple: 1 = activo, 0 = desactivado.'),
    ]),
]

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('MU - Editor de Configuración del Servidor')
        self.geometry('1150x720')
        self.file_texts = {}   # filename -> text
        self.file_kv = {}      # filename -> dict
        self.widgets = []       # (key,file,type,widget,var)

        top = ttk.Frame(self); top.pack(fill='x', padx=8, pady=6)
        ttk.Label(top, text=f'MU raíz: {ROOT}').pack(side='left')
        ttk.Label(top, text=f'  |  Config: {DATA_DIR}').pack(side='left')
        self.status = ttk.Label(top, text=''); self.status.pack(side='right')

        bar = ttk.Frame(self); bar.pack(fill='x', padx=8, pady=4)
        ttk.Button(bar, text='Recargar todo', command=self.load_all).pack(side='left', padx=3)
        ttk.Button(bar, text='Guardar cambios (campos)', command=self.save_fields).pack(side='left', padx=3)
        ttk.Button(bar, text='Guardar archivo avanzado', command=self.save_advanced).pack(side='left', padx=3)
        ttk.Label(bar, text='  (reiniciá GameServer para aplicar)').pack(side='left', padx=8)

        nb = ttk.Notebook(self); nb.pack(fill='both', expand=True, padx=8, pady=8)
        self.nb = nb

        # Tab: campos comunes
        self.form_tab = ttk.Frame(nb); nb.add(self.form_tab, text='Configuración común')
        self.build_form()

        # Tab: avanzado por archivo
        self.adv_tab = ttk.Frame(nb); nb.add(self.adv_tab, text='Avanzado (por archivo)')
        self.build_advanced()

        self.load_all()

    def show_help(self, title, text):
        if not text:
            return
        messagebox.showinfo(title, text, parent=self)

    def build_form(self):
        canvas = tk.Canvas(self.form_tab, borderwidth=0, highlightthickness=0)
        vsb = ttk.Scrollbar(self.form_tab, orient='vertical', command=canvas.yview)
        frame = ttk.Frame(canvas)
        frame.bind('<Configure>', lambda e: canvas.configure(scrollregion=canvas.bbox('all')))
        canvas.create_window((0,0), window=frame, anchor='nw')
        canvas.configure(yscrollcommand=vsb.set)
        canvas.pack(side='left', fill='both', expand=True)
        vsb.pack(side='right', fill='y')
        # mousewheel scroll
        def _on_mousewheel(event):
            canvas.yview_scroll(int(-1*(event.delta/120)), 'units')
        canvas.bind_all('<MouseWheel>', _on_mousewheel)

        # Intro
        intro = ttk.LabelFrame(frame, text='Ayuda rápida')
        intro.pack(fill='x', padx=8, pady=6)
        intro_txt = (
            "• Modificá los valores y hacé clic en \"Guardar cambios (campos)\".\n"
            "• Para aplicar los cambios hay que REINICIAR el GameServer.\n"
            "• AL0 = cuenta normal, AL1/AL2/AL3 = cuentas VIP (niveles 1, 2 y 3).\n"
            "• En opciones de Sí/No: 1 = Activado/Sí, 0 = Desactivado/No.\n"
            "• Hacé clic en (?) para ver qué significa cada opción. La pestaña \"Avanzado\" permite editar cualquier ajuste."
        )
        ttk.Label(intro, text=intro_txt, justify='left').pack(anchor='w', padx=8, pady=6)

        self.widgets = []
        for section_title, section_help, items in SCHEMA:
            lf = ttk.LabelFrame(frame, text=section_title)
            lf.pack(fill='x', padx=8, pady=6)
            if section_help:
                hdr = ttk.Frame(lf); hdr.grid(row=0, column=0, columnspan=4, sticky='w', padx=6, pady=(4,6))
                ttk.Label(hdr, text=section_help.split('\n')[0], foreground='#444').pack(side='left')
                q = ttk.Button(hdr, text='(?)', width=3, command=lambda t=section_title, h=section_help: self.show_help(t, h))
                q.pack(side='left', padx=6)
                ToolTip(q, 'Ver explicación de esta sección')
                base_row = 1
            else:
                base_row = 0
            for r, (label, key, fname, ftype, help_text) in enumerate(items, start=base_row):
                ttk.Label(lf, text=label).grid(row=r, column=0, sticky='w', padx=6, pady=3)
                var = tk.StringVar()
                if ftype == 'bool':
                    w = ttk.Combobox(lf, textvariable=var, values=['0','1'], width=10, state='readonly')
                else:
                    w = ttk.Entry(lf, textvariable=var, width=24)
                w.grid(row=r, column=1, sticky='w', padx=6, pady=3)
                qb = ttk.Button(lf, text='?', width=2, command=lambda t=label, h=help_text, k=key: self.show_help(t, (h or '') + (f"\n\n(Ajuste interno: {k})" if k else "")))
                qb.grid(row=r, column=2, sticky='w', padx=2, pady=3)
                tip = help_text if help_text else f'Ajuste interno: {key}'
                ToolTip(qb, tip[:300] + ('...' if len(tip)>300 else ''))
                ToolTip(w, tip[:300] + ('...' if len(tip)>300 else ''))
                ttk.Label(lf, text=key, foreground='#888').grid(row=r, column=3, sticky='w', padx=6, pady=3)
                self.widgets.append((key, fname, ftype, w, var))

    def build_advanced(self):
        top = ttk.Frame(self.adv_tab); top.pack(fill='x', padx=6, pady=4)
        ttk.Label(top, text='Archivo:').pack(side='left')
        self.adv_file = tk.StringVar(value=FILES[0])
        cb = ttk.Combobox(top, textvariable=self.adv_file, values=FILES, state='readonly', width=40)
        cb.pack(side='left', padx=6)
        cb.bind('<<ComboboxSelected>>', lambda e: self.load_advanced())
        ttk.Label(top, text='Buscar clave:').pack(side='left', padx=(12,2))
        self.adv_search = tk.StringVar(); self.adv_search.trace_add('write', lambda *a: self.filter_advanced())
        ttk.Entry(top, textvariable=self.adv_search, width=20).pack(side='left')
        ttk.Button(top, text='Recargar archivo', command=self.load_advanced).pack(side='left', padx=6)

        mid = ttk.Frame(self.adv_tab); mid.pack(fill='both', expand=True, padx=6, pady=4)
        cols = ('key','value')
        self.adv_tree = ttk.Treeview(mid, columns=cols, show='headings')
        self.adv_tree.heading('key', text='Clave'); self.adv_tree.heading('value', text='Valor')
        self.adv_tree.column('key', width=380); self.adv_tree.column('value', width=380)
        vsb = ttk.Scrollbar(mid, orient='vertical', command=self.adv_tree.yview)
        self.adv_tree.configure(yscrollcommand=vsb.set)
        self.adv_tree.pack(side='left', fill='both', expand=True)
        vsb.pack(side='left', fill='y')
        self.adv_tree.bind('<Double-1>', self.edit_adv)

        right = ttk.Frame(mid); right.pack(side='left', fill='y', padx=8)
        ttk.Button(right, text='Editar valor', command=self.edit_adv).pack(fill='x', pady=2)
        ttk.Label(right, text='Doble clic en una fila\npara cambiar el valor.\n\n"Guardar archivo avanzado"\nescribe los cambios en el .dat\npreservando comentarios.', justify='left').pack(pady=8)
        self.adv_rows = []

    def load_all(self):
        self.file_texts = {}
        self.file_kv = {}
        if not os.path.isdir(DATA_DIR):
            self.status.config(text='No se encontró carpeta DATA: ' + DATA_DIR)
            messagebox.showwarning('No encontrado', f'No se encontró:\n{DATA_DIR}\n\nSi moviste el editor, creá mu_path.txt con la ruta del MU.')
            return
        for fn in FILES:
            p = os.path.join(DATA_DIR, fn)
            if os.path.exists(p):
                t = read_text(p)
                self.file_texts[fn] = t
                self.file_kv[fn] = parse_kv(t)
        # fill form
        for key, fname, ftype, w, var in self.widgets:
            kv = self.file_kv.get(fname, {})
            var.set(kv.get(key, ''))
        self.status.config(text=f'Cargados {len(self.file_texts)} archivos de configuración')
        self.load_advanced()

    def save_fields(self):
        try:
            # group by file
            changes = {}
            for key, fname, ftype, w, var in self.widgets:
                val = var.get().strip()
                changes.setdefault(fname, {})[key] = val
            count = 0
            for fname, kvs in changes.items():
                p = os.path.join(DATA_DIR, fname)
                if not os.path.exists(p):
                    continue
                text = self.file_texts.get(fname, read_text(p))
                for k, v in kvs.items():
                    text = set_key(text, k, v)
                write_text(p, text)
                self.file_texts[fname] = text
                self.file_kv[fname] = parse_kv(text)
                count += len(kvs)
            self.status.config(text=f'Guardado OK ({count} campos). Reiniciá GameServer.')
            messagebox.showinfo('Guardado', 'Configuración guardada (campos comunes).\nSe crearon backups .bak-editorcfg-*.\n\nReiniciá el GameServer para aplicar los cambios.')
        except Exception as e:
            messagebox.showerror('Error al guardar', str(e))

    def load_advanced(self):
        fn = self.adv_file.get()
        kv = self.file_kv.get(fn, {})
        self.adv_rows = sorted(kv.items())
        self.filter_advanced()

    def filter_advanced(self):
        q = self.adv_search.get().lower().strip()
        for i in self.adv_tree.get_children():
            self.adv_tree.delete(i)
        for k, v in self.adv_rows:
            if q and q not in k.lower() and q not in str(v).lower():
                continue
            self.adv_tree.insert('', 'end', values=(k, v))

    def edit_adv(self, event=None):
        sel = self.adv_tree.selection()
        if not sel:
            return
        k, v = self.adv_tree.item(sel[0], 'values')
        nv = tk.simpledialog.askstring('Editar valor', f'Clave: {k}\nNuevo valor:', initialvalue=v, parent=self)
        if nv is None:
            return
        fn = self.adv_file.get()
        if fn not in self.file_kv:
            return
        self.file_kv[fn][k] = nv
        self.adv_rows = sorted(self.file_kv[fn].items())
        self.filter_advanced()

    def save_advanced(self):
        try:
            fn = self.adv_file.get()
            p = os.path.join(DATA_DIR, fn)
            if not os.path.exists(p):
                messagebox.showerror('Error', 'Archivo no encontrado: ' + p); return
            text = self.file_texts.get(fn, read_text(p))
            for k, v in self.file_kv.get(fn, {}).items():
                text = set_key(text, k, v)
            write_text(p, text)
            self.file_texts[fn] = text
            self.file_kv[fn] = parse_kv(text)
            self.status.config(text=f'Guardado {fn}. Reiniciá GameServer.')
            messagebox.showinfo('Guardado', f'Archivo guardado:\n{p}\n\nBackup creado. Reiniciá GameServer para aplicar.')
        except Exception as e:
            messagebox.showerror('Error al guardar', str(e))

if __name__ == '__main__':
    app = App()
    app.mainloop()
