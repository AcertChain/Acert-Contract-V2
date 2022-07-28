

const hre = require("hardhat");
const dotenv = require('dotenv');
const { saveToJSON, getDeployment } = require("./utils");

const Addrs = ["0x3606ea190abfcb68b2095945630eab771e240cf3"
    , "0x034c60e1b700fed7b0013149ca69027f396e568d"
    , "0x04eaea5a95e80b8123018056e322416f90723b90"
    , "0xa9ce9635b9bd561d6d3991f857bab843805da223"
    , "0xbd3410152beea8275610f816a2fc78623665b8fc"
    , "0xd636da39d761c836a1f06cbe2aa3d28725adf0ce"
    , "0xb1ef6bb53f55b2331891d5083a25991213c2a0e7"
    , "0x82c64555783836de4d50e64502e31197605cab8c"
    , "0xBbE111C5dF0EfbB78E507A38141d7379b4b98672"
    , "0xD59326fE4D650Af5304A769555dac3d4CC274840"
    , "0x69E6D384412e8581cf3c571847318CA14B9122cE"
    , "0xff792f36D943118e3FaD187333EF359F2a14dBB9"
    , "0x6510d6012863B6F2969f4224cCD41D1DAd5397eA"
    , "0x479ea67006663CC867373d93952343Ea8dB93b91"
    , "0xaA1e2b39262C0Bd9991EC4d6d9911b5E9b34831f"
    , "0x02766512d2034e46dF91630ca3FaF95a14F59027"
    , "0xF5c5FEb24c396A61639Ed159675Ab427734b4dFE"
    , "0x2F6e06cf90a3A8ad72A3055aa013948339bC4248"
    , "0xd09E74444D2A961Ae24A1B510BD12c9D9cf5ee8F"
    , "0x3E7132b34D2f87EFbD29a84c42ea3B64285Be465"
    , "0xF418ADfA44f23Da39CC24BF3864fa7C26CbFd26d"
    , "0x51dB471475C1CdA9C6EDb2aD3589b03E30f90Ec6"
    , "0xF5E77Fa40210B92f54ea3B047d7F1DfC64c5C2c1"]

dotenv.config();
async function main() {

    const [deployer] = await ethers.getSigners();

    const World = (await ethers.getContractFactory("World")).connect(deployer);

    const WordlContract = World.attach(getDeployment("World").address);



    for (var i = 0; i < Addrs.length; i++) {
        console.log("create addr: ", Addrs[i]);

        await (await WordlContract.getOrCreateAccountId(Addrs[i])).wait();
    }



    for (var i = 0; i < Addrs.length; i++) {
        console.log(Addrs[i], " id : ", await WordlContract.getAccountIdByAddress(Addrs[i]));
    }

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });