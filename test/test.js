const {
    web3
} = require('hardhat');

// buy
const packed = web3.utils
  .soliditySha3(
    { type: "address", value: "0x29dD1C75FF0402f050cAe420ECA3A0C5FfFCc03A" },
    { type: "address", value: "0xd636da39d761c836a1f06cbe2aa3d28725adf0ce" },
    { type: "address", value: "0x0000000000000000000000000000000000000000"},
    { type: "uint256", value: 250 },
    { type: "uint256", value: 0 },
    { type: "uint256", value: 0 },
    { type: "uint256", value: 0 },
    { type: "address", value: "0x0000000000000000000000000000000000000000"},
    { type: "uint8", value: 1},
    { type: "uint8", value: 0 },
    { type: "uint8", value: 0 },
    { type: "address", value: "0x646C5506859d8C2dBC8573F03D8e153d29c57564" },
    { type: "uint8", value: 0 },
    { type: "bytes", value: "0x42842e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d636da39d761c836a1f06cbe2aa3d28725adf0ce0000000000000000000000000000000000000000000000000000000000000001" },
    { type: "bytes", value: "0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" },
    { type: "address", value: "0x0000000000000000000000000000000000000000"},
    { type: "bytes", value: "0x00" },
    { type: "address", value: "0x9eD6B6674610324F9E992bf9E65c03c0B48B6fBd" },
    { type: "uint256", value: 1000000000000000},
    { type: "uint256", value: 0 },
    { type: "uint256", value: 1658926800 },
    { type: "uint256", value: 0 },
    { type: "uint256", value: 1658938409144 }
  ).toString("hex");
console.log("packed", packed);

var privateKey = "093436e88c4aea1937ce805959f768ff083a77db6436ddfe95eb54c77e47338b";
console.log(web3.eth.accounts.privateKeyToAccount(privateKey).address);

const result = web3.eth.accounts.sign(packed, privateKey)
console.log(result)

const result1 = web3.eth.accounts.sign(result.messageHash, privateKey)
console.log(result1)



const packed2 = web3.utils
  .soliditySha3(
    { type: "address", value: "0x29dD1C75FF0402f050cAe420ECA3A0C5FfFCc03A" },
    { type: "address", value: "0xb1ef6bb53f55b2331891d5083a25991213c2a0e7" },
    { type: "address", value: "0x0000000000000000000000000000000000000000"},
    { type: "uint256", value: 250 },
    { type: "uint256", value: 0 },
    { type: "uint256", value: 0 },
    { type: "uint256", value: 0 },
    { type: "address", value: "0xd636da39d761c836A1F06CBe2Aa3d28725ADF0Ce"},
    { type: "uint8", value: 1},
    { type: "uint8", value: 1 },
    { type: "uint8", value: 0 },
    { type: "address", value: "0x646C5506859d8C2dBC8573F03D8e153d29c57564" },
    { type: "uint8", value: 0 },
    { type: "bytes", value: "0x42842e0e000000000000000000000000b1ef6bb53f55b2331891d5083a25991213c2a0e700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001" },
    { type: "bytes", value: "0x000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000" },
    { type: "address", value: "0x0000000000000000000000000000000000000000"},
    { type: "bytes", value: "0x00" },
    { type: "address", value: "0x9eD6B6674610324F9E992bf9E65c03c0B48B6fBd" },
    { type: "uint256", value: 1000000000000000},
    { type: "uint256", value: 1 },
    { type: "uint256", value: 1658926800 },
    { type: "uint256", value: 1659186000 },
    { type: "uint256", value: 1658938074095 }
  ).toString("hex");
console.log("packed", packed2);

var privateKey = "093436e88c4aea1937ce805959f768ff083a77db6436ddfe95eb54c77e47338b";
console.log(web3.eth.accounts.privateKeyToAccount(privateKey).address);
const result2 = web3.eth.accounts.sign(packed2, privateKey)
console.log(result2)
