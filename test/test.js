const {
    web3
} = require('hardhat');

// var message = ''

// console.log(web3.utils.soliditySha3(message));

// 


//  console.log(web3.eth.accounts.privateKeyToAccount(privateKey));


// const packed = web3.utils
// .soliditySha3(
// { type: "address", value: "0x6eA7409A10F4DBc59BAc37894fB63aCF7D39EB79" },
// { type: "address", value: "0xb1ef6bb53f55b2331891d5083a25991213c2a0e7" },
// { type: "address", value: "0x0000000000000000000000000000000000000000"},
// { type: "uint256", value: 250 },
// { type: "uint256", value: 0 },
// { type: "uint256", value: 0 },
// { type: "uint256", value: 0 },
// { type: "address", value: "0xd636da39d761c836A1F06CBe2Aa3d28725ADF0Ce"},
// { type: "uint8", value: 1},
// { type: "uint8", value: 1 },
// { type: "uint8", value: 0 },
// { type: "address", value: "0xE2a81C62BC4ccF200ED9B4eDE7Fd3e3bbc7F6f44" },
// { type: "uint8", value: 0 },
// { type: "bytes", value: "0x42842e0e000000000000000000000000b1ef6bb53f55b2331891d5083a25991213c2a0e700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001" },
// { type: "bytes", value: "0x000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000" },
// { type: "address", value: "0x0000000000000000000000000000000000000000"},
// { type: "bytes", value: "0x00" },
// { type: "address", value: "0x4A29B0D31fB273F41c26B84e1E47aE32B6FAd7BC" },
// { type: "uint256", value: 1000000000000000},
// { type: "uint256", value: 1 },
// { type: "uint256", value: 1658926800 },
// { type: "uint256", value: 1659186000 },
// { type: "uint256", value: 1658930004791 }
// ).toString("hex");
// console.log("packed: ", packed);

// var privateKey = "093436e88c4aea1937ce805959f768ff083a77db6436ddfe95eb54c77e47338b";
// console.log("addr: ", web3.eth.accounts.privateKeyToAccount(privateKey).address);
// const result = web3.eth.accounts.sign(packed, privateKey)
// console.log(result)

// console.log("recover",web3.eth.accounts.recover(packed, result.signature));
// console.log("recover",web3.eth.accounts.recover(packed, result.v,result.r,result.s));



// var privateKey1 = "81d46de9378b9e21b6344a6f0d952a1caace4137827cacde1dafcf00c51a4b21";
// console.log("addr sss: ", web3.eth.accounts.privateKeyToAccount(privateKey1).address);
// const result1 = web3.eth.accounts.sign(packed, privateKey1)
// console.log(result1)

// console.log("recover1",web3.eth.accounts.recover(packed, result1.signature));
// console.log("recover1",web3.eth.accounts.recover(packed, result1.v,result1.r,result1.s));



// const packed = web3.utils
//   .soliditySha3(
//     { type: "address", value: "0x29dD1C75FF0402f050cAe420ECA3A0C5FfFCc03A" },
//     { type: "address", value: "0xb1ef6bb53f55b2331891d5083a25991213c2a0e7" },
//     { type: "address", value: "0x0000000000000000000000000000000000000000"},
//     { type: "uint256", value: 250 },
//     { type: "uint256", value: 0 },
//     { type: "uint256", value: 0 },
//     { type: "uint256", value: 0 },
//     { type: "address", value: "0xd636da39d761c836A1F06CBe2Aa3d28725ADF0Ce"},
//     { type: "uint8", value: 1},
//     { type: "uint8", value: 1 },
//     { type: "uint8", value: 0 },
//     { type: "address", value: "0x646C5506859d8C2dBC8573F03D8e153d29c57564" },
//     { type: "uint8", value: 0 },
//     { type: "bytes", value: "0x42842e0e000000000000000000000000b1ef6bb53f55b2331891d5083a25991213c2a0e700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001" },
//     { type: "bytes", value: "0x000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000" },
//     { type: "address", value: "0x0000000000000000000000000000000000000000"},
//     { type: "bytes", value: "0x00" },
//     { type: "address", value: "0x9eD6B6674610324F9E992bf9E65c03c0B48B6fBd" },
//     { type: "uint256", value: 1000000000000000},
//     { type: "uint256", value: 1 },
//     { type: "uint256", value: 1658926800 },
//     { type: "uint256", value: 1659186000 },
//     { type: "uint256", value: 1658938074095 }
//   ).toString("hex");
// console.log("packed", packed);

// var privateKey = "093436e88c4aea1937ce805959f768ff083a77db6436ddfe95eb54c77e47338b";
// console.log(web3.eth.accounts.privateKeyToAccount(privateKey).address);
// const result = web3.eth.accounts.sign(packed, privateKey)
// console.log(result)

// ["0x29dD1C75FF0402f050cAe420ECA3A0C5FfFCc03A","0xb1ef6bb53f55b2331891d5083a25991213c2a0e7","0x0000000000000000000000000000000000000000","0xd636da39d761c836A1F06CBe2Aa3d28725ADF0Ce","0x646C5506859d8C2dBC8573F03D8e153d29c57564","0x0000000000000000000000000000000000000000","0x9eD6B6674610324F9E992bf9E65c03c0B48B6fBd"]

// [250,0,0,0,1000000000000000,1,1658926800,1659186000,1658938074095]


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

// ["0x29dD1C75FF0402f050cAe420ECA3A0C5FfFCc03A","0xd636da39d761c836a1f06cbe2aa3d28725adf0ce","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x646C5506859d8C2dBC8573F03D8e153d29c57564","0x0000000000000000000000000000000000000000","0x9eD6B6674610324F9E992bf9E65c03c0B48B6fBd"]
// [250,0,0,0,1000000000000000,0,1658926800,0,1658938409144]


// ["0x29dD1C75FF0402f050cAe420ECA3A0C5FfFCc03A","0xd636da39d761c836a1f06cbe2aa3d28725adf0ce","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x646C5506859d8C2dBC8573F03D8e153d29c57564","0x0000000000000000000000000000000000000000","0x9eD6B6674610324F9E992bf9E65c03c0B48B6fBd","0x29dD1C75FF0402f050cAe420ECA3A0C5FfFCc03A","0xb1ef6bb53f55b2331891d5083a25991213c2a0e7","0x0000000000000000000000000000000000000000","0xd636da39d761c836A1F06CBe2Aa3d28725ADF0Ce","0x646C5506859d8C2dBC8573F03D8e153d29c57564","0x0000000000000000000000000000000000000000","0x9eD6B6674610324F9E992bf9E65c03c0B48B6fBd"]
// [250,0,0,0,1000000000000000,0,1658926800,0,1658938409144,250,0,0,0,1000000000000000,1,1658926800,1659186000,1658938074095]
// [1,0,0,0,1,1,0,0]

// 0x42842e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d636da39d761c836a1f06cbe2aa3d28725adf0ce0000000000000000000000000000000000000000000000000000000000000001
// 0x42842e0e000000000000000000000000b1ef6bb53f55b2331891d5083a25991213c2a0e700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
// 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
// 0x000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000

// ["0x00a5ff7aa7298dc8d699a0f1ba0951c1708ec4c1b85ca7185b549a89415702a4","0x3ed073e925c88682b7b8107b929f3539ff4ff9e9bf0454d05cbede28ea5a86b9","0xafedd87e3dfe27dc824b35f4a1b1f98e01313d9a49c40396ad398ec7d1a8491f","0x7675a9383f320921efe953911279571db367ca3c66904b78ceedd6ff8e45c453","0x7675a9383f320921efe953911279571db367ca3c66904b78ceedd6ff8e45c453"]
// ["0x777f24fd62ef6468ba3f2c0039c100cba4fcedfb0e29ffd43cd4efc322feb658","0x32798a784c8a4f5e2f662b9686c1da2f480dfe936c3992bde4f34540d2549f4a","0xafedd87e3dfe27dc824b35f4a1b1f98e01313d9a49c40396ad398ec7d1a8491f","0x7675a9383f320921efe953911279571db367ca3c66904b78ceedd6ff8e45c453","0x0000000000000000000000000000000000000000000000000000000000000000"]
// {
//     message: '0x80d2b6ba47fe9a1db2d1ce050da5a390360a57572c87d4b10e72a6a4305f6a34',
//     messageHash: '0xe55ee712f0f25011fe670640473aac12332fda9a0beb5bf1ca606433ba7e8bb7',
//     v: '0x1b',
//     r: '0x00a5ff7aa7298dc8d699a0f1ba0951c1708ec4c1b85ca7185b549a89415702a4',
//     s: '0x3ed073e925c88682b7b8107b929f3539ff4ff9e9bf0454d05cbede28ea5a86b9',
//     signature: '0x00a5ff7aa7298dc8d699a0f1ba0951c1708ec4c1b85ca7185b549a89415702a43ed073e925c88682b7b8107b929f3539ff4ff9e9bf0454d05cbede28ea5a86b91b'
//   }


//   {
//     message: '0x4df66853f5005024c17fd91bcfb96a50864ad3417fb295366ab5d0409189fac4',
//     messageHash: '0x80f2d0d7f318e3102525ac55e79a197e1dea13b74462b5282ebab71a2aeb6fc7',
//     v: '0x1b',
//     r: '0xafedd87e3dfe27dc824b35f4a1b1f98e01313d9a49c40396ad398ec7d1a8491f',
//     s: '0x7675a9383f320921efe953911279571db367ca3c66904b78ceedd6ff8e45c453',
//     signature: '0xafedd87e3dfe27dc824b35f4a1b1f98e01313d9a49c40396ad398ec7d1a8491f7675a9383f320921efe953911279571db367ca3c66904b78ceedd6ff8e45c4531b'
//   }