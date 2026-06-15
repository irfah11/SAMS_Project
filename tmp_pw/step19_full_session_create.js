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
    btns = await getButtons(page);
    const addBtn = btns.find(b => b.text.includes('Add Attendance'));
    await clickAt(page, addBtn.x, addBtn.y);
    await page.waitForTimeout(800);

    // Date picker
    btns = await getButtons(page);
    const dateField = btns.find(b => b.text === 'Select date');
    await clickAt(page, dateField.x, dateField.y);
    await page.waitForTimeout(600);
    btns = await getButtons(page);
    const day20 = btns.find(b => b.text.startsWith('20,'));
    await clickAt(page, day20.x, day20.y);
    btns = await getButtons(page);
    const okDate = btns.find(b => b.text === 'OK');
    await clickAt(page, okDate.x, okDate.y);
    await page.waitForTimeout(600);
    await page.screenshot({ path: 'screens/25_after_date.png' });
    btns = await getButtons(page);
    console.log('After date selected:', JSON.stringify(btns.map(b=>b.text)));

    // Start time picker
    const startField = btns.find(b => b.text === 'Start');
    await clickAt(page, startField.x, startField.y);
    await page.waitForTimeout(600);
    await page.screenshot({ path: 'screens/26_start_time_picker.png' });
    btns = await getButtons(page);
    console.log('Start time picker:', JSON.stringify(btns.map(b=>b.text)));
    const okStart = btns.find(b => b.text === 'OK');
    await clickAt(page, okStart.x, okStart.y);
    await page.waitForTimeout(600);

    // End time picker
    btns = await getButtons(page);
    console.log('Before end time click:', JSON.stringify(btns.map(b=>b.text)));
    const endField = btns.find(b => b.text === 'End');
    await clickAt(page, endField.x, endField.y);
    await page.waitForTimeout(600);
    await page.screenshot({ path: 'screens/27_end_time_picker.png' });
    btns = await getButtons(page);
    console.log('End time picker:', JSON.stringify(btns.map(b=>b.text)));
    const okEnd = btns.find(b => b.text === 'OK');
    await clickAt(page, okEnd.x, okEnd.y);
    await page.waitForTimeout(600);

    await page.screenshot({ path: 'screens/28_form_filled_times.png' });
    btns = await getButtons(page);
    console.log('Form after times:', JSON.stringify(btns));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step19.png' });
  } finally {
    await browser.close();
  }
})();
