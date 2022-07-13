function send_data(data) {

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState == 4) { //State 4 = request complete
            document.getElementById('output').innerHTML = xhr.responseText.toString()
        }
    }
    xhr.open("GET", 'http://localhost:8081/getcomputer/' + data, true);
    xhr.setRequestHeader('Content-Type', 'text/plain');
    xhr.setRequestHeader('computername',data)
    xhr.send(data);

};