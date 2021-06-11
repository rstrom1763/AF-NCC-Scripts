const fs = require('fs');
const express = require('express');
const app = express();

port = 8081;
app.use(express.json());
app.listen(port);
console.log('Listening on port ' + port + '... ');

datadir = './data/';

app.post('/write', (req, res) => {

    if (!(req.body.hasOwnProperty('ComputerName'))) {
        computername = req.body.computername;
    } else {
        computername = req.body.ComputerName;
    }
    console.log(computername);
    fs.writeFile(datadir + computername + '.json', JSON.stringify(req.body), (err) => err);
    res.send("Update Written");

});
