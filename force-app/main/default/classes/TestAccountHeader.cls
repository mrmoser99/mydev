@isTest(SeeAllData=true)
private class TestAccountHeader {

Static testmethod void test1(){

	Account a = [select id from Account limit 1];
	AccountPageHeader.getAccountData((a.id));



}
}