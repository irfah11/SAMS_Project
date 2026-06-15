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

    // Date
    btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'Select date').x, btns.find(b => b.text === 'Select date').y);
    await page.waitForTimeout(600);
    btns = await getButtons(page);
    const day20 = btns.find(b => b.text.startsWith('20,'));
    await clickAt(page, day20.x, day20.y);
    btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'OK').x, btns.find(b => b.text === 'OK').y);
    await page.waitForTimeout(600);

    // Start time
    btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'Start').x, btns.find(b => b.text === 'Start').y);
    await page.waitForTimeout(600);
    btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'OK').x, btns.find(b => b.text === 'OK').y);
    await page.waitForTimeout(600);

    // End time
    btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'End').x, btns.find(b => b.text === 'End').y);
    await page.waitForTimeout(600);
    btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'OK').x, btns.find(b => b.text === 'OK').y);
    await page.waitForTimeout(600);

    // Now find input fields (Description, Radius)
    const inputs = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('input, textarea').forEach(el => {
        const r = el.getBoundingClientRect();
        out.push({tag: el.tagName, label: el.getAttribute('aria-label'), value: el.value, x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height)});
      });
      return out;
    });
    console.log('Inputs found:', JSON.stringify(inputs, null, 1));

    // Click on description field area (below End time row, around y=420 based on screenshot earlier showed _label at y~340 then field)
    // Use the input bounding boxes directly
    const descInput = inputs.find(i => i.label && i.label.includes('Regular class session'));
    if (descInput) {
      await page.mouse.click(descInput.x, descInput.y);
      await page.waitForTimeout(300);
      await page.keyboard.type('Futsal Training Session - Week 1', { delay: 50 });
    } else {
      console.log('Description input not found by label, trying first textarea/input');
    }
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'screens/29_desc_filled.png' });

    await enableSemantics(page);
    btns = await getButtons(page);
    console.log('Form before confirm:', JSON.stringify(btns));

    const confirm = btns.find(b => b.text === 'Confirm');
    await page.mouse.click(confirm.x, confirm.y);
    await page.waitForTimeout(2000);
    await enableSemantics(page);
    await page.screenshot({ path: 'screens/30_after_confirm.png' });

    const full = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const r = el.getBoundingClientRect();
        const text = (el.textContent || '').trim();
        if (r.width > 0 && r.height > 0 && text) out.push(text.slice(0,150));
      });
      return out;
    });
    console.log('After confirm:', JSON.stringify(full, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step20.png' });
  } finally {
    await browser.close();
  }
})();
