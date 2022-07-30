function printJsonResult(data) {
    //Reset div
    var div = document.getElementById("main");
    while (div.firstChild) { //Reset the div
        div.removeChild(div.firstChild);
    }
    //Set div with JSON information
    data = JSON.parse(data)
    for (key in data) {
        var div = document.createElement("div");
        div.className = "results"
        div.style.color = "black"
        div.style.width = "25%"
        div.style.padding = "24px"
        div.style.border = "4px solid rgb(255,255,255)"
        div.innerHTML = key + ": " + data[key]
        document.getElementById("main").appendChild(div);
    }
}


function download_json(computername) {
    var request = new XMLHttpRequest();
    request.responseType = "blob";
    request.onreadystatechange = function () {
        if (this.readyState == 4 && request.status === 200) {
            const file = window.URL.createObjectURL(this.response);
            const anchor = document.createElement("a");
            anchor.href = file;
            anchor.download = computername + ".json";
            document.body.appendChild(anchor);
            anchor.click();
        }
        if (this.readyState == 4 && request.status === 404) {
            return
        }
    }
    request.open("GET", 'http://' + location.host + '/downloadjson/' + computername, true);
    request.send();
}

function downloadreport() {
    var request = new XMLHttpRequest();
    request.responseType = "blob";
    request.onreadystatechange = function () {
        if (this.readyState == 4 && request.status === 200) {
            const file = window.URL.createObjectURL(this.response);
            const anchor = document.createElement("a");
            anchor.href = file;
            anchor.download = "mastercsv.csv";
            document.body.appendChild(anchor);
            anchor.click();
        }
        if (this.readyState == 4 && request.status === 404) {

            return
        }
    }
    request.open("GET", 'http://' + location.host + '/downloadreport', true);
    request.send();
}


function create_download_button() {
    div = document.getElementById("download")
    while (div.firstChild) { //Reset the div
        div.removeChild(div.firstChild);
    };
    var button = document.createElement("button");
    button.onclick = function () {
        download_json(document.getElementById("input").value)
    }
    button.innerHTML = "Download as JSON";
    document.getElementById("download").appendChild(button)
};

function remove_download_button() {
    div = document.getElementById("download")
    while (div.firstChild) { //Reset the div
        div.removeChild(div.firstChild);
    };
}

function send_data(data) {
    var request = new XMLHttpRequest();
    request.onreadystatechange = function () {
        if (request.readyState === request.DONE) {
            if (request.status === 200) {
                create_download_button();
                printJsonResult(request.response);
            }
            if (request.status === 404) {
                remove_download_button()
                document.getElementById('main').innerHTML = 'Computer Not Found'
            }
        }
    }
    request.open("GET", 'http://' + location.host + '/getcomputer/' + data, true);
    request.send(data.toLowerCase());
};

