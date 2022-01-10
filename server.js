// require('dotenv').config();
const fs = require("fs")
const express= require('express')
const app =express()
const routes = require('./routes')
const Web3 = require('web3');
// const mongodb = require('mongodb').MongoClient
if (typeof web3 !== 'undefined') {
    var web3 = new Web3(web3.currentProvider)
  } else {
    var web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'))
}

var bytecode = fs.readFileSync('./Voting_sol_Ballot.bin').toString()
var abi = JSON.parse(fs.readFileSync('./Voting_sol_Ballot.abi').toString())
const listOfCandidates = ['Ahmet', 'Mehmet', 'Ramazan']
const votingContract = new web3.eth.Contract(abi);


(async function () {
    const accounts = await web3.eth.getAccounts();
    votingContract.deploy({
        data: bytecode,
        arguments: [listOfCandidates.map(name => web3.utils.asciiToHex(name)), [accounts[1], accounts[2], accounts[3]], "1619876127", "1619876127"]
    }).send({
        from: accounts[0],
        gas: 5500000,
        gasPrice: web3.utils.toWei('0.00000000000001', 'ether')
    }).then((newContractInstance) => {
        votingContract.options.address = newContractInstance.options.address
        console.log("Contract address: " + newContractInstance.options.address)
    })

    routes(app, votingContract, listOfCandidates)
    app.listen(process.env.PORT || 8082, () => {
        console.log('listening on port '+ (process.env.PORT || 8082));
    })
})();
