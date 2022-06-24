# Solidity API

## IItem721BWO

### TransferItemBWO

```solidity
event TransferItemBWO(uint256 from, uint256 to, uint256 tokenId, address sender, uint256 nonce, uint256 deadline)
```

### ApprovalItemBWO

```solidity
event ApprovalItemBWO(address to, uint256 tokenId, address sender, uint256 nonce, uint256 deadline)
```

### ApprovalForAllItemBWO

```solidity
event ApprovalForAllItemBWO(uint256 from, address to, bool approved, address sender, uint256 nonce, uint256 deadline)
```

### safeTransferFromItemBWO

```solidity
function safeTransferFromItemBWO(uint256 from, uint256 to, uint256 tokenId, bytes data, address sender, uint256 deadline, bytes signature) external
```

### transferFromItemBWO

```solidity
function transferFromItemBWO(uint256 from, uint256 to, uint256 tokenId, address sender, uint256 deadline, bytes signature) external
```

### approveItemBWO

```solidity
function approveItemBWO(address to, uint256 tokenId, address sender, uint256 deadline, bytes signature) external
```

### setApprovalForAllItemBWO

```solidity
function setApprovalForAllItemBWO(uint256 from, address to, bool approved, address sender, uint256 deadline, bytes signature) external
```

