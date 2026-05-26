import { useState, useEffect, useRef } from 'react';
import {
  Home, TrendingUp, CreditCard, Brain, ShoppingCart,
  Plus, Bell, BellOff, Clock, ChevronRight, X, Check, Mic, Video,
  Calendar, AlertCircle, Zap, Users, Trash2,
  Settings, Activity, Sparkles, Package,
  ArrowRight, Coffee, Sun, Moon as MoonIcon, Flame,
  TrendingDown, Wallet, BookOpen, MapPin, Repeat,
  Camera, ChevronDown, ChevronUp, FileText, ListChecks, Loader2,
  Dumbbell, Apple, Droplet
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
    { id: 'kz1', name: 'Asian', startMin: 19 * 60, endMin: 21 * 60 + 30, color: 'amber', alertOn: true, alertBefore: 15, journal: [] },
    { id: 'kz2', name: 'London', startMin: 2 * 60, endMin: 5 * 60, color: 'sky', alertOn: true, alertBefore: 15, journal: [] },
    { id: 'kz3', name: 'NY AM', startMin: 8 * 60 + 30, endMin: 11 * 60, color: 'rose', alertOn: true, alertBefore: 30, journal: [{ id: 'j1', date: todayPlus(-1), result: 'W', note: 'OB sweep, clean retest' }] },
    { id: 'kz4', name: 'London Close', startMin: 10 * 60, endMin: 12 * 60, color: 'violet', alertOn: false, alertBefore: 15, journal: [] },
    { id: 'kz5', name: 'NY PM', startMin: 13 * 60 + 30, endMin: 16 * 60, color: 'emerald', alertOn: true, alertBefore: 15, journal: [] }
  ],
  subscriptions: [
    { id: 's1', name: 'Anthropic API', cost: 200, cycle: 'monthly', nextRenewal: todayPlus(8), type: 'api', apiCap: 200, apiUsed: 142, category: 'AI', startedAt: todayPlus(-22) },
    { id: 's2', name: 'OpenAI API', cost: 50, cycle: 'monthly', nextRenewal: todayPlus(14), type: 'api', apiCap: 50, apiUsed: 18, category: 'AI', startedAt: todayPlus(-16) },
    { id: 's3', name: 'Netflix', cost: 15.49, cycle: 'monthly', nextRenewal: todayPlus(3), type: 'subscription', category: 'Entertainment' },
    { id: 's4', name: 'Notion', cost: 10, cycle: 'monthly', nextRenewal: todayPlus(21), type: 'subscription', category: 'Productivity' },
    { id: 's5', name: 'TradingView', cost: 59.95, cycle: 'monthly', nextRenewal: todayPlus(1), type: 'subscription', category: 'Trading' }
  ],
  braindumps: [
    { id: 'b1', type: 'text', text: 'Call mom Sunday morning', createdAt: todayPlus(-1), reminderAt: todayPlus(2), completed: false, tag: 'personal' },
    { id: 'b2', type: 'text', text: 'Review NY AM trades from last week', createdAt: todayPlus(-1), reminderAt: null, completed: false, tag: 'trading' },
    { id: 'b3', type: 'text', text: 'Idea: tracker app with widget for killzones', createdAt: todayPlus(-2), reminderAt: null, completed: true, tag: 'idea' }
  ],
  groceries: {
    list: [
      { id: 'g1', name: 'Eggs', qty: 12, category: 'Dairy', addedBy: 'You', completed: false },
      { id: 'g2', name: 'Sourdough bread', qty: 1, category: 'Bakery', addedBy: 'Sam', completed: false },
      { id: 'g3', name: 'Olive oil', qty: 1, category: 'Pantry', addedBy: 'You', completed: false },
      { id: 'g4', name: 'Avocados', qty: 4, category: 'Produce', addedBy: 'Alex', completed: true }
    ],
    pantry: [
      { id: 'p1', name: 'Olive oil', qty: 0, lowThreshold: 1, unit: 'bottle' },
      { id: 'p2', name: 'Rice', qty: 2, lowThreshold: 1, unit: 'kg' },
      { id: 'p3', name: 'Coffee beans', qty: 1, lowThreshold: 1, unit: 'bag' },
      { id: 'p4', name: 'Pasta', qty: 4, lowThreshold: 2, unit: 'box' }
    ],
    members: ['You', 'Sam', 'Alex']
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

  useEffect(() => {
    (async () => {
      try {
        const r = await window.storage.get(STORE_KEY);
        if (r && r.value) {
          setData(JSON.parse(r.value));
        } else {
          setData(defaultData);
          await window.storage.set(STORE_KEY, JSON.stringify(defaultData));
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

  const save = async (next) => {
    setData(next);
    try { await window.storage.set(STORE_KEY, JSON.stringify(next)); } catch {}
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
        </div>

        <div className="absolute bottom-0 left-0 right-0 bg-zinc-950/95 backdrop-blur-xl border-t border-zinc-800/80 px-2 py-2 pb-3">
          <div className="flex justify-around items-center">
            {[
              { id: 'home', icon: Home, label: 'Home' },
              { id: 'killzone', icon: TrendingUp, label: 'Trading' },
              { id: 'subs', icon: CreditCard, label: 'Spend' },
              { id: 'brain', icon: Brain, label: 'Capture' },
              { id: 'grocery', icon: ShoppingCart, label: 'Pantry' },
              { id: 'body', icon: Dumbbell, label: 'Body' }
            ].map((it) => {
              const active = tab === it.id;
              const Icon = it.icon;
              return (
                <button
                  key={it.id}
                  onClick={() => setTab(it.id)}
                  className={`flex flex-col items-center gap-0.5 py-1.5 px-3 rounded-xl transition-all ${active ? 'text-cyan-400' : 'text-zinc-500 hover:text-zinc-300'}`}
                >
                  <Icon size={20} strokeWidth={active ? 2.4 : 1.8} />
                  <span className="text-[10px] font-medium">{it.label}</span>
                </button>
              );
            })}
          </div>
        </div>

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
          <div className="text-xl font-bold">12 <span className="text-xs font-medium text-zinc-500">days</span></div>
          <div className="text-[11px] text-zinc-500 mt-1.5">Macros on track</div>
        </button>

        <button onClick={() => setTab('body')} className="text-left rounded-2xl bg-zinc-900/80 ring-1 ring-zinc-800 p-4 hover:bg-zinc-900 transition">
          <div className="flex items-center gap-1.5 mb-2">
            <Dumbbell size={12} className="text-cyan-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">Body</span>
          </div>
          <div className="text-xl font-bold">1840 <span className="text-xs font-medium text-zinc-500">/ 2400</span></div>
          <div className="text-[11px] text-zinc-500 mt-1.5">Push Day · 6:30 PM</div>
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

  const toggleAlert = (id) => {
    const next = { ...data, killzones: data.killzones.map(k => k.id === id ? { ...k, alertOn: !k.alertOn } : k) };
    save(next);
    flash('Alert updated');
  };

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
          return (
            <div key={kz.id} className={`rounded-2xl p-4 ring-1 transition ${isActive ? `${c.bg} ${c.ring} ring-2` : 'bg-zinc-900/60 ring-zinc-800'} ${isPast && !isActive ? 'opacity-50' : ''}`}>
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <div className={`w-2 h-2 rounded-full ${c.dot} ${isActive ? 'animate-pulse' : ''}`}></div>
                    <span className={`text-sm font-semibold ${isActive ? c.text : 'text-zinc-200'}`}>{kz.name}</span>
                    {isActive && <span className={`text-[10px] font-bold uppercase ${c.text} px-1.5 py-0.5 rounded ${c.bg}`}>Live</span>}
                  </div>
                  <div className="text-zinc-500 text-xs tabular-nums">
                    {fmtTime(kz.startMin)} – {fmtTime(kz.endMin)}
                  </div>
                  {!isActive && !isPast && (
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
                <div className="mt-3 flex items-center gap-2">
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
                </div>
              )}
            </div>
          );
        })}
      </div>

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

/* ─── SUBSCRIPTIONS ─────────────────────────────────────── */
function SubsScreen({ data, save, setModal, flash }) {
  const monthly = data.subscriptions.reduce((s, x) => s + x.cost, 0);
  const apis = data.subscriptions.filter(s => s.type === 'api');
  const subs = data.subscriptions.filter(s => s.type === 'subscription');

  const remove = (id) => {
    save({ ...data, subscriptions: data.subscriptions.filter(s => s.id !== id) });
    flash('Removed');
  };

  return (
    <div className="px-5 pt-6">
      <div className="flex items-center justify-between mb-1">
        <h1 className="text-2xl font-bold tracking-tight">Spend</h1>
        <button onClick={() => setModal({ type: 'sub-add' })} className="w-9 h-9 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-300 hover:bg-zinc-800">
          <Plus size={16} />
        </button>
      </div>
      <p className="text-zinc-500 text-sm mb-5">Subscriptions & API burn</p>

      <div className="rounded-2xl bg-gradient-to-br from-rose-600/30 via-rose-500/10 to-transparent ring-1 ring-rose-500/20 p-5 mb-5">
        <div className="text-xs font-semibold uppercase tracking-wider text-rose-300 mb-1">Monthly total</div>
        <div className="text-3xl font-bold tabular-nums">${monthly.toFixed(2)}</div>
        <div className="text-zinc-400 text-xs mt-1">{data.subscriptions.length} active · {apis.length} API</div>
      </div>

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
            return (
              <div key={s.id} className="rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 p-3.5 flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-0.5">
                    <span className="font-medium text-sm">{s.name}</span>
                    {d <= 3 && <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-400">{d === 0 ? 'TODAY' : d === 1 ? 'TOMORROW' : `${d}D`}</span>}
                  </div>
                  <div className="text-[11px] text-zinc-500">{s.category} · monthly</div>
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

function BrainItem({ item, expanded, onToggleExpand, onToggle, onRemove }) {
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
          <div className="space-y-2 mb-5">
            {pending.map(g => (
              <div key={g.id} className="rounded-xl bg-zinc-900/60 ring-1 ring-zinc-800 p-3.5 flex items-center gap-3">
                <button onClick={() => toggleItem(g.id)} className="w-5 h-5 rounded-full ring-1 ring-zinc-600 hover:ring-emerald-400 transition flex-shrink-0"></button>
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-medium">{g.name}</div>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="text-[10px] text-zinc-500">×{g.qty} · {g.category}</span>
                    <span className={`text-[10px] px-1.5 py-0.5 rounded ${memberColor(g.addedBy)}`}>{g.addedBy}</span>
                  </div>
                </div>
                <button onClick={() => removeItem(g.id)} className="text-zinc-600 hover:text-rose-400">
                  <Trash2 size={13} />
                </button>
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
            return (
              <div key={p.id} className={`rounded-xl ring-1 p-3.5 flex items-center justify-between ${low ? 'bg-amber-500/5 ring-amber-500/20' : 'bg-zinc-900/60 ring-zinc-800'}`}>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">{p.name}</span>
                    {low && <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-400">{p.qty === 0 ? 'OUT' : 'LOW'}</span>}
                  </div>
                  <div className="text-[11px] text-zinc-500 mt-0.5 tabular-nums">{p.qty} {p.unit} · alert at {p.lowThreshold}</div>
                </div>
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
  // Sample data — wire into `data.body` later
  const macros = { calories: { used: 1840, goal: 2400 }, protein: { used: 142, goal: 180 }, water: { used: 6, goal: 10 } };
  const streak = 12;
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

  const calPct = Math.round((macros.calories.used / macros.calories.goal) * 100);
  const proPct = Math.round((macros.protein.used / macros.protein.goal) * 100);
  const waterPct = Math.round((macros.water.used / macros.water.goal) * 100);

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

      {/* Streak banner */}
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
          <TrendingUp size={18} className="text-orange-400" />
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

      {/* Macro stats grid */}
      <div className="grid grid-cols-3 gap-3 mb-4">
        <MacroCard icon={Flame} iconColor="text-orange-400" label="Calories" used={macros.calories.used} goal={macros.calories.goal} unit="kcal" pct={calPct} barColor="bg-orange-400" />
        <MacroCard icon={Activity} iconColor="text-emerald-400" label="Protein" used={macros.protein.used} goal={macros.protein.goal} unit="g" pct={proPct} barColor="bg-emerald-400" />
        <MacroCard icon={Droplet} iconColor="text-sky-400" label="Water" used={macros.water.used} goal={macros.water.goal} unit="cups" pct={waterPct} barColor="bg-sky-400" />
      </div>

      {/* Quick log */}
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

/* ─── MODAL ────────────────────────────────────────────── */
function Modal({ modal, data, save, close, flash }) {
  const [form, setForm] = useState({});
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
      next.braindumps = [{ id: `b${Date.now()}`, type: 'text', text: form.text, createdAt: new Date().toISOString(), reminderAt: form.reminderAt || null, completed: false, tag: form.tag || null }, ...data.braindumps];
      flash('Captured ✨');
    } else if (modal.type === 'sub-add') {
      if (!form.name?.trim() || !form.cost) return;
      next.subscriptions = [...data.subscriptions, { id: `s${Date.now()}`, name: form.name, cost: parseFloat(form.cost), cycle: 'monthly', nextRenewal: todayPlus(parseInt(form.days || 30)), type: form.type || 'subscription', category: form.category || 'Other', apiCap: form.type === 'api' ? parseFloat(form.cost) : undefined, apiUsed: 0 }];
      flash('Subscription added');
    } else if (modal.type === 'grocery-add') {
      if (!form.name?.trim()) return;
      next.groceries = { ...data.groceries, list: [...data.groceries.list, { id: `g${Date.now()}`, name: form.name, qty: parseInt(form.qty || 1), category: form.category || 'Other', addedBy: 'You', completed: false }] };
      flash('Added to list');
    } else if (modal.type === 'pantry-add') {
      if (!form.name?.trim()) return;
      next.groceries = { ...data.groceries, pantry: [...data.groceries.pantry, { id: `p${Date.now()}`, name: form.name, qty: parseInt(form.qty || 1), lowThreshold: parseInt(form.lowThreshold || 1), unit: form.unit || 'unit' }] };
      flash('Pantry updated');
    } else if (modal.type === 'kz-add') {
      if (!form.name?.trim() || !form.start || !form.end) return;
      const [sh, sm] = form.start.split(':').map(Number);
      const [eh, em] = form.end.split(':').map(Number);
      next.killzones = [...data.killzones, { id: `kz${Date.now()}`, name: form.name, startMin: sh * 60 + sm, endMin: eh * 60 + em, color: form.color || 'amber', alertOn: true, alertBefore: 15, journal: [] }];
      flash('Killzone added');
    } else if (modal.type === 'kz-journal') {
      if (!form.kzId || !form.note) return;
      next.killzones = data.killzones.map(k => k.id === form.kzId ? { ...k, journal: [{ id: `j${Date.now()}`, date: new Date().toISOString(), result: form.result || '—', note: form.note }, ...k.journal] } : k);
      flash('Logged');
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
        </div>

        <button onClick={handle} className="w-full mt-5 bg-cyan-500 hover:bg-cyan-400 text-zinc-900 font-semibold py-3 rounded-xl transition">
          Save
        </button>
      </div>
    </div>
  );
}
