# Cork Protected Loop on Euler — Build README

## Source of Truth

- **Full spec, addresses, formulas, architecture:** `implementation.md`
- **Deployment runbook + remaining gaps:** `TODO.md`
- **Frontend pipeline + partner deployments:** See the Euler Lite Sales Deployments doc

## Compilation

All six contracts compile. Pre-existing submodule errors (LayerZero, Redstone, permit2, reward-streams) are unrelated — exit code 0 = success.

```bash
# Oracle contracts
cd euler-price-oracle-cork
forge build src/adapter/cork/CorkOracleImpl.sol src/adapter/cork/CSTZeroOracle.sol

# Vault, hook, liquidator, deployment script
cd evk-periphery-cork
forge build src/Vault/deployed/ERC4626EVCCollateralCork.sol
forge build src/HookTarget/ProtectedLoopHook.sol
forge build src/Liquidator/CorkProtectedLoopLiquidator.sol
forge build script/production/mainnet/clusters/CorkProtectedLoop.s.sol
```

## File Index

| Contract | Repo | Path |
|---|---|---|
| CorkOracleImpl | euler-price-oracle-cork | `src/adapter/cork/CorkOracleImpl.sol` |
| CSTZeroOracle | euler-price-oracle-cork | `src/adapter/cork/CSTZeroOracle.sol` |
| ERC4626EVCCollateralCork | evk-periphery-cork | `src/Vault/deployed/ERC4626EVCCollateralCork.sol` |
| ProtectedLoopHook | evk-periphery-cork | `src/HookTarget/ProtectedLoopHook.sol` |
| CorkProtectedLoopLiquidator | evk-periphery-cork | `src/Liquidator/CorkProtectedLoopLiquidator.sol` |
| CorkProtectedLoop.s.sol | evk-periphery-cork | `script/production/mainnet/clusters/CorkProtectedLoop.s.sol` |

Do not rewrite these. Read the existing files and `implementation.md` before touching anything.