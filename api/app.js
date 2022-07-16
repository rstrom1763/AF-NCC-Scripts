const fs = require('fs');
const express = require('express');
const app = express();

port = 8081;
app.use(express.json());
const nocache = require('nocache');//Hopefully disable browser caching
app.use(nocache());
app.use(express.static('./'));
app.disable('etag', false);
app.listen(port);
console.log('Listening on port ' + port + '... ');

datadir = './data/';

app.post('/write', (req, res) => {

    if (!(req.body.hasOwnProperty('ComputerName'))) {
        computername = req.body.computername;
    } else {
        computername = req.body.ComputerName;
    }
    computername = computername.toLowerCase()
    console.log(computername);
    fs.writeFile(datadir + computername + '.json', JSON.stringify(req.body), (err) => err);
    res.send("Update Written");

});

app.get('/getcomputer/:id', (req, res) => {
    var id = req.params['id'].toLowerCase()
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

app.get('/downloadjson/:computername', function (req, res) {
    var computername = req.params['computername'].toLowerCase()
    const file = datadir + computername + '.json'
    console.log(file)
    try {
        res.download(file); // Set disposition and send it.
    } catch (e) {
        res.setHeader('Content-Type', 'text/plain')
        res.statusCode = 404
        res.send("Not found")
        return
    }
});
