# Solidity API

## Item721Mock

### constructor

```solidity
constructor(string name, string symbol, string version, string tokenURI, address world) public
```

### exists

```solidity
function exists(uint256 tokenId) public view returns (bool)
```

### mint

```solidity
function mint(address to, uint256 tokenId) public
```

### safeMint

```solidity
function safeMint(address to, uint256 tokenId) public
```

### safeMint

```solidity
function safeMint(address to, uint256 tokenId, bytes _data) public
```

### burn

```solidity
function burn(uint256 tokenId) public
```

### getChainId

```solidity
function getChainId() external view returns (uint256)
```

