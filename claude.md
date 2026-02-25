# Alpha Growth — Euler Lite Sales Deployments

## What This Is

White-label deployments of [euler-xyz/euler-lite](https://github.com/euler-xyz/euler-lite) branded for **Alpha Growth**, used as live sales demos for protocol partners. Each deployment is a working Euler Finance frontend customized per pitch — showing the specific vault clusters, lending markets, and Eulerswap pools that AG is proposing to curate for that partner.

**Pattern:** `cork.alphagrowth.fun`, `balancer.alphagrowth.fun`, `infinifi.alphagrowth.fun`, etc.

**Branding:** Alpha Growth primary, with partner + Euler logos as co-branding. These are AG's tools, not the partner's product.

**Lifecycle:**
1. AG spins up a custom frontend per pitch with proposed vault structures
2. Partner sees a live URL: "borrowers deposit here, lenders deposit here, Eulerswap pools monitored here"
3. AG launches custom clusters, liquidators, dashboards as the deal matures
4. If the product graduates, it moves to the official Euler frontend — the AG demo served its purpose

This replaces pitch decks and tear sheets with working software.

## Mission

Build a repeatable deployment pipeline where standing up a new `<partner>.alphagrowth.fun` is mostly config: env vars, labels repo, logo assets, vault addresses. The first deployment is for **Cork Protocol** (protected looping vaults for insured RWA leverage).

---

## Repo Overview

**Stack:** Nuxt 3 (Vue 3) + TypeScript + Tailwind CSS + SCSS + Viem + Wagmi + Reown (WalletConnect)

**SSR:** Disabled (`ssr: false` in nuxt.config.ts). This is a client-side SPA with a Nitro server for API proxying (RPC, wallet screening, Tenderly).

**Key directories:**

```
entities/custom.ts          ← THEME HUE + intrinsic APY sources (EDIT THIS)
assets/styles/variables.scss ← Full color palette, shadows, radii (EDIT FOR DEEPER BRANDING)
composables/useEnvConfig.ts  ← API URLs, app title/desc (driven by env vars)
composables/useDeployConfig.ts ← Feature flags, labels repo, social URLs (driven by env vars)
composables/useChainConfig.ts  ← Chains auto-detected from RPC_URL_HTTP_<chainId> env vars
composables/useEulerConfig.ts  ← Combines all config, builds labels URLs from repo setting
entities/menu.ts             ← Navigation items (Portfolio, Explore, Earn, Lend, Borrow)
plugins/00.wagmi.ts          ← Wallet connection setup (reads env config)
server/plugins/app-config.ts ← Injects env vars into HTML as window.__APP_CONFIG__
server/plugins/chain-config.ts ← Injects chain config into HTML as window.__CHAIN_CONFIG__
nuxt.config.ts               ← Meta tags, runtime config defaults, modules
public/entities/             ← Entity logos (alphagrowth.svg already exists, need cork logo)
public/favicons/             ← Favicon files (replace with Cork branding)
assets/tokens/               ← Token icon overrides by symbol
```

---

## Customization Checklist

### 1. Environment Variables (`.env`)

Copy `.env.example` → `.env` and configure. Below is the Cork deployment example — swap partner-specific values for each deployment.

```bash
# === REQUIRED (same across all AG deployments) ===
APPKIT_PROJECT_ID=<get from reown.com — one ID works for all subdomains>

# === PER-DEPLOYMENT ===
NUXT_PUBLIC_APP_URL=https://cork.alphagrowth.fun

# RPC — at minimum Ethereum mainnet
RPC_URL_HTTP_1=<alchemy/infura/quicknode URL>

# Euler APIs (same across all deployments)
NUXT_PUBLIC_EULER_API_URL="https://indexer.euler.finance"
NUXT_PUBLIC_SWAP_API_URL="https://swap-dev.euler.finance"
NUXT_PUBLIC_PRICE_API_URL="https://indexer.euler.finance"
NUXT_PUBLIC_PYTH_HERMES_URL=https://hermes.pyth.network

# Subgraphs (same across all deployments on same chains)
NUXT_PUBLIC_SUBGRAPH_URI_1="https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-mainnet/latest/gn"

# === AG BRANDING (consistent across deployments, partner name in title) ===
NUXT_PUBLIC_CONFIG_APP_TITLE="Alpha Growth × Cork — Protected Loops"
NUXT_PUBLIC_CONFIG_APP_DESCRIPTION="Insured leverage on RWAs, powered by Cork Protocol and Euler Finance. Curated by Alpha Growth."
NUXT_PUBLIC_CONFIG_DOCS_URL="https://docs.cork.tech/"

# Social links — AG primary, can add partner links in entities.json
NUXT_PUBLIC_CONFIG_X_URL=""
NUXT_PUBLIC_CONFIG_DISCORD_URL=""
NUXT_PUBLIC_CONFIG_TELEGRAM_URL=""
NUXT_PUBLIC_CONFIG_GITHUB_URL=""

# === FEATURE FLAGS ===
NUXT_PUBLIC_CONFIG_ENABLE_EARN_PAGE="true"
NUXT_PUBLIC_CONFIG_ENABLE_LEND_PAGE="true"
NUXT_PUBLIC_CONFIG_ENABLE_EXPLORE_PAGE="false"
NUXT_PUBLIC_CONFIG_ENABLE_ENTITY_BRANDING="true"
NUXT_PUBLIC_CONFIG_ENABLE_VAULT_TYPE="true"

# === LABELS (per-deployment — points at partner-specific labels repo) ===
NUXT_PUBLIC_CONFIG_LABELS_REPO="alphagrowth/cork-euler-labels"
NUXT_PUBLIC_CONFIG_LABELS_REPO_BRANCH="main"
```

**Reusable across deployments:** APPKIT_PROJECT_ID, Euler API URLs, subgraph URIs, RPC URLs.
**Changes per deployment:** APP_URL, APP_TITLE, APP_DESCRIPTION, LABELS_REPO, DOCS_URL.

### 2. Theme & Branding

**AG is the brand. Partners and Euler are co-branded via entity logos.**

`entities/custom.ts` has a legacy `themeHue` value. The current SCSS in `assets/styles/variables.scss` uses a fixed institutional palette (navy/gold). For AG branding:

- Modify `variables.scss` directly — the `--primary-*`, `--accent-*`, and `--aquamarine-*` CSS variable families control the entire palette
- The `--aquamarine-*` variables control accent/CTA colors (currently gold/bronze)
- The `--euler-dark-*` variables control the surface/background hierarchy
- Dark theme overrides are in `[data-theme="dark"]` block

Keep the AG palette consistent across all deployments. Partner differentiation comes from:
- App title (env var)
- Entity logos in the labels repo (AG + partner + Euler)
- Vault descriptions in products.json

### 3. Logos & Favicons

- **AG favicon:** Replace files in `public/favicons/` with AG branding
- **Manifest image:** Replace `public/manifest-img.png` (used by WalletConnect)
- **Entity logos:** AG logo already exists at `public/entities/alphagrowth.svg`. Add partner logos to the custom labels repo's `logo/` directory (e.g. `cork.svg`, `euler.svg`)
- **Token icons:** Add overrides to `assets/tokens/<symbol>.png` if needed

### 4. Meta Tags (`nuxt.config.ts`)

The `app.head` section has hardcoded "Euler Lite" references. These are overridden at runtime by env vars for `title` and `description`, BUT og:title, og:description, twitter:title, twitter:description are hardcoded. Update per deployment or make them dynamic:

```typescript
// nuxt.config.ts → app.head.meta
{ property: 'og:title', content: 'Alpha Growth × Cork — Protected Loops' },
{ property: 'og:description', content: 'Insured leverage on RWAs...' },
{ name: 'twitter:title', content: 'Alpha Growth × Cork — Protected Loops' },
{ name: 'twitter:description', content: 'Insured leverage on RWAs...' },
```

**Future improvement:** Pull these from env vars so meta tags don't require code changes per deployment.

---

## Architecture Quick Reference

### Data Flow

```
User → Pages (Vue) → Composables → Entities/Utils → External APIs
                                                      ├── Euler Indexer API (token data, vault data)
                                                      ├── Euler Swap API
                                                      ├── Euler Price API
                                                      ├── Subgraph (vault registry, positions)
                                                      ├── RPC (via server proxy at /api/rpc/<chainId>)
                                                      ├── Pyth (oracle prices)
                                                      ├── GitHub Labels Repo (products, entities, earn-vaults)
                                                      └── Merkl/Brevis (rewards)
```

### Vault Discovery & Filtering (Critical)

**Vault visibility is NOT controlled by the subgraph.** The subgraph returns all Euler vaults on a chain. Filtering happens at the **labels layer**.

The flow:

1. `useEulerLabels.ts` fetches `products.json` from the configured labels repo:
   `https://raw.githubusercontent.com/<LABELS_REPO>/refs/heads/<BRANCH>/<chainId>/products.json`
2. `normalizeProducts()` extracts every vault address from all products → `verifiedVaultAddresses`
3. `fetchVaults()` in `entities/vault/fetcher.ts` (line 407) uses `verifiedVaultAddresses` as the vault list:
   ```typescript
   const verifiedVaults = vaultAddresses || verifiedVaultAddresses.value
   ```
4. Only vaults in this list get fetched via the Lens contract and displayed in the UI
5. `getVerifiedEvkVaults()` further filters to `v.verified === true` — which is set when the vault address exists in `verifiedVaultAddresses`

**This means: if a vault address is NOT in your labels repo's `products.json`, it does not exist in the UI. Period.**

#### To show only Cork vaults:

1. Create a GitHub repo (e.g. `alphagrowth/cork-euler-labels`)
2. Structure:
   ```
   cork-euler-labels/
   ├── logo/
   │   ├── cork.svg          # Cork entity logo
   │   └── alphagrowth.svg   # AG entity logo
   ├── 1/                    # Ethereum mainnet (chain ID 1)
   │   ├── products.json     # Only Cork vault addresses
   │   ├── entities.json     # Cork + AG entity metadata
   │   ├── points.json       # {} (empty or with point programs)
   │   └── earn-vaults.json  # [] (or EulerEarn vault addresses if applicable)
   ```
3. `products.json` example:
   ```json
   {
     "cork-protected-loop-rwa": {
       "name": "Cork Protected Loop — RWA",
       "description": "Leveraged RWA exposure insured by Cork Swap Tokens",
       "entity": ["alphagrowth", "cork", "euler"],
       "url": "https://docs.cork.tech/",
       "vaults": [
         "0x<REF_VAULT_ADDRESS>",
         "0x<CST_VAULT_ADDRESS>",
         "0x<USDC_VAULT_ADDRESS>"
       ],
       "featuredVaults": ["0x<REF_VAULT_ADDRESS>"]
     }
   }
   ```
4. `entities.json` example (three-way co-branding):
   ```json
   {
     "alphagrowth": {
       "name": "Alpha Growth",
       "logo": "alphagrowth.svg",
       "description": "DeFi risk curation and vault management",
       "url": "https://alphagrowth.fun",
       "addresses": { "0x<AG_CURATOR_ADDRESS>": "Alpha Growth Curator" },
       "social": { "twitter": "", "youtube": "", "discord": "", "telegram": "", "github": "" }
     },
     "cork": {
       "name": "Cork Protocol",
       "logo": "cork.svg",
       "description": "Tokenized risk infrastructure for DeFi",
       "url": "https://cork.tech",
       "addresses": { "0x<CORK_GOVERNOR_ADDRESS>": "Cork Governor" },
       "social": { "twitter": "https://x.com/corkprotocol", "youtube": "", "discord": "", "telegram": "https://t.me/corkprotocol", "github": "" }
     },
     "euler": {
       "name": "Euler Finance",
       "logo": "euler.svg",
       "description": "Modular lending protocol",
       "url": "https://euler.finance",
       "addresses": {},
       "social": { "twitter": "https://x.com/eulerfinance", "youtube": "", "discord": "", "telegram": "", "github": "https://github.com/euler-xyz" }
     }
   }
   ```
5. Set env var: `NUXT_PUBLIC_CONFIG_LABELS_REPO=alphagrowth/cork-euler-labels`
6. Set env var: `NUXT_PUBLIC_CONFIG_LABELS_REPO_BRANCH=main`

**Before vaults are deployed:** Use placeholder/test vault addresses in products.json to verify the pipeline works. With an empty `products.json` (`{}`), the frontend will show zero vaults — a blank branded shell.

### Labels File Schema Reference

Each labels repo has the same five files per chain plus a shared `logo/` directory:

| File | Keyed by | Frontend effect |
|---|---|---|
| `products.json` | product slug | Defines named vault clusters. Every vault address in every product's `vaults` array becomes `verifiedVaultAddresses`. **If a vault isn't here, it's invisible.** |
| `vaults.json` | checksum address | Per-vault display name, description, and entity ID. Shown in table rows and vault detail pages. Falls back to on-chain asset symbol if missing. |
| `entities.json` | entity slug | Org name, logo filename, website, addresses, socials. Referenced by `products.json` and `vaults.json` via slug. Entity logo badges appear on every vault card. |
| `points.json` | array | Incentive/points programs mapped to collateral or liability vault addresses. Rendered as tooltips on vault rows. Use `[]` if no programs. |
| `opportunities.json` | checksum address | Maps vault addresses to Cozy Finance safety module contracts. Shows a protection badge in the UI. Use `{}` if not applicable. |

`logo/` — SVG or PNG files referenced by `entities.json` (`logo` field) and `points.json` (`logo` field). Fetched directly from the raw GitHub URL.

**For a minimal Cork deployment you need:**
- `products.json` — Cork vault addresses grouped into a product
- `vaults.json` — display names for each Cork vault
- `entities.json` — entries for `alphagrowth`, `cork`, `euler`
- `points.json` — `[]`
- `opportunities.json` — `{}`
- `logo/` — `alphagrowth.svg`, `cork.svg`, `euler.svg`

### Key Composables

| Composable | Purpose |
|---|---|
| `useVaults` | Fetches vault list from subgraph, enriches with labels/prices |
| `useEulerOperations` | Transaction builders (deposit, borrow, repay, withdraw) |
| `useWagmi` / `useWallets` | Wallet connection state |
| `useEulerAccount` | User's Euler account positions |
| `useAccountPositions` | Computed position data per vault |
| `useVaultRegistry` | On-chain vault metadata via multicall |
| `useOracleAdapterPrices` | Oracle price resolution |
| `useSwapApi` | Swap routing for deposits/withdrawals |
| `useMarketGroups` | Groups related vaults for display |

### Pages

| Route | Page | Notes |
|---|---|---|
| `/` | Redirects to default page | Default order: explore → earn → lend → borrow → portfolio |
| `/earn` | EulerEarn vaults | Toggled by `ENABLE_EARN_PAGE` |
| `/lend` | Individual lending vaults | Toggled by `ENABLE_LEND_PAGE` |
| `/borrow` | Borrowing interface | Always enabled |
| `/explore` | Vault explorer | Toggled by `ENABLE_EXPLORE_PAGE` |
| `/portfolio` | User positions | Always enabled |
| `/position/[chainId]/[vault]` | Individual vault detail | Deposit/withdraw/borrow UI |

---

## Deployment

### Local Dev

```bash
npm install
npm run dev
# → http://localhost:3000
```

### Production Build

```bash
npm run build
npm run preview  # local preview
```

### Docker

One image, many deployments. Build once, configure per partner via env vars:

```bash
docker build --build-arg APP_PORT=3000 -t ag-euler-lite .

# Cork deployment
docker run -p 3001:3000 \
  -e NUXT_PUBLIC_APP_URL=https://cork.alphagrowth.fun \
  -e NUXT_PUBLIC_CONFIG_APP_TITLE="Alpha Growth × Cork — Protected Loops" \
  -e NUXT_PUBLIC_CONFIG_LABELS_REPO=alphagrowth/cork-euler-labels \
  -e EULER_API_URL=https://indexer.euler.finance \
  -e SWAP_API_URL=https://swap-dev.euler.finance \
  -e PRICE_API_URL=https://indexer.euler.finance \
  -e APPKIT_PROJECT_ID=<your-id> \
  -e RPC_URL_HTTP_1=<your-rpc> \
  -e NUXT_PUBLIC_SUBGRAPH_URI_1=<goldsky-url> \
  ag-euler-lite node .output/server/index.mjs

# Balancer deployment (same image, different config)
docker run -p 3002:3000 \
  -e NUXT_PUBLIC_APP_URL=https://balancer.alphagrowth.fun \
  -e NUXT_PUBLIC_CONFIG_APP_TITLE="Alpha Growth × Balancer — BPT Leverage" \
  -e NUXT_PUBLIC_CONFIG_LABELS_REPO=alphagrowth/balancer-euler-labels \
  # ... same Euler APIs, RPCs, subgraphs ...
  ag-euler-lite node .output/server/index.mjs
```

### Hosting Targets

- **Railway / Render / Fly.io:** Docker deploy, env vars via dashboard
- **Vercel / Netlify:** `npm run build`, deploy `.output/` — but note SSR is disabled so `npm run generate` may also work
- **VPS:** Docker or bare Node.js with process manager

---

## Partner Context: Cork Protocol (First Deployment)

### What Cork Protected Loops Are

A leveraged position on an illiquid RWA (Reference Asset / REF) using Euler vaults, where Cork Swap Tokens (cST) provide depeg/duration insurance enabling atomic liquidation. The design:

1. **REF Vault** — Collateral-only. RWA token. Oracle prices it based on Cork unwind value (CA-backed), not raw NAV.
2. **cST Vault** — Collateral-only. Oracle = 0. Control token that enables liquidation routing (REF + cST → CA → USDC).
3. **USDC Vault** — Borrowable. The leverage asset.

Hooks enforce: REF and cST must be paired 1:1 whenever debt exists. Liquidators seize both, exercise through Cork Pool to CA, swap CA to USDC. No warehousing of illiquid RWAs.

### What Each Frontend Shows

Each deployment is a scoped view of Euler's infrastructure, filtered to only the vaults and markets relevant to that partner pitch. The pages map to actions:

| Page | Sales Function |
|---|---|
| `/lend` | "Lenders deposit here" — shows lending vaults where LPs supply capital |
| `/borrow` | "Borrowers deposit here" — shows collateral/borrow pairs for leveraged positions |
| `/earn` | "Earn vaults here" — EulerEarn aggregated yield vaults |
| `/portfolio` | Position management — track and manage active positions |

As deals mature, AG can add:
- Custom dashboards for monitoring Eulerswap pools
- Liquidation bot status pages
- Risk parameter displays

If the product graduates to production, it migrates to the official Euler frontend. The AG deployment served its purpose as the sales tool and staging ground.

### Custom Vault Labels

Each partner deployment gets its own labels repo. See **"Vault Discovery & Filtering"** section above for the full technical chain.

**Repo naming convention:** `alphagrowth/cork-euler-labels`, `alphagrowth/balancer-euler-labels`, etc.

```bash
NUXT_PUBLIC_CONFIG_LABELS_REPO=alphagrowth/cork-euler-labels
NUXT_PUBLIC_CONFIG_LABELS_REPO_BRANCH=main
```

The entities.json in each labels repo should include AG, Euler, and the partner — three logos co-branded on every vault.

---

## File Edit Quick Reference

| To change... | Edit this file |
|---|---|
| Brand colors (full palette) | `assets/styles/variables.scss` |
| Theme hue (legacy) | `entities/custom.ts` line 1 |
| App title & description | `.env` → `NUXT_PUBLIC_CONFIG_APP_TITLE`, `NUXT_PUBLIC_CONFIG_APP_DESCRIPTION` |
| Social links | `.env` → `NUXT_PUBLIC_CONFIG_X_URL`, `DISCORD_URL`, `TELEGRAM_URL`, `GITHUB_URL` |
| Docs link | `.env` → `NUXT_PUBLIC_CONFIG_DOCS_URL` |
| OG/Twitter meta tags | `nuxt.config.ts` → `app.head.meta` |
| Enabled chains | `.env` → add `RPC_URL_HTTP_<chainId>` + matching `NUXT_PUBLIC_SUBGRAPH_URI_<chainId>` |
| Navigation pages | `.env` → `NUXT_PUBLIC_CONFIG_ENABLE_EARN_PAGE`, `ENABLE_LEND_PAGE`, `ENABLE_EXPLORE_PAGE` |
| Entity logos | `public/entities/<name>.png` or `.svg` |
| Favicons | `public/favicons/` |
| Token icons | `assets/tokens/<symbol>.png` |
| Vault curation (which vaults appear) | Custom labels repo → `products.json` vault arrays. Set `NUXT_PUBLIC_CONFIG_LABELS_REPO`. Empty products = zero vaults shown. |
| Tailwind extensions | `tailwind.config.js` |
| Wallet connect metadata | Reads from env config automatically |

---

## Gotchas

1. **No RPC env = crash.** The wagmi plugin throws if zero `RPC_URL_HTTP_*` vars are set.
2. **APPKIT_PROJECT_ID required** for wallet connections. Get one free at reown.com.
3. **Subgraph URIs must match chain IDs.** If you set `RPC_URL_HTTP_42161` you need `NUXT_PUBLIC_SUBGRAPH_URI_42161`.
4. **Labels repo must have correct structure.** Each chain needs `<chainId>/products.json`, `entities.json`, etc. Use the default `euler-xyz/euler-labels` until you set up custom.
5. **SCSS variables vs Tailwind:** The app uses BOTH. SCSS variables in `variables.scss` define the design tokens. Tailwind config in `tailwind.config.js` maps to those CSS variables. Change the SCSS source of truth.
6. **The `themeHue` in custom.ts** is referenced by the theme plugin (`plugins/theme.client.ts`) but the current SCSS palette is hardcoded institutional colors, not hue-derived. Changing themeHue alone won't dramatically shift the look — you need to edit the SCSS variables.
7. **Entity branding** (logos next to vault names) pulls from the labels repo's `logo/` directory. For custom logos, either use a custom labels repo or add files to `public/entities/` and reference them in your labels JSON.
8. **Empty labels repo = empty frontend.** If your custom labels repo has `products.json` as `{}`, the UI shows zero vaults. This is expected — vault discovery is driven entirely by the labels repo, not the subgraph.
9. **Labels are always fetched from GitHub raw URLs — no local path support.** `useEulerConfig.ts` line 27 hardcodes: `https://raw.githubusercontent.com/${labelsRepo}/refs/heads/${labelsRepoBranch}`. The workflow is: build JSON files locally → push to GitHub → app fetches at runtime. To support local paths you'd need to modify `useEulerConfig.ts`.

---


---

## Partner Contract Context

Cork-specific contract architecture, deployed addresses, and critical facts live in:
- `cork-contracts/CLAUDE.md` — read this before touching any Cork contracts
