const { launch, gotoApp, login, enableSemantics } = require('./helpers');

async function getButtons(page) {
  return await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"], flt-semantics[role="link"], flt-semantics[role="textbox"]').forEach(el => {
      const r = el.getBoundingClientRect();
      const text = (el.textContent || '').trim();
      const role = el.getAttribute('role');
      if (r.width > 0 && r.height > 0) {
        out.push({ text, role, x: Math.round(r.x + r.width/2), y: Math.round(r.y + r.height/2), w: Math.round(r.width), h: Math.round(r.height) });
      }
    });
    return out;
  });
}
async function clickAt(page, x, y) {
  await page.mouse.click(x, y);
  await page.waitForTimeout(1000);
  await enableSemantics(page);
}

(async () => {
  const { browser, page } = await launch();
  try {
    await gotoApp(page);
    await login(page, 'lecturer@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'Manage Attendance').x, btns.find(b => b.text === 'Manage Attendance').y);
    btns = await getButtons(page);
    const coq = btns.find(b => b.text.includes('Futsal Training'));
    await clickAt(page, coq.x, coq.y);
    await page.waitForTimeout(800);
    btns = await getButtons(page);

    const session = btns.find(b => b.text.includes('Futsal Training Session - Week 1'));
    await clickAt(page, session.x, session.y);
    btns = await getButtons(page);
    console.log('Action sheet:', JSON.stringify(btns.map(b=>b.text)));

    const gen = btns.find(b => b.text.includes('Generate Code Attendance'));
    await clickAt(page, gen.x, gen.y);
    btns = await getButtons(page);
    console.log('Confirm screen:', JSON.stringify(btns.map(b=>b.text)));

    const yes = btns.find(b => b.text.includes('Yes, Generate'));
    await clickAt(page, yes.x, yes.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screens/32_coq_code_generated.png' });

    const full = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const r = el.getBoundingClientRect();
        const text = (el.textContent || '').trim();
        if (r.width > 0 && r.height > 0 && text) out.push(text.slice(0,150));
      });
      return out;
    });
    console.log('Code screen:', JSON.stringify(full.slice(-6), null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step22.png' });
  } finally {
    await browser.close();
  }
})();
