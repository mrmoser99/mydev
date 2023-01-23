/**
@Classname :       TesteArchiveUtils
@Description :     This class is written to cover the code of eArchiveUtils.
Change Log:
*  11/11/2022 - Dibyendu Created the class 
**/
@isTest (seeAllData=false)
private class TesteArchiveUtils {

    
    Static testmethod void testGetDocument(){
        User usr = TestUserData();
        system.runAs(usr){
        String st = '{"searchDocumentsResult": {"statusCode": 0,"statusCodeName": "OK","error": {"message": ""},"matchingDocuments": {"documentInfo": [{"din": "4C6213DD-6A01-AA5D-E1B3-B89A50EC2B51","timeStamp": 1609765803884,"indexValues": {"indexValue": [{"name": "Contract Number","value": "100-10000119"}]},"url": ""}]}}}';
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', st);
		Test.setMock(HttpCalloutMock.class, mock);
        //Test.setMock(HttpCalloutMock.class, new TesteArchiveCalloutMock(st));
        test.starttest();
        eArchiveUtils eArch = new eArchiveUtils();
        //eArchiveUtils.tokenClass tc = new eArchiveUtils.tokenClass();
        String cDoc = eArchiveUtils.GetDocument('Test Contract Number');
        test.stoptest();
        }
    }
    Static testmethod void testSearchContractDocs(){
        User usr = TestUserData();
        system.runAs(usr){
        String st = '{"searchDocumentsResult": {"statusCode": 0,"statusCodeName": "OK","error": {"message": ""},"matchingDocuments": {"documentInfo": [{"din": "4C6213DD-6A01-AA5D-E1B3-B89A50EC2B51","timeStamp": 1609765803884,"indexValues": {"indexValue": [{"name": "Contract Number","value": "100-10000119"}]},"url": ""}]}}}';
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', st);
		Test.setMock(HttpCalloutMock.class, mock);
        test.starttest();
        String cDoc = eArchiveUtils.SearchContractDocs('Test Contract Number');
        test.stoptest();
        }
    }
    Static testmethod void testGetDocument1(){	
        User usr = TestUserData();
        system.runAs(usr){
        String st = '{"searchDocumentsResult": {"statusCode": 0,"statusCodeName": "OK","error": {"message": ""},"matchingDocuments": {"documentInfo": [{"din": "4C6213DD-6A01-AA5D-E1B3-B89A50EC2B51","timeStamp": 1609765803884,"indexValues": {"indexValue": [{"name": "Contract Number","value": "100-10000119"}]},"url": ""}]}}}';
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(500, 'Error', st);
		Test.setMock(HttpCalloutMock.class, mock);
        test.starttest();
        eArchiveUtils eArch = new eArchiveUtils();
        //eArchiveUtils.tokenClass tc = new eArchiveUtils.tokenClass();
        String cDoc = eArchiveUtils.GetDocument('Test DIN Number');
        test.stoptest();
        }
    }
    Static testmethod void testSearchContractDocs1(){
        User usr = TestUserData();
        system.runAs(usr){
        String st = '{"searchDocumentsResult": {"statusCode": 0,"statusCodeName": "OK","error": {"message": ""},"matchingDocuments": {"documentInfo": [{"din": "4C6213DD-6A01-AA5D-E1B3-B89A50EC2B51","timeStamp": 1609765803884,"indexValues": {"indexValue": [{"name": "Contract Number","value": "100-10000119"}]},"url": ""}]}}}';
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(500, 'Error', st);
		Test.setMock(HttpCalloutMock.class, mock);
        test.starttest();
        String cDoc = eArchiveUtils.SearchContractDocs('Test DIN Number');
        JSONSearchDoc jcd = JSONSearchDoc.parse(st);
        JSONSearchDocResults jcd1 = JSONSearchDocResults.parse(st);
        JSONGetDocument jcd2 = JSONGetDocument.parse(st);
        JSONGetDocumentResult jcd3 = JSONGetDocumentResult.parse(st);
        test.stoptest();
        }
    }
    /*Static testmethod void testgetToken(){
        User usr = TestUserData();
        system.runAs(usr){
        String st = '{"access_token":"ddtyui","token_type":"Bearer","expires_in":3600,"refresh_token":"jhtyui", "scope":"create"}';
        MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', st);
		Test.setMock(HttpCalloutMock.class, mock);
        test.starttest();
        String token = PricingUtils.getToken();
        test.stoptest();
        }
    }*/
    Static User TestUserData(){
    Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1];

	User testUser = new User(Alias = 'testUsr', Email='testemail@test.com', FirstName='fName',
	                  EmailEncodingKey='UTF-8', LastName='lName', LanguageLocaleKey='en_US', isActive=true,
	                  LocaleSidKey='en_US', ProfileId = p.Id, 
	                  TimeZoneSidKey='America/Los_Angeles',Legal_Entity_Description__c ='DLL;AFC',Username = System.now().millisecond() + 'testuser@test.com');
	insert testUser;
    return testUser;
    }
}