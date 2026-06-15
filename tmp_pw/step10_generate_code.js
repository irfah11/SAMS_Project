const { launch, gotoApp, login, enableSemantics } = require('./helpers');

async function getButtons(page) {
  return await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"], flt-semantics[role="link"]').forEach(el => {
      const r = el.getBoundingClientRect();
      const text = (el.textContent || '').trim();
      if (r.width > 0 && r.height > 0) {
        out.push({ text, x: Math.round(r.x + r.width/2), y: Math.round(r.y + r.height/2), w: Math.round(r.width), h: Math.round(r.height) });
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
    const subj = btns.find(b => b.text.includes('Software Engineering'));
    await clickAt(page, subj.x, subj.y);
    btns = await getButtons(page);
    console.log('Subject sessions:', JSON.stringify(btns));

    // Tap the session tile
    const session = btns.find(b => b.text.includes('Regular class session'));
    await clickAt(page, session.x, session.y);
    await page.screenshot({ path: 'screens/11_action_sheet.png' });
    btns = await getButtons(page);
    console.log('Action sheet:', JSON.stringify(btns));

    // Click "Generate Code Attendance"
    const gen = btns.find(b => b.text.includes('Generate Code Attendance'));
    await clickAt(page, gen.x, gen.y);
    await page.screenshot({ path: 'screens/12_generate_confirm.png' });
    btns = await getButtons(page);
    console.log('Generate confirm screen:', JSON.stringify(btns));

    // Click "Yes, Generate"
    const yes = btns.find(b => b.text.includes('Yes, Generate') || b.text.includes('Generate'));
    if (yes) {
      await clickAt(page, yes.x, yes.y);
      await page.waitForTimeout(1500);
      await page.screenshot({ path: 'screens/13_code_display.png' });
      btns = await getButtons(page);
      console.log('Code display screen buttons:', JSON.stringify(btns));

      // Dump full text content to find the code
      const full = await page.evaluate(() => {
        const out = [];
        document.querySelectorAll('flt-semantics').forEach(el => {
          const r = el.getBoundingClientRect();
          const text = (el.textContent || '').trim();
          if (r.width > 0 && r.height > 0 && text) out.push(text);
        });
        return out;
      });
      console.log('Full text on code screen:', JSON.stringify(full));
    } else {
      console.log('No "Yes, Generate" button found');
    }
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step10.png' });
  } finally {
    await browser.close();
  }
})();
