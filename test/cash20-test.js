const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { artifacts,ethers } = require("hardhat");
const { ZERO_ADDRESS } = constants;

const Cash20 = artifacts.require('Cash20');
const World = artifacts.require('World');



contract('Cash20', function (accounts) {
    // deploy World contract
    const worldName = 'My World';
    const worldSymbol = 'MW';
    const worldSupply = 100;

    beforeEach(async function () {
      });

    const [ initialHolder, recipient, anotherAccount ] = accounts;

    const name = 'My Token';
    const symbol = 'MTKN';
    const version = '1.0.0';
    const initialSupply = new BN(100);
    
    beforeEach(async function () {
        world = await World.new(name, symbol,worldSupply);
        this.token = await Cash20.new(name, symbol,version , world.getAddress());
    });

    it('has a name', async function () {
        expect(await this.token.name()).to.equal(name);
    });
    
    it('has a symbol', async function () {
        expect(await this.token.symbol()).to.equal(symbol);
    });
    
    it('has 18 decimals', async function () {
        expect(await this.token.decimals()).to.be.bignumber.equal('18');
    });

});