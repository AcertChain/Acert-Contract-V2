# Solidity API

## IWorldAsset

### ProtocolEnum

```solidity
enum ProtocolEnum {
  CASH20,
  ITEM721
}
```

### symbol

```solidity
function symbol() external view returns (string)
```

### protocol

```solidity
function protocol() external pure returns (enum IWorldAsset.ProtocolEnum)
```

