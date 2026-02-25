# AG-Euler

Alpha Growth's Euler deployment monorepo. Each subdirectory is a partner deployment — custom contracts, deployment scripts, and docs. One frontend ([ag-euler-lite](https://github.com/rootdraws/ag-euler-lite)), configured per partner via env vars in Vercel.

```bash
git clone --recurse-submodules https://github.com/rootdraws/ag-euler.git
```

---

## Deployments

| Partner | URL | Contracts | Status |
|---|---|---|---|
| Cork Protocol | [cork.alphagrowth.fun](https://cork.alphagrowth.fun) | [cork-contracts/](cork-contracts/) | Live |
| Balancer | balancer.alphagrowth.fun | balancer/ | Planned |

---

## Structure

```
AG-Euler/
├── cork-contracts/          ← Cork Protocol deployment
│   ├── src/                 ← oracle, hook, liquidator, vault
│   ├── script/              ← 7 deployment scripts
│   ├── cork-README.md
│   ├── cork-implementation.md
│   └── cork-claude.md
├── reference/               ← upstream read-only repos (submodules)
│   ├── ethereum-vault-connector/
│   ├── euler-interfaces/
│   ├── euler-labels/
│   ├── euler-vault-kit/
│   ├── euler-vault-scripts/
│   └── phoenix/
├── euler-lite/              ← frontend (independent repo → rootdraws/ag-euler-lite)
├── cork-TODO.md             ← Cork post-deployment tasks
├── claude.md                ← AG-wide frontend context
└── README.md
```

---

## The Core Insight

There is no forking. Everything lives in one place, and every partner deployment is just a different set of env vars.

**Three repos, total:**

```
AG-Euler/  (this repo)                ← all development happens here
rootdraws/ag-euler-lite               ← one frontend, Vercel watches it
rootdraws/ag-euler-<partner>-labels   ← one per partner, fetched at runtime
```

**N Vercel projects, one codebase:**

```
rootdraws/ag-euler-lite
  └── Vercel Project: cork.alphagrowth.fun     → Cork env vars
  └── Vercel Project: balancer.alphagrowth.fun → Balancer env vars
  └── Vercel Project: infinifi.alphagrowth.fun → InfiniFi env vars
```

Changing env vars in Vercel morphs the site completely. No partner ever gets their own frontend repo.

---

## The Frontend Model

`ag-euler-lite` is one Nuxt 3 SPA. Every partner site is a Vercel project pointed at `rootdraws/ag-euler-lite` with a different env var set:

| Env Var | Controls |
|---|---|
| `NUXT_PUBLIC_CONFIG_LABELS_REPO` | Which vaults appear — the entire product |
| `NUXT_PUBLIC_CONFIG_APP_TITLE` | Page title and header branding |
| `NUXT_PUBLIC_CONFIG_APP_DESCRIPTION` | Meta description |
| `NUXT_PUBLIC_CONFIG_DOCS_URL` | Docs link in nav |
| `NUXT_PUBLIC_CONFIG_ENABLE_EARN_PAGE` | Show/hide Earn page |
| `NUXT_PUBLIC_CONFIG_ENABLE_LEND_PAGE` | Show/hide Lend page |
| `NUXT_PUBLIC_CONFIG_ENABLE_EXPLORE_PAGE` | Show/hide Explore page |
| `RPC_URL_HTTP_<chainId>` | Which chains are active |
| `NUXT_PUBLIC_SUBGRAPH_URI_<chainId>` | Subgraph per chain |

For custom UI: add feature-flagged Vue pages to `ag-euler-lite` toggled via `NUXT_PUBLIC_CONFIG_ENABLE_<FEATURE>`. Do NOT create per-partner frontend repos.

Reference repos (`euler-vault-kit`, `ethereum-vault-connector`, `euler-interfaces`, `euler-labels`, `phoenix`) are submodules — pinned upstream sources. Labels repos (`rootdraws/ag-euler-<partner>-labels`) are standalone, managed independently.

---

## The 7-Script Deployment Pattern

| Script | Reusable? | What changes per partner |
|---|---|---|
| `01_DeployRouter.s.sol` | Identical — copy as-is | Nothing |
| `02_DeployOracles.s.sol` | Custom | Oracle formula, constructor args |
| `03_DeployVaults.s.sol` | Mostly reusable | Asset addresses, vault names |
| `04_WireRouter.s.sol` | Mostly reusable | Oracle + asset addresses |
| `05_DeployHookAndWire.s.sol` | Custom | Hook invariant logic |
| `06_ConfigureCluster.s.sol` | Mostly reusable | LTVs, IRM params, fee receiver |
| `07_DeployLiquidator.s.sol` | Custom | Liquidation exit path |

---

## Per-Deployment Checklist

**Contracts:**
- [ ] Create `<partner>/contracts/src/` with custom oracle, hook, liquidator
- [ ] Copy 7 scripts from a prior deployment, update constants + addresses
- [ ] Create `<partner>/contracts/.env` — RPC, private key, Etherscan key, protocol addresses
- [ ] Run scripts 01–07, paste each deployed address into `.env` before next step
- [ ] Send liquidator address to partner team for whitelist if required

**Frontend:**
- [ ] Create new Vercel project → source: `rootdraws/ag-euler-lite` → set partner env vars
- [ ] Set custom domain `<partner>.alphagrowth.fun`

**Labels:**
- [ ] Create `rootdraws/ag-euler-<partner>-labels` on GitHub
- [ ] Add `1/products.json`, `1/vaults.json`, `1/entities.json`, `1/points.json`, `1/opportunities.json`
- [ ] Add `logo/alphagrowth.svg`, `logo/euler.svg`, `logo/<partner>.svg`
- [ ] Set `NUXT_PUBLIC_CONFIG_LABELS_REPO=rootdraws/ag-euler-<partner>-labels` in Vercel

**Docs:**
- [ ] Add `<partner>-TODO.md` at repo root
- [ ] Add `<partner>/contracts/<partner>-implementation.md` and `<partner>-claude.md`

---

## Shared Lib Migration

`cork-contracts/lib/` contains its own copies of `evk-periphery` (1.1G) and `euler-price-oracle` (203M). When adding the first new partner:

1. Move to `shared/lib/` at repo root
2. Update each partner's `foundry.toml` to reference `../../shared/lib/`
3. Delete duplicated copies

Do this once when adding `balancer/contracts/` — not before.
