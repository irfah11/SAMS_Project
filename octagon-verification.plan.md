# Octagon Asset and Check-in Verification

## Application Overview
This test ensures that the new octagon visual asset is correctly loaded and rendered after a server restart, and verifies that the recent fix for the check-in functionality is working as intended.

## Test Scenarios

### 1. Asset and Feature Verification

**Seed:** `tests/seed.spec.ts`

#### 1.1. verify-octagon-asset-and-check-in-fix

**File:** `tests/octagon-verification/verify-asset-and-fix.spec.ts`

**Steps:**
  1. Log in to the application
    - expect: the dashboard is visible
  2. Locate the octagon asset on the page
    - expect: the image is visible and uses the correct source path
  3. Perform a check-in action
    - expect: a success message is displayed