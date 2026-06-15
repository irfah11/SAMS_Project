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
  await page.waitForTimeout(1200);
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
    if (!coq) throw new Error('Futsal Training card not found: ' + JSON.stringify(btns));
    await clickAt(page, coq.x, coq.y);
    await page.waitForTimeout(800);
    await page.screenshot({ path: 'screens/22_coq_session_list.png' });
    btns = await getButtons(page);
    console.log('COQ001 session list:', JSON.stringify(btns));

    const addBtn = btns.find(b => b.text.includes('Add Attendance'));
    await clickAt(page, addBtn.x, addBtn.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screens/23_add_attendance_form.png' });
    btns = await getButtons(page);
    console.log('Add Attendance form:', JSON.stringify(btns));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step17.png' });
  } finally {
    await browser.close();
  }
})();
