/**
 * Voter login --> Gökhan 
 * --Government start election--
 * Check my vote --> Dilara
 * Get election result --> Burak
*/

function routes(app, contract, listOfCandidates){
    app.post('/vote', (req, res) => {
        let candidate = req.body.candidate
        let from = req.body.from
        contract.methods.vote(candidate).send({from: from, gas: 120000}).then((result) => {
            console.log("The result: ", result)
            return res.status(200).send({msg: "Voted successfully."})
        }).catch((err) => {
            var reason = getRevertReason(err.data)
            return res.status(404).send({reason: reason})
        })
    })
    app.post('/get/election-results', (req,res)=>{
        console.log("Election results endpoint")
        let from = req.body.from
        contract.methods.getElectionResult().call({from: from, gas: 120000}).then((result) => {
            return res.status(200).send({candidates: listOfCandidates, voteCounts: result[1]})
        }).catch((err) => {
            let reason = getRevertReason(err.data)
            return res.status(404).send({reason: reason})
        })
    })
    app.post('/get/check-my-vote', (req,res)=>{
        console.log("My Vote")
        let from = req.body.from
        contract.methods.checkMyVote().call({from: from, gas: 120000}).then((result) => {
            return res.status(200).send({vote: result[0]})
        }).catch((err) => {
            let reason = getRevertReason(err.data)
            return res.status(404).send({reason: reason})
        })
    })
    app.post('/login', (req,res)=>{
        let email = req.body.email
        if(email){
            db.findOne({email}, (err, doc)=>{
                if(doc){
                    res.json({"status":"success","id":doc.id})
                }else{
                    res.status(400).json({"status":"Failed", "reason":"Not recognised"})
                }
            })
        }else{
            res.status(400).json({"status":"Failed", "reason":"wrong input"})
        }
    })

}

/**
 * 
 * @param {JSON} err - Error message which has reason
 * @returns String - Reason message
 */
function getRevertReason(err) {
    
    for (var x in err) {
        if (x.startsWith("0x")) {
            return err[x]["reason"]
        }
    }
    return "Unknown reason";    // sender account not recognized
}

module.exports = routes
