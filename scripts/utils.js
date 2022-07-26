const fs = require("fs");

function saveToJSON(contractName, value) {
    const network = process.env.NETWORK;
    const fileName = contractName + ".json";
    const path = `deployments/${network}/${fileName}`;
    // if (!fs.existsSync(path)) {
    //     fs.mkdirSync(path);
    // }
    fs.writeFileSync(path, JSON.stringify(value));
}

function getDeployment(contractName) {
    const network = process.env.NETWORK;
    const fileName = contractName + ".json";
    const path = `deployments/${network}/${fileName}`;
    return fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, "utf8")) : null;
}

module.exports = {
    saveToJSON,
    getDeployment,
};