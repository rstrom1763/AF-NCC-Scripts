const fs = require('fs');
const express = require('express');
const app = express();

port = 8081;
app.use(express.json());
app.use(express.static('./'));
app.disable('etag');
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

app.get('/getcomputer/:id', (req, res) => {
    var id = req.params['id']
    try {
        data = fs.readFileSync(datadir + id + '.json', 'utf8');
    } catch (e) {
        res.setHeader('Content-Type', 'text/plain')
        res.statusCode = 404
        res.send("No entry available")
        return
    }

    res.setHeader('Content-Type', 'Application/json')
    res.statusCode = 200
    res.send(data)
});

app.get('/', (req, res) => {
    res.send(fs.readFileSync('index.html', 'utf8'))
});