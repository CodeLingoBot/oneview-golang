package main

import (
	"fmt"
	"github.com/HewlettPackard/oneview-golang/ov"
	"os"
)

func main() {
	var (
		ClientOV  *ov.OVClient
		scp_name  = "NewTestscope"
		new_scope = "updatescope"
		upd_scope = "newscope"
	)
	ovc := ClientOV.NewOVClient(
		os.Getenv("ONEVIEW_OV_USER"),
		os.Getenv("ONEVIEW_OV_PASSWORD"),
		os.Getenv("ONEVIEW_OV_DOMAIN"),
		os.Getenv("ONEVIEW_OV_ENDPOINT"),
		false,
		800,
		"*")
	ovVer, _ := ovc.GetAPIVersion()

	fmt.Println(ovVer)

	fmt.Println("#................... Scope by Name ...............#")
	scp, _ := ovc.GetScopeByName(scp_name)
	fmt.Println(scp)

	sort := "name:desc"
	scp_list, err := ovc.GetScopes("", sort)
	if err != nil {
		panic(err)
	}
	fmt.Println("# ................... Scopes List .................#")
	for i := 0; i < len(scp_list.Members); i++ {
		fmt.Println(scp_list.Members[i].Name)
	}

	scope := ov.Scope{Name: scp_name, Description: "Test from script", Type: "ScopeV3"}

	er := ovc.CreateScope(scope)
	if er != nil {
		fmt.Println("............... Scope Creation Failed:", err)
	}
	fmt.Println("# ................... Scope Created Successfully.................#")

	new_scp, _ := ovc.GetScopeByName(new_scope)
	new_scp.Name = upd_scope
	err = ovc.UpdateScope(new_scp)
	if err != nil {
		panic(err)
	}

	fmt.Println("#.................... Scope after Updating ...........#")
	up_list, err := ovc.GetScopes("", sort)
	for i := 0; i < len(up_list.Members); i++ {
		fmt.Println(up_list.Members[i].Name)
	}

	err = ovc.DeleteScope(scp_name)
	if err != nil {
		panic(err)
	}
	fmt.Println("#...................... Deleted Scope Successfully .....#")

}
