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

var privateKey = "81d46de9378b9e21b6344a6f0d952a1caace4137827cacde1dafcf00c51a4b21";
console.log(web3.eth.accounts.privateKeyToAccount(privateKey).address);
const result = web3.eth.accounts.sign(packed, privateKey)
console.log(result)
