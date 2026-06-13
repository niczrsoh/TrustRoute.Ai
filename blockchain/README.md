# Blockchain Evidence Trail

Deploy `contracts/DefectReportRegistry.sol` to Sepolia or another Ethereum testnet.

The backend calls:

```solidity
anchorReport(
    bytes32 shipmentHash,
    bytes32 evidenceHash,
    DefectType defectType,
    uint16 confidenceBps,
    uint64 detectedAt
)
```

Set these backend environment variables before starting the server:

```powershell
$env:ETH_RPC_URL = "https://sepolia.infura.io/v3/YOUR_KEY"
$env:ETH_PRIVATE_KEY = "YOUR_BACKEND_WALLET_PRIVATE_KEY"
$env:ETH_CHAIN_ID = "11155111"
$env:DEFECT_REGISTRY_ADDRESS = "0xYOUR_DEPLOYED_CONTRACT"
$env:SLT_AUTO_ANCHOR_REPORTS = "true"
```

The deployer wallet is authorized by default. If the backend uses a different wallet, call `setReporter(backendWallet, true)` from the owner wallet.
