const { chromium } = require('playwright');

async function launch() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text());
  });
  page.on('pageerror', err => errors.push('PAGEERROR: ' + err.message));
  return { browser, page, errors };
}

async function gotoApp(page) {
  await page.goto('http://localhost:8766/', { waitUntil: 'load', timeout: 60000 });
  await page.waitForSelector('flutter-view, canvas', { timeout: 60000 });
  await page.waitForTimeout(2000);
  await enableSemantics(page);
}

// Flutter web only builds an accessible DOM (flt-semantics-host) after the
// semantics placeholder receives a click; it's a 1x1 off-screen element so
// it needs dispatchEvent rather than a real mouse click.
async function enableSemantics(page) {
  const ph = await page.$('flt-semantics-placeholder');
  if (ph) {
    await ph.dispatchEvent('click');
    await page.waitForTimeout(500);
  }
}

async function login(page, email, password) {
  await page.getByLabel('Email address').fill(email);
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'LOGIN', exact: true }).click();
  await page.waitForTimeout(3000);
  await enableSemantics(page);
}

// Dump the semantics tree as readable text (role + label/text per node)
async function dumpSemantics(page) {
  return await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics, input[data-semantics-role]').forEach(el => {
      const role = el.getAttribute('role') || el.getAttribute('data-semantics-role') || '';
      const label = el.getAttribute('aria-label') || '';
      const text = el.childNodes.length && el.children.length === 0 ? el.textContent.trim() : '';
      if (role || label || text) out.push({ role, label, text });
    });
    return out;
  });
}

module.exports = { launch, gotoApp, login, enableSemantics, dumpSemantics };
