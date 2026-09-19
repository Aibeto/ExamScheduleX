//! main.js - 区块索引: [state] [clock] [tone] [render] [banner] [fit] [splitter] [editor] [announce] [sync] [bridge] [notice] [boot]
import './style.css'

const FILE_NAME = 'schedule.json'
const K = {
  schedule: 'exsx.schedule', split: 'exsx.split', theme: 'exsx.theme', lock: 'exsx.lock',
  scale: 'exsx.scale', hideEn: 'exsx.hideEn', hideZh: 'exsx.hideZh', offset: 'exsx.offset',
}

// [state]
const state = {
  subjects: [], // {name, start:'YYYY-MM-DD HH:mm', end:...}
  announcement: { text: '', size: 100 }, // 左栏公告，随课表一起写入 json
  locked: false,
  theme: 'dark',
  hasActive: false,
  offsetMs: 0, // 时间校准偏移（本机设置）
  bannerShown: false,
}

// 状态标签的双语文案：勾选「隐藏中文」且科目进行中时用英文
const TAG_TEXT = {
  active: { zh: '进行中', en: 'LIVE' },
  next: { zh: '即将开始', en: 'NEXT' },
  past: { zh: '已结束', en: 'DONE' },
  idle: { zh: '待机', en: 'STANDBY' },
}

// 字号调节分组：fit 元素按比例调整上限/结果，固定组直接缩放
const SCALE_GROUPS = [
  { id: 'clock', label: '时钟' },
  { id: 'countdown', label: '倒计时' },
  { id: 'current-name', label: '当前科目名' },
  { id: 'subject-name', label: '列表科目名' },
  { id: 'subject-time', label: '列表时间' },
  { id: 'subject-duration', label: '列表时长' },
]
const sizes = (() => {
  try { return JSON.parse(localStorage.getItem(K.scale)) || {} } catch { return {} }
})()
// 公告字号存在 json 配置里，其余分组存在本机
const scaleOf = (group) => {
  if (group === 'announce') return state.announcement.size
  return sizes[group] == null ? 100 : sizes[group]
}

const $ = (id) => document.getElementById(id)
const el = {
  app: $('app'), clock: $('clock'), dateNum: $('date-num'), dateWeek: $('date-week'),
  card: { wrap: $('current-card'), name: $('current-name'), tag: $('current-tag'), range: $('current-range'), count: $('countdown'), progressWrap: $('current-progress-wrap'), progress: $('current-progress') },
  list: $('subject-list'), empty: $('list-empty'),
  splitter: $('splitter'),
  editor: { dialog: $('editor-dialog'), rows: $('editor-rows'), footer: $('editor-footer'), add: $('btn-add-row') },
  scaleRows: $('scale-rows'),
  sourceDialog: $('source-dialog'),
  notices: $('notice-stack'),
  optHideEn: $('opt-hide-en'), optHideZh: $('opt-hide-zh'),
  announce: $('announce'), announceText: $('announce-text'),
  announceInput: $('announce-input'), announceScale: $('announce-scale'),
  banner: $('banner'), bannerClose: $('btn-banner-close'),
  syncDate: $('sync-date'), syncTime: $('sync-time'), syncReadout: $('sync-readout'),
  btnSyncApply: $('btn-sync-apply'), btnSyncReset: $('btn-sync-reset'),
  btn: { theme: $('btn-theme'), edit: $('btn-edit'), lock: $('btn-lock'), lockIcon: $('btn-lock-icon') },
}

const LOCK_PATH = 'M12 2a5 5 0 0 0-5 5v3H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2h-1V7a5 5 0 0 0-5-5zm-3 8V7a3 3 0 1 1 6 0v3H9z'
const UNLOCK_PATH = 'M12 2a5 5 0 0 0-5 5v2h2V7a3 3 0 1 1 6 0v1h2V7a5 5 0 0 0-5-5zM6 11a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-7a2 2 0 0 0-2-2H6z'

const pad = (n) => String(n).padStart(2, '0')
const parseTime = (s) => (s ? new Date(s.replace(' ', 'T')) : null)
const isValidDate = (d) => d && !Number.isNaN(d.getTime())
const fmtDate = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
const fmtTime = (d) => `${pad(d.getHours())}:${pad(d.getMinutes())}`
const fmtRange = (s, e) => {
  if (!s || !e) return '--'
  const sameDay = s.slice(5, 10) === e.slice(5, 10)
  return `${s.slice(5, 10)} ${s.slice(11, 16)} ~ ${sameDay ? e.slice(11, 16) : `${e.slice(5, 10)} ${e.slice(11, 16)}`}`
}
const durationText = (s, e) => {
  const min = Math.round((e - s) / 60000)
  const h = Math.floor(min / 60), m = min % 60
  return h ? `${h}小时${m ? m + '分' : ''}` : `${m}分钟`
}
// 倒计时 HH:MM:SS，超过 24h 显示「X天 HH:MM:SS」
const fmtCountdown = (ms) => {
  if (ms <= 0) return '00:00:00'
  const t = Math.floor(ms / 1000), d = Math.floor(t / 86400)
  const hms = `${pad(Math.floor((t % 86400) / 3600))}:${pad(Math.floor((t % 3600) / 60))}:${pad(t % 60)}`
  return d ? `${d}天 ${hms}` : hms
}
const WEEK = ['日', '一', '二', '三', '四', '五', '六']

// [clock] 页面内部时间 = 系统时间 + 校准偏移
const nowMs = () => Date.now() + state.offsetMs
const nowDate = () => new Date(nowMs())

// [tone] 剩余时间百分比 → 页面信号色：充足(蓝) → 过半(琥珀) → 将尽(红)
const TONE_STOPS = [
  { at: 100, rgb: [74, 171, 234] },
  { at: 50, rgb: [241, 198, 68] },
  { at: 0, rgb: [227, 59, 59] },
]
function toneFor(remainPct) {
  const p = Math.min(100, Math.max(0, remainPct))
  const [a, b] = p >= 50 ? [TONE_STOPS[0], TONE_STOPS[1]] : [TONE_STOPS[1], TONE_STOPS[2]]
  const t = (p - a.at) / (b.at - a.at)
  const c = a.rgb.map((v, i) => Math.round(v + (b.rgb[i] - v) * t))
  return `rgb(${c.join(', ')})`
}

function applyTone(remainPct) {
  if (remainPct == null) document.documentElement.style.removeProperty('--app-tone')
  else document.documentElement.style.setProperty('--app-tone', toneFor(remainPct))
}

// [clock] 秒级刷新，无动画
function startClock() {
  const tick = () => {
    const now = nowDate()
    el.clock.textContent = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`
    el.dateNum.textContent = fmtDate(now)
    el.dateWeek.textContent = `星期${WEEK[now.getDay()]}`
    renderCurrent(now)
    markRows(now)
    if (el.editor.dialog.open) updateSyncReadout()
  }
  tick()
  const delay = 1000 - (nowMs() % 1000) + 20
  setTimeout(() => { tick(); setInterval(tick, 1000) }, delay)
}

// [render] 科目列表与当前科目
const rowRefs = []
function renderList() {
  el.list.replaceChildren()
  rowRefs.length = 0
  const sorted = [...state.subjects].sort((a, b) => a.start.localeCompare(b.start))
  for (const s of sorted) {
    const row = document.createElement('article')
    row.className = 'subject-row'
    row.setAttribute('role', 'listitem')
    // 科目名来自外部 JSON，用 textContent 防注入
    const nameNode = document.createElement('div')
    nameNode.className = 'subject-row__name fit'
    nameNode.dataset.fs = 'subject-name'
    nameNode.textContent = s.name
    nameNode.title = s.name
    const timeNode = document.createElement('div')
    timeNode.className = 'subject-row__time'
    timeNode.dataset.fs = 'subject-time'
    timeNode.textContent = fmtRange(s.start, s.end)
    // 左列合并为信息块，时长与状态各自成列，形成纵向对齐的数据栏
    const info = document.createElement('div')
    info.className = 'subject-row__info'
    info.append(nameNode, timeNode)
    const durationNode = document.createElement('span')
    durationNode.className = 'subject-row__duration'
    durationNode.dataset.fs = 'subject-duration'
    durationNode.textContent = durationText(parseTime(s.start), parseTime(s.end))
    const tagNode = document.createElement('span')
    tagNode.className = 'ak-tag subject-row__tag'
    tagNode.textContent = '—'
    row.append(info, durationNode, tagNode)
    el.list.appendChild(row)
    rowRefs.push({ row, s, name: nameNode, tag: tagNode })
  }
  el.empty.hidden = sorted.length > 0
  fitAll()
  markRows(nowDate())
}

// 语言遮罩：勾选且当前有进行中的科目时生效
function applyMask(activeNow) {
  document.body.classList.toggle('app-mask-en', el.optHideEn.checked && activeNow)
  document.body.classList.toggle('app-mask-zh', el.optHideZh.checked && activeNow)
}
const tagText = (key) => (document.body.classList.contains('app-mask-zh') ? TAG_TEXT[key].en : TAG_TEXT[key].zh)

function markRows(now) {
  for (const { row, s, tag } of rowRefs) {
    const st = parseTime(s.start), en = parseTime(s.end)
    row.classList.remove('subject-row--active', 'subject-row--next', 'subject-row--past')
    if (now >= en) { row.classList.add('subject-row--past'); tag.textContent = tagText('past') }
    else if (now >= st) { row.classList.add('subject-row--active'); tag.textContent = tagText('active') }
    else { row.classList.add('subject-row--next'); tag.textContent = tagText('next') }
  }
}

function renderCurrent(now) {
  const sorted = [...state.subjects].sort((a, b) => a.start.localeCompare(b.start))
  const active = sorted.find((s) => { const a = parseTime(s.start), b = parseTime(s.end); return isValidDate(a) && isValidDate(b) && now >= a && now < b })
  const next = sorted.find((s) => isValidDate(parseTime(s.start)) && parseTime(s.start) > now)
  const set = (name, tag, tagCls, range, count, pct) => {
    // 进度/倒计时每秒都变，签名只含低频字段，内容不变时跳过重渲染与文本适配
    const sig = `${name}|${tag}|${range}|${pct != null}`
    if (el.card.name.dataset.sig !== sig) {
      el.card.name.dataset.sig = sig
      el.card.name.textContent = name
      el.card.tag.textContent = tag
      el.card.tag.className = `ak-tag ${tagCls}`
      el.card.range.textContent = range
      el.card.progressWrap.hidden = pct == null
      fitAll()
    }
    // 结束时剩余不足 1 秒算出的百分位停留在 99.x%，四舍五入让进度条拉到 100%
    if (pct != null) el.card.progress.style.width = `${Math.min(100, Math.round(Math.max(0, pct)))}%`
    el.card.count.textContent = count
  }
  if (active) {
    const a = parseTime(active.start), b = parseTime(active.end)
    const remainPct = ((b - now) / (b - a)) * 100
    applyTone(remainPct)
    set(active.name, tagText('active'), 'ak-tag--advanced', fmtRange(active.start, active.end), fmtCountdown(b - now), 100 - remainPct)
  } else if (next) {
    applyTone(null)
    set(next.name, tagText('next'), '', fmtRange(next.start, next.end), fmtCountdown(parseTime(next.start) - now), null)
  } else if (sorted.length) {
    applyTone(null)
    set('已结束', tagText('past'), 'ak-tag--neutral', '--', '--:--:--', null)
    showBanner()
  } else {
    applyTone(null)
    set('等待数据', tagText('idle'), 'ak-tag--neutral', '--', '--:--:--', null)
  }
  state.hasActive = !!active
  applyMask(!!active)
}

// [banner] 全部结束后弹出一次完成横幅
function showBanner() {
  if (state.bannerShown) return
  state.bannerShown = true
  el.banner.hidden = false
}

function hideBanner() {
  el.banner.hidden = true
}

el.bannerClose.addEventListener('click', hideBanner)
el.banner.addEventListener('click', (e) => { if (e.target === el.banner) hideBanner() })
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !el.banner.hidden) hideBanner()
})

// [fit] 单行文本按容器宽度自适应字号（计算后 -1 防御）；受字号调节比例控制
function fitAll() {
  // 固定组（列表时间/时长）按比例直接缩放
  for (const node of document.querySelectorAll('[data-fs]:not(.fit)')) {
    const base = node.dataset.baseSize ??= parseFloat(getComputedStyle(node).fontSize)
    node.style.fontSize = `${(base * scaleOf(node.dataset.fs)) / 100}px`
  }
  // 收缩组：字号上限 = CSS 基准 × 比例，超宽时压缩
  for (const node of document.querySelectorAll('.fit[data-fs]')) {
    const base = node.dataset.baseSize ??= parseFloat(getComputedStyle(node).fontSize)
    const max = (base * scaleOf(node.dataset.fs)) / 100
    node.style.fontSize = '100px'
    const w = node.scrollWidth
    if (!w) { node.style.fontSize = ''; continue }
    const size = Math.max(10, Math.floor((100 * node.clientWidth) / w) - 1)
    node.style.fontSize = `${Math.min(max, size)}px`
  }
  // 时钟与倒计时始终撑满可用宽度
  for (const node of [el.clock, el.card.count]) {
    node.style.fontSize = '100px'
    const w = node.scrollWidth
    if (!w) { node.style.fontSize = ''; continue }
    node.style.fontSize = `${Math.max(10, (Math.floor((100 * node.clientWidth) / w) - 1) * scaleOf(node.dataset.fs) / 100)}px`
  }
}
new ResizeObserver(() => fitAll()).observe(document.body)

// [splitter] 分隔线拖拽
function initSplitter() {
  const saved = parseFloat(localStorage.getItem(K.split))
  if (!Number.isNaN(saved)) el.app.style.setProperty('--split', `${saved * 100}%`)
  let dragging = false
  el.splitter.addEventListener('pointerdown', (e) => {
    if (state.locked) return
    dragging = true
    el.splitter.classList.add('splitter--active')
    el.splitter.setPointerCapture(e.pointerId)
  })
  el.splitter.addEventListener('pointermove', (e) => {
    if (!dragging) return
    const rect = el.app.getBoundingClientRect()
    // 两侧最小宽度均为 40%（即分隔范围 40% ~ 60%）
    const pct = Math.min(0.6, Math.max(0.4, (e.clientX - rect.left) / rect.width))
    el.app.style.setProperty('--split', `${pct * 100}%`)
    fitAll()
  })
  const stop = () => {
    if (!dragging) return
    dragging = false
    el.splitter.classList.remove('splitter--active')
    const m = /([\d.]+)%/.exec(el.app.style.getPropertyValue('--split'))
    if (m) localStorage.setItem(K.split, String(parseFloat(m[1]) / 100))
  }
  el.splitter.addEventListener('pointerup', stop)
  el.splitter.addEventListener('pointercancel', stop)
}

// [notice]
function notice(code, title, variant = '') {
  const aside = document.createElement('aside')
  aside.className = `ak-notice ak-notice--enter ${variant}`.trim()
  aside.setAttribute('role', 'status')
  aside.innerHTML = `<span class="ak-notice__code">${code}</span>
    <div class="ak-notice__body"><strong class="ak-notice__title"></strong></div>`
  aside.querySelector('.ak-notice__title').textContent = title
  el.notices.appendChild(aside)
  setTimeout(() => aside.remove(), 3200)
}

// [bridge] 与 Flutter 宿主通信；浏览器环境下保存=下载
const inHost = typeof window.flutter_inappwebview !== 'undefined'

async function persist(json) {
  localStorage.setItem(K.schedule, json)
  if (inHost) {
    try { return !!(await window.flutter_inappwebview.callHandler('saveConfig', json)) }
    catch { return false }
  }
  const url = URL.createObjectURL(new Blob([json], { type: 'application/json' }))
  const a = document.createElement('a')
  a.href = url
  a.download = FILE_NAME
  a.click()
  setTimeout(() => URL.revokeObjectURL(url), 4000)
  return true
}

// 宿主启动时注入 exe 同目录的 schedule.json（可能为 null）
window.__hostProvideFileConfig = (json) => {
  const cached = localStorage.getItem(K.schedule)
  if (!json) return
  if (!cached) { applyConfig(json); return }
  if (json === cached) return
  el.sourceDialog.showModal()
  el.sourceDialog.addEventListener('close', () => {
    if (el.sourceDialog.returnValue === 'file') {
      applyConfig(json)
      localStorage.setItem(K.schedule, json)
      notice('DATA / SYNC', '已载入 schedule.json')
    }
  }, { once: true })
}

// 解析配置：兼容纯数组（旧格式）与 {subjects, announcement}
function normalize(json) {
  try {
    const data = JSON.parse(json)
    const list = Array.isArray(data) ? data : data.subjects
    if (!Array.isArray(list)) throw new Error('bad shape')
    const ann = (Array.isArray(data) ? null : data.announcement) || {}
    const size = Number(ann.size)
    return {
      subjects: list
        .filter((s) => s && s.name && isValidDate(parseTime(s.start)) && isValidDate(parseTime(s.end)))
        .map((s) => ({ name: String(s.name), start: s.start, end: s.end }))
        .sort((a, b) => a.start.localeCompare(b.start)),
      announcement: {
        text: typeof ann.text === 'string' ? ann.text : '',
        size: Number.isFinite(size) && size >= 50 && size <= 200 ? size : 100,
      },
    }
  } catch {
    notice('PRTS / ERR', '课表数据格式无效', 'ak-notice--danger')
    return null
  }
}

// 应用配置并重绘
function applyConfig(json) {
  const cfg = normalize(json)
  if (!cfg) return
  state.subjects = cfg.subjects
  state.announcement = cfg.announcement
  state.bannerShown = false
  applyAnnouncement()
  renderList()
}

// [editor] 图形化编辑科目列表
function openEditor() {
  el.editor.rows.replaceChildren()
  const sorted = [...state.subjects].sort((a, b) => a.start.localeCompare(b.start))
  for (const s of sorted) addEditorRow(s)
  if (!sorted.length) addEditorRow(null)
  el.announceInput.value = state.announcement.text
  buildTimeSync()
  el.editor.dialog.showModal()
}

function addEditorRow(s) {
  const row = document.createElement('div')
  row.className = 'editor-row'
  const name = s?.name ?? ''
  const startDate = s ? s.start.slice(0, 10) : fmtDate(new Date())
  const startTime = s ? s.start.slice(11, 16) : fmtTime(new Date(Date.now() + 3600e3))
  const endDate = s ? s.end.slice(0, 10) : fmtDate(new Date())
  const endTime = s ? s.end.slice(11, 16) : fmtTime(new Date(Date.now() + 9000e3))
  row.innerHTML = `
    <input class="ak-input editor-name" type="text" value="" placeholder="科目名" maxlength="40">
    <input class="ak-input" type="date">
    <input class="ak-input" type="time" step="60">
    <input class="ak-input" type="date">
    <input class="ak-input" type="time" step="60">
    <span class="subject-row__duration editor-duration">—</span>
    <span class="editor-actions">
      <button class="icon-btn" type="button" data-act="up" title="上移">↑</button>
      <button class="icon-btn" type="button" data-act="down" title="下移">↓</button>
      <button class="icon-btn" type="button" data-act="del" title="删除">✕</button>
    </span>`
  row.querySelector('.editor-name').value = name
  // 第一个 input 是科目名，日期时间从第二个开始
  const [, sd, st, ed, et] = row.querySelectorAll('input')
  sd.value = startDate
  st.value = startTime
  ed.value = endDate
  et.value = endTime
  const refresh = () => {
    const a = new Date(`${sd.value}T${st.value}`), b = new Date(`${ed.value}T${et.value}`)
    row.querySelector('.editor-duration').textContent =
      isValidDate(a) && isValidDate(b) && b > a ? durationText(a, b) : '—'
  }
  for (const input of [sd, st, ed, et]) input.addEventListener('change', refresh)
  row.addEventListener('click', (e) => {
    const act = e.target.closest('button')?.dataset.act
    if (!act) return
    if (act === 'del') row.remove()
    else if (act === 'up' && row.previousElementSibling) row.before(row.previousElementSibling)
    else if (act === 'down' && row.nextElementSibling) row.after(row.nextElementSibling)
  })
  refresh()
  el.editor.rows.appendChild(row)
}

el.editor.add.addEventListener('click', () => addEditorRow(null))

el.editor.footer.addEventListener('submit', (e) => {
  if (e.submitter?.value !== 'save') return
  const subjects = []
  for (const row of el.editor.rows.querySelectorAll('.editor-row')) {
    const inputs = row.querySelectorAll('input')
    const name = row.querySelector('.editor-name').value.trim()
    const [sd, st, ed, et] = [inputs[1], inputs[2], inputs[3], inputs[4]]
    const start = `${sd.value} ${st.value}`
    const end = `${ed.value} ${et.value}`
    if (!name) { notice('PRTS / ERR', '科目名不能为空', 'ak-notice--danger'); e.preventDefault(); return }
    const a = parseTime(start), b = parseTime(end)
    if (!isValidDate(a) || !isValidDate(b) || b <= a) {
      notice('PRTS / ERR', `「${name}」的结束时间需晚于开始时间`, 'ak-notice--danger')
      e.preventDefault()
      return
    }
    subjects.push({ name, start, end })
  }
  subjects.sort((a, b) => a.start.localeCompare(b.start))
  state.subjects = subjects
  state.announcement = { text: el.announceInput.value.replace(/\s+$/, ''), size: state.announcement.size }
  state.bannerShown = false
  applyAnnouncement()
  renderList()
  persist(JSON.stringify({ subjects, announcement: state.announcement }, null, 2)).then((ok) =>
    notice('RI / INFO', ok ? `已保存并写入 ${FILE_NAME}` : '保存失败', ok ? 'ak-notice--success' : 'ak-notice--danger'),
  )
})

// [announce] 左栏公告：内容与字号来自配置，允许主动换行
function applyAnnouncement() {
  const { text } = state.announcement
  el.announceText.textContent = text
  el.announce.hidden = !text.trim()
  fitAll()
}

function buildAnnounceScale() {
  const row = document.createElement('div')
  row.className = 'scale-row'
  row.innerHTML = `<span>公告字号</span>
    <input type="range" min="50" max="200" step="5">
    <span class="scale-value"></span>`
  const input = row.querySelector('input')
  const valueEl = row.querySelector('.scale-value')
  input.value = state.announcement.size
  valueEl.textContent = `${state.announcement.size}%`
  input.addEventListener('input', () => {
    state.announcement.size = Number(input.value)
    valueEl.textContent = `${input.value}%`
    fitAll()
  })
  el.announceScale.appendChild(row)
}

// [sync] 时间校准：偏移存本机，立即生效
function buildTimeSync() {
  const now = nowDate()
  el.syncDate.value = fmtDate(now)
  el.syncTime.value = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`
  updateSyncReadout()
}

function updateSyncReadout() {
  const s = Math.round(state.offsetMs / 1000)
  const now = nowDate()
  el.syncReadout.textContent =
    `当前内部时间 ${fmtDate(now)} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())} · 偏移 ${s > 0 ? '+' : ''}${s}s`
}

el.btnSyncApply.addEventListener('click', () => {
  const target = new Date(`${el.syncDate.value}T${el.syncTime.value}`)
  if (!el.syncDate.value || !el.syncTime.value || !isValidDate(target)) {
    notice('PRTS / ERR', '校准时间无效', 'ak-notice--danger')
    return
  }
  state.offsetMs = target.getTime() - Date.now()
  localStorage.setItem(K.offset, String(state.offsetMs))
  updateSyncReadout()
  const s = Math.round(state.offsetMs / 1000)
  notice('RI / INFO', `已校准 ${s > 0 ? '+' : ''}${s}s`, 'ak-notice--success')
})

el.btnSyncReset.addEventListener('click', () => {
  state.offsetMs = 0
  localStorage.setItem(K.offset, '0')
  buildTimeSync()
  notice('RI / INFO', '已重置为系统时间')
})

// [boot]
function applyTheme(t) {
  state.theme = t
  document.documentElement.dataset.theme = t
  el.btn.theme.title = t === 'dark' ? '切换亮色主题' : '切换暗色主题'
  localStorage.setItem(K.theme, t)
}

function applyLock(v) {
  state.locked = v
  document.body.classList.toggle('app--locked', v)
  el.btn.lockIcon.setAttribute('d', v ? UNLOCK_PATH : LOCK_PATH)
  el.btn.lock.title = v ? '解锁界面' : '锁定界面'
  localStorage.setItem(K.lock, v ? '1' : '0')
}

el.btn.theme.addEventListener('click', () => applyTheme(state.theme === 'dark' ? 'light' : 'dark'))
el.btn.edit.addEventListener('click', openEditor)
el.btn.lock.addEventListener('click', () => applyLock(!state.locked))
el.splitter.addEventListener('dblclick', () => {
  if (state.locked) return
  el.app.style.setProperty('--split', '58%')
  localStorage.setItem(K.split, '0.58')
  fitAll()
})

function boot() {
  state.offsetMs = Number(localStorage.getItem(K.offset)) || 0
  const saved = localStorage.getItem(K.schedule)
  if (saved) applyConfig(saved)
  applyTheme(localStorage.getItem(K.theme) === 'light' ? 'light' : 'dark')
  applyLock(localStorage.getItem(K.lock) === '1')
  initSplitter()
  initLangOpts()
  buildScaleRows()
  buildAnnounceScale()
  applyAnnouncement()
  renderList()
  startClock()
}

// 语言隐藏选项：勾选即时生效（是否遮蔽取决于当前是否有进行中的科目）
function initLangOpts() {
  el.optHideEn.checked = localStorage.getItem(K.hideEn) === '1'
  el.optHideZh.checked = localStorage.getItem(K.hideZh) === '1'
  el.optHideEn.addEventListener('change', () => {
    localStorage.setItem(K.hideEn, el.optHideEn.checked ? '1' : '0')
    applyMask(state.hasActive)
  })
  el.optHideZh.addEventListener('change', () => {
    localStorage.setItem(K.hideZh, el.optHideZh.checked ? '1' : '0')
    applyMask(state.hasActive)
    renderList()
  })
}

// 编辑器内的字号调节：拖动滑块实时生效并持久化（50% ~ 200%）
function buildScaleRows() {
  for (const { id, label } of SCALE_GROUPS) {
    const row = document.createElement('div')
    row.className = 'scale-row'
    row.innerHTML = `<span>${label}</span>
      <input type="range" min="50" max="200" step="5">
      <span class="scale-value"></span>`
    const input = row.querySelector('input')
    const valueEl = row.querySelector('.scale-value')
    input.value = scaleOf(id)
    valueEl.textContent = `${scaleOf(id)}%`
    input.addEventListener('input', () => {
      sizes[id] = Number(input.value)
      valueEl.textContent = `${input.value}%`
      localStorage.setItem(K.scale, JSON.stringify(sizes))
      fitAll()
    })
    el.scaleRows.appendChild(row)
  }
}

boot()
