# Solidity API

## World

### RegisterAsset

```solidity
event RegisterAsset(address asset, string name, string image, enum IWorldAsset.ProtocolEnum protocol)
```

### UpdateAsset

```solidity
event UpdateAsset(address asset, string image)
```

### AddOperator

```solidity
event AddOperator(address operator)
```

### RemoveOperator

```solidity
event RemoveOperator(address operator)
```

### AddSafeContract

```solidity
event AddSafeContract(address safeContract, string name)
```

### RemoveSafeContract

```solidity
event RemoveSafeContract(address safeContract)
```

### TrustContract

```solidity
event TrustContract(uint256 id, address safeContract)
```

### UntrustContract

```solidity
event UntrustContract(uint256 id, address safeContract)
```

### TrustWorld

```solidity
event TrustWorld(uint256 id)
```

### UntrustWorld

```solidity
event UntrustWorld(uint256 id)
```

### TrustContractBWO

```solidity
event TrustContractBWO(uint256 id, address safeContract, address sender, uint256 nonce, uint256 deadline)
```

### UntrustContractBWO

```solidity
event UntrustContractBWO(uint256 id, address safeContract, address sender, uint256 nonce, uint256 deadline)
```

### TrustWorldBWO

```solidity
event TrustWorldBWO(uint256 id, address sender, uint256 nonce, uint256 deadline)
```

### UntrustWorldBWO

```solidity
event UntrustWorldBWO(uint256 id, address sender, uint256 nonce, uint256 deadline)
```

### Asset

```solidity
struct Asset {
  bool _isExist;
  address _contract;
  string _name;
  string _image;
  enum IWorldAsset.ProtocolEnum _protocol;
}
```

### Contract

```solidity
struct Contract {
  bool _isExist;
  address _contract;
  string _name;
}
```

### _isOperatorByAddress

```solidity
mapping(address => bool) _isOperatorByAddress
```

### _safeContracts

```solidity
mapping(address => struct World.Contract) _safeContracts
```

### _isTrustContractByAccountId

```solidity
mapping(uint256 => mapping(address => bool)) _isTrustContractByAccountId
```

### _isTrustWorld

```solidity
mapping(uint256 => bool) _isTrustWorld
```

### _assets

```solidity
mapping(address => struct World.Asset) _assets
```

### _nonces

```solidity
mapping(address => uint256) _nonces
```

### _assetAddresses

```solidity
address[] _assetAddresses
```

### _metaverse

```solidity
address _metaverse
```

### constructor

```solidity
constructor(address metaverse, string name_, string version_) public
```

### registerAsset

```solidity
function registerAsset(address _contract, string _image) public
```

### updateAsset

```solidity
function updateAsset(address _contract, string _image) public
```

### getAsset

```solidity
function getAsset(address _contract) public view returns (struct World.Asset)
```

### addSafeContract

```solidity
function addSafeContract(address _contract, string _name) public
```

### removeSafeContract

```solidity
function removeSafeContract(address _contract) public
```

### isSafeContract

```solidity
function isSafeContract(address _contract) public view returns (bool)
```

### getSafeContract

```solidity
function getSafeContract(address _contract) public view returns (struct World.Contract)
```

### addOperator

```solidity
function addOperator(address _operator) public
```

### removeOperator

```solidity
function removeOperator(address _operator) public
```

### isOperator

```solidity
function isOperator(address _operator) public view returns (bool)
```

### isBWO

```solidity
function isBWO(address _addr) public view virtual returns (bool)
```

### trustContract

```solidity
function trustContract(uint256 _id, address _contract) public
```

### trustContractBWO

```solidity
function trustContractBWO(uint256 _id, address _contract, address sender, uint256 deadline, bytes signature) public
```

### _trustContract

```solidity
function _trustContract(uint256 _id, address _contract) private
```

### untrustContract

```solidity
function untrustContract(uint256 _id, address _contract) public
```

### untrustContractBWO

```solidity
function untrustContractBWO(uint256 _id, address _contract, address sender, uint256 deadline, bytes signature) public
```

### _untrustContract

```solidity
function _untrustContract(uint256 _id, address _contract) private
```

### trustWorld

```solidity
function trustWorld(uint256 _id) public
```

### trustWorldBWO

```solidity
function trustWorldBWO(uint256 _id, address sender, uint256 deadline, bytes signature) public
```

### _trustWorld

```solidity
function _trustWorld(uint256 _id) private
```

### untrustWorld

```solidity
function untrustWorld(uint256 _id) public
```

### untrustWorldBWO

```solidity
function untrustWorldBWO(uint256 _id, address sender, uint256 deadline, bytes signature) public
```

### _untrustWorld

```solidity
function _untrustWorld(uint256 _id) private
```

### isTrustWorld

```solidity
function isTrustWorld(uint256 _id) public view returns (bool _isTrust)
```

### isTrust

```solidity
function isTrust(address _contract, uint256 _id) public view virtual returns (bool _isTrust)
```

### getMetaverse

```solidity
function getMetaverse() public view returns (address)
```

### checkAddress

```solidity
function checkAddress(address _address, uint256 _id) public view returns (bool)
```

### getAccountIdByAddress

```solidity
function getAccountIdByAddress(address _address) public view returns (uint256)
```

### getAddressById

```solidity
function getAddressById(uint256 _id) public view returns (address)
```

### isFreeze

```solidity
function isFreeze(uint256 _id) public view returns (bool)
```

### getOrCreateAccountId

```solidity
function getOrCreateAccountId(address _address) public returns (uint256 id)
```

### getNonce

```solidity
function getNonce(address account) public view returns (uint256)
```

### getChainId

```solidity
function getChainId() external view returns (uint256)
```

### _recoverSig

```solidity
function _recoverSig(uint256 deadline, address signer, bytes32 digest, bytes signature) internal view
```

