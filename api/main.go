package main

import (
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	r.GET("/getcomputer/MAUL", getComputer)
	r.Run(":8081")
}

func getComputer(c *gin.Context) {
	computername := c.Param("computername")
	fileBytes, err := ioutil.ReadFile("./data/" + computername + ".json")
	fmt.Print(fileBytes)
	if err != nil {
		panic(err)
	}
	c.JSON(http.StatusOK, gin.H{"data": true})
}
