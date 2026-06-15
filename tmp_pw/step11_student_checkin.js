const { launch, gotoApp, login, enableSemantics } = require('./helpers');

async function getButtons(page) {
  return await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"], flt-semantics[role="link"], flt-semantics[role="switch"], flt-semantics[role="checkbox"]').forEach(el => {
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
    await login(page, 'student@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.screenshot({ path: 'screens/14_student_dashboard.png' });

    // Open drawer (top-right button)
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    console.log('Drawer buttons:', JSON.stringify(btns));

    // Click "Check In" - may be nested under "Attendance" dropdown, may need to expand
    let checkIn = btns.find(b => b.text === 'Check In');
    if (!checkIn) {
      // try expanding "Attendance"
      const attBtn = btns.find(b => b.text.includes('Attendance'));
      if (attBtn) {
        await clickAt(page, attBtn.x, attBtn.y);
        btns = await getButtons(page);
        console.log('After Attendance click:', JSON.stringify(btns));
        checkIn = btns.find(b => b.text === 'Check In');
      }
    }
    if (!checkIn) throw new Error('Check In not found. Buttons: ' + JSON.stringify(btns));
    await clickAt(page, checkIn.x, checkIn.y);
    await page.screenshot({ path: 'screens/15_student_coq_subjects.png' });
    btns = await getButtons(page);
    console.log('Co-Q subjects screen:', JSON.stringify(btns));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step11.png' });
  } finally {
    await browser.close();
  }
})();
