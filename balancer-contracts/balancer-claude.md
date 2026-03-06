# Balancer BPT Vault Deployment — Learnings

Deployment completed on Monad (chain 143). Notes for the next person running this.

---

## Deployed Addresses

| Contract | Address |
|---|---|
| KinkIRM | `0x2CB88c8E5558380077056ECb9DDbe1e00fdbC402` |
| EulerRouter | `0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73` |
| AUSD Borrow Vault | `0x438cedcE647491B1d93a73d491eC19A50194c222` |
| WMON Borrow Vault | `0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19` |
| Pool1 Vault (wnAUSD/wnUSDC/wnUSDT0) | `0x5795130BFb9232C7500C6E57A96Fdd18bFA60436` |
| Pool2 Vault (sMON/wnWMON) | `0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5` |
| Pool3 Vault (shMON/wnWMON) | `0x6660195421557BC6803e875466F99A764ae49Ed7` |
| Pool4 Vault (wnLOAZND/AZND/wnAUSD) | `0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92` |

LP Oracles and ChainlinkOracle adapters in `.env`.

---

## Hard-Won Lessons

### 1. `[etherscan]` in foundry.toml breaks `forge script` on unknown chains

The `[etherscan]` block with `chain = "143"` causes `Error: Chain 143 not supported` even for dry runs with no `--verify` flag. Remove the entire `[etherscan]` section. Verify contracts manually after deployment if needed.

### 2. EVault `createProxy` trailingData must be exactly 60 bytes

`GenericFactory.createProxy(implementation, upgradeable, trailingData)` prepends `bytes4(0)` to trailingData, making it 64 bytes (`PROXY_METADATA_LENGTH`). The vault's `initialize()` checks `msg.data.length == 4 + 32 + 64` and reverts with `E_ProxyMetadata()` if wrong.

Correct format: `abi.encodePacked(asset, oracle, unitOfAccount)` = 3 x 20 bytes = 60 bytes.

For **borrow vaults**: pass real oracle (EulerRouter) and unitOfAccount.
For **collateral vaults**: pass `address(0)` for both oracle and unitOfAccount — they're unused.

### 3. `forge script` gas estimates are ~3-4x too low on Monad

Forge's local EVM simulation consistently underestimates gas for Monad. Simulated gas is ~44k for `setInterestRateModel`; actual on-chain cost is ~144k. All config transactions fail with status 0 (out of gas) when broadcast without adjustment.

**Fix:** always use `--gas-estimate-multiplier 400` for all `forge script --broadcast` calls on Monad.

```bash
forge script script/06_ConfigureCluster.s.sol \
  --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
  --broadcast --gas-estimate-multiplier 400
```

### 4. Never mix deploy + config in the same forge script on Monad

If you deploy a contract and immediately call methods on it in the same `forge script`, the broadcast will fail. Forge computes addresses for in-script deployments at simulation time. If anything causes a nonce mismatch between simulation and broadcast, all subsequent calls to those addresses go to dead addresses.

Pattern that works (Cork-style): one script deploys and logs addresses, next script reads addresses from `.env` via `vm.envAddress()` and configures. Steps are always separated.

### 5. `setLTV` takes `uint32 rampDuration`, not `uint16`

The correct EVault interface signature is:
```solidity
function setLTV(address collateral, uint16 borrowLTV, uint16 liquidationLTV, uint32 rampDuration) external;
```
Using `uint16` for rampDuration produces the wrong function selector and silently reverts with empty revert data.

### 6. Oracle for collateral vaults is set on the BORROW vault, not the collateral vault

The EulerRouter lives on the borrow vault. When Euler prices collateral, it uses the borrow vault's configured oracle. Collateral vaults do not need a real oracle set — they just hold the BPT token.

### 7. IRM factory selection: KinkIRM vs KinkyIRM

Two factories exist:
- `kinkIRMFactory` (`0x05Cc...`): 4-param `deploy(baseRate, slope1, slope2, kink)` — standard 2-slope linear. **This is what the calculator outputs.**
- `kinkyIRMFactory` (`0x3512...`): 5-param `deploy(baseRate, slope, shape, kink, cutoff)` — non-linear spike with hard cap.

The `calculate-irm-linear-kink.js` script outputs values for **KinkIRM**, not KinkyIRM. Use `kinkIRMFactory`.

### 8. `ethereum-vault-connector` remapping must point to `src/`, not repo root

`euler-price-oracle` internally remaps `ethereum-vault-connector/ → lib/ethereum-vault-connector/src/`. Forge's auto-detection overrides this with the repo root. Add to `remappings.txt`:

```
ethereum-vault-connector/=lib/euler-price-oracle/lib/ethereum-vault-connector/src/
```

### 9. Solidity requires EIP-55 checksummed addresses

Lowercase hex addresses in `address constant` declarations are rejected at compile time. Use the checksummed form (mixed case). The compiler error message includes the correct checksummed version.

### 10. `cast send` works fine on Monad even when `forge script --broadcast` fails

If a forge script broadcast is failing, use `cast send` to test individual calls. `cast send` computes gas dynamically and doesn't suffer from the estimation problem. It's also useful for ad-hoc config calls (setFeeReceiver, tightening caps, etc.) without needing a full script.

### 11. Monad EVault factory initializes all vaults with operations disabled

On Monad, newly created EVault proxies have `hookedOps = 32767` (all 15 operation bits set) and `hookTarget = address(0)`. This means **every operation is disabled by default** — deposit, withdraw, borrow, repay, liquidate, etc. The frontend shows "Transaction simulation failed: Operation Disabled".

The governor must call `setHookConfig(address(0), 0)` on each vault after deployment to clear the disabled flags. This was not part of the original 6-step deployment and was added as step 7 (`07_EnableOperations.s.sol`).

`forge script --broadcast` fails to land these txs on Monad (gas/nonce issues with batched sends). Use `cast send` instead:

```bash
source .env
for VAULT in $AUSD_BORROW_VAULT $WMON_BORROW_VAULT \
              $POOL1_VAULT $POOL2_VAULT $POOL3_VAULT $POOL4_VAULT; do
  cast send $VAULT "setHookConfig(address,uint32)" \
    "0x0000000000000000000000000000000000000000" 0 \
    --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MONAD
done
```

Verify: `cast call $VAULT "hookConfig()(address,uint32)" --rpc-url $RPC_URL_MONAD` should return `address(0)` and `0`.

### 12. Frontend CSP blocks chain default RPCs — route wagmi through server proxy

The Euler Lite frontend has a strict Content Security Policy. Wagmi/AppKit's client-side transport uses each chain's default public RPC (e.g. `rpc.monad.xyz`) directly from the browser, which gets blocked by CSP `connect-src`.

Fix: configure wagmi's `transports` to route through the app's server proxy (`/api/rpc/<chainId>`), which forwards to the operator's configured RPC (Alchemy, QuickNode, etc.). This keeps the API key server-side and avoids CSP issues entirely. See `plugins/00.wagmi.ts`.

### 13. TOS signing must be explicitly bypassed when `TOS_MD_URL` is unset

The `prepareTos()` helper in `useEulerOperations` calls `getTosData()` unconditionally, which throws if `NUXT_PUBLIC_CONFIG_TOS_MD_URL` is empty. The `enableTosSignature` flag (derived from `!!configTosMdUrl`) correctly disables TOS in `guardWithTerms()`, but the plan builder still called `getTosData()` deeper in the stack.

Fix: add an early return in `prepareTos()` when `enableTermsOfUseSignature` is false. See `composables/useEulerOperations/helpers.ts`.

### 14. EulerRouter requires `govSetResolvedVault` for collateral vaults

`govSetConfig(BPT, borrowAsset, adapter)` alone is not enough. The borrow vault's health check passes the **collateral vault address** (not the BPT address) to the router. The router needs `resolvedVaults[vaultAddress] → BPT` so it can convert vault shares → assets → then price the BPT.

Without `govSetResolvedVault(collateralVault, true)` on the EulerRouter, the router receives `base = collateralVault`, finds no resolution, and reverts with "Price Oracle Not Supported".

```bash
source .env
for VAULT in $POOL1_VAULT $POOL2_VAULT $POOL3_VAULT $POOL4_VAULT; do
  cast send $EULER_ROUTER "govSetResolvedVault(address,bool)" $VAULT true \
    --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MONAD
done
```

Verify: `cast call $EULER_ROUTER "resolvedVaults(address)(address)" $VAULT --rpc-url $RPC_URL_MONAD` should return the BPT address.
