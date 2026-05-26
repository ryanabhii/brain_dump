import { useState, useEffect, useRef } from 'react';
import {
  Home, TrendingUp, CreditCard, Brain, ShoppingCart,
  Plus, Bell, BellOff, Clock, ChevronLeft, ChevronRight, X, Check, Mic, Video,
  Calendar, AlertCircle, Zap, Users, Trash2,
  Settings, Activity, Sparkles, Package,
  ArrowRight, Coffee, Sun, Moon as MoonIcon, Flame,
  TrendingDown, Wallet, BookOpen, MapPin, Repeat,
  Camera, ChevronDown, ChevronUp, FileText, ListChecks, Loader2,
  Dumbbell, Apple, Droplet, User,
  DollarSign, ArrowDownCircle, ArrowUpCircle, Search, Edit3, Snowflake, Moon
} from 'lucide-react';

const STORE_KEY = 'utracker:data:v1';

const KZ_COLORS = {
  amber: { bg: 'bg-amber-500/10', text: 'text-amber-400', ring: 'ring-amber-500/30', dot: 'bg-amber-400', solid: 'bg-amber-500' },
  sky: { bg: 'bg-sky-500/10', text: 'text-sky-400', ring: 'ring-sky-500/30', dot: 'bg-sky-400', solid: 'bg-sky-500' },
  rose: { bg: 'bg-rose-500/10', text: 'text-rose-400', ring: 'ring-rose-500/30', dot: 'bg-rose-400', solid: 'bg-rose-500' },
  violet: { bg: 'bg-violet-500/10', text: 'text-violet-400', ring: 'ring-violet-500/30', dot: 'bg-violet-400', solid: 'bg-violet-500' },
  emerald: { bg: 'bg-emerald-500/10', text: 'text-emerald-400', ring: 'ring-emerald-500/30', dot: 'bg-emerald-400', solid: 'bg-emerald-500' }
};

const todayPlus = (d) => {
  const x = new Date();
  x.setDate(x.getDate() + d);
  return x.toISOString();
};

const defaultData = {
  killzones: [
    { id: 'kz1', name: 'Asian', startMin: 19 * 60, endMin: 21 * 60 + 30, color: 'amber', alertOn: true, alertBefore: 15, journal: [], checklist: ['HTF bias set', 'News checked', 'Risk defined'], skipUntil: null },
    { id: 'kz2', name: 'London', startMin: 2 * 60, endMin: 5 * 60, color: 'sky', alertOn: true, alertBefore: 15, journal: [], checklist: ['HTF bias set', 'News checked', 'Risk defined'], skipUntil: null },
    { id: 'kz3', name: 'NY AM', startMin: 8 * 60 + 30, endMin: 11 * 60, color: 'rose', alertOn: true, alertBefore: 30, journal: [{ id: 'j1', date: todayPlus(-1), result: 'W', note: 'OB sweep, clean retest' }], checklist: ['HTF bias set', 'News checked', 'Risk defined'], skipUntil: null },
    { id: 'kz4', name: 'London Close', startMin: 10 * 60, endMin: 12 * 60, color: 'violet', alertOn: false, alertBefore: 15, journal: [], checklist: ['HTF bias set', 'News checked', 'Risk defined'], skipUntil: null },
    { id: 'kz5', name: 'NY PM', startMin: 13 * 60 + 30, endMin: 16 * 60, color: 'emerald', alertOn: true, alertBefore: 15, journal: [], checklist: ['HTF bias set', 'News checked', 'Risk defined'], skipUntil: null }
  ],
  trading: {
    accounts: [
      { id: 'acc1', name: 'FTMO Challenge', type: 'broker', currency: 'USD', balance: 102350 },
      { id: 'acc2', name: 'Personal Live', type: 'broker', currency: 'USD', balance: 8240 },
      { id: 'acc3', name: 'Kraken', type: 'wallet', currency: 'USD', balance: 1820 }
    ],
    flows: [
      { id: 'f1', accountId: 'acc1', type: 'deposit', amount: 100000, date: todayPlus(-25), note: 'Challenge funding' },
      { id: 'f2', accountId: 'acc2', type: 'deposit', amount: 5000, date: todayPlus(-90), note: 'Initial' },
      { id: 'f3', accountId: 'acc2', type: 'deposit', amount: 2000, date: todayPlus(-12), note: 'Top-up' },
      { id: 'f4', accountId: 'acc2', type: 'withdrawal', amount: 500, date: todayPlus(-3), note: 'Profit pull' },
      { id: 'f5', accountId: 'acc3', type: 'deposit', amount: 2000, date: todayPlus(-40), note: 'BTC swing' }
    ]
  },
  subscriptions: [
    { id: 's1', name: 'Anthropic API', cost: 200, cycle: 'monthly', nextRenewal: todayPlus(8), type: 'api', apiCap: 200, apiUsed: 142, category: 'AI', startedAt: todayPlus(-22), usedThisMonth: true, lastUsedReset: todayPlus(-2) },
    { id: 's2', name: 'OpenAI API', cost: 50, cycle: 'monthly', nextRenewal: todayPlus(14), type: 'api', apiCap: 50, apiUsed: 18, category: 'AI', startedAt: todayPlus(-16), usedThisMonth: true, lastUsedReset: todayPlus(-2) },
    { id: 's3', name: 'Netflix', cost: 15.49, cycle: 'monthly', nextRenewal: todayPlus(3), type: 'subscription', category: 'Entertainment', usedThisMonth: false, lastUsedReset: todayPlus(-35) },
    { id: 's4', name: 'Notion', cost: 10, cycle: 'monthly', nextRenewal: todayPlus(21), type: 'subscription', category: 'Productivity', usedThisMonth: true, lastUsedReset: todayPlus(-2) },
    { id: 's5', name: 'TradingView', cost: 59.95, cycle: 'monthly', nextRenewal: todayPlus(1), type: 'subscription', category: 'Trading', usedThisMonth: true, lastUsedReset: todayPlus(-2) }
  ],
  braindumps: [
    { id: 'b1', type: 'text', text: 'Call mom Sunday morning', createdAt: todayPlus(-1), reminderAt: todayPlus(2), completed: false, tag: 'personal' },
    { id: 'b2', type: 'text', text: 'Review NY AM trades from last week', createdAt: todayPlus(-1), reminderAt: null, completed: false, tag: 'trading' },
    { id: 'b3', type: 'text', text: 'Idea: tracker app with widget for killzones', createdAt: todayPlus(-2), reminderAt: null, completed: true, tag: 'idea' }
  ],
  groceries: {
    list: [
      { id: 'g1', name: 'Eggs', qty: 12, category: 'Dairy', addedBy: 'You', completed: false, recurring: 'weekly' },
      { id: 'g2', name: 'Sourdough bread', qty: 1, category: 'Bakery', addedBy: 'Sam', completed: false, recurring: null },
      { id: 'g3', name: 'Olive oil', qty: 1, category: 'Pantry', addedBy: 'You', completed: false, recurring: null },
      { id: 'g4', name: 'Avocados', qty: 4, category: 'Produce', addedBy: 'Alex', completed: true, recurring: null }
    ],
    pantry: [
      { id: 'p1', name: 'Olive oil', qty: 0, lowThreshold: 1, unit: 'bottle' },
      { id: 'p2', name: 'Rice', qty: 2, lowThreshold: 1, unit: 'kg' },
      { id: 'p3', name: 'Coffee beans', qty: 1, lowThreshold: 1, unit: 'bag' },
      { id: 'p4', name: 'Pasta', qty: 4, lowThreshold: 2, unit: 'box' }
    ],
    members: ['You', 'Sam', 'Alex'],
    lastRecurringRun: todayPlus(-8)
  },
  body: {
    macros: { calories: { used: 1840, goal: 2400 }, protein: { used: 142, goal: 180 }, carbs: { used: 210, goal: 280 }, fat: { used: 58, goal: 80 }, water: { used: 6, goal: 10 } },
    streak: 12,
    streakFreezes: 1,
    lastSleep: { hours: 7.2, rpe: 3, date: todayPlus(0) }
  },
  profile: {
    notifications: {
      master: true,
      leadTime: 15,             // 5 | 15 | 30
      quietStart: '22:00',
      quietEnd: '07:00',
      browserPermission: 'default' // default | granted | denied
    },
    dailyReviewTime: '21:00'
  }
};

function fmtTime(min) {
  const h = Math.floor(min / 60);
  const m = min % 60;
  const ampm = h >= 12 ? 'PM' : 'AM';
  const h12 = h % 12 || 12;
  return `${h12}:${m.toString().padStart(2, '0')} ${ampm}`;
}

function fmtDur(s) {
  const m = Math.floor(s / 60);
  const ss = s % 60;
  return `${m}:${ss.toString().padStart(2, '0')}`;
}

function nowMin(d = new Date()) {
  return d.getHours() * 60 + d.getMinutes();
}

function daysUntil(iso) {
  const t = new Date(iso).getTime();
  const now = Date.now();
  return Math.ceil((t - now) / 86400000);
}

function timeUntil(targetMin) {
  const cur = nowMin();
  let diff = targetMin - cur;
  if (diff < 0) diff += 1440;
  const h = Math.floor(diff / 60);
  const m = diff % 60;
  return { h, m, total: diff };
}

/* ─── EXTRA HELPERS ─────────────────────────────────────── */
function startOfWeek(d = new Date()) {
  const x = new Date(d);
  const day = (x.getDay() + 6) % 7; // Monday = 0
  x.setHours(0, 0, 0, 0);
  x.setDate(x.getDate() - day);
  return x;
}
function startOfMonth(d = new Date()) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  x.setDate(1);
  return x;
}
function sameDay(a, b) {
  return new Date(a).toDateString() === new Date(b).toDateString();
}

// P&L = current balance - net deposits in the window
// Per-account, per window (week/month/all)
function computePnL(account, flows, fromDate) {
  const accFlows = flows.filter(f => f.accountId === account.id);
  const windowFlows = fromDate ? accFlows.filter(f => new Date(f.date) >= fromDate) : accFlows;
  const netDeposits = windowFlows.reduce((s, f) => s + (f.type === 'deposit' ? f.amount : -f.amount), 0);
  // For "all-time" P&L: balance - lifetime net deposits
  // For windowed: assume starting baseline at window start, approximated by (balance - lifetime net deposits + flows-outside-window)
  // Simpler & honest: window P&L = balance change attributable to non-flow activity over window
  if (!fromDate) {
    const lifetimeNet = accFlows.reduce((s, f) => s + (f.type === 'deposit' ? f.amount : -f.amount), 0);
    return { pnl: account.balance - lifetimeNet, netDeposits: lifetimeNet, flowCount: accFlows.length };
  }
  const lifetimeNet = accFlows.reduce((s, f) => s + (f.type === 'deposit' ? f.amount : -f.amount), 0);
  const beforeWindowNet = accFlows.filter(f => new Date(f.date) < fromDate)
    .reduce((s, f) => s + (f.type === 'deposit' ? f.amount : -f.amount), 0);
  // P&L in window = (current balance - lifetime net) gives all-time P&L; we don't have historical balances.
  // Best honest approx: report window flow activity + lifetime P&L since the app can't reconstruct prior balances.
  return { pnl: account.balance - lifetimeNet, netDeposits, windowDeposits: windowFlows.filter(f => f.type === 'deposit').reduce((s, f) => s + f.amount, 0), windowWithdrawals: windowFlows.filter(f => f.type === 'withdrawal').reduce((s, f) => s + f.amount, 0), flowCount: windowFlows.length, beforeWindowNet };
}

// Heuristic AI-style auto-routing for brain dumps → suggested destination
function autoRoute(text) {
  const t = (text || '').toLowerCase();
  if (/\b(buy|pick up|grocery|groceries|milk|eggs|bread|bananas|oil|rice|coffee|pasta|cheese|water bottle)\b/.test(t)) return 'grocery';
  if (/(\$\d|cancel.*subscription|renew|subscription|trial)/.test(t)) return 'subscription';
  if (/\b(killzone|trade|setup|liquidity|sweep|fvg|ny am|london|asian)\b/.test(t)) return 'killzone';
  if (/\b(workout|protein|calories|meal|gym|push day|pull day|rep|set)\b/.test(t)) return 'body';
  return null;
}
function autoTag(text) {
  const t = (text || '').toLowerCase();
  if (/\b(trade|killzone|liquidity|setup|fvg|broker|wallet)\b/.test(t)) return 'trading';
  if (/\b(meeting|deploy|deadline|client|sprint|standup|email)\b/.test(t)) return 'work';
  if (/\b(idea|maybe|what if|concept|prototype)\b/.test(t)) return 'idea';
  return 'personal';
}

// Browser notification helpers
async function ensureNotifPermission() {
  if (typeof Notification === 'undefined') return 'unsupported';
  if (Notification.permission === 'granted' || Notification.permission === 'denied') return Notification.permission;
  try {
    return await Notification.requestPermission();
  } catch {
    return 'denied';
  }
}
function fireNotif(title, body) {
  try {
    if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
      new Notification(title, { body, silent: false });
    }
  } catch {}
}
function inQuietHours(now, start, end) {
  const [sh, sm] = start.split(':').map(Number);
  const [eh, em] = end.split(':').map(Number);
  const cur = now.getHours() * 60 + now.getMinutes();
  const s = sh * 60 + sm;
  const e = eh * 60 + em;
  return s < e ? (cur >= s && cur < e) : (cur >= s || cur < e);
}

async function analyzeTranscript(text) {
  const prompt = `Analyze this voice transcript from a recorded video memo. Extract structured insights.

Transcript:
"""
${text}
"""

Return ONLY valid JSON matching this exact shape (no markdown fences, no preamble, no commentary):
{
  "title": "3-7 word title capturing the core topic",
  "topic": "One sentence describing what this video is about",
  "keyPoints": ["3-6 short bullet points capturing the most important insights"],
  "stepsOrApproaches": ["Concrete steps, approaches, or action items mentioned. Empty array if none."],
  "essence": "2-3 sentence dense essence/summary"
}`;

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1000,
      messages: [{ role: "user", content: prompt }]
    })
  });
  if (!response.ok) throw new Error(`API ${response.status}`);
  const data = await response.json();
  const rawText = data.content.map(i => i.type === 'text' ? i.text : '').join('').trim();
  const clean = rawText.replace(/```json|```/g, '').trim();
  return JSON.parse(clean);
}

export default function UniversalTracker() {
  const [tab, setTab] = useState('home');
  const [data, setData] = useState(null);
  const [now, setNow] = useState(new Date());
  const [modal, setModal] = useState(null);
  const [toast, setToast] = useState(null);
  const [searchOpen, setSearchOpen] = useState(false);
  const [fabOpen, setFabOpen] = useState(false);
  const notifFiredRef = useRef(new Set());

  useEffect(() => {
    (async () => {
      try {
        let raw = null;
        // Prefer Claude-artifacts API if present, else localStorage
        if (typeof window !== 'undefined' && window.storage?.get) {
          const r = await window.storage.get(STORE_KEY);
          raw = r?.value || null;
        } else if (typeof localStorage !== 'undefined') {
          raw = localStorage.getItem(STORE_KEY);
        }
        if (raw) {
          const parsed = JSON.parse(raw);
          setData({ ...defaultData, ...parsed, profile: { ...defaultData.profile, ...(parsed.profile || {}) } });
        } else {
          setData(defaultData);
          try {
            if (window.storage?.set) await window.storage.set(STORE_KEY, JSON.stringify(defaultData));
            else localStorage.setItem(STORE_KEY, JSON.stringify(defaultData));
          } catch {}
        }
      } catch (e) {
        setData(defaultData);
      }
    })();
  }, []);

  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  // Global Cmd-K / Ctrl-K opens search palette
  useEffect(() => {
    const onKey = (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setSearchOpen(s => !s);
      } else if (e.key === 'Escape') {
        setSearchOpen(false);
        setFabOpen(false);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  // Recurring grocery auto-run: once per week re-add items flagged recurring: 'weekly'
  useEffect(() => {
    if (!data?.groceries) return;
    const last = data.groceries.lastRecurringRun ? new Date(data.groceries.lastRecurringRun) : null;
    const weekAgo = new Date(Date.now() - 7 * 86400000);
    if (last && last > weekAgo) return;
    const recurringTemplates = data.groceries.list.filter(g => g.recurring === 'weekly');
    if (recurringTemplates.length === 0) {
      // still bump timestamp to avoid re-checking constantly
      if (!last) save({ ...data, groceries: { ...data.groceries, lastRecurringRun: new Date().toISOString() } });
      return;
    }
    const newItems = recurringTemplates
      .filter(t => !data.groceries.list.some(g => !g.completed && g.name.toLowerCase() === t.name.toLowerCase() && g.id !== t.id))
      .map(t => ({ ...t, id: `g${Date.now()}-${Math.random().toString(36).slice(2, 6)}`, completed: false }));
    if (newItems.length === 0) {
      save({ ...data, groceries: { ...data.groceries, lastRecurringRun: new Date().toISOString() } });
      return;
    }
    save({
      ...data,
      groceries: {
        ...data.groceries,
        list: [...data.groceries.list, ...newItems],
        lastRecurringRun: new Date().toISOString()
      }
    });
    flash(`${newItems.length} weekly item${newItems.length > 1 ? 's' : ''} re-added`);
    // eslint-disable-next-line
  }, [data?.groceries?.lastRecurringRun]);

  // Killzone lead-time browser notifications (respect quiet hours)
  useEffect(() => {
    if (!data) return;
    if (typeof Notification === 'undefined' || Notification.permission !== 'granted') return;
    if (!data.profile?.notifications?.master) return;
    const cur = nowMin(now);
    const quiet = inQuietHours(now, data.profile.notifications.quietStart, data.profile.notifications.quietEnd);
    if (quiet) return;
    data.killzones.forEach(kz => {
      if (!kz.alertOn) return;
      if (kz.skipUntil && new Date(kz.skipUntil) > new Date()) return;
      const lead = kz.alertBefore ?? data.profile.notifications.leadTime ?? 15;
      const dueMin = kz.startMin - lead;
      const key = `${kz.id}-${new Date().toDateString()}`;
      if (cur >= dueMin && cur < kz.startMin && !notifFiredRef.current.has(key)) {
        notifFiredRef.current.add(key);
        fireNotif(`${kz.name} opens in ${kz.startMin - cur}m`, `${fmtTime(kz.startMin)} – ${fmtTime(kz.endMin)}`);
      }
    });
    // brain-dump reminders fire when reminderAt time has passed and not completed
    data.braindumps.forEach(b => {
      if (b.completed || !b.reminderAt) return;
      const key = `dump-${b.id}`;
      if (new Date(b.reminderAt) <= now && !notifFiredRef.current.has(key)) {
        notifFiredRef.current.add(key);
        fireNotif('Reminder', b.text?.slice(0, 80) || 'Open brain dump');
      }
    });
  }, [now, data]);

  const save = async (next) => {
    setData(next);
    try {
      if (window.storage?.set) await window.storage.set(STORE_KEY, JSON.stringify(next));
      else localStorage.setItem(STORE_KEY, JSON.stringify(next));
    } catch {}
  };

  const flash = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(null), 1800);
  };

  if (!data) {
    return (
      <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
        <div className="text-zinc-500 text-sm">Loading tracker…</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-zinc-950 via-black to-zinc-950 text-zinc-100 flex items-center justify-center md:p-8">
      <div className="w-full max-w-md min-h-screen md:min-h-0 md:h-[860px] md:rounded-[3rem] bg-zinc-950 md:border md:border-zinc-800 md:shadow-2xl md:shadow-black overflow-hidden flex flex-col relative">
        <div className="hidden md:flex justify-between items-center px-8 pt-4 pb-2 text-xs text-zinc-400">
          <span>{now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
          <span className="flex items-center gap-1.5">
            <span className="w-1 h-1 rounded-full bg-emerald-400"></span>
            <span className="w-3 h-2 border border-zinc-500 rounded-sm relative">
              <span className="absolute inset-0.5 bg-zinc-300 rounded-[1px]" style={{ width: '70%' }}></span>
            </span>
          </span>
        </div>

        <div className="flex-1 overflow-y-auto pb-24">
          {tab === 'home' && <DashboardScreen data={data} now={now} setTab={setTab} setModal={setModal} />}
          {tab === 'killzone' && <KillzoneScreen data={data} now={now} save={save} setModal={setModal} flash={flash} />}
          {tab === 'subs' && <SubsScreen data={data} save={save} setModal={setModal} flash={flash} />}
          {tab === 'brain' && <BrainScreen data={data} save={save} setModal={setModal} flash={flash} />}
          {tab === 'grocery' && <GroceryScreen data={data} save={save} setModal={setModal} flash={flash} />}
          {tab === 'body' && <BodyScreen data={data} now={now} save={save} setModal={setModal} flash={flash} />}
          {tab === 'profile' && <ProfileScreen data={data} save={save} flash={flash} />}
        </div>

        <BottomNav tab={tab} setTab={setTab} />

        {/* Floating universal "+" sits above bottom nav */}
        <button
          onClick={() => setFabOpen(true)}
          className="absolute bottom-20 right-4 w-12 h-12 rounded-full bg-cyan-500 text-zinc-900 shadow-xl shadow-cyan-900/50 flex items-center justify-center hover:bg-cyan-400 transition active:scale-95 z-30"
          title="Quick add (Ctrl/Cmd-K to search)"
        >
          <Plus size={22} strokeWidth={2.5} />
        </button>

        {fabOpen && (
          <FabSheet
            close={() => setFabOpen(false)}
            onPick={(action) => {
              setFabOpen(false);
              if (action === 'search') setSearchOpen(true);
              else setModal({ type: action });
            }}
          />
        )}

        {searchOpen && (
          <SearchPalette
            data={data}
            close={() => setSearchOpen(false)}
            jumpTo={(t) => { setTab(t); setSearchOpen(false); }}
          />
        )}

        {toast && (
          <div className="absolute top-6 left-1/2 -translate-x-1/2 bg-zinc-100 text-zinc-900 px-4 py-2 rounded-full text-xs font-medium shadow-lg z-50">
            {toast}
          </div>
        )}

        {modal && (
          <Modal modal={modal} data={data} save={save} close={() => setModal(null)} flash={flash} />
        )}
      </div>
    </div>
  );
}

/* ─── FAB SHEET (universal +) ──────────────────────────── */
function FabSheet({ close, onPick }) {
  const items = [
    { id: 'brain-add', label: 'Brain dump', icon: Sparkles, color: 'bg-violet-500' },
    { id: 'grocery-add', label: 'Grocery item', icon: ShoppingCart, color: 'bg-emerald-500' },
    { id: 'sub-add', label: 'Subscription', icon: CreditCard, color: 'bg-rose-500' },
    { id: 'kz-journal', label: 'Trade journal', icon: BookOpen, color: 'bg-amber-500' },
    { id: 'trading-flow', label: 'Deposit / Withdraw', icon: DollarSign, color: 'bg-cyan-500' },
    { id: 'meal-add', label: 'Log a meal', icon: Apple, color: 'bg-teal-500' },
    { id: 'search', label: 'Search everything', icon: Search, color: 'bg-zinc-700' }
  ];
  return (
    <div className="absolute inset-0 z-40 bg-black/70 backdrop-blur-sm flex items-end justify-center" onClick={close}>
      <div onClick={e => e.stopPropagation()} className="w-full bg-zinc-950 ring-1 ring-zinc-800 rounded-t-3xl p-5 pb-7">
        <div className="w-10 h-1 rounded-full bg-zinc-700 mx-auto mb-4" />
        <div className="text-xs uppercase tracking-wider text-zinc-500 mb-3">Quick add</div>
        <div className="grid grid-cols-2 gap-2">
          {items.map(it => {
            const Icon = it.icon;
            return (
              <button
                key={it.id}
                onClick={() => onPick(it.id)}
                className="flex items-center gap-3 p-3 rounded-xl bg-zinc-900 ring-1 ring-zinc-800 hover:bg-zinc-800 transition text-left"
              >
                <div className={`w-9 h-9 rounded-full ${it.color} flex items-center justify-center text-white flex-shrink-0`}>
                  <Icon size={16} />
                </div>
                <span className="text-sm font-medium text-zinc-100">{it.label}</span>
              </button>
            );
          })}
        </div>
        <div className="text-[10px] text-zinc-500 text-center mt-4">Tip: press <kbd className="px-1.5 py-0.5 rounded bg-zinc-800 text-zinc-300 text-[10px]">Ctrl/⌘ K</kbd> to search</div>
      </div>
    </div>
  );
}

/* ─── SEARCH PALETTE (Cmd/Ctrl-K) ──────────────────────── */
function SearchPalette({ data, close, jumpTo }) {
  const [q, setQ] = useState('');
  const results = (() => {
    if (!q.trim()) return [];
    const needle = q.toLowerCase();
    const out = [];
    data.braindumps.forEach(b => {
      const txt = (b.text || b.video?.title || '').toLowerCase();
      if (txt.includes(needle)) out.push({ kind: 'Brain dump', tab: 'brain', label: b.text || b.video?.title || '(video)', sub: b.tag || '' });
    });
    data.subscriptions.forEach(s => {
      if (s.name.toLowerCase().includes(needle) || s.category?.toLowerCase().includes(needle)) {
        out.push({ kind: 'Subscription', tab: 'subs', label: s.name, sub: `$${s.cost}/mo · ${s.category}` });
      }
    });
    data.groceries.list.forEach(g => {
      if (g.name.toLowerCase().includes(needle)) out.push({ kind: 'Grocery', tab: 'grocery', label: g.name, sub: `×${g.qty} · ${g.category}` });
    });
    data.groceries.pantry.forEach(p => {
      if (p.name.toLowerCase().includes(needle)) out.push({ kind: 'Pantry', tab: 'grocery', label: p.name, sub: `${p.qty} ${p.unit}` });
    });
    data.killzones.forEach(kz => {
      if (kz.name.toLowerCase().includes(needle)) out.push({ kind: 'Killzone', tab: 'killzone', label: kz.name, sub: `${fmtTime(kz.startMin)}–${fmtTime(kz.endMin)}` });
      kz.journal.forEach(j => {
        if ((j.note || '').toLowerCase().includes(needle)) out.push({ kind: 'Journal', tab: 'killzone', label: j.note, sub: `${kz.name} · ${j.result}` });
      });
    });
    (data.trading?.accounts || []).forEach(a => {
      if (a.name.toLowerCase().includes(needle)) out.push({ kind: 'Account', tab: 'killzone', label: a.name, sub: `${a.type} · $${a.balance.toLocaleString()}` });
    });
    return out.slice(0, 30);
  })();

  return (
    <div className="absolute inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-start justify-center pt-12" onClick={close}>
      <div onClick={e => e.stopPropagation()} className="w-[92%] max-w-md bg-zinc-950 ring-1 ring-zinc-800 rounded-2xl overflow-hidden shadow-2xl">
        <div className="flex items-center gap-2 p-3 border-b border-zinc-800">
          <Search size={14} className="text-zinc-500" />
          <input
            autoFocus
            value={q}
            onChange={e => setQ(e.target.value)}
            placeholder="Search dumps, subs, grocery, trades…"
            className="flex-1 bg-transparent outline-none text-sm text-zinc-100 placeholder-zinc-600"
          />
          <kbd className="px-1.5 py-0.5 rounded bg-zinc-800 text-zinc-400 text-[10px]">Esc</kbd>
        </div>
        <div className="max-h-[60vh] overflow-y-auto">
          {q && results.length === 0 && (
            <div className="text-center py-10 text-zinc-500 text-xs">No matches</div>
          )}
          {results.map((r, i) => (
            <button
              key={i}
              onClick={() => jumpTo(r.tab)}
              className="w-full px-4 py-2.5 flex items-center justify-between hover:bg-zinc-900 text-left border-b border-zinc-900/60 last:border-0"
            >
              <div className="min-w-0">
                <div className="text-sm text-zinc-100 truncate">{r.label}</div>
                <div className="text-[10px] text-zinc-500">{r.sub}</div>
              </div>
              <span className="text-[10px] text-cyan-400 ml-3 flex-shrink-0">{r.kind}</span>
            </button>
          ))}
          {!q && (
            <div className="px-4 py-6 text-zinc-500 text-xs">
              Type to search across brain dumps, subscriptions, grocery, pantry, killzones, journal entries, and trading accounts.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/* ─── DASHBOARD ─────────────────────────────────────────── */
function DashboardScreen({ data, now, setTab, setModal }) {
  const cur = nowMin(now);
  const todaySessions = data.killzones.map(k => ({ ...k, diff: k.startMin - cur }));
  const active = todaySessions.find(k => cur >= k.startMin && cur < k.endMin);
  const upcoming = todaySessions
    .filter(k => k.startMin > cur)
    .sort((a, b) => a.startMin - b.startMin)[0]
    || todaySessions.sort((a, b) => a.startMin - b.startMin)[0];

  const monthlySpend = data.subscriptions.reduce((s, x) => s + x.cost, 0);
  const renewSoon = data.subscriptions
    .filter(s => daysUntil(s.nextRenewal) <= 3)
    .sort((a, b) => daysUntil(a.nextRenewal) - daysUntil(b.nextRenewal));

  const apiBurns = data.subscriptions.filter(s => s.type === 'api');
  const highBurn = apiBurns.find(s => (s.apiUsed / s.apiCap) > 0.65);

  const pendingDumps = data.braindumps.filter(b => !b.completed).length;
  const lowStock = data.groceries.pantry.filter(p => p.qty <= p.lowThreshold);
  const groceryPending = data.groceries.list.filter(g => !g.completed).length;
  const body = data.body || { macros: { calories: { used: 0, goal: 2400 }, protein: { used: 0, goal: 180 }, carbs: { used: 0, goal: 280 }, fat: { used: 0, goal: 80 }, water: { used: 0, goal: 10 } }, streak: 0, streakFreezes: 0 };

  const greeting = now.getHours() < 12 ? 'Good morning' : now.getHours() < 17 ? 'Good afternoon' : 'Good evening';
  const GreetIcon = now.getHours() < 12 ? Coffee : now.getHours() < 17 ? Sun : MoonIcon;

  return (
    <div className="px-5 pt-6 pb-4">
      <div className="flex items-start justify-between mb-6">
        <div>
          <div className="flex items-center gap-2 text-zinc-500 text-xs mb-1">
            <GreetIcon size={12} />
            <span>{greeting}</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight">Today's tracker</h1>
          <p className="text-zinc-500 text-sm mt-1">{now.toLocaleDateString([], { weekday: 'long', month: 'short', day: 'numeric' })}</p>
        </div>
        <button className="w-10 h-10 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-400 hover:bg-zinc-800 transition">
          <Settings size={16} />
        </button>
      </div>

      <button
        onClick={() => setTab('killzone')}
        className={`w-full text-left rounded-2xl p-5 mb-4 transition relative overflow-hidden ${active ? 'bg-gradient-to-br from-rose-500/20 via-rose-500/5 to-transparent ring-1 ring-rose-500/30' : 'bg-zinc-900/80 ring-1 ring-zinc-800'}`}
      >
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2">
            <TrendingUp size={14} className={active ? 'text-rose-400' : 'text-zinc-400'} />
            <span className={`text-xs font-semibold uppercase tracking-wider ${active ? 'text-rose-400' : 'text-zinc-400'}`}>
              {active ? 'Live Session' : 'Next Killzone'}
            </span>
          </div>
          {active && <span className="flex h-2 w-2 relative"><span className="absolute h-2 w-2 rounded-full bg-rose-400 animate-ping opacity-75"></span><span className="relative h-2 w-2 rounded-full bg-rose-500"></span></span>}
        </div>
        {active ? (
          <>
            <div className="text-3xl font-bold">{active.name}</div>
            <div className="text-zinc-400 text-sm mt-1">In progress · ends {fmtTime(active.endMin)}</div>
          </>
        ) : upcoming ? (
          <>
            <div className="text-3xl font-bold">{upcoming.name}</div>
            <Countdown targetMin={upcoming.startMin} now={now} />
          </>
        ) : null}
      </button>

      <div className="grid grid-cols-2 gap-3 mb-4">
        <button onClick={() => setTab('subs')} className="text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 hover:bg-zinc-900 transition">
          <div className="flex items-center gap-1.5 mb-2">
            <Wallet size={12} className="text-rose-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">Monthly</span>
          </div>
          <div className="text-xl font-bold">${monthlySpend.toFixed(2)}</div>
          {renewSoon.length > 0 && (
            <div className="text-[11px] text-amber-400 mt-1.5 flex items-center gap-1">
              <AlertCircle size={10} /> {renewSoon.length} renew soon
            </div>
          )}
        </button>

        <button onClick={() => setTab('subs')} className="text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 hover:bg-zinc-900 transition">
          <div className="flex items-center gap-1.5 mb-2">
            <Flame size={12} className="text-orange-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">API Burn</span>
          </div>
          {highBurn ? (
            <>
              <div className="text-xl font-bold">{Math.round((highBurn.apiUsed / highBurn.apiCap) * 100)}%</div>
              <div className="text-[11px] text-zinc-500 mt-1.5 truncate">{highBurn.name}</div>
            </>
          ) : (
            <>
              <div className="text-xl font-bold text-emerald-400">OK</div>
              <div className="text-[11px] text-zinc-500 mt-1.5">All within budget</div>
            </>
          )}
        </button>

        <button onClick={() => setTab('brain')} className="text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 hover:bg-zinc-900 transition">
          <div className="flex items-center gap-1.5 mb-2">
            <Brain size={12} className="text-violet-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">Capture</span>
          </div>
          <div className="text-xl font-bold">{pendingDumps}</div>
          <div className="text-[11px] text-zinc-500 mt-1.5">Open items</div>
        </button>

        <button onClick={() => setTab('grocery')} className="text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 hover:bg-zinc-900 transition">
          <div className="flex items-center gap-1.5 mb-2">
            <Package size={12} className="text-emerald-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">Household</span>
          </div>
          <div className="text-xl font-bold">{groceryPending}</div>
          <div className="text-[11px] text-zinc-500 mt-1.5">
            {lowStock.length > 0 ? <span className="text-amber-400">{lowStock.length} low stock</span> : 'On list'}
          </div>
        </button>

        <button onClick={() => setTab('body')} className="text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 hover:bg-zinc-900 transition">
          <div className="flex items-center gap-1.5 mb-2">
            <Flame size={12} className="text-orange-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">Streak</span>
          </div>
          <div className="text-xl font-bold">{body.streak} <span className="text-xs font-medium text-zinc-500">days</span></div>
          <div className="text-[11px] text-zinc-500 mt-1.5">Macros on track</div>
        </button>

        <button onClick={() => setTab('body')} className="text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 hover:bg-zinc-900 transition">
          <div className="flex items-center gap-1.5 mb-2">
            <Dumbbell size={12} className="text-cyan-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">Body</span>
          </div>
          <div className="text-xl font-bold tabular-nums">{body.macros.calories.used} <span className="text-xs font-medium text-zinc-500">/ {body.macros.calories.goal}</span></div>
          <div className="text-[11px] text-zinc-500 mt-1.5">{body.macros.protein.used}g / {body.macros.protein.goal}g protein</div>
        </button>
      </div>

      <button
        onClick={() => setModal({ type: 'brain-add' })}
        className="w-full rounded-2xl bg-gradient-to-r from-violet-600 to-indigo-600 p-4 text-left shadow-lg shadow-violet-900/30 hover:shadow-violet-900/50 transition mb-4 active:scale-[0.98]"
      >
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-white/15 flex items-center justify-center">
            <Sparkles size={18} />
          </div>
          <div className="flex-1">
            <div className="font-semibold">Quick brain dump</div>
            <div className="text-violet-100 text-xs">Tap to capture · text, voice, or video</div>
          </div>
          <Plus size={20} />
        </div>
      </button>

      {renewSoon.length > 0 && (
        <div className="rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 mb-4">
          <div className="flex items-center justify-between mb-3">
            <div className="text-xs font-semibold uppercase tracking-wider text-zinc-400">Renewing soon</div>
            <ChevronRight size={14} className="text-zinc-600" />
          </div>
          <div className="space-y-2.5">
            {renewSoon.slice(0, 3).map(s => {
              const d = daysUntil(s.nextRenewal);
              return (
                <div key={s.id} className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className={`w-1.5 h-1.5 rounded-full ${d <= 1 ? 'bg-rose-400' : 'bg-amber-400'}`}></div>
                    <span className="text-sm">{s.name}</span>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-medium">${s.cost.toFixed(2)}</div>
                    <div className="text-[10px] text-zinc-500">{d === 0 ? 'Today' : d === 1 ? 'Tomorrow' : `in ${d} days`}</div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {lowStock.length > 0 && (
        <button onClick={() => setTab('grocery')} className="w-full text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="text-xs font-semibold uppercase tracking-wider text-zinc-400">Running low</div>
            <ChevronRight size={14} className="text-zinc-600" />
          </div>
          <div className="flex flex-wrap gap-2">
            {lowStock.map(p => (
              <span key={p.id} className="text-xs bg-amber-500/10 text-amber-400 px-2.5 py-1 rounded-full">
                {p.name} {p.qty === 0 ? '· out' : `· ${p.qty} ${p.unit}`}
              </span>
            ))}
          </div>
        </button>
      )}
    </div>
  );
}

function Countdown({ targetMin, now }) {
  const cur = nowMin(now);
  let diff = targetMin - cur;
  if (diff < 0) diff += 1440;
  const h = Math.floor(diff / 60);
  const m = diff % 60;
  const s = 60 - now.getSeconds();
  return (
    <div className="text-zinc-400 text-sm mt-1 tabular-nums">
      Opens in <span className="text-zinc-100 font-medium">{h}h {m}m {s}s</span> · {fmtTime(targetMin)}
    </div>
  );
}

/* ─── KILLZONE ──────────────────────────────────────────── */
function KillzoneScreen({ data, now, save, setModal, flash }) {
  const cur = nowMin(now);
  const sorted = [...data.killzones].sort((a, b) => a.startMin - b.startMin);
  const [expandedKz, setExpandedKz] = useState(null);

  const toggleAlert = (id) => {
    const next = { ...data, killzones: data.killzones.map(k => k.id === id ? { ...k, alertOn: !k.alertOn } : k) };
    save(next);
    flash('Alert updated');
  };

  const toggleSkipToday = (id) => {
    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);
    save({
      ...data,
      killzones: data.killzones.map(k => {
        if (k.id !== id) return k;
        const isSkipping = k.skipUntil && new Date(k.skipUntil) > new Date();
        return { ...k, skipUntil: isSkipping ? null : endOfDay.toISOString() };
      })
    });
  };

  // 7-day win/loss aggregation by killzone name
  const weekAgo = new Date(Date.now() - 7 * 86400000);
  const statsByKz = Object.fromEntries(data.killzones.map(kz => {
    const recent = kz.journal.filter(j => new Date(j.date) >= weekAgo);
    const w = recent.filter(j => j.result === 'W').length;
    const l = recent.filter(j => j.result === 'L').length;
    const pct = w + l > 0 ? Math.round((w / (w + l)) * 100) : null;
    return [kz.id, { w, l, pct }];
  }));

  return (
    <div className="px-5 pt-6">
      <div className="flex items-center justify-between mb-1">
        <h1 className="text-2xl font-bold tracking-tight">Killzones</h1>
        <button onClick={() => setModal({ type: 'kz-add' })} className="w-9 h-9 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-300 hover:bg-zinc-800">
          <Plus size={16} />
        </button>
      </div>
      <p className="text-zinc-500 text-sm mb-5">Trading sessions · local time</p>

      <div className="space-y-3 mb-6">
        {sorted.map(kz => {
          const c = KZ_COLORS[kz.color];
          const isActive = cur >= kz.startMin && cur < kz.endMin;
          const isPast = cur >= kz.endMin;
          const tu = timeUntil(kz.startMin);
          const stats = statsByKz[kz.id];
          const skipping = kz.skipUntil && new Date(kz.skipUntil) > new Date();
          const isExpanded = expandedKz === kz.id;
          return (
            <div key={kz.id} className={`rounded-2xl p-4 ring-1 transition ${isActive ? `${c.bg} ${c.ring} ring-2` : 'bg-zinc-900/60 ring-zinc-800'} ${(isPast && !isActive) || skipping ? 'opacity-50' : ''}`}>
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1 flex-wrap">
                    <div className={`w-2 h-2 rounded-full ${c.dot} ${isActive ? 'animate-pulse' : ''}`}></div>
                    <span className={`text-sm font-semibold ${isActive ? c.text : 'text-zinc-200'}`}>{kz.name}</span>
                    {isActive && <span className={`text-[10px] font-bold uppercase ${c.text} px-1.5 py-0.5 rounded ${c.bg}`}>Live</span>}
                    {skipping && <span className="text-[10px] font-bold uppercase text-zinc-400 px-1.5 py-0.5 rounded bg-zinc-800">Skipped today</span>}
                    {stats?.pct !== null && (
                      <span className="text-[10px] font-medium text-zinc-400 ml-auto tabular-nums">
                        7d · <span className="text-emerald-400">{stats.w}W</span>/<span className="text-rose-400">{stats.l}L</span> · {stats.pct}%
                      </span>
                    )}
                  </div>
                  <div className="text-zinc-500 text-xs tabular-nums">
                    {fmtTime(kz.startMin)} – {fmtTime(kz.endMin)}
                  </div>
                  {!isActive && !isPast && !skipping && (
                    <div className="text-zinc-400 text-xs mt-1.5 tabular-nums">
                      In <span className="text-zinc-200">{tu.h}h {tu.m}m</span>
                    </div>
                  )}
                  {isPast && <div className="text-zinc-500 text-xs mt-1.5">Closed</div>}
                </div>
                <button
                  onClick={() => toggleAlert(kz.id)}
                  className={`w-9 h-9 rounded-full flex items-center justify-center transition ${kz.alertOn ? `${c.bg} ${c.text}` : 'bg-zinc-800/50 text-zinc-500'}`}
                >
                  {kz.alertOn ? <Bell size={14} /> : <BellOff size={14} />}
                </button>
              </div>
              {kz.alertOn && (
                <div className="mt-3 flex items-center gap-2 flex-wrap">
                  <span className="text-[10px] uppercase tracking-wider text-zinc-500">Alert</span>
                  <div className="flex gap-1">
                    {[5, 15, 30].map(m => (
                      <button
                        key={m}
                        onClick={() => save({ ...data, killzones: data.killzones.map(k => k.id === kz.id ? { ...k, alertBefore: m } : k) })}
                        className={`text-[11px] px-2 py-0.5 rounded-full transition ${kz.alertBefore === m ? `${c.bg} ${c.text}` : 'bg-zinc-800/50 text-zinc-500'}`}
                      >
                        {m}m
                      </button>
                    ))}
                  </div>
                  <button
                    onClick={() => toggleSkipToday(kz.id)}
                    className={`text-[11px] px-2 py-0.5 rounded-full ml-auto ${skipping ? 'bg-zinc-700 text-zinc-200' : 'bg-zinc-800/50 text-zinc-500 hover:text-zinc-300'}`}
                  >
                    {skipping ? 'Un-skip' : 'Skip today'}
                  </button>
                  <button
                    onClick={() => setExpandedKz(isExpanded ? null : kz.id)}
                    className="text-[11px] px-2 py-0.5 rounded-full bg-zinc-800/50 text-zinc-400 hover:text-zinc-200 flex items-center gap-0.5"
                  >
                    <ListChecks size={10} /> {(kz.checklist || []).length}
                    {isExpanded ? <ChevronUp size={10} /> : <ChevronDown size={10} />}
                  </button>
                </div>
              )}
              {isExpanded && (
                <div className="mt-3 pt-3 border-t border-zinc-800/60">
                  <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-2">Pre-session checklist</div>
                  <div className="space-y-1.5">
                    {(kz.checklist || []).map((item, i) => (
                      <div key={i} className="flex items-center gap-2 text-xs text-zinc-300">
                        <span className={`w-1 h-1 rounded-full ${c.dot}`} />
                        <span>{item}</span>
                      </div>
                    ))}
                    {(kz.checklist || []).length === 0 && (
                      <div className="text-[11px] text-zinc-600">No items. Edit in Profile (coming soon).</div>
                    )}
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      <TradingPnLSection data={data} save={save} setModal={setModal} flash={flash} />

      <div className="mb-6">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-semibold uppercase tracking-wider text-zinc-400">Session Journal</h2>
          <button onClick={() => setModal({ type: 'kz-journal' })} className="text-xs text-cyan-400 hover:text-cyan-300">+ Entry</button>
        </div>
        <div className="space-y-2">
          {data.killzones.flatMap(kz => kz.journal.map(j => ({ ...j, kz: kz.name, color: kz.color })))
            .sort((a, b) => new Date(b.date) - new Date(a.date))
            .slice(0, 5)
            .map(j => {
              const c = KZ_COLORS[j.color];
              return (
                <div key={j.id} className="rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 p-3">
                  <div className="flex items-center justify-between mb-1">
                    <div className="flex items-center gap-2">
                      <span className={`text-xs font-medium ${c.text}`}>{j.kz}</span>
                      <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${j.result === 'W' ? 'bg-emerald-500/20 text-emerald-400' : j.result === 'L' ? 'bg-rose-500/20 text-rose-400' : 'bg-zinc-700/40 text-zinc-400'}`}>
                        {j.result}
                      </span>
                    </div>
                    <span className="text-[10px] text-zinc-500">{new Date(j.date).toLocaleDateString([], { month: 'short', day: 'numeric' })}</span>
                  </div>
                  <p className="text-xs text-zinc-300">{j.note}</p>
                </div>
              );
            })}
          {data.killzones.every(kz => kz.journal.length === 0) && (
            <div className="text-xs text-zinc-500 text-center py-4">No journal entries yet</div>
          )}
        </div>
      </div>
    </div>
  );
}

/* ─── TRADING P&L ───────────────────────────────────────── */
function TradingPnLSection({ data, save, setModal, flash }) {
  const trading = data.trading || { accounts: [], flows: [] };
  const [window, setWindow] = useState('month'); // week | month | all
  const [openAcc, setOpenAcc] = useState(null);

  const fromDate = window === 'week' ? startOfWeek() : window === 'month' ? startOfMonth() : null;

  const perAccount = trading.accounts.map(acc => {
    const stats = computePnL(acc, trading.flows, fromDate);
    return { acc, ...stats };
  });

  const totals = perAccount.reduce((s, x) => ({
    balance: s.balance + x.acc.balance,
    pnl: s.pnl + x.pnl,
    deposits: s.deposits + (x.windowDeposits ?? (x.netDeposits > 0 ? x.netDeposits : 0)),
    withdrawals: s.withdrawals + (x.windowWithdrawals ?? 0)
  }), { balance: 0, pnl: 0, deposits: 0, withdrawals: 0 });

  const updateBalance = (id, val) => {
    const num = parseFloat(val);
    if (isNaN(num)) return;
    save({
      ...data,
      trading: {
        ...trading,
        accounts: trading.accounts.map(a => a.id === id ? { ...a, balance: num } : a)
      }
    });
  };

  const removeFlow = (id) => {
    save({ ...data, trading: { ...trading, flows: trading.flows.filter(f => f.id !== id) } });
    flash('Flow removed');
  };

  const removeAccount = (id) => {
    if (!confirm('Remove this account and all its flows?')) return;
    save({
      ...data,
      trading: {
        ...trading,
        accounts: trading.accounts.filter(a => a.id !== id),
        flows: trading.flows.filter(f => f.accountId !== id)
      }
    });
    flash('Account removed');
  };

  return (
    <div className="mb-6">
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-sm font-semibold uppercase tracking-wider text-zinc-400 flex items-center gap-1.5">
          <DollarSign size={12} /> P&L
        </h2>
        <div className="flex gap-1">
          <button onClick={() => setModal({ type: 'trading-account' })} className="text-[11px] px-2 py-1 rounded-full bg-zinc-900 ring-1 ring-zinc-800 text-zinc-400 hover:text-zinc-200">+ Account</button>
          <button onClick={() => setModal({ type: 'trading-flow' })} className="text-[11px] px-2 py-1 rounded-full bg-cyan-500/10 ring-1 ring-cyan-500/30 text-cyan-300">+ Flow</button>
        </div>
      </div>

      <div className="rounded-2xl bg-gradient-to-br from-emerald-600/15 via-emerald-600/5 to-transparent ring-1 ring-emerald-500/20 p-4 mb-3">
        <div className="flex gap-1 mb-3">
          {[
            { id: 'week', label: 'This week' },
            { id: 'month', label: 'This month' },
            { id: 'all', label: 'All time' }
          ].map(o => (
            <button
              key={o.id}
              onClick={() => setWindow(o.id)}
              className={`text-[11px] px-2.5 py-1 rounded-full transition ${window === o.id ? 'bg-emerald-500/30 text-emerald-200 ring-1 ring-emerald-500/40' : 'bg-zinc-900/40 text-zinc-400 ring-1 ring-zinc-800'}`}
            >
              {o.label}
            </button>
          ))}
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <div className="text-[10px] uppercase tracking-wider text-zinc-500">Total balance</div>
            <div className="text-2xl font-bold tabular-nums">${totals.balance.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</div>
          </div>
          <div>
            <div className="text-[10px] uppercase tracking-wider text-zinc-500">All-time P&L</div>
            <div className={`text-2xl font-bold tabular-nums ${totals.pnl >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
              {totals.pnl >= 0 ? '+' : ''}${totals.pnl.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}
            </div>
          </div>
        </div>
        {window !== 'all' && (
          <div className="flex items-center gap-3 mt-3 pt-3 border-t border-emerald-500/10 text-[11px]">
            <span className="text-zinc-400 flex items-center gap-1">
              <ArrowDownCircle size={11} className="text-emerald-400" />
              Deposited <span className="text-zinc-200 tabular-nums">${totals.deposits.toLocaleString()}</span>
            </span>
            <span className="text-zinc-400 flex items-center gap-1">
              <ArrowUpCircle size={11} className="text-rose-400" />
              Withdrew <span className="text-zinc-200 tabular-nums">${totals.withdrawals.toLocaleString()}</span>
            </span>
          </div>
        )}
      </div>

      <div className="space-y-2">
        {perAccount.length === 0 && (
          <div className="text-center py-8 text-zinc-500 text-xs">No accounts yet. Tap “+ Account”.</div>
        )}
        {perAccount.map(({ acc, pnl, netDeposits }) => {
          const isExpanded = openAcc === acc.id;
          const accFlows = trading.flows.filter(f => f.accountId === acc.id)
            .filter(f => !fromDate || new Date(f.date) >= fromDate)
            .sort((a, b) => new Date(b.date) - new Date(a.date));
          const pos = pnl >= 0;
          return (
            <div key={acc.id} className="rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 overflow-hidden">
              <button
                onClick={() => setOpenAcc(isExpanded ? null : acc.id)}
                className="w-full p-3.5 flex items-center justify-between hover:bg-zinc-900 transition text-left"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-semibold truncate">{acc.name}</span>
                    <span className="text-[10px] uppercase tracking-wider text-zinc-500 px-1.5 py-0.5 rounded bg-zinc-800/60">{acc.type}</span>
                  </div>
                  <div className="text-[11px] text-zinc-500 mt-0.5 tabular-nums">
                    Balance <span className="text-zinc-300">${acc.balance.toLocaleString()}</span> · Net in <span className="text-zinc-300">${netDeposits.toLocaleString()}</span>
                  </div>
                </div>
                <div className="text-right ml-3">
                  <div className={`text-sm font-bold tabular-nums ${pos ? 'text-emerald-400' : 'text-rose-400'}`}>
                    {pos ? '+' : ''}${pnl.toLocaleString(undefined, { maximumFractionDigits: 0 })}
                  </div>
                  <div className="text-[10px] text-zinc-500">all-time P&L</div>
                </div>
                {isExpanded ? <ChevronUp size={14} className="ml-2 text-zinc-500" /> : <ChevronDown size={14} className="ml-2 text-zinc-500" />}
              </button>
              {isExpanded && (
                <div className="border-t border-zinc-800 p-3.5 bg-zinc-950/40 space-y-3">
                  <div className="flex items-center gap-2">
                    <label className="text-[10px] uppercase tracking-wider text-zinc-500 flex-shrink-0">Update balance</label>
                    <input
                      type="number"
                      defaultValue={acc.balance}
                      onBlur={(e) => updateBalance(acc.id, e.target.value)}
                      className="flex-1 bg-zinc-900 ring-1 ring-zinc-800 rounded-lg px-2.5 py-1 text-xs text-zinc-100 focus:ring-cyan-500 outline-none tabular-nums"
                    />
                    <button onClick={() => removeAccount(acc.id)} className="text-zinc-600 hover:text-rose-400">
                      <Trash2 size={13} />
                    </button>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-1.5">
                      Flows {window !== 'all' ? `(${window})` : ''}
                    </div>
                    {accFlows.length === 0 && (
                      <div className="text-[11px] text-zinc-600">No flows in this window.</div>
                    )}
                    <div className="space-y-1.5">
                      {accFlows.map(f => (
                        <div key={f.id} className="flex items-center gap-2 text-xs">
                          {f.type === 'deposit'
                            ? <ArrowDownCircle size={12} className="text-emerald-400 flex-shrink-0" />
                            : <ArrowUpCircle size={12} className="text-rose-400 flex-shrink-0" />}
                          <span className="flex-1 truncate text-zinc-300">{f.note || (f.type === 'deposit' ? 'Deposit' : 'Withdrawal')}</span>
                          <span className={`tabular-nums font-medium ${f.type === 'deposit' ? 'text-emerald-400' : 'text-rose-400'}`}>
                            {f.type === 'deposit' ? '+' : '−'}${f.amount.toLocaleString()}
                          </span>
                          <span className="text-[10px] text-zinc-500 tabular-nums">{new Date(f.date).toLocaleDateString([], { month: 'short', day: 'numeric' })}</span>
                          <button onClick={() => removeFlow(f.id)} className="text-zinc-600 hover:text-rose-400">
                            <X size={11} />
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>
      <p className="text-[10px] text-zinc-600 mt-2 leading-relaxed">
        P&L = current balance − net deposits. Update balances after each session to track non-flow gains/losses per broker or wallet.
      </p>
    </div>
  );
}

/* ─── SUBSCRIPTIONS ─────────────────────────────────────── */
function SubsScreen({ data, save, setModal, flash }) {
  const monthly = data.subscriptions.reduce((s, x) => s + x.cost, 0);
  const annual = monthly * 12;
  const apis = data.subscriptions.filter(s => s.type === 'api');
  const subs = data.subscriptions.filter(s => s.type === 'subscription');

  // Aggregate by category
  const byCat = data.subscriptions.reduce((m, s) => {
    m[s.category || 'Other'] = (m[s.category || 'Other'] || 0) + s.cost;
    return m;
  }, {});
  const catEntries = Object.entries(byCat).sort((a, b) => b[1] - a[1]);

  const remove = (id) => {
    save({ ...data, subscriptions: data.subscriptions.filter(s => s.id !== id) });
    flash('Removed');
  };

  const toggleUsed = (id) => {
    save({
      ...data,
      subscriptions: data.subscriptions.map(s => {
        if (s.id !== id) return s;
        const next = !s.usedThisMonth;
        return { ...s, usedThisMonth: next, lastUsedReset: next ? new Date().toISOString() : s.lastUsedReset };
      })
    });
  };

  const daysSinceUsed = (s) => s.lastUsedReset ? Math.floor((Date.now() - new Date(s.lastUsedReset).getTime()) / 86400000) : null;

  return (
    <div className="px-5 pt-6">
      <div className="flex items-center justify-between mb-1">
        <h1 className="text-2xl font-bold tracking-tight">Spend</h1>
        <button onClick={() => setModal({ type: 'sub-add' })} className="w-9 h-9 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-300 hover:bg-zinc-800">
          <Plus size={16} />
        </button>
      </div>
      <p className="text-zinc-500 text-sm mb-5">Subscriptions & API burn</p>

      <div className="rounded-2xl bg-gradient-to-br from-rose-600/30 via-rose-500/10 to-transparent ring-1 ring-rose-500/20 p-5 mb-3">
        <div className="text-xs font-semibold uppercase tracking-wider text-rose-300 mb-1">Monthly total</div>
        <div className="text-3xl font-bold tabular-nums">${monthly.toFixed(2)}</div>
        <div className="text-zinc-400 text-xs mt-1 flex items-center gap-2 flex-wrap">
          <span>{data.subscriptions.length} active · {apis.length} API</span>
          <span className="text-zinc-500">·</span>
          <span>~ <span className="text-zinc-300 tabular-nums">${annual.toFixed(0)}</span>/yr</span>
        </div>
      </div>

      {/* Per-category breakdown */}
      {catEntries.length > 0 && (
        <div className="rounded-2xl bg-zinc-900/60 ring-1 ring-zinc-800 p-4 mb-5">
          <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-3">By category</div>
          <div className="space-y-2">
            {catEntries.map(([cat, total]) => {
              const pct = (total / monthly) * 100;
              return (
                <div key={cat}>
                  <div className="flex items-center justify-between text-xs mb-1">
                    <span className="text-zinc-300">{cat}</span>
                    <span className="tabular-nums text-zinc-400">${total.toFixed(2)} <span className="text-zinc-600">· {pct.toFixed(0)}%</span></span>
                  </div>
                  <div className="h-1 bg-zinc-800 rounded-full overflow-hidden">
                    <div className="h-full bg-rose-400 rounded-full" style={{ width: `${pct}%` }} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {apis.length > 0 && (
        <div className="mb-6">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-3 flex items-center gap-1.5">
            <Flame size={11} className="text-orange-400" /> API Burn
          </h2>
          <div className="space-y-3">
            {apis.map(s => {
              const pct = Math.min(100, (s.apiUsed / s.apiCap) * 100);
              const high = pct > 65;
              const cycleDays = 30;
              const elapsedDays = Math.max(1, cycleDays - daysUntil(s.nextRenewal));
              const burnRate = s.apiUsed / elapsedDays;
              const willDeplete = burnRate > 0 ? Math.ceil((s.apiCap - s.apiUsed) / burnRate) : 999;
              return (
                <div key={s.id} className="rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 p-4">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <div className="font-semibold text-sm">{s.name}</div>
                      <div className="text-[11px] text-zinc-500">${s.cost}/mo · {s.category}</div>
                    </div>
                    <div className="text-right">
                      <div className={`text-sm font-bold tabular-nums ${high ? 'text-rose-400' : 'text-emerald-400'}`}>{Math.round(pct)}%</div>
                      <div className="text-[10px] text-zinc-500 tabular-nums">${s.apiUsed} / ${s.apiCap}</div>
                    </div>
                  </div>
                  <div className="h-1.5 bg-zinc-800 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all ${pct > 80 ? 'bg-rose-500' : pct > 65 ? 'bg-amber-500' : 'bg-emerald-500'}`}
                      style={{ width: `${pct}%` }}
                    ></div>
                  </div>
                  <div className="flex items-center justify-between mt-2.5 text-[11px]">
                    <span className="text-zinc-500 flex items-center gap-1">
                      <TrendingDown size={10} />
                      Burn: <span className="text-zinc-300 tabular-nums">${burnRate.toFixed(2)}/day</span>
                    </span>
                    <span className={`tabular-nums ${willDeplete < daysUntil(s.nextRenewal) ? 'text-rose-400' : 'text-zinc-500'}`}>
                      {willDeplete < daysUntil(s.nextRenewal) ? `Depletes in ${willDeplete}d` : `Renews ${daysUntil(s.nextRenewal)}d`}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      <div>
        <h2 className="text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-3 flex items-center gap-1.5">
          <Repeat size={11} /> Subscriptions
        </h2>
        <div className="space-y-2">
          {subs.map(s => {
            const d = daysUntil(s.nextRenewal);
            const idle = daysSinceUsed(s);
            const dormant = !s.usedThisMonth && idle !== null && idle >= 30;
            return (
              <div key={s.id} className="rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 p-3.5">
                <div className="flex items-center justify-between">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-0.5 flex-wrap">
                      <span className="font-medium text-sm">{s.name}</span>
                      {d <= 3 && <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-400">{d === 0 ? 'TODAY' : d === 1 ? 'TOMORROW' : `${d}D`}</span>}
                      {dormant && <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-rose-500/20 text-rose-400">CONSIDER CANCEL</span>}
                    </div>
                    <div className="text-[11px] text-zinc-500">{s.category} · monthly · ${(s.cost * 12).toFixed(0)}/yr</div>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="text-right">
                      <div className="text-sm font-semibold tabular-nums">${s.cost.toFixed(2)}</div>
                      <div className="text-[10px] text-zinc-500">{d}d</div>
                    </div>
                    <button onClick={() => remove(s.id)} className="text-zinc-600 hover:text-rose-400 transition">
                      <Trash2 size={13} />
                    </button>
                  </div>
                </div>
                <div className="flex items-center gap-2 mt-2 pt-2 border-t border-zinc-800/60">
                  <span className="text-[10px] uppercase tracking-wider text-zinc-500">Used this month?</span>
                  <button
                    onClick={() => toggleUsed(s.id)}
                    className={`text-[11px] px-2 py-0.5 rounded-full ${s.usedThisMonth ? 'bg-emerald-500/20 text-emerald-400' : 'bg-zinc-800 text-zinc-400'}`}
                  >
                    {s.usedThisMonth ? 'Yes' : 'Not yet'}
                  </button>
                  {idle !== null && (
                    <span className="text-[10px] text-zinc-600 ml-auto">last used {idle}d ago</span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

/* ─── BRAIN DUMP ───────────────────────────────────────── */
function BrainScreen({ data, save, setModal, flash }) {
  const [filter, setFilter] = useState('open');
  const [expanded, setExpanded] = useState(null);
  const [showVideoModal, setShowVideoModal] = useState(false);

  const items = data.braindumps.filter(b => filter === 'open' ? !b.completed : filter === 'done' ? b.completed : true)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  const toggle = (id) => {
    save({ ...data, braindumps: data.braindumps.map(b => b.id === id ? { ...b, completed: !b.completed } : b) });
  };

  const remove = (id) => {
    save({ ...data, braindumps: data.braindumps.filter(b => b.id !== id) });
    flash('Deleted');
  };

  // Move a dump to its suggested destination (currently: grocery list)
  const moveDump = (item, dest) => {
    if (dest === 'grocery') {
      const groceryItem = {
        id: `g${Date.now()}`,
        name: item.text.replace(/^(buy|pick up|get)\s+/i, '').trim().slice(0, 40),
        qty: 1,
        category: 'Other',
        addedBy: 'You',
        completed: false,
        recurring: null
      };
      save({
        ...data,
        braindumps: data.braindumps.map(b => b.id === item.id ? { ...b, completed: true } : b),
        groceries: { ...data.groceries, list: [...data.groceries.list, groceryItem] }
      });
      flash('Moved to grocery list');
    }
  };

  const saveVideoEntry = async (entry) => {
    const next = { ...data, braindumps: [entry, ...data.braindumps] };
    await save(next);
    flash('Video captured ✨');
  };

  return (
    <div className="px-5 pt-6">
      <div className="flex items-center justify-between mb-1">
        <h1 className="text-2xl font-bold tracking-tight">Capture</h1>
      </div>
      <p className="text-zinc-500 text-sm mb-5">Brain dumps · single tap</p>

      <div className="grid grid-cols-2 gap-3 mb-5">
        <button
          onClick={() => setModal({ type: 'brain-add' })}
          className="rounded-2xl bg-gradient-to-br from-violet-600/25 via-indigo-600/10 to-transparent ring-1 ring-violet-500/30 p-4 hover:from-violet-600/35 transition active:scale-[0.98]"
        >
          <div className="w-10 h-10 rounded-full bg-violet-600 flex items-center justify-center shadow-lg shadow-violet-900/40 mb-3">
            <Mic size={16} className="text-white" />
          </div>
          <div className="text-left">
            <div className="font-semibold text-sm">Quick dump</div>
            <div className="text-[11px] text-zinc-400 mt-0.5">Text or voice</div>
          </div>
        </button>

        <button
          onClick={() => setShowVideoModal(true)}
          className="rounded-2xl bg-gradient-to-br from-rose-600/25 via-orange-600/10 to-transparent ring-1 ring-rose-500/30 p-4 hover:from-rose-600/35 transition active:scale-[0.98]"
        >
          <div className="w-10 h-10 rounded-full bg-rose-600 flex items-center justify-center shadow-lg shadow-rose-900/40 mb-3 relative">
            <Video size={16} className="text-white" />
            <span className="absolute -top-0.5 -right-0.5 w-3 h-3 rounded-full bg-amber-400 ring-2 ring-zinc-950 flex items-center justify-center">
              <Sparkles size={6} className="text-zinc-900" strokeWidth={3} />
            </span>
          </div>
          <div className="text-left">
            <div className="font-semibold text-sm">Record video</div>
            <div className="text-[11px] text-zinc-400 mt-0.5">AI extracts essence</div>
          </div>
        </button>
      </div>

      <div className="flex gap-2 mb-4">
        {[
          { id: 'open', label: 'Open' },
          { id: 'done', label: 'Done' },
          { id: 'all', label: 'All' }
        ].map(f => (
          <button
            key={f.id}
            onClick={() => setFilter(f.id)}
            className={`text-xs px-3 py-1.5 rounded-full font-medium transition ${filter === f.id ? 'bg-zinc-100 text-zinc-900' : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}
          >
            {f.label}
          </button>
        ))}
      </div>

      <div className="space-y-2">
        {items.map(b => (
          <BrainItem
            key={b.id}
            item={b}
            expanded={expanded === b.id}
            onToggleExpand={() => setExpanded(expanded === b.id ? null : b.id)}
            onToggle={() => toggle(b.id)}
            onRemove={() => remove(b.id)}
            onMove={(dest) => moveDump(b, dest)}
          />
        ))}
        {items.length === 0 && (
          <div className="text-center py-12 text-zinc-500 text-sm">
            {filter === 'open' ? 'All clear ✨' : 'Nothing here'}
          </div>
        )}
      </div>

      {showVideoModal && (
        <VideoRecordModal close={() => setShowVideoModal(false)} onSave={saveVideoEntry} />
      )}
    </div>
  );
}

function BrainItem({ item, expanded, onToggleExpand, onToggle, onRemove, onMove }) {
  const tagColor = (t) => ({
    personal: 'bg-pink-500/15 text-pink-400',
    trading: 'bg-amber-500/15 text-amber-400',
    idea: 'bg-violet-500/15 text-violet-400',
    work: 'bg-sky-500/15 text-sky-400'
  })[t] || 'bg-zinc-700/40 text-zinc-400';

  if (item.type === 'video' && item.video) {
    return (
      <div className={`rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 overflow-hidden ${item.completed ? 'opacity-50' : ''}`}>
        <div className="p-3.5 flex items-start gap-3">
          <button
            onClick={onToggle}
            className={`mt-1 w-5 h-5 rounded-full flex-shrink-0 flex items-center justify-center ring-1 transition ${item.completed ? 'bg-violet-500 ring-violet-500' : 'ring-zinc-600 hover:ring-violet-400'}`}
          >
            {item.completed && <Check size={12} className="text-white" />}
          </button>
          <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-zinc-800 flex-shrink-0">
            {item.video.thumbnail ? (
              <img src={item.video.thumbnail} className="w-full h-full object-cover" alt="" />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-rose-500/30 to-violet-500/30" />
            )}
            <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
              <Video size={18} className="text-white drop-shadow-lg" />
            </div>
            <div className="absolute bottom-0.5 right-0.5 text-[9px] text-white bg-black/70 px-1 rounded tabular-nums">
              {fmtDur(item.video.duration)}
            </div>
          </div>
          <div className="flex-1 min-w-0">
            <div className={`text-sm font-semibold ${item.completed ? 'line-through' : ''}`}>{item.video.title}</div>
            <div className="text-[11px] text-zinc-400 line-clamp-2 mt-0.5">{item.video.essence}</div>
            <div className="flex items-center gap-2 mt-1.5 flex-wrap">
              <span className="text-[10px] bg-rose-500/15 text-rose-400 px-1.5 py-0.5 rounded flex items-center gap-1">
                <Video size={9} /> Video
              </span>
              {item.tag && <span className={`text-[10px] px-1.5 py-0.5 rounded ${tagColor(item.tag)}`}>{item.tag}</span>}
              <button onClick={onToggleExpand} className="text-[10px] text-cyan-400 hover:text-cyan-300 ml-auto flex items-center gap-0.5">
                {expanded ? <>Hide <ChevronUp size={10} /></> : <>Details <ChevronDown size={10} /></>}
              </button>
            </div>
          </div>
          <button onClick={onRemove} className="text-zinc-600 hover:text-rose-400 mt-1">
            <Trash2 size={13} />
          </button>
        </div>
        {expanded && (
          <div className="border-t border-zinc-800/80 px-4 py-3.5 bg-zinc-950/40 space-y-3.5">
            <div>
              <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-1.5 flex items-center gap-1">
                <FileText size={9} /> About
              </div>
              <p className="text-xs text-zinc-300 leading-relaxed">{item.video.topic}</p>
            </div>
            {item.video.keyPoints?.length > 0 && (
              <div>
                <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-1.5 flex items-center gap-1">
                  <Sparkles size={9} /> Key points
                </div>
                <ul className="space-y-1.5">
                  {item.video.keyPoints.map((p, i) => (
                    <li key={i} className="text-xs text-zinc-300 flex gap-2 leading-relaxed">
                      <span className="text-violet-400 flex-shrink-0">•</span>
                      <span>{p}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            {item.video.stepsOrApproaches?.length > 0 && (
              <div>
                <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-1.5 flex items-center gap-1">
                  <ListChecks size={9} /> Steps / approaches
                </div>
                <ol className="space-y-1.5">
                  {item.video.stepsOrApproaches.map((s, i) => (
                    <li key={i} className="text-xs text-zinc-300 flex gap-2 leading-relaxed">
                      <span className="text-amber-400 tabular-nums font-semibold flex-shrink-0">{i + 1}.</span>
                      <span>{s}</span>
                    </li>
                  ))}
                </ol>
              </div>
            )}
            {item.video.transcript && (
              <details className="group">
                <summary className="text-[10px] uppercase tracking-wider text-zinc-500 cursor-pointer hover:text-zinc-400 list-none flex items-center gap-1">
                  <BookOpen size={9} /> Transcript
                  <ChevronDown size={9} className="group-open:rotate-180 transition" />
                </summary>
                <p className="text-[11px] text-zinc-500 mt-2 italic leading-relaxed">{item.video.transcript}</p>
              </details>
            )}
          </div>
        )}
      </div>
    );
  }

  return (
    <div className={`rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 p-3.5 flex items-start gap-3 ${item.completed ? 'opacity-50' : ''}`}>
      <button
        onClick={onToggle}
        className={`mt-0.5 w-5 h-5 rounded-full flex-shrink-0 flex items-center justify-center ring-1 transition ${item.completed ? 'bg-violet-500 ring-violet-500' : 'ring-zinc-600 hover:ring-violet-400'}`}
      >
        {item.completed && <Check size={12} className="text-white" />}
      </button>
      <div className="flex-1 min-w-0">
        <div className={`text-sm ${item.completed ? 'line-through text-zinc-500' : 'text-zinc-100'}`}>{item.text}</div>
        <div className="flex items-center gap-2 mt-1.5 flex-wrap">
          {item.tag && <span className={`text-[10px] px-1.5 py-0.5 rounded ${tagColor(item.tag)}`}>{item.tag}</span>}
          {item.reminderAt && (
            <span className="text-[10px] text-amber-400 flex items-center gap-1">
              <Bell size={9} /> {new Date(item.reminderAt).toLocaleDateString([], { month: 'short', day: 'numeric' })}
            </span>
          )}
          {!item.completed && (() => {
            const dest = autoRoute(item.text);
            if (dest === 'grocery' && onMove) {
              return (
                <button
                  onClick={() => onMove('grocery')}
                  className="text-[10px] bg-emerald-500/15 text-emerald-300 hover:bg-emerald-500/25 px-1.5 py-0.5 rounded flex items-center gap-1 ring-1 ring-emerald-500/30"
                  title="Auto-detected: looks like a grocery item"
                >
                  <Sparkles size={9} /> Move to Grocery <ArrowRight size={9} />
                </button>
              );
            }
            if (dest && dest !== 'grocery') {
              return (
                <span className="text-[10px] bg-zinc-800/60 text-zinc-400 px-1.5 py-0.5 rounded flex items-center gap-1">
                  <Sparkles size={9} /> looks like · {dest}
                </span>
              );
            }
            return null;
          })()}
          <span className="text-[10px] text-zinc-500">{new Date(item.createdAt).toLocaleDateString([], { month: 'short', day: 'numeric' })}</span>
        </div>
      </div>
      <button onClick={onRemove} className="text-zinc-600 hover:text-rose-400 mt-0.5">
        <Trash2 size={13} />
      </button>
    </div>
  );
}

/* ─── VIDEO RECORD MODAL ───────────────────────────────── */
function VideoRecordModal({ close, onSave }) {
  const [phase, setPhase] = useState('init');
  const [error, setError] = useState(null);
  const [transcript, setTranscript] = useState('');
  const [interim, setInterim] = useState('');
  const [duration, setDuration] = useState(0);
  const [thumbnail, setThumbnail] = useState(null);
  const [analysis, setAnalysis] = useState(null);
  const [demoText, setDemoText] = useState('');

  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const recorderRef = useRef(null);
  const recognitionRef = useRef(null);
  const timerRef = useRef(null);
  const startTime = useRef(null);
  const transcriptRef = useRef('');

  useEffect(() => {
    let mounted = true;
    (async () => {
      if (!navigator.mediaDevices?.getUserMedia) {
        setError('Camera API not available');
        setPhase('error');
        return;
      }
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'user', width: { ideal: 720 }, height: { ideal: 1280 } },
          audio: true
        });
        if (!mounted) {
          stream.getTracks().forEach(t => t.stop());
          return;
        }
        streamRef.current = stream;
        if (videoRef.current) videoRef.current.srcObject = stream;
        setPhase('preview');
      } catch (e) {
        setError(e.message || 'Could not access camera');
        setPhase('error');
      }
    })();
    return () => {
      mounted = false;
      cleanup();
    };
    // eslint-disable-next-line
  }, []);

  const cleanup = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(t => t.stop());
      streamRef.current = null;
    }
    if (recognitionRef.current) {
      try { recognitionRef.current.stop(); } catch {}
      recognitionRef.current = null;
    }
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
  };

  const startRecording = () => {
    if (!streamRef.current) return;

    try {
      const rec = new MediaRecorder(streamRef.current);
      recorderRef.current = rec;
      rec.start();
    } catch (e) { /* non-fatal */ }

    const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (SR) {
      try {
        const rec = new SR();
        rec.continuous = true;
        rec.interimResults = true;
        rec.lang = 'en-US';
        rec.onresult = (e) => {
          let finalText = '';
          let interimText = '';
          for (let i = e.resultIndex; i < e.results.length; i++) {
            const t = e.results[i][0].transcript;
            if (e.results[i].isFinal) finalText += t + ' ';
            else interimText += t;
          }
          if (finalText) {
            transcriptRef.current += finalText;
            setTranscript(transcriptRef.current);
          }
          setInterim(interimText);
        };
        rec.onerror = () => {};
        rec.start();
        recognitionRef.current = rec;
      } catch (e) { /* non-fatal */ }
    }

    startTime.current = Date.now();
    timerRef.current = setInterval(() => {
      setDuration(Math.floor((Date.now() - startTime.current) / 1000));
    }, 250);

    setPhase('recording');
  };

  const stopRecording = async () => {
    if (recorderRef.current && recorderRef.current.state !== 'inactive') {
      try { recorderRef.current.stop(); } catch {}
    }
    if (recognitionRef.current) {
      try { recognitionRef.current.stop(); } catch {}
    }
    if (timerRef.current) clearInterval(timerRef.current);

    let thumb = null;
    if (videoRef.current && videoRef.current.videoWidth > 0) {
      try {
        const c = document.createElement('canvas');
        c.width = videoRef.current.videoWidth;
        c.height = videoRef.current.videoHeight;
        c.getContext('2d').drawImage(videoRef.current, 0, 0);
        thumb = c.toDataURL('image/jpeg', 0.5);
        setThumbnail(thumb);
      } catch {}
    }

    setPhase('processing');

    const text = (transcriptRef.current + ' ' + interim).trim();
    if (!text || text.length < 8) {
      setAnalysis({
        title: 'Brief video memo',
        topic: 'A short recording with no transcribable speech captured.',
        keyPoints: [],
        stepsOrApproaches: [],
        essence: 'No clear speech was captured. The video saved, but no insights could be extracted.'
      });
      setPhase('review');
      return;
    }

    try {
      const result = await analyzeTranscript(text);
      setAnalysis(result);
      setPhase('review');
    } catch (e) {
      setError('Analysis failed: ' + e.message);
      setPhase('error');
    }
  };

  const handleDemoSubmit = async () => {
    if (!demoText.trim() || demoText.trim().length < 10) return;
    setPhase('processing');
    try {
      const result = await analyzeTranscript(demoText);
      setAnalysis(result);
      setTranscript(demoText);
      setDuration(Math.max(15, Math.floor(demoText.length / 12)));
      setPhase('review');
    } catch (e) {
      setError(e.message);
      setPhase('error');
    }
  };

  const handleSave = async () => {
    const entry = {
      id: `b${Date.now()}`,
      type: 'video',
      createdAt: new Date().toISOString(),
      completed: false,
      tag: 'idea',
      text: transcript,
      video: {
        duration,
        thumbnail,
        transcript,
        title: analysis.title,
        topic: analysis.topic,
        keyPoints: analysis.keyPoints || [],
        stepsOrApproaches: analysis.stepsOrApproaches || [],
        essence: analysis.essence
      }
    };
    await onSave(entry);
    cleanup();
    close();
  };

  const handleClose = () => {
    cleanup();
    close();
  };

  return (
    <div className="absolute inset-0 z-50 bg-black flex flex-col">
      <div className="flex items-center justify-between p-4 absolute top-0 left-0 right-0 z-10">
        <button onClick={handleClose} className="w-10 h-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center text-white">
          <X size={18} />
        </button>
        {phase === 'recording' && (
          <div className="flex items-center gap-2 bg-rose-500/30 backdrop-blur px-3 py-1.5 rounded-full ring-1 ring-rose-500/50">
            <span className="w-2 h-2 rounded-full bg-rose-400 animate-pulse"></span>
            <span className="text-white text-xs font-semibold tabular-nums">REC {fmtDur(duration)}</span>
          </div>
        )}
        {phase === 'preview' && (
          <div className="bg-black/50 backdrop-blur px-3 py-1.5 rounded-full">
            <span className="text-white text-[11px] font-medium">Ready</span>
          </div>
        )}
        <div className="w-10"></div>
      </div>

      <div className="flex-1 relative overflow-hidden bg-zinc-950">
        {(phase === 'preview' || phase === 'recording') && (
          <>
            <video ref={videoRef} autoPlay playsInline muted className="w-full h-full object-cover" />
            {phase === 'recording' && (transcript || interim) && (
              <div className="absolute bottom-32 left-4 right-4 bg-black/70 backdrop-blur-md rounded-2xl p-3.5 max-h-40 overflow-y-auto ring-1 ring-white/10">
                <div className="text-[10px] uppercase tracking-wider text-violet-300 mb-1.5 flex items-center gap-1">
                  <Sparkles size={9} /> Live transcript
                </div>
                <p className="text-sm text-white leading-relaxed">
                  {transcript}<span className="text-zinc-400">{interim}</span>
                </p>
              </div>
            )}
            {phase === 'preview' && (
              <div className="absolute top-20 left-4 right-4">
                <div className="bg-black/60 backdrop-blur-md rounded-2xl p-4 ring-1 ring-white/10">
                  <div className="flex items-center gap-2 text-amber-300 text-xs font-semibold mb-1">
                    <Sparkles size={12} /> AI-powered capture
                  </div>
                  <p className="text-zinc-200 text-xs leading-relaxed">
                    Speak naturally while recording. After you stop, Claude extracts the title, key points, steps, and essence.
                  </p>
                </div>
              </div>
            )}
          </>
        )}

        {phase === 'init' && (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="flex flex-col items-center gap-3">
              <Loader2 size={24} className="text-zinc-400 animate-spin" />
              <div className="text-zinc-400 text-sm">Requesting camera access…</div>
            </div>
          </div>
        )}

        {phase === 'error' && (
          <div className="absolute inset-0 flex flex-col items-center justify-center p-6 text-center">
            <div className="w-16 h-16 rounded-full bg-amber-500/20 flex items-center justify-center mb-4">
              <Camera size={28} className="text-amber-400" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Camera unavailable</h3>
            <p className="text-zinc-400 text-sm mb-6 max-w-xs leading-relaxed">
              {error || 'Could not access camera.'} In the real Flutter app you'll have full native camera support. Try the demo below to see the AI analysis flow.
            </p>
            <button onClick={() => { setError(null); setPhase('demo'); }} className="bg-violet-500 hover:bg-violet-400 text-white px-5 py-2.5 rounded-full text-sm font-semibold flex items-center gap-2">
              <Sparkles size={14} /> Try demo flow
            </button>
          </div>
        )}

        {phase === 'demo' && (
          <div className="absolute inset-0 flex flex-col p-5 pt-20">
            <div className="bg-violet-500/10 border border-violet-500/30 rounded-xl p-3.5 mb-4">
              <div className="text-violet-300 text-[11px] font-semibold mb-1 flex items-center gap-1">
                <Sparkles size={11} /> Demo mode
              </div>
              <p className="text-zinc-300 text-xs leading-relaxed">
                Type what you'd say in your video (more than a sentence). Claude will extract the structured essence — exactly as it would from a real recording's transcript.
              </p>
            </div>
            <textarea
              autoFocus
              placeholder="e.g. I'm thinking about my trading approach for next week. The plan is to focus only on the NY AM killzone and skip Asian session entirely. I want to wait for liquidity sweeps below previous day low, then look for reversal patterns. Three things I need to do: backtest this on last month's data, set up alerts at 8:25 AM, and journal every trade including the ones I skip..."
              className="flex-1 bg-zinc-900 rounded-xl p-4 text-sm text-zinc-100 placeholder-zinc-600 resize-none outline-none ring-1 ring-zinc-800 focus:ring-violet-500"
              value={demoText}
              onChange={e => setDemoText(e.target.value)}
            />
            <button
              onClick={handleDemoSubmit}
              disabled={demoText.trim().length < 10}
              className="mt-4 w-full bg-violet-500 disabled:bg-zinc-800 disabled:text-zinc-600 text-white font-semibold py-3 rounded-xl transition flex items-center justify-center gap-2"
            >
              <Sparkles size={14} /> Analyze with Claude
            </button>
          </div>
        )}

        {phase === 'processing' && (
          <div className="absolute inset-0 bg-zinc-950 flex flex-col items-center justify-center p-6">
            {thumbnail && (
              <div className="relative w-32 h-32 rounded-2xl overflow-hidden mb-6 ring-1 ring-zinc-800">
                <img src={thumbnail} className="w-full h-full object-cover" alt="" />
                <div className="absolute inset-0 bg-gradient-to-t from-violet-500/40 to-transparent animate-pulse"></div>
              </div>
            )}
            <div className="flex items-center gap-2 mb-3">
              <div className="w-2 h-2 rounded-full bg-violet-400 animate-bounce" style={{ animationDelay: '0ms' }}></div>
              <div className="w-2 h-2 rounded-full bg-violet-400 animate-bounce" style={{ animationDelay: '150ms' }}></div>
              <div className="w-2 h-2 rounded-full bg-violet-400 animate-bounce" style={{ animationDelay: '300ms' }}></div>
            </div>
            <p className="text-zinc-100 font-semibold">Analyzing your recording</p>
            <p className="text-zinc-500 text-xs mt-1.5">Claude is extracting key points & essence…</p>
            {transcript && (
              <div className="mt-6 max-w-xs">
                <div className="text-[10px] uppercase tracking-wider text-zinc-600 mb-1 text-center">Transcript</div>
                <p className="text-[11px] text-zinc-500 italic line-clamp-3 text-center leading-relaxed">"{transcript.slice(0, 200)}{transcript.length > 200 ? '…' : ''}"</p>
              </div>
            )}
          </div>
        )}

        {phase === 'review' && analysis && (
          <div className="absolute inset-0 bg-zinc-950 overflow-y-auto pt-16 pb-24">
            <div className="px-5">
              {thumbnail && (
                <div className="relative w-full aspect-video rounded-2xl overflow-hidden mb-4 ring-1 ring-zinc-800">
                  <img src={thumbnail} className="w-full h-full object-cover" alt="" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
                  <div className="absolute bottom-2 right-2 bg-black/70 backdrop-blur px-2 py-1 rounded text-[10px] text-white tabular-nums flex items-center gap-1">
                    <Video size={10} />{fmtDur(duration)}
                  </div>
                  <div className="absolute top-2 left-2 bg-violet-500/90 backdrop-blur px-2 py-1 rounded text-[10px] text-white font-semibold flex items-center gap-1">
                    <Sparkles size={10} /> Analyzed
                  </div>
                </div>
              )}

              <h2 className="text-xl font-bold mb-2 leading-tight">{analysis.title}</h2>
              <p className="text-sm text-zinc-300 mb-5 leading-relaxed">{analysis.essence}</p>

              <div className="space-y-4">
                <div className="bg-zinc-900/50 rounded-xl p-3.5 ring-1 ring-zinc-800">
                  <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-2 flex items-center gap-1">
                    <FileText size={9} /> About
                  </div>
                  <p className="text-sm text-zinc-200 leading-relaxed">{analysis.topic}</p>
                </div>

                {analysis.keyPoints?.length > 0 && (
                  <div className="bg-zinc-900/50 rounded-xl p-3.5 ring-1 ring-zinc-800">
                    <div className="text-[10px] uppercase tracking-wider text-violet-400 mb-2 flex items-center gap-1">
                      <Sparkles size={9} /> Key points
                    </div>
                    <ul className="space-y-2">
                      {analysis.keyPoints.map((p, i) => (
                        <li key={i} className="text-sm text-zinc-200 flex gap-2.5 leading-relaxed">
                          <span className="text-violet-400 mt-0.5">•</span>
                          <span>{p}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {analysis.stepsOrApproaches?.length > 0 && (
                  <div className="bg-zinc-900/50 rounded-xl p-3.5 ring-1 ring-zinc-800">
                    <div className="text-[10px] uppercase tracking-wider text-amber-400 mb-2 flex items-center gap-1">
                      <ListChecks size={9} /> Steps & approaches
                    </div>
                    <ol className="space-y-2">
                      {analysis.stepsOrApproaches.map((s, i) => (
                        <li key={i} className="text-sm text-zinc-200 flex gap-2.5 leading-relaxed">
                          <span className="text-amber-400 mt-0.5 tabular-nums font-semibold">{i + 1}.</span>
                          <span>{s}</span>
                        </li>
                      ))}
                    </ol>
                  </div>
                )}

                {transcript && (
                  <details className="bg-zinc-900/30 rounded-xl p-3.5 ring-1 ring-zinc-800/50 group">
                    <summary className="text-[10px] uppercase tracking-wider text-zinc-500 cursor-pointer hover:text-zinc-400 list-none flex items-center justify-between">
                      <span className="flex items-center gap-1"><BookOpen size={9} /> Raw transcript</span>
                      <ChevronDown size={11} className="group-open:rotate-180 transition" />
                    </summary>
                    <p className="text-xs text-zinc-500 mt-2.5 italic leading-relaxed">{transcript}</p>
                  </details>
                )}
              </div>
            </div>
          </div>
        )}
      </div>

      {phase === 'preview' && (
        <div className="p-6 pb-8 flex flex-col items-center gap-3 bg-gradient-to-t from-black to-transparent">
          <button onClick={startRecording} className="w-20 h-20 rounded-full bg-rose-500 ring-4 ring-rose-500/30 flex items-center justify-center hover:scale-105 transition active:scale-95 shadow-2xl">
            <div className="w-7 h-7 rounded-full bg-white"></div>
          </button>
          <p className="text-zinc-400 text-xs">Tap to start recording</p>
        </div>
      )}

      {phase === 'recording' && (
        <div className="p-6 pb-8 flex flex-col items-center gap-3 bg-gradient-to-t from-black to-transparent">
          <button onClick={stopRecording} className="w-20 h-20 rounded-full bg-rose-500 ring-4 ring-rose-500/30 flex items-center justify-center hover:scale-105 transition active:scale-95 shadow-2xl">
            <div className="w-7 h-7 rounded bg-white"></div>
          </button>
          <p className="text-zinc-400 text-xs">Tap to stop & analyze</p>
        </div>
      )}

      {phase === 'review' && (
        <div className="p-4 flex gap-2 bg-zinc-950 border-t border-zinc-800 absolute bottom-0 left-0 right-0">
          <button onClick={handleClose} className="flex-1 bg-zinc-900 ring-1 ring-zinc-800 text-zinc-300 font-medium py-3 rounded-xl hover:bg-zinc-800 transition">
            Discard
          </button>
          <button onClick={handleSave} className="flex-1 bg-violet-500 hover:bg-violet-400 text-white font-semibold py-3 rounded-xl transition flex items-center justify-center gap-2">
            <Check size={16} /> Save entry
          </button>
        </div>
      )}
    </div>
  );
}

/* ─── GROCERY / PANTRY ─────────────────────────────────── */
function GroceryScreen({ data, save, setModal, flash }) {
  const [view, setView] = useState('list');
  const { list, pantry, members } = data.groceries;

  const toggleItem = (id) => {
    save({ ...data, groceries: { ...data.groceries, list: list.map(g => g.id === id ? { ...g, completed: !g.completed } : g) } });
  };

  const removeItem = (id) => {
    save({ ...data, groceries: { ...data.groceries, list: list.filter(g => g.id !== id) } });
    flash('Removed');
  };

  const adjustPantry = (id, delta) => {
    save({ ...data, groceries: { ...data.groceries, pantry: pantry.map(p => p.id === id ? { ...p, qty: Math.max(0, p.qty + delta) } : p) } });
  };

  const addPantryToList = (p) => {
    const already = list.some(g => !g.completed && g.name.toLowerCase() === p.name.toLowerCase());
    if (already) {
      flash('Already on list');
      return;
    }
    save({
      ...data,
      groceries: {
        ...data.groceries,
        list: [...list, { id: `g${Date.now()}`, name: p.name, qty: Math.max(1, (p.lowThreshold || 1) + 1 - p.qty), category: 'Pantry', addedBy: 'You', completed: false, recurring: null }]
      }
    });
    flash(`${p.name} added to list`);
  };

  const toggleRecurring = (id) => {
    save({
      ...data,
      groceries: {
        ...data.groceries,
        list: list.map(g => g.id === id ? { ...g, recurring: g.recurring === 'weekly' ? null : 'weekly' } : g)
      }
    });
  };

  const cycleMember = (id) => {
    save({
      ...data,
      groceries: {
        ...data.groceries,
        list: list.map(g => {
          if (g.id !== id) return g;
          const idx = members.indexOf(g.addedBy);
          return { ...g, addedBy: members[(idx + 1) % members.length] };
        })
      }
    });
  };

  const pending = list.filter(g => !g.completed);
  const done = list.filter(g => g.completed);
  const lowStock = pantry.filter(p => p.qty <= p.lowThreshold);

  const memberColor = (m) => ({ You: 'bg-cyan-500/20 text-cyan-400', Sam: 'bg-emerald-500/20 text-emerald-400', Alex: 'bg-amber-500/20 text-amber-400' })[m] || 'bg-zinc-700 text-zinc-400';

  return (
    <div className="px-5 pt-6">
      <div className="flex items-center justify-between mb-1">
        <h1 className="text-2xl font-bold tracking-tight">Household</h1>
        <button onClick={() => setModal({ type: view === 'list' ? 'grocery-add' : 'pantry-add' })} className="w-9 h-9 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-300 hover:bg-zinc-800">
          <Plus size={16} />
        </button>
      </div>
      <p className="text-zinc-500 text-sm mb-4">Shared with {members.length} people</p>

      <div className="flex gap-1 mb-5 bg-zinc-900 p-1 rounded-xl ring-1 ring-zinc-800">
        {[
          { id: 'list', label: 'Groceries', count: pending.length },
          { id: 'pantry', label: 'Pantry', count: lowStock.length, alert: true }
        ].map(t => (
          <button
            key={t.id}
            onClick={() => setView(t.id)}
            className={`flex-1 text-xs font-medium py-2 rounded-lg transition flex items-center justify-center gap-1.5 ${view === t.id ? 'bg-zinc-100 text-zinc-900' : 'text-zinc-400'}`}
          >
            {t.label}
            {t.count > 0 && <span className={`text-[10px] px-1.5 rounded-full ${view === t.id ? 'bg-zinc-900 text-zinc-100' : t.alert ? 'bg-amber-500/30 text-amber-300' : 'bg-zinc-800 text-zinc-400'}`}>{t.count}</span>}
          </button>
        ))}
      </div>

      <div className="flex items-center gap-2 mb-4">
        <span className="text-[10px] uppercase tracking-wider text-zinc-500">Household:</span>
        <div className="flex -space-x-1.5">
          {members.map(m => (
            <div key={m} className={`w-6 h-6 rounded-full ring-2 ring-zinc-950 flex items-center justify-center text-[10px] font-bold ${memberColor(m)}`}>{m[0]}</div>
          ))}
        </div>
      </div>

      {view === 'list' && (
        <>
          <div className="space-y-4 mb-5">
            {Object.entries(pending.reduce((acc, g) => {
              const cat = g.category || 'Other';
              (acc[cat] = acc[cat] || []).push(g);
              return acc;
            }, {})).sort((a, b) => a[0].localeCompare(b[0])).map(([cat, items]) => (
              <div key={cat}>
                <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-1.5 px-1">{cat}</div>
                <div className="space-y-2">
                  {items.map(g => (
                    <div key={g.id} className="rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 p-3.5 flex items-center gap-3">
                      <button onClick={() => toggleItem(g.id)} className="w-5 h-5 rounded-full ring-1 ring-zinc-600 hover:ring-emerald-400 transition flex-shrink-0"></button>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          <span className="text-sm font-medium">{g.name}</span>
                          {g.recurring === 'weekly' && (
                            <span className="text-[9px] bg-violet-500/15 text-violet-300 px-1 py-0.5 rounded flex items-center gap-0.5" title="Auto-re-adds every week">
                              <Repeat size={8} /> wk
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-[10px] text-zinc-500">×{g.qty}</span>
                          <button onClick={() => cycleMember(g.id)} className={`text-[10px] px-1.5 py-0.5 rounded ${memberColor(g.addedBy)}`} title="Tap to reassign">
                            {g.addedBy}
                          </button>
                          <button onClick={() => toggleRecurring(g.id)} className="text-[10px] text-zinc-500 hover:text-violet-300" title="Toggle weekly recurring">
                            <Repeat size={10} />
                          </button>
                        </div>
                      </div>
                      <button onClick={() => removeItem(g.id)} className="text-zinc-600 hover:text-rose-400">
                        <Trash2 size={13} />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            ))}
            {pending.length === 0 && (
              <div className="text-center py-12 text-zinc-500 text-sm">List is empty 🎉</div>
            )}
          </div>
          {done.length > 0 && (
            <div className="mb-4">
              <div className="text-[10px] uppercase tracking-wider text-zinc-500 mb-2">In cart</div>
              <div className="space-y-1.5">
                {done.map(g => (
                  <div key={g.id} className="rounded-xl bg-zinc-900/30 p-3 flex items-center gap-3 opacity-60">
                    <button onClick={() => toggleItem(g.id)} className="w-5 h-5 rounded-full bg-emerald-500 flex items-center justify-center flex-shrink-0">
                      <Check size={11} className="text-white" />
                    </button>
                    <div className="flex-1 text-sm line-through text-zinc-400">{g.name}</div>
                    <button onClick={() => removeItem(g.id)} className="text-zinc-600 hover:text-rose-400">
                      <X size={13} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}

      {view === 'pantry' && (
        <div className="space-y-2">
          {pantry.sort((a, b) => a.qty - b.qty).map(p => {
            const low = p.qty <= p.lowThreshold;
            const onList = list.some(g => !g.completed && g.name.toLowerCase() === p.name.toLowerCase());
            return (
              <div key={p.id} className={`rounded-xl ring-1 p-3.5 flex items-center justify-between gap-2 ${low ? 'bg-amber-500/5 ring-amber-500/20' : 'bg-zinc-900/60 ring-zinc-800'}`}>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-sm font-medium">{p.name}</span>
                    {low && <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-400">{p.qty === 0 ? 'OUT' : 'LOW'}</span>}
                  </div>
                  <div className="text-[11px] text-zinc-500 mt-0.5 tabular-nums">{p.qty} {p.unit} · alert at {p.lowThreshold}</div>
                </div>
                {low && (
                  <button
                    onClick={() => addPantryToList(p)}
                    disabled={onList}
                    className={`text-[10px] px-2 py-1 rounded-full ring-1 flex items-center gap-1 ${onList ? 'bg-zinc-800 text-zinc-500 ring-zinc-700 cursor-not-allowed' : 'bg-emerald-500/15 text-emerald-300 ring-emerald-500/30 hover:bg-emerald-500/25'}`}
                  >
                    {onList ? <Check size={10} /> : <Plus size={10} />} {onList ? 'on list' : 'add'}
                  </button>
                )}
                <div className="flex items-center gap-1">
                  <button onClick={() => adjustPantry(p.id, -1)} className="w-7 h-7 rounded-lg bg-zinc-800 hover:bg-zinc-700 flex items-center justify-center text-zinc-300">−</button>
                  <span className="w-7 text-center text-sm font-semibold tabular-nums">{p.qty}</span>
                  <button onClick={() => adjustPantry(p.id, 1)} className="w-7 h-7 rounded-lg bg-zinc-800 hover:bg-zinc-700 flex items-center justify-center text-zinc-300">+</button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

/* ─── BODY (Fitness + Diet) ────────────────────────────── */
function BodyScreen({ data, now, save, setModal, flash }) {
  const body = data.body || { macros: { calories: { used: 0, goal: 2400 }, protein: { used: 0, goal: 180 }, carbs: { used: 0, goal: 280 }, fat: { used: 0, goal: 80 }, water: { used: 0, goal: 10 } }, streak: 0, streakFreezes: 0 };
  const macros = body.macros;
  const streak = body.streak;
  const nextWorkout = { name: 'Push Day', time: '6:30 PM', in: '2h 15m', focus: 'Chest · Shoulders · Triceps' };
  const weekWorkouts = [
    { day: 'Mon', name: 'Pull', done: true, vol: '12,400 lbs' },
    { day: 'Tue', name: 'Legs', done: true, vol: '18,200 lbs' },
    { day: 'Wed', name: 'Rest', done: true, vol: '—' },
    { day: 'Thu', name: 'Push', done: true, vol: '11,100 lbs' },
    { day: 'Fri', name: 'Pull', done: false, vol: 'Tonight' },
  ];
  const recentMeals = [
    { id: 'm1', name: 'Greek yogurt + berries', kcal: 280, p: 22, time: '8:15 AM', tag: 'breakfast' },
    { id: 'm2', name: 'Chicken rice bowl', kcal: 620, p: 48, time: '12:40 PM', tag: 'lunch' },
    { id: 'm3', name: 'Whey shake', kcal: 180, p: 30, time: '3:20 PM', tag: 'snack' },
  ];

  const pct = (m) => Math.round((m.used / m.goal) * 100);

  const addWater = () => {
    save({
      ...data,
      body: { ...body, macros: { ...macros, water: { ...macros.water, used: Math.min(macros.water.goal + 4, macros.water.used + 1) } } }
    });
    flash('+1 cup');
  };

  const useFreeze = () => {
    if (body.streakFreezes <= 0) return;
    save({ ...data, body: { ...body, streakFreezes: body.streakFreezes - 1 } });
    flash('Freeze used · streak protected');
  };

  return (
    <div className="px-5 pt-6 pb-4">
      {/* Header */}
      <div className="flex items-start justify-between mb-5">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Body</h1>
          <p className="text-zinc-500 text-sm mt-1">Workouts · macros · weight</p>
        </div>
        <button
          onClick={() => setModal({ type: 'meal-add' })}
          className="w-10 h-10 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-400 hover:bg-zinc-800 transition"
        >
          <Plus size={16} />
        </button>
      </div>

      {/* Streak banner with freeze */}
      <div className="rounded-2xl bg-gradient-to-br from-orange-500/20 via-rose-500/5 to-transparent ring-1 ring-orange-500/30 p-4 mb-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-orange-500/20 flex items-center justify-center">
              <Flame size={20} className="text-orange-400" />
            </div>
            <div>
              <div className="text-2xl font-bold">{streak}-day streak</div>
              <div className="text-zinc-400 text-xs">Hit calorie + protein 4 days running</div>
            </div>
          </div>
          <button
            onClick={useFreeze}
            disabled={body.streakFreezes <= 0}
            className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-full text-[11px] font-medium ring-1 ${body.streakFreezes > 0 ? 'bg-sky-500/15 text-sky-300 ring-sky-500/30 hover:bg-sky-500/25' : 'bg-zinc-800 text-zinc-600 ring-zinc-700 cursor-not-allowed'}`}
            title="Use a streak freeze (1 per week)"
          >
            <Snowflake size={11} /> {body.streakFreezes}
          </button>
        </div>
      </div>

      {/* Next workout */}
      <button
        onClick={() => flash && flash('Workout starts at ' + nextWorkout.time)}
        className="w-full text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-5 mb-4"
      >
        <div className="flex items-center gap-2 mb-2">
          <Dumbbell size={14} className="text-cyan-400" />
          <span className="text-xs font-semibold uppercase tracking-wider text-zinc-400">Next Workout</span>
        </div>
        <div className="text-3xl font-bold">{nextWorkout.name}</div>
        <div className="text-zinc-400 text-sm mt-1">{nextWorkout.focus}</div>
        <div className="text-zinc-500 text-xs mt-2 flex items-center gap-1.5">
          <Clock size={12} /> In <span className="text-white font-semibold">{nextWorkout.in}</span> · {nextWorkout.time}
        </div>
      </button>

      {/* Macro stats — calories full row, P/C/F + Water grid */}
      <div className="rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 mb-3">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-1.5">
            <Flame size={12} className="text-orange-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">Calories</span>
          </div>
          <span className="text-[11px] text-zinc-500 tabular-nums">{macros.calories.used} / {macros.calories.goal} kcal</span>
        </div>
        <div className="h-1.5 bg-zinc-800 rounded-full overflow-hidden">
          <div className="h-full bg-orange-400" style={{ width: `${Math.min(100, pct(macros.calories))}%` }} />
        </div>
      </div>

      <div className="grid grid-cols-3 gap-2 mb-3">
        <MacroCard icon={Activity} iconColor="text-emerald-400" label="Protein" used={macros.protein.used} goal={macros.protein.goal} unit="g" pct={pct(macros.protein)} barColor="bg-emerald-400" />
        <MacroCard icon={Zap} iconColor="text-amber-400" label="Carbs" used={macros.carbs?.used ?? 0} goal={macros.carbs?.goal ?? 280} unit="g" pct={pct(macros.carbs ?? { used: 0, goal: 1 })} barColor="bg-amber-400" />
        <MacroCard icon={Droplet} iconColor="text-rose-300" label="Fat" used={macros.fat?.used ?? 0} goal={macros.fat?.goal ?? 80} unit="g" pct={pct(macros.fat ?? { used: 0, goal: 1 })} barColor="bg-rose-300" />
      </div>

      {/* Water with quick log */}
      <div className="rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 mb-4 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <Droplet size={14} className="text-sky-400" />
          <div>
            <div className="text-[10px] uppercase tracking-wider text-zinc-500">Water</div>
            <div className="text-sm font-semibold tabular-nums">{macros.water.used} / {macros.water.goal} cups</div>
          </div>
        </div>
        <button
          onClick={addWater}
          className="bg-sky-500/15 text-sky-300 hover:bg-sky-500/25 ring-1 ring-sky-500/30 px-3 py-1.5 rounded-full text-xs font-medium flex items-center gap-1"
        >
          <Plus size={12} /> Cup
        </button>
      </div>

      {/* Quick log meal */}
      <button
        onClick={() => setModal({ type: 'meal-add' })}
        className="w-full rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-600 p-4 text-left shadow-lg shadow-emerald-900/30 mb-4 active:scale-[0.98] transition"
      >
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-white/15 flex items-center justify-center">
            <Apple size={18} />
          </div>
          <div className="flex-1">
            <div className="font-semibold">Log a meal</div>
            <div className="text-emerald-100 text-xs">Voice or photo · AI estimates macros</div>
          </div>
          <Plus size={20} />
        </div>
      </button>

      {/* Sleep + RPE */}
      {body.lastSleep && (
        <div className="rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 mb-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Moon size={14} className="text-violet-400" />
            <div>
              <div className="text-[10px] uppercase tracking-wider text-zinc-500">Recovery</div>
              <div className="text-sm font-semibold tabular-nums">{body.lastSleep.hours}h sleep · RPE {body.lastSleep.rpe}</div>
            </div>
          </div>
          <span className="text-[10px] text-zinc-500">{new Date(body.lastSleep.date).toLocaleDateString([], { month: 'short', day: 'numeric' })}</span>
        </div>
      )}

      {/* This week */}
      <div className="rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 mb-4">
        <div className="flex items-center justify-between mb-3">
          <div className="text-xs font-semibold uppercase tracking-wider text-zinc-400">This week</div>
          <ChevronRight size={14} className="text-zinc-600" />
        </div>
        <div className="space-y-2.5">
          {weekWorkouts.map((w, i) => (
            <div key={i} className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className={`w-7 text-center text-[10px] font-bold uppercase ${w.done ? 'text-zinc-300' : 'text-zinc-600'}`}>{w.day}</div>
                <div className="flex items-center gap-2">
                  {w.done
                    ? <div className="w-5 h-5 rounded-full bg-emerald-500/20 flex items-center justify-center"><Check size={12} className="text-emerald-400" /></div>
                    : <div className="w-5 h-5 rounded-full border border-zinc-700"></div>}
                  <span className={`text-sm ${w.done ? 'text-white' : 'text-zinc-400'}`}>{w.name}</span>
                </div>
              </div>
              <div className={`text-xs ${w.done ? 'text-zinc-500' : 'text-cyan-400 font-medium'}`}>{w.vol}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Recent meals */}
      <div className="rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4">
        <div className="flex items-center justify-between mb-3">
          <div className="text-xs font-semibold uppercase tracking-wider text-zinc-400">Today's meals</div>
          <span className="text-[10px] text-zinc-500">{recentMeals.reduce((s, m) => s + m.kcal, 0)} kcal</span>
        </div>
        <div className="space-y-3">
          {recentMeals.map(m => (
            <div key={m.id} className="flex items-center justify-between">
              <div className="flex-1 min-w-0">
                <div className="text-sm truncate">{m.name}</div>
                <div className="text-[11px] text-zinc-500 flex items-center gap-2 mt-0.5">
                  <span className="bg-emerald-500/10 text-emerald-400 px-1.5 py-0.5 rounded">{m.tag}</span>
                  <span>{m.time}</span>
                </div>
              </div>
              <div className="text-right ml-3">
                <div className="text-sm font-semibold">{m.kcal}</div>
                <div className="text-[10px] text-zinc-500">{m.p}g protein</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function MacroCard({ icon: Icon, iconColor, label, used, goal, unit, pct, barColor }) {
  return (
    <div className="rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-3">
      <div className="flex items-center gap-1.5 mb-1.5">
        <Icon size={11} className={iconColor} />
        <span className="text-[9px] font-semibold uppercase tracking-wider text-zinc-500">{label}</span>
      </div>
      <div className="text-lg font-bold leading-tight">{used}</div>
      <div className="text-[10px] text-zinc-500 mb-2">of {goal} {unit}</div>
      <div className="h-1 bg-zinc-800 rounded-full overflow-hidden">
        <div className={`h-full ${barColor} rounded-full`} style={{ width: `${Math.min(100, pct)}%` }}></div>
      </div>
    </div>
  );
}

/* ─── BOTTOM NAV (fixed Home + Profile, scrollable middle) ─────────────── */
const NAV_TABS = [
  { id: 'home', icon: Home, label: 'Home', fixed: 'left' },
  { id: 'killzone', icon: TrendingUp, label: 'Trading' },
  { id: 'subs', icon: CreditCard, label: 'Spend' },
  { id: 'brain', icon: Brain, label: 'Capture' },
  { id: 'grocery', icon: ShoppingCart, label: 'Pantry' },
  { id: 'body', icon: Dumbbell, label: 'Body' },
  { id: 'profile', icon: User, label: 'Profile', fixed: 'right' }
];

function BottomNav({ tab, setTab }) {
  const scrollerRef = useRef(null);
  const [canLeft, setCanLeft] = useState(false);
  const [canRight, setCanRight] = useState(false);

  const home = NAV_TABS.find(t => t.fixed === 'left');
  const profile = NAV_TABS.find(t => t.fixed === 'right');
  const middle = NAV_TABS.filter(t => !t.fixed);

  // Auto-scroll active middle tab into view
  useEffect(() => {
    const el = scrollerRef.current?.querySelector(`[data-tab="${tab}"]`);
    if (el) el.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
  }, [tab]);

  // Track scroll-edge state so chevrons reflect available scope
  useEffect(() => {
    const sc = scrollerRef.current;
    if (!sc) return;
    const update = () => {
      const max = sc.scrollWidth - sc.clientWidth;
      setCanLeft(sc.scrollLeft > 1);
      setCanRight(sc.scrollLeft < max - 1);
    };
    update();
    sc.addEventListener('scroll', update, { passive: true });
    const ro = new ResizeObserver(update);
    ro.observe(sc);
    return () => {
      sc.removeEventListener('scroll', update);
      ro.disconnect();
    };
  }, []);

  const cellW = 'calc(100cqi / 5.5)';
  const maskLeft = canLeft ? '12%' : '0';
  const maskRight = canRight ? '88%' : '100%';

  return (
    <div
      className="absolute bottom-0 left-0 right-0 bg-zinc-950/95 backdrop-blur-xl border-t border-zinc-800/80 pb-3 pt-2"
      style={{ containerType: 'inline-size' }}
    >
      <div className="flex items-stretch">
        <NavCell item={home} active={tab === home.id} onClick={() => setTab(home.id)} width={cellW} />

        <div className="relative" style={{ width: `calc(100cqi * 3.5 / 5.5)` }}>
          <div
            ref={scrollerRef}
            className="flex overflow-x-auto scroll-smooth snap-x snap-mandatory"
            style={{
              scrollbarWidth: 'none',
              msOverflowStyle: 'none',
              maskImage: `linear-gradient(to right, transparent 0, black ${maskLeft}, black ${maskRight}, transparent 100%)`,
              WebkitMaskImage: `linear-gradient(to right, transparent 0, black ${maskLeft}, black ${maskRight}, transparent 100%)`
            }}
          >
            <style>{`.nav-scroller::-webkit-scrollbar{display:none}`}</style>
            {middle.map(it => (
              <div key={it.id} data-tab={it.id} className="flex-none snap-start" style={{ width: cellW }}>
                <NavCell item={it} active={tab === it.id} onClick={() => setTab(it.id)} width="100%" />
              </div>
            ))}
          </div>
          {canLeft && (
            <div className="pointer-events-none absolute left-0.5 top-1/2 -translate-y-1/2 flex items-center text-cyan-400/90">
              <ChevronLeft size={18} strokeWidth={2.5} />
            </div>
          )}
          {canRight && (
            <div className="pointer-events-none absolute right-0.5 top-1/2 -translate-y-1/2 flex items-center text-cyan-400/90">
              <ChevronRight size={18} strokeWidth={2.5} />
            </div>
          )}
        </div>

        <NavCell item={profile} active={tab === profile.id} onClick={() => setTab(profile.id)} width={cellW} />
      </div>
    </div>
  );
}

function NavCell({ item, active, onClick, width }) {
  const Icon = item.icon;
  return (
    <button
      onClick={onClick}
      className={`flex flex-col items-center justify-center gap-0.5 py-1.5 rounded-xl transition-colors ${active ? 'text-cyan-400' : 'text-zinc-500 hover:text-zinc-300'}`}
      style={{ width, flex: 'none' }}
    >
      <Icon size={20} strokeWidth={active ? 2.4 : 1.8} />
      <span className="text-[10px] font-medium">{item.label}</span>
    </button>
  );
}

/* ─── PROFILE ──────────────────────────────────────────── */
function ProfileScreen({ data, save, flash }) {
  const p = data.profile;

  const saveProfile = (patch) => {
    save({ ...data, profile: { ...p, ...patch } });
  };

  const setNotif = (patch) => {
    saveProfile({ notifications: { ...p.notifications, ...patch } });
  };

  const exportJson = () => {
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `tracker-backup-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    flash('Exported');
  };

  const resetAll = () => {
    if (!confirm('Reset everything to defaults? This cannot be undone.')) return;
    localStorage.removeItem('utracker:data:v1');
    location.reload();
  };

  return (
    <div className="px-5 pt-6 space-y-5">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Profile</h1>
        <p className="text-zinc-500 text-sm mt-0.5">Reminders · household · data</p>
      </div>

      <div className="rounded-2xl bg-zinc-900/60 ring-1 ring-zinc-800 p-4 flex items-center gap-3">
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-cyan-500/30 to-violet-500/30 ring-1 ring-zinc-700 flex items-center justify-center text-xl">
          👤
        </div>
        <div className="flex-1">
          <div className="text-sm font-semibold text-zinc-100">You</div>
          <div className="text-[11px] text-zinc-500">Timezone · {Intl.DateTimeFormat().resolvedOptions().timeZone}</div>
        </div>
      </div>

      {/* Killzone reminders */}
      <Section title="Killzone reminders">
        <div className="rounded-2xl bg-zinc-900/60 ring-1 ring-zinc-800 divide-y divide-zinc-800/60 overflow-hidden">
          <button
            onClick={() => setNotif({ master: !p.notifications.master })}
            className="w-full flex items-center gap-3 p-3.5 text-left hover:bg-zinc-900 transition"
          >
            <div className="flex-1">
              <div className="text-sm font-semibold text-zinc-100">All alerts</div>
              <div className="text-[11px] text-zinc-500">Master switch for every reminder</div>
            </div>
            <Toggle on={p.notifications.master} />
          </button>

          <div className={`p-4 ${p.notifications.master ? '' : 'opacity-40 pointer-events-none'}`}>
            <div className="text-[11px] uppercase tracking-wider text-zinc-500 mb-2">Default lead-time</div>
            <ChipGroup
              options={[5, 15, 30].map(m => ({ id: m, label: `${m} min` }))}
              value={p.notifications.leadTime}
              onChange={(v) => setNotif({ leadTime: v })}
            />
          </div>

          <div className={`p-4 ${p.notifications.master ? '' : 'opacity-40 pointer-events-none'}`}>
            <div className="text-[11px] uppercase tracking-wider text-zinc-500 mb-2">Quiet hours</div>
            <div className="flex items-center gap-2">
              <TimeInput value={p.notifications.quietStart} onChange={(v) => setNotif({ quietStart: v })} />
              <span className="text-zinc-500 text-xs">to</span>
              <TimeInput value={p.notifications.quietEnd} onChange={(v) => setNotif({ quietEnd: v })} />
            </div>
          </div>

          <div className={`p-4 ${p.notifications.master ? '' : 'opacity-40 pointer-events-none'}`}>
            <div className="text-[11px] uppercase tracking-wider text-zinc-500 mb-2">Browser notifications</div>
            <button
              onClick={async () => {
                const res = await ensureNotifPermission();
                setNotif({ browserPermission: res });
                flash(res === 'granted' ? 'Notifications enabled' : res === 'denied' ? 'Permission denied' : 'Not supported');
              }}
              className={`text-xs px-3 py-2 rounded-lg w-full font-medium transition ${p.notifications.browserPermission === 'granted' ? 'bg-emerald-500/15 text-emerald-300 ring-1 ring-emerald-500/30' : 'bg-cyan-500/15 text-cyan-300 ring-1 ring-cyan-500/30 hover:bg-cyan-500/25'}`}
            >
              {p.notifications.browserPermission === 'granted' ? '✓ Notifications enabled' : 'Enable browser notifications'}
            </button>
            <p className="text-[10px] text-zinc-500 mt-1.5 leading-relaxed">Fires lead-time alerts for killzones and brain-dump reminders, respecting quiet hours.</p>
          </div>
        </div>
      </Section>

      {/* Household */}
      <Section title="Household">
        <div className="rounded-2xl bg-zinc-900/60 ring-1 ring-zinc-800 p-4">
          <div className="text-sm font-semibold text-zinc-200 mb-2">Members</div>
          <div className="flex flex-wrap gap-1.5">
            {(data.groceries?.members || []).map(m => (
              <span key={m} className="text-[11px] px-2 py-1 rounded-full bg-zinc-800/60 text-zinc-300">{m}</span>
            ))}
          </div>
        </div>
      </Section>

      {/* Data */}
      <Section title="Data">
        <button onClick={exportJson} className="w-full rounded-2xl bg-zinc-900/60 ring-1 ring-zinc-800 p-4 text-left hover:bg-zinc-900 transition">
          <div className="text-sm font-semibold text-zinc-200">Export JSON</div>
          <div className="text-[11px] text-zinc-500 mt-0.5">Download a full backup of your data</div>
        </button>
        <button onClick={resetAll} className="w-full rounded-2xl bg-zinc-900/60 ring-1 ring-rose-900/40 p-4 text-left hover:bg-rose-950/30 transition">
          <div className="text-sm font-semibold text-rose-400">Reset to defaults</div>
          <div className="text-[11px] text-zinc-500 mt-0.5">Clears all local data</div>
        </button>
      </Section>

      <div className="text-center text-[10px] text-zinc-600 pt-2 pb-4">Tracker prototype · v0.2</div>
    </div>
  );
}

/* ─── PROFILE atoms ────────────────────────────────────── */
function Section({ title, right, children }) {
  return (
    <div>
      <div className="flex items-center justify-between mb-2 px-1">
        <div className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">{title}</div>
        {right}
      </div>
      <div className="space-y-2">{children}</div>
    </div>
  );
}

function Toggle({ on }) {
  return (
    <div className={`w-10 h-6 rounded-full transition relative flex-none ${on ? 'bg-cyan-500/80' : 'bg-zinc-700'}`}>
      <div className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-all ${on ? 'left-[18px]' : 'left-0.5'}`} />
    </div>
  );
}

function ChipGroup({ options, value, onChange }) {
  return (
    <div className="flex flex-wrap gap-1.5">
      {options.map(o => {
        const active = value === o.id;
        return (
          <button
            key={o.id}
            onClick={() => onChange(o.id)}
            className={`text-xs px-3 py-1.5 rounded-full transition ${active ? 'bg-cyan-500/20 text-cyan-300 ring-1 ring-cyan-500/40' : 'bg-zinc-800/60 text-zinc-400 hover:bg-zinc-800'}`}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

function TimeInput({ value, onChange }) {
  return (
    <input
      type="time"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="bg-zinc-800/60 rounded-lg px-3 py-1.5 text-sm text-zinc-200 ring-1 ring-zinc-700 focus:ring-cyan-500/60 focus:outline-none tabular-nums"
    />
  );
}

/* ─── MODAL ────────────────────────────────────────────── */
function Modal({ modal, data, save, close, flash }) {
  const [form, setForm] = useState(() => {
    // Preset values from modal.* (e.g. journal preset kz)
    const f = {};
    if (modal.presetKzId) f.kzId = modal.presetKzId;
    if (modal.presetAccountId) f.accountId = modal.presetAccountId;
    return f;
  });
  const [voiceRecording, setVoiceRecording] = useState(false);
  const [voiceInterim, setVoiceInterim] = useState('');
  const voiceRecognitionRef = useRef(null);

  useEffect(() => {
    return () => {
      if (voiceRecognitionRef.current) {
        try { voiceRecognitionRef.current.stop(); } catch {}
      }
    };
  }, []);

  const toggleVoiceCapture = () => {
    if (voiceRecording) {
      try { voiceRecognitionRef.current?.stop(); } catch {}
      setVoiceRecording(false);
      setVoiceInterim('');
      return;
    }
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR) {
      flash('Voice not supported in this browser');
      return;
    }
    try {
      const rec = new SR();
      rec.continuous = true;
      rec.interimResults = true;
      rec.lang = 'en-US';
      rec.onresult = (e) => {
        let finalText = '';
        let interimText = '';
        for (let i = e.resultIndex; i < e.results.length; i++) {
          const t = e.results[i][0].transcript;
          if (e.results[i].isFinal) finalText += t;
          else interimText += t;
        }
        if (finalText) {
          setForm(f => ({ ...f, text: ((f.text || '') + ' ' + finalText).trim() }));
        }
        setVoiceInterim(interimText);
      };
      rec.onerror = () => {
        setVoiceRecording(false);
        setVoiceInterim('');
      };
      rec.onend = () => {
        setVoiceRecording(false);
        setVoiceInterim('');
      };
      rec.start();
      voiceRecognitionRef.current = rec;
      setVoiceRecording(true);
    } catch (e) {
      flash('Could not start voice');
    }
  };

  const handle = async () => {
    let next = { ...data };
    if (modal.type === 'brain-add') {
      if (!form.text?.trim()) return;
      const tag = form.tag || autoTag(form.text);
      next.braindumps = [{ id: `b${Date.now()}`, type: 'text', text: form.text, createdAt: new Date().toISOString(), reminderAt: form.reminderAt || null, completed: false, tag }, ...data.braindumps];
      flash('Captured ✨');
    } else if (modal.type === 'sub-add') {
      if (!form.name?.trim() || !form.cost) return;
      next.subscriptions = [...data.subscriptions, { id: `s${Date.now()}`, name: form.name, cost: parseFloat(form.cost), cycle: 'monthly', nextRenewal: todayPlus(parseInt(form.days || 30)), type: form.type || 'subscription', category: form.category || 'Other', apiCap: form.type === 'api' ? parseFloat(form.cost) : undefined, apiUsed: 0, usedThisMonth: true, lastUsedReset: new Date().toISOString() }];
      flash('Subscription added');
    } else if (modal.type === 'grocery-add') {
      if (!form.name?.trim()) return;
      next.groceries = { ...data.groceries, list: [...data.groceries.list, { id: `g${Date.now()}`, name: form.name, qty: parseInt(form.qty || 1), category: form.category || 'Other', addedBy: 'You', completed: false, recurring: form.recurring ? 'weekly' : null }] };
      flash('Added to list');
    } else if (modal.type === 'pantry-add') {
      if (!form.name?.trim()) return;
      next.groceries = { ...data.groceries, pantry: [...data.groceries.pantry, { id: `p${Date.now()}`, name: form.name, qty: parseInt(form.qty || 1), lowThreshold: parseInt(form.lowThreshold || 1), unit: form.unit || 'unit' }] };
      flash('Pantry updated');
    } else if (modal.type === 'kz-add') {
      if (!form.name?.trim() || !form.start || !form.end) return;
      const [sh, sm] = form.start.split(':').map(Number);
      const [eh, em] = form.end.split(':').map(Number);
      next.killzones = [...data.killzones, { id: `kz${Date.now()}`, name: form.name, startMin: sh * 60 + sm, endMin: eh * 60 + em, color: form.color || 'amber', alertOn: true, alertBefore: 15, journal: [], checklist: ['HTF bias set', 'News checked', 'Risk defined'], skipUntil: null }];
      flash('Killzone added');
    } else if (modal.type === 'kz-journal') {
      if (!form.kzId || !form.note) return;
      next.killzones = data.killzones.map(k => k.id === form.kzId ? { ...k, journal: [{ id: `j${Date.now()}`, date: new Date().toISOString(), result: form.result || '—', note: form.note }, ...k.journal] } : k);
      flash('Logged');
    } else if (modal.type === 'trading-account') {
      if (!form.name?.trim() || form.balance === undefined || form.balance === '') return;
      next.trading = {
        ...(data.trading || { accounts: [], flows: [] }),
        accounts: [
          ...(data.trading?.accounts || []),
          { id: `acc${Date.now()}`, name: form.name, type: form.accType || 'broker', currency: form.currency || 'USD', balance: parseFloat(form.balance) }
        ]
      };
      flash('Account added');
    } else if (modal.type === 'trading-flow') {
      if (!form.accountId || !form.amount || !form.flowType) return;
      next.trading = {
        ...(data.trading || { accounts: [], flows: [] }),
        flows: [
          ...(data.trading?.flows || []),
          { id: `f${Date.now()}`, accountId: form.accountId, type: form.flowType, amount: parseFloat(form.amount), date: form.date || new Date().toISOString(), note: form.note || '' }
        ]
      };
      flash(form.flowType === 'deposit' ? 'Deposit logged' : 'Withdrawal logged');
    } else if (modal.type === 'meal-add') {
      if (!form.name?.trim()) return;
      const kcal = parseFloat(form.kcal || 0);
      const protein = parseFloat(form.protein || 0);
      const carbs = parseFloat(form.carbs || 0);
      const fat = parseFloat(form.fat || 0);
      const b = data.body || defaultData.body;
      next.body = {
        ...b,
        macros: {
          ...b.macros,
          calories: { ...b.macros.calories, used: b.macros.calories.used + kcal },
          protein: { ...b.macros.protein, used: b.macros.protein.used + protein },
          carbs: { ...(b.macros.carbs || { used: 0, goal: 280 }), used: (b.macros.carbs?.used || 0) + carbs },
          fat: { ...(b.macros.fat || { used: 0, goal: 80 }), used: (b.macros.fat?.used || 0) + fat }
        }
      };
      flash('Meal logged');
    }
    save(next);
    close();
  };

  const inputCls = "w-full bg-zinc-900 ring-1 ring-zinc-800 rounded-xl px-4 py-3 text-sm focus:ring-cyan-500 outline-none placeholder-zinc-600";

  return (
    <div className="absolute inset-0 z-40 flex items-end md:items-center justify-center bg-black/70 backdrop-blur-sm" onClick={close}>
      <div onClick={e => e.stopPropagation()} className="w-full bg-zinc-950 ring-1 ring-zinc-800 rounded-t-3xl md:rounded-3xl p-6 max-h-[85vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-5">
          <h3 className="text-lg font-bold">
            {modal.type === 'brain-add' && 'Brain dump'}
            {modal.type === 'sub-add' && 'New subscription'}
            {modal.type === 'grocery-add' && 'Add to list'}
            {modal.type === 'pantry-add' && 'Add to pantry'}
            {modal.type === 'kz-add' && 'New killzone'}
            {modal.type === 'kz-journal' && 'Journal entry'}
            {modal.type === 'trading-account' && 'New account'}
            {modal.type === 'trading-flow' && 'Deposit / Withdrawal'}
            {modal.type === 'meal-add' && 'Log a meal'}
          </h3>
          <button onClick={close} className="w-8 h-8 rounded-full bg-zinc-900 flex items-center justify-center text-zinc-400">
            <X size={16} />
          </button>
        </div>

        <div className="space-y-3">
          {modal.type === 'brain-add' && (
            <>
              <div className="relative">
                <textarea
                  autoFocus
                  placeholder={voiceRecording ? 'Listening… speak your thought' : "What's on your mind?"}
                  value={form.text || ''}
                  className={inputCls + ' min-h-[100px] resize-none pr-14'}
                  onChange={e => setForm({ ...form, text: e.target.value })}
                />
                <button
                  onClick={toggleVoiceCapture}
                  type="button"
                  className={`absolute bottom-3 right-3 w-10 h-10 rounded-full flex items-center justify-center transition shadow-lg ${voiceRecording ? 'bg-rose-500 ring-4 ring-rose-500/30 shadow-rose-900/50' : 'bg-violet-500 hover:bg-violet-400 shadow-violet-900/40'}`}
                  title={voiceRecording ? 'Stop' : 'Voice input'}
                >
                  {voiceRecording ? <div className="w-3 h-3 bg-white rounded-sm"></div> : <Mic size={16} className="text-white" />}
                </button>
              </div>
              {voiceRecording && (
                <div className="bg-rose-500/10 ring-1 ring-rose-500/30 rounded-xl p-3 flex items-center gap-2.5">
                  <div className="flex gap-0.5 items-end h-4">
                    {[0, 120, 240, 360, 180].map((d, i) => (
                      <div key={i} className="w-0.5 bg-rose-400 rounded-full animate-pulse" style={{ height: `${8 + (i % 3) * 4}px`, animationDelay: `${d}ms` }}></div>
                    ))}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-[10px] uppercase tracking-wider text-rose-300 font-semibold">Listening</div>
                    {voiceInterim ? (
                      <div className="text-xs text-zinc-300 italic truncate">{voiceInterim}</div>
                    ) : (
                      <div className="text-xs text-zinc-500">Tap mic to stop</div>
                    )}
                  </div>
                </div>
              )}
              <div className="flex gap-2 flex-wrap">
                {['personal', 'work', 'trading', 'idea'].map(t => (
                  <button key={t} onClick={() => setForm({ ...form, tag: t })} className={`text-xs px-3 py-1.5 rounded-full ${form.tag === t ? 'bg-violet-500 text-white' : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}>{t}</button>
                ))}
              </div>
              <div>
                <label className="text-[11px] uppercase tracking-wider text-zinc-500">Remind me</label>
                <div className="flex gap-2 mt-1.5 flex-wrap">
                  {[
                    { l: 'Later today', d: 0.25 },
                    { l: 'Tomorrow', d: 1 },
                    { l: 'Next week', d: 7 }
                  ].map(o => (
                    <button key={o.l} onClick={() => setForm({ ...form, reminderAt: todayPlus(o.d) })} className={`text-xs px-3 py-1.5 rounded-full ${form.reminderAt === todayPlus(o.d) ? 'bg-amber-500 text-zinc-900' : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}>
                      <Bell size={10} className="inline mr-1" />{o.l}
                    </button>
                  ))}
                </div>
              </div>
            </>
          )}

          {modal.type === 'sub-add' && (
            <>
              <input autoFocus placeholder="Name (e.g. Netflix)" className={inputCls} onChange={e => setForm({ ...form, name: e.target.value })} />
              <input type="number" step="0.01" placeholder="Monthly cost" className={inputCls} onChange={e => setForm({ ...form, cost: e.target.value })} />
              <div className="flex gap-2">
                {['subscription', 'api'].map(t => (
                  <button key={t} onClick={() => setForm({ ...form, type: t })} className={`flex-1 text-xs py-2.5 rounded-xl font-medium ${form.type === t ? 'bg-cyan-500 text-zinc-900' : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}>
                    {t === 'api' ? 'API / metered' : 'Flat subscription'}
                  </button>
                ))}
              </div>
              <input placeholder="Category" className={inputCls} onChange={e => setForm({ ...form, category: e.target.value })} />
              <input type="number" placeholder="Days until next renewal" className={inputCls} onChange={e => setForm({ ...form, days: e.target.value })} />
            </>
          )}

          {modal.type === 'grocery-add' && (
            <>
              <input autoFocus placeholder="Item (e.g. Milk)" className={inputCls} onChange={e => setForm({ ...form, name: e.target.value })} />
              <div className="flex gap-2">
                <input type="number" placeholder="Qty" defaultValue={1} className={inputCls + ' flex-1'} onChange={e => setForm({ ...form, qty: e.target.value })} />
                <input placeholder="Category" className={inputCls + ' flex-1'} onChange={e => setForm({ ...form, category: e.target.value })} />
              </div>
            </>
          )}

          {modal.type === 'pantry-add' && (
            <>
              <input autoFocus placeholder="Pantry item" className={inputCls} onChange={e => setForm({ ...form, name: e.target.value })} />
              <div className="flex gap-2">
                <input type="number" placeholder="Qty" defaultValue={1} className={inputCls + ' flex-1'} onChange={e => setForm({ ...form, qty: e.target.value })} />
                <input placeholder="Unit (bottle, kg…)" className={inputCls + ' flex-1'} onChange={e => setForm({ ...form, unit: e.target.value })} />
              </div>
              <input type="number" placeholder="Alert when at or below" defaultValue={1} className={inputCls} onChange={e => setForm({ ...form, lowThreshold: e.target.value })} />
            </>
          )}

          {modal.type === 'kz-add' && (
            <>
              <input autoFocus placeholder="Session name" className={inputCls} onChange={e => setForm({ ...form, name: e.target.value })} />
              <div className="flex gap-2">
                <input type="time" className={inputCls + ' flex-1'} onChange={e => setForm({ ...form, start: e.target.value })} />
                <input type="time" className={inputCls + ' flex-1'} onChange={e => setForm({ ...form, end: e.target.value })} />
              </div>
              <div className="flex gap-2">
                {Object.keys(KZ_COLORS).map(c => (
                  <button key={c} onClick={() => setForm({ ...form, color: c })} className={`flex-1 h-10 rounded-xl ${KZ_COLORS[c].solid} ${form.color === c ? 'ring-2 ring-white' : 'opacity-70'}`}></button>
                ))}
              </div>
            </>
          )}

          {modal.type === 'kz-journal' && (
            <>
              <div>
                <label className="text-[11px] uppercase tracking-wider text-zinc-500">Session</label>
                <div className="flex gap-1.5 mt-1.5 flex-wrap">
                  {data.killzones.map(kz => (
                    <button key={kz.id} onClick={() => setForm({ ...form, kzId: kz.id })} className={`text-xs px-3 py-1.5 rounded-full ${form.kzId === kz.id ? `${KZ_COLORS[kz.color].solid} text-zinc-900 font-medium` : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}>{kz.name}</button>
                  ))}
                </div>
              </div>
              <div>
                <label className="text-[11px] uppercase tracking-wider text-zinc-500">Result</label>
                <div className="flex gap-1.5 mt-1.5">
                  {['W', 'L', '—'].map(r => (
                    <button key={r} onClick={() => setForm({ ...form, result: r })} className={`flex-1 py-2.5 rounded-xl text-sm font-bold ${form.result === r ? (r === 'W' ? 'bg-emerald-500 text-zinc-900' : r === 'L' ? 'bg-rose-500 text-white' : 'bg-zinc-700 text-zinc-200') : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}>{r}</button>
                  ))}
                </div>
              </div>
              <textarea placeholder="Notes on the session…" className={inputCls + ' min-h-[80px] resize-none'} onChange={e => setForm({ ...form, note: e.target.value })} />
            </>
          )}

          {modal.type === 'trading-account' && (
            <>
              <input autoFocus placeholder="Account name (e.g. FTMO, Kraken)" className={inputCls} onChange={e => setForm({ ...form, name: e.target.value })} />
              <div className="flex gap-2">
                {['broker', 'wallet', 'prop'].map(t => (
                  <button key={t} onClick={() => setForm({ ...form, accType: t })} className={`flex-1 text-xs py-2.5 rounded-xl font-medium capitalize ${form.accType === t ? 'bg-cyan-500 text-zinc-900' : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}>
                    {t}
                  </button>
                ))}
              </div>
              <div className="flex gap-2">
                <input type="number" step="0.01" placeholder="Current balance" className={inputCls + ' flex-1'} onChange={e => setForm({ ...form, balance: e.target.value })} />
                <input placeholder="USD" defaultValue="USD" className={inputCls + ' w-20'} onChange={e => setForm({ ...form, currency: e.target.value })} />
              </div>
            </>
          )}

          {modal.type === 'trading-flow' && (
            <>
              <div>
                <label className="text-[11px] uppercase tracking-wider text-zinc-500">Account</label>
                <div className="flex gap-1.5 mt-1.5 flex-wrap">
                  {(data.trading?.accounts || []).map(a => (
                    <button key={a.id} onClick={() => setForm({ ...form, accountId: a.id })} className={`text-xs px-3 py-1.5 rounded-full ${form.accountId === a.id ? 'bg-cyan-500 text-zinc-900 font-medium' : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}>{a.name}</button>
                  ))}
                </div>
                {(data.trading?.accounts || []).length === 0 && (
                  <p className="text-[11px] text-zinc-500 mt-2">No accounts yet — add one first.</p>
                )}
              </div>
              <div>
                <label className="text-[11px] uppercase tracking-wider text-zinc-500">Type</label>
                <div className="flex gap-2 mt-1.5">
                  {[
                    { id: 'deposit', label: 'Deposit', cls: 'bg-emerald-500 text-zinc-900', icon: ArrowDownCircle },
                    { id: 'withdrawal', label: 'Withdrawal', cls: 'bg-rose-500 text-white', icon: ArrowUpCircle }
                  ].map(o => {
                    const Icon = o.icon;
                    return (
                      <button key={o.id} onClick={() => setForm({ ...form, flowType: o.id })} className={`flex-1 py-2.5 rounded-xl text-sm font-semibold flex items-center justify-center gap-1.5 ${form.flowType === o.id ? o.cls : 'bg-zinc-900 text-zinc-400 ring-1 ring-zinc-800'}`}>
                        <Icon size={14} /> {o.label}
                      </button>
                    );
                  })}
                </div>
              </div>
              <input type="number" step="0.01" placeholder="Amount" className={inputCls} onChange={e => setForm({ ...form, amount: e.target.value })} />
              <input type="date" defaultValue={new Date().toISOString().slice(0, 10)} className={inputCls} onChange={e => setForm({ ...form, date: new Date(e.target.value).toISOString() })} />
              <input placeholder="Note (optional)" className={inputCls} onChange={e => setForm({ ...form, note: e.target.value })} />
            </>
          )}

          {modal.type === 'meal-add' && (
            <>
              <input autoFocus placeholder="Meal (e.g. Chicken rice bowl)" className={inputCls} onChange={e => setForm({ ...form, name: e.target.value })} />
              <div className="grid grid-cols-2 gap-2">
                <input type="number" placeholder="Calories" className={inputCls} onChange={e => setForm({ ...form, kcal: e.target.value })} />
                <input type="number" placeholder="Protein (g)" className={inputCls} onChange={e => setForm({ ...form, protein: e.target.value })} />
                <input type="number" placeholder="Carbs (g)" className={inputCls} onChange={e => setForm({ ...form, carbs: e.target.value })} />
                <input type="number" placeholder="Fat (g)" className={inputCls} onChange={e => setForm({ ...form, fat: e.target.value })} />
              </div>
              <p className="text-[10px] text-zinc-500">Totals roll into today’s macros.</p>
            </>
          )}
        </div>

        <button onClick={handle} className="w-full mt-5 bg-cyan-500 hover:bg-cyan-400 text-zinc-900 font-semibold py-3 rounded-xl transition">
          Save
        </button>
      </div>
    </div>
  );
}
