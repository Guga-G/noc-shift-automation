(() => {
  'use strict';

  const SITES = {
    '192.0.2.11':      { name: 'PRTG-SITE-A',      user: 'prtg-viewer',  pass: 'REPLACE_ME', start: '/group.htm?id=0&tabid=1' },
    '192.0.2.12':      { name: 'PRTG-SITE-B',      user: 'prtg-viewer',  pass: 'REPLACE_ME', start: '/group.htm?id=0&tabid=1' },
    '192.0.2.13':      { name: 'PRTG-SITE-C',      user: 'prtg-noc',     pass: 'REPLACE_ME', start: '/group.htm?id=0&tabid=1' },
    '198.51.100.21':   { name: 'Billing Portal 1', user: 'portal-user',  pass: 'REPLACE_ME' },
    '198.51.100.22':   { name: 'Billing Portal 1b',user: 'portal-user',  pass: 'REPLACE_ME' },
    '198.51.100.23':   { name: 'Billing Portal 2', user: 'portal-user',  pass: 'REPLACE_ME' },
    'mail.example.com':{ name: 'Webmail',          user: 'portal-user',  pass: 'REPLACE_ME' }
  };

  const site = SITES[location.hostname];
  if (!site) return;

  const TAG = '[dash-login]';
  const log = (...a) => console.log(TAG, site.name + ':', ...a);

  const MAX_ATTEMPTS = 3;
  const KEY = 'dashLoginAttempts';
  const attempts = () => parseInt(sessionStorage.getItem(KEY) || '0', 10);
  const bump = () => sessionStorage.setItem(KEY, String(attempts() + 1));
  const reset = () => sessionStorage.removeItem(KEY);

  const qs = new URLSearchParams(location.search);

  if (qs.has('logout')) {
    log('logged out by hand, giving the attempt budget back');
    reset();
  }

  const back = qs.get('loginurl') || '';
  if (/logout/i.test(back)) {
    log('login page would send me back to ' + back + ' after login; dropping that');
    reset();
    qs.delete('loginurl');
    const q = qs.toString();
    location.replace(location.pathname + (q ? '?' + q : ''));
    return;
  }

  let done = false;

  const visible = (el) => {
    if (!el) return false;
    const s = getComputedStyle(el);
    if (s.display === 'none' || s.visibility === 'hidden' || s.opacity === '0') return false;
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  };

  const nativeSet = (el, value) => {
    const proto = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
    Object.getOwnPropertyDescriptor(proto, 'value').set.call(el, value);
    el.dispatchEvent(new Event('input',  { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  };

  const findPassword = () =>
    [...document.querySelectorAll('input[type="password"]')].find(visible) || null;

  const findUsername = (pw) => {
    const cands = [...document.querySelectorAll(
      'input[type="text"], input[type="email"], input[type="tel"], input:not([type])')].filter(visible);
    if (!cands.length) return null;
    const hint = /user|login|email|uname|account|j_username/i;
    const hinted = cands.find(i =>
      hint.test([i.name, i.id, i.autocomplete, i.placeholder].join(' ')));
    if (hinted) return hinted;
    if (pw) {
      const before = cands.filter(i => i.compareDocumentPosition(pw) & Node.DOCUMENT_POSITION_FOLLOWING);
      if (before.length) return before[before.length - 1];
    }
    return cands[0];
  };

  const findSubmit = (scope) => {
    const root = scope || document;
    let b = [...root.querySelectorAll('button[type="submit"], input[type="submit"]')].find(visible);
    if (b) return b;
    const re = /log ?in|sign ?in|log ?on|submit|enter|შესვლა/i;
    return [...root.querySelectorAll('button, input[type="button"], a[role="button"]')]
      .filter(visible).find(b2 => re.test([b2.value, b2.textContent].join(' '))) || null;
  };

  const submit = (pw, form) => {
    const btn = findSubmit(form);
    if (btn) { log('submit via button'); btn.click(); return; }
    if (form && form.requestSubmit) { log('submit via requestSubmit'); form.requestSubmit(); return; }
    if (form) { log('submit via form.submit'); form.submit(); return; }
    log('submit via Enter key');
    ['keydown', 'keypress', 'keyup'].forEach(t =>
      pw.dispatchEvent(new KeyboardEvent(t, { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true })));
  };

  const tryLogin = () => {
    if (done) return true;
    const pw = findPassword();
    if (!pw) return false;

    if (attempts() >= MAX_ATTEMPTS) { log('max attempts reached, standing down'); return (done = true); }
    const form = pw.form || pw.closest('form');

    const user = findUsername(pw);
    if (!user) { log('username field not found yet'); return false; }
    bump(); log('filling credentials + submitting');
    nativeSet(user, site.user);
    nativeSet(pw, site.pass);

    if (site.start) {
      const ret = form && form.querySelector('input[name="loginurl"]');
      if (ret && !ret.value) {
        ret.value = site.start;
        log('no return page on this login, pointing it at my start page ' + site.start);
      }
    }

    submit(pw, form);
    return (done = true);
  };

  if (tryLogin()) return;

  const obs = new MutationObserver(() => { if (tryLogin()) cleanup(); });
  obs.observe(document.documentElement, { childList: true, subtree: true });
  const poll = setInterval(() => { if (tryLogin()) cleanup(); }, 500);
  const timer = setTimeout(() => {
    reset();
    log('no login form within 20s (already logged in?), attempt budget reset');
    cleanup();
  }, 20000);

  function cleanup() { obs.disconnect(); clearInterval(poll); clearTimeout(timer); }
})();
