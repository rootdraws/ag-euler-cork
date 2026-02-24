# Cork Protected Loop — ELI5

A lending market on Euler where people borrow sUSDe against vbUSDC + cST collateral. If they can't pay back, a liquidator seizes the collateral and converts it to sUSDe through Cork's exercise mechanism to make lenders whole.

---

## Before You Touch Anything On-Chain

- Get RPC keys and deployer wallet ready
- Ask Cork team to whitelist your deployer address so you can interact with their pool at all
- Verify the interest rate math hasn't drifted

---

## Deploy in Four Waves

### 1. Oracles

Two contracts in `euler-price-oracle-cork`. One prices vbUSDC in USD using Cork's swap rate. The other always returns zero for cST — its value is implicit. The hook forces 1:1 pairing, so if you have vbUSDC collateral, you must have matching cST.

### 2. Vaults

Three vaults. The sUSDe borrow vault is a standard Euler vault (lenders deposit sUSDe here, borrowers take sUSDe from here). Then two custom collateral vaults: one for vbUSDC, one for cST. These have built-in rules that prevent withdrawing collateral in ways that would break the 1:1 pairing.

### 3. Hook and Liquidator

The hook sits on the borrow vault and blocks any borrow attempt unless you've deposited matched vbUSDC + cST first. The liquidator is a special contract that knows how to seize both collaterals, exercise them through Cork to get sUSDe, and send the proceeds to the liquidation bot.

### 4. Main Script

Wires everything together. Deploys the oracle router, connects each vault to the right oracle, sets interest rates, LTV ratios, caps, attaches the hook, and links the paired vaults to each other. All the addresses from steps 1-3 get fed in as environment variables.

---

## After Deployment

Get test tokens, update the frontend labels repo with the new vault addresses, verify the UI loads, test a borrow, test a liquidation.

---

## Not Yet Working

Blocked on Cork building `CorkSeriesRegistry`:

- Oracle doesn't auto-zero when cST approaches expiry — governor has to do it manually
- No automatic rollover from old cST to new cST series
- These need to be solved before the cST expires on April 19, 2026
