const ethUtil = require("ethereumjs-util");


function padWithZeroes(number, length) {
    let myString = `${number}`;
    while (myString.length < length) {
        myString = `0${myString}`;
    }
    return myString;
}

function concatSig(v, r, s) {
    const rSig = ethUtil.fromSigned(r);
    const sSig = ethUtil.fromSigned(s);
    const vSig = ethUtil.bufferToInt(v);
    const rStr = padWithZeroes(ethUtil.toUnsigned(rSig).toString('hex'), 64);
    const sStr = padWithZeroes(ethUtil.toUnsigned(sSig).toString('hex'), 64);
    const vStr = ethUtil.stripHexPrefix(ethUtil.intToHex(vSig));
    return ethUtil.addHexPrefix(rStr.concat(sStr, vStr)).toString('hex');
}


privateKey = ethUtil.toBuffer("0x22dbbdd89034ab361ece6f0cf9f3b28a183a3581eb6ad7a46e60608054f1bbeb");
hash = ethUtil.toBuffer("0xa5ab92db32582e8daa1d1c07394f816648dbaf92e6a20458fc223a3cfbc2ddcf")
const sig = ethUtil.ecsign(hash, privateKey);
console.log(ethUtil.bufferToHex(concatSig(sig.v, sig.r, sig.s))) 
