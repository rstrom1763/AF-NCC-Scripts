const fs = require('fs');
const express = require('express');
let converter = require('json-2-csv')
const app = express();

'use strict';

port = 8081;
app.use(express.json());
const nocache = require('nocache');//Disable browser caching
app.use(nocache());
app.use(express.static('./'));
app.disable('etag', false);//Disable etag to help prevent http 304 issues
app.listen(port);
console.log('Listening on port ' + port + '... ');

datadir = './data/';

try {
    var masterjson = JSON.parse(fs.readFileSync('./masterjson.json', 'utf-8'));
} catch (e) {
    var masterjson = { "computers": [] }
}

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
    masterjson['computers'].push(req.body);
    console.log(typeof(masterjson.computers))
    mastercsv = converter.json2csv(masterjson.computers, (err, data) => { if (err) { err } }, { "emptyFieldValue": "null", "unwindArrays": true });
    console.log(JSON.stringify(masterjson))
    fs.writeFile('./masterjson.json', JSON.stringify(masterjson, (err) => err), (err) => err);
    fs.writeFile('./mastercsv.csv', converter.json2csv(masterjson, (err) => err), (err) => err);

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
    try {
        res.download(file); // Set disposition and send it.
    } catch (e) {
        res.setHeader('Content-Type', 'text/plain')
        res.statusCode = 404
        res.send("Not found")
        return
    }
});

app.get('/getreport', (req, res) => {
    data = converter.json2csv(masterjson, (err) => err);
    res.setHeader('Content-Type', 'Application/json')
    res.send(data)


    res.setHeader('Content-Type', 'text/plain')

});


app.get('/csvtest', (req, res) => {


})