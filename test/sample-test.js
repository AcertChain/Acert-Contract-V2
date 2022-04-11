const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("World", function () {
  it("Should return the new greeting once it's changed", async function () {
    const World = await ethers.getContractFactory("World");
    const world = await World.deploy();
    await world.deployed();

    expect(await world.greet()).to.equal("Hello, world!");

    const setGreetingTx = await world.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await world.greet()).to.equal("Hola, mundo!");
  });
});
