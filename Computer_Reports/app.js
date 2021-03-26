const fs = require('fs');
const express = require('express');
const app = express();

app.use(express.json());
app.listen(8081);

datadir = './data/';
datafile = 'test.txt';

app.post('/write', (req, res) => {

    console.log(req.body.ComputerName);
    fs.writeFile(datadir + req.body.ComputerName + '.json', JSON.stringify(req.body), (err) => err);
    res.send("Update Written");

});