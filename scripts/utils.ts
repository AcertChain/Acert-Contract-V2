import * as fs from "fs";

export function saveToJSON(contractName: string, value: object) {
    const network = process.env.NETWORK;
    const fileName = contractName + ".json";
    const path = `deployments/${network}`;
    if (!fs.existsSync(path)) {
        fs.mkdirSync(path);
    }
    fs.writeFileSync(path + `/${fileName}`, JSON.stringify(value));
}

export function saveToJSONNetWork(network: string,contractName: string, value: object) {
    const fileName = contractName + ".json";
    const path = `deployments/${network}`;
    if (!fs.existsSync(path)) {
        fs.mkdirSync(path);
    }
    fs.writeFileSync(path + `/${fileName}`, JSON.stringify(value));
}


export function getDeployment(contractName: string) {
    const network = process.env.NETWORK;
    const fileName = contractName + ".json";
    const path = `deployments/${network}/${fileName}`;
    return fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, "utf8")) : null;
}

export function getDeploymentNetWork(network: string, contractName: string) {
    const fileName = contractName + ".json";
    const path = `deployments/${network}/${fileName}`;
    return fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, "utf8")) : null;
}
