function printJsonResult(data) {

    //Reset div
    var div = document.getElementById("main");
    while (div.firstChild) {
        div.removeChild(div.firstChild);
    }

    //Set div with JSON information
    data = JSON.parse(data)
    for (key in data) {
        var div = document.createElement("div");
        div.className = "center"
        div.style.color = "black"
        div.style.width = "25%"
        div.style.padding = "24px"
        div.style.border = "4px solid powderblue"
        div.innerHTML = key + ": " + data[key]
        document.getElementById("main").appendChild(div);
        document.getElementById("output").innerHTML = ''
    }
}

function send_data(data) {

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState === xhr.DONE) {
            if (xhr.status === 200) {
                printJsonResult(xhr.response)
            }
            if (xhr.status === 404) {
                document.getElementById('output').innerHTML = '404 not found'
            }
        }
    }
    xhr.open("GET", 'http://10.0.0.89:8081/getcomputer/' + data, true);
    xhr.send(data);

};