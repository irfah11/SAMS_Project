const { launch, gotoApp, login, enableSemantics, dumpSemantics } = require('./helpers');

async function getButtons(page) {
  return await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"], flt-semantics[role="link"]').forEach(el => {
      const r = el.getBoundingClientRect();
      const text = (el.textContent || '').trim();
      if (r.width > 0 && r.height > 0) {
        out.push({ text, x: r.x + r.width/2, y: r.y + r.height/2, w: r.width, h: r.height });
      }
    });
    return out;
  });
}

async function clickByText(page, text, exact = true) {
  await enableSemantics(page);
  const btns = await getButtons(page);
  const match = btns.find(b => exact ? b.text === text : b.text.includes(text));
  if (!match) throw new Error(`Button not found: "${text}". Available: ${JSON.stringify(btns.map(b=>b.text))}`);
  await page.mouse.click(match.x, match.y);
  return match;
}

(async () => {
  const { browser, page } = await launch();
  try {
    await gotoApp(page);
    await login(page, 'lecturer@sams.com', 'sams1234');
    await page.waitForTimeout(2000);

    // Open hamburger menu
    await enableSemantics(page);
    let btns = await getButtons(page);
    console.log('After login buttons:', btns.map(b=>b.text));

    // Click hamburger (usually first icon button, often has no text or "menu")
    const menuBtn = btns.find(b => b.text === '' && b.w < 60 && b.h < 60 && b.x < 100);
    if (menuBtn) {
      await page.mouse.click(menuBtn.x, menuBtn.y);
      await page.waitForTimeout(1000);
    } else {
      console.log('No menu button found by heuristic, trying "Manage Attendance" directly');
    }

    await clickByText(page, 'Manage Attendance', false);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: 'screens/08_manage_attendance.png' });

    btns = await getButtons(page);
    console.log('Manage Attendance screen buttons:', JSON.stringify(btns.map(b=>b.text)));

    // Click Software Engineering subject
    await clickByText(page, 'Software Engineering', false);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: 'screens/09_subject_sessions.png' });

    btns = await getButtons(page);
    console.log('Subject sessions screen buttons:', JSON.stringify(btns.map(b=>b.text)));

  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step8.png' });
  } finally {
    await browser.close();
  }
})();
