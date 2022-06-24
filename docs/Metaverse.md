# Solidity API

## Metaverse

### worlds

```solidity
struct EnumerableSet.AddressSet worlds
```

### AddWorld

```solidity
event AddWorld(address world, string name, string icon, string url, string description)
```

### UpdateWorld

```solidity
event UpdateWorld(address world, string name, string icon, string url, string description)
```

### RemoveWorld

```solidity
event RemoveWorld(address world)
```

### SetAdmin

```solidity
event SetAdmin(address admin)
```

### AddOperator

```solidity
event AddOperator(address operator)
```

### RemoveOperator

```solidity
event RemoveOperator(address operator)
```

### CreateAccount

```solidity
event CreateAccount(uint256 id, address account)
```

### UpdateAccount

```solidity
event UpdateAccount(uint256 id, address newAddress, bool isTrustAdmin)
```

### UpdateAccountBWO

```solidity
event UpdateAccountBWO(uint256 id, address newAddress, bool isTrustAdmin, uint256 nonce, uint256 deadline)
```

### FreezeAccount

```solidity
event FreezeAccount(uint256 id)
```

### FreezeAccountBWO

```solidity
event FreezeAccountBWO(uint256 id, uint256 nonce, uint256 deadline)
```

### UnFreezeAccount

```solidity
event UnFreezeAccount(uint256 id)
```

### worldInfos

```solidity
mapping(address => struct Metaverse.WorldInfo) worldInfos
```

### WorldInfo

```solidity
struct WorldInfo {
  address world;
  string name;
  string icon;
  string url;
  string description;
}
```

### Account

```solidity
struct Account {
  bool _isExist;
  bool _isTrustAdmin;
  bool _isFreeze;
  uint256 _id;
  address _address;
}
```

### _accountsById

```solidity
mapping(uint256 => struct Metaverse.Account) _accountsById
```

### _addressesToIds

```solidity
mapping(address => uint256) _addressesToIds
```

### _isOperatorByAddress

```solidity
mapping(address => bool) _isOperatorByAddress
```

### _nonces

```solidity
mapping(address => uint256) _nonces
```

### _totalAccount

```solidity
uint256 _totalAccount
```

### _admin

```solidity
address _admin
```

### _startId

```solidity
uint256 _startId
```

### constructor

```solidity
constructor(string name_, string version_, uint256 startId_) public
```

### addWorld

```solidity
function addWorld(address _world, string _name, string _icon, string _url, string _description) public
```

### removeWorld

```solidity
function removeWorld(address _world) public
```

### updateWorldInfo

```solidity
function updateWorldInfo(address _world, string _name, string _icon, string _url, string _description) public
```

### getWorldInfo

```solidity
function getWorldInfo(address _world) public view returns (struct Metaverse.WorldInfo)
```

### containsWorld

```solidity
function containsWorld(address _world) public view returns (bool)
```

### getWorlds

```solidity
function getWorlds() public view returns (address[])
```

### getWorldCount

```solidity
function getWorldCount() public view returns (uint256)
```

### setAdmin

```solidity
function setAdmin(address _addr) public
```

### getAdmin

```solidity
function getAdmin() public view returns (address)
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
function isBWO(address _addr) public view returns (bool)
```

### getOrCreateAccountId

```solidity
function getOrCreateAccountId(address _address) public returns (uint256 id)
```

### createAccount

```solidity
function createAccount(address _address, bool _isTrustAdmin) public returns (uint256 id)
```

### changeAccount

```solidity
function changeAccount(uint256 _id, address _newAddress, bool _isTrustAdmin) public
```

### changeAccountBWO

```solidity
function changeAccountBWO(uint256 _id, address _newAddress, bool _isTrustAdmin, address sender, uint256 deadline, bytes signature) public
```

### _changeAccount

```solidity
function _changeAccount(uint256 _id, address _newAddress, bool _isTrustAdmin) private
```

### freezeAccount

```solidity
function freezeAccount(uint256 _id) public
```

### freezeAccountBWO

```solidity
function freezeAccountBWO(uint256 _id, address sender, uint256 deadline, bytes signature) public
```

### unfreezeAccount

```solidity
function unfreezeAccount(uint256 _id) public
```

### isFreeze

```solidity
function isFreeze(uint256 _id) public view returns (bool)
```

### checkAddress

```solidity
function checkAddress(address _address, uint256 _id) public view returns (bool)
```

### getIdByAddress

```solidity
function getIdByAddress(address _address) public view returns (uint256)
```

### getAddressById

```solidity
function getAddressById(uint256 _id) public view returns (address)
```

### getAccountInfo

```solidity
function getAccountInfo(uint256 _id) public view returns (struct Metaverse.Account)
```

### getTotalAccount

```solidity
function getTotalAccount() public view returns (uint256)
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

