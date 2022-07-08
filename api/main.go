package main

import (
	"io/ioutil"
	"net/http"
	"fmt"
	"github.com/tidwall/gjson"
)

func main() {
	const port int = 8081
	fmt.Println("Listening on port " + fmt.Sprint(port) + "...")

	// Routes
	handler := http.HandlerFunc(getComputer)
	http.Handle("/get", handler)
	handler2 := http.HandlerFunc(postComputer)
	http.Handle("/write",handler2)

	http.ListenAndServe(":" + fmt.Sprint(port), nil)
}

func getComputer(w http.ResponseWriter, r *http.Request) {
	computername := r.Header.Get("computername")

	fileBytes, err := ioutil.ReadFile("./data/" + computername + ".json")
	if err != nil {
		panic(err)
	}
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	w.Write(fileBytes)
	return
}

func postComputer(w http.ResponseWriter, r *http.Request){

	defer r.Body.Close()
	body, err := ioutil.ReadAll(r.Body)
	var computername string

	data := string(body)
	if (gjson.Get(data,"computername")).Exists() {
		computername = (gjson.Get(data,"computername")).String()
	} else if (gjson.Get(data,"ComputerName")).Exists() {
		computername = (gjson.Get(data,"ComputerName")).String()
	}
	
	ioutil.WriteFile("./data/" + computername + ".json",body,0777)
	if err != nil {
		panic(err)
	}
	w.WriteHeader(http.StatusCreated)
	w.Header().Set("Content-Type", "application/json")
	w.Write(body)
	return
}