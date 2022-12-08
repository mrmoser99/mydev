/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-08-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/


@isTest
private class TestAsyncApexSharing {

@testSetup
static void setup(){

	
}

Static testmethod void test1(){

    ID jobID = System.enqueueJob(new AsyncApexSharing( null,null,null));
}


}