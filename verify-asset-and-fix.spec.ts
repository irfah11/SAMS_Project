// spec: specs/octagon-verification.plan.md
// seed: tests/seed.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Asset and Feature Verification', () => {
  test('verify-octagon-asset-and-check-in-fix', async ({ page }) => {
    // 1. Log in to the application
    // Note: Assuming navigation is handled by a global setup or fixture, 
    // otherwise add page.goto('/') here.
    await page.getByLabel('Username').fill('test-user');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: /log in/i }).click();
    
    await expect(page).toHaveURL(/.*dashboard/);

    // 2. Locate the octagon asset on the page
    const octagon = page.getByRole('img', { name: /octagon/i });
    await expect(octagon).toBeVisible();
    // Verify the asset path specifically if needed
    await expect(octagon).toHaveAttribute('src', /.*octagon\.(png|svg|webp)/);

    // 3. Perform a check-in action
    const checkInButton = page.getByRole('button', { name: /check-in/i });
    await checkInButton.click();

    await expect(page.getByText(/check-in successful/i)).toBeVisible();
  });
});