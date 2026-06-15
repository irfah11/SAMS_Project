const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text());
  });
  page.on('pageerror', err => errors.push('PAGEERROR: ' + err.message));

  console.log('Navigating...');
  await page.goto('http://localhost:8766/', { waitUntil: 'load', timeout: 60000 });

  // Wait for flutter app to bootstrap (canvaskit / semantics placeholder)
  console.log('Waiting for flt-semantics-placeholder or canvas...');
  await page.waitForSelector('flt-semantics-placeholder, flutter-view, canvas', { timeout: 60000 });

  await page.waitForTimeout(3000);

  await page.screenshot({ path: 'tmp_pw/01_initial.png', fullPage: true });
  console.log('Screenshot saved: 01_initial.png');

  // Try enabling semantics by clicking the placeholder
  const placeholder = await page.$('flt-semantics-placeholder');
  if (placeholder) {
    console.log('Found semantics placeholder, clicking...');
    await placeholder.click();
    await page.waitForTimeout(2000);
  } else {
    console.log('No semantics placeholder found');
  }

  await page.screenshot({ path: 'tmp_pw/02_after_semantics_click.png', fullPage: true });

  const html = await page.content();
  require('fs').writeFileSync('tmp_pw/page.html', html);
  console.log('HTML length:', html.length);

  console.log('\n=== CONSOLE ERRORS ===');
  errors.forEach(e => console.log(e));

  await browser.close();
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
