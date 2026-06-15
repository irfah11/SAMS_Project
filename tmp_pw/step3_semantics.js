const { launch, gotoApp, login } = require('./helpers');

(async () => {
  const { browser, page, errors } = await launch();
  await gotoApp(page);

  // Enable Flutter semantics tree via dispatchEvent (bypasses visibility check)
  const ph = await page.$('flt-semantics-placeholder');
  console.log('placeholder found:', !!ph);
  if (ph) {
    const box = await ph.boundingBox();
    console.log('placeholder box:', JSON.stringify(box));
    await ph.dispatchEvent('click');
    await page.waitForTimeout(1000);
  }

  // Check viewport / canvas size
  const dims = await page.evaluate(() => {
    const c = document.querySelector('flutter-view');
    return {
      innerWidth: window.innerWidth,
      innerHeight: window.innerHeight,
      devicePixelRatio: window.devicePixelRatio,
      flutterViewRect: c ? c.getBoundingClientRect() : null,
    };
  });
  console.log('dims:', JSON.stringify(dims));

  // Dump semantics tree text content
  const semHtml = await page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host') || document.querySelector('flt-glass-pane');
    return host ? host.outerHTML.slice(0, 5000) : 'NO SEMANTICS HOST';
  });
  console.log('=== SEMANTICS HOST (truncated) ===');
  console.log(semHtml);

  await page.screenshot({ path: 'screens/03_semantics.png' });

  console.log('=== CONSOLE ERRORS ===');
  errors.forEach(e => console.log(e));

  await browser.close();
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
