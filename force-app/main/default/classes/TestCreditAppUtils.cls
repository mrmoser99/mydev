/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-11-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class TestCreditAppUtils {

@testSetup
static void setup(){


	Account a = new Account(name = 'Test');
	a.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User').getRecordTypeId();

	insert a;

	Account v = new Account(name = 'Test Vendor', originating_site_id__c = '0000105570-0001');
	v.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Vendor').getRecordTypeId();

	insert v;

	Contact c = new Contact(firstName = 'Test', lastName = 'Dog', accountId = v.id, role__c='Partner Sales Rep');
	insert c;

	Contact c2 = new Contact(firstName = 'Test', lastName = 'Dog', accountId = a.id, role__c='Ultimate Beneficial Owner');
	insert c2;

	Opportunity o = new Opportunity( nickname__c = 'dog1', amount = 10000.00,
	 Name='jack', accountId = v.id, StageName = 'Quoting', CloseDate = date.today().addDays(30));
	o.recordtypeId =  Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Retail').getRecordTypeId();
	system.debug('o is: ' + o);
	insert o;

	Related_Party__c rp = new Related_Party__c(first_name__c = 'test'
	                                           ,last_name__c = 'cat'
	                                           ,address_line__c = '430 dog head lane '
	                                           ,city__c = 'Pet Ville'
	                                           ,ssn_encrypted__c = '989112222'
	                                           ,opportunity__c = o.id);
	insert rp;

	Quote q = new Quote (end_user__c = a.id, name = 'dog1', opportunityId = o.id, lease_type__c = 'Fair Market Value (FMV)', term__c = '48', payment_frequency__c = 'monthly', payment_timing__c = 'in-arrears');
	insert q;

	System_ID__c s = new System_Id__c(account__c = a.id, dll_external_key_source__c = 'ORACLE', dll_External_id__c = '12345'
	                                  , dll_external_key_type__c = 'TCAPartyID');
	insert s;

	Quote_Line__c ql = new Quote_Line__c(quote__c = q.id);
	insert ql;
}

Static testmethod void test1(){

	Quote q = [select id from quote];

	CreditAppUtils.submitCreditApp(q.id);

	Opportunity o = [select id from Opportunity];

	CreditAppUtils.submitPreQualCreditApp(o.id);

	CreditAppUtils.submitPreQualCreditAppFuture(o.id);


	CreditAppUtils.testBooster();



}
Static testmethod void test2(){


	Account a1 = new Account(name = 'Equipment Depot', originating_site_id__c = '0000105570-0001');
	a1.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Vendor').getRecordTypeId();

	insert a1;

	Account a1a = new Account(name = 'Equipment Depot 1A', originating_site_id__c = '0000105570-0002');
	a1.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Vendor').getRecordTypeId();

	insert a1a;

	Account a2 = new Account(name = 'Test End User', originating_site_id__c = '0000105570-0001');
	a2.recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User').getRecordTypeId();

	insert a2;

	Opportunity o = new Opportunity( nickname__c = 'dog1', amount = 10000.00, Name='jack', accountId = a2.id, StageName = 'Quoting', CloseDate = date.today().addDays(30));
	o.recordtypeId =  Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Retail').getRecordTypeId();
	system.debug('o is: ' + o);
	insert o;



	Account_Account_Relationship__c aar = new Account_Account_Relationship__c(account_2__c = a2.id, account_1__c = a1.Id, role__c = 'End User');
	insert aar;

	Account_Account_Relationship__c aar2 = new Account_Account_Relationship__c(account_2__c = a2.id, account_1__c = a1a.Id, role__c = 'End User');
	insert aar2;

	Contact c = new Contact(firstName = 'Test', lastName = 'Dog', accountId = a1.id, role__c='Partner Sales Rep');
	insert c;

	Contact c1 = new Contact(firstName = 'Test', lastName = 'Cat', accountId = a1.id, role__c='Partner Sales Rep');
	insert c1;

	AccountContactRelation acr = [select id from AccountContactRelation where ContactId = : c.id];
	acr.roles = 'Partner Admin';
	update acr;


	AccountContactRelation acr2 = [select id from AccountContactRelation where ContactId = : c1.id];
	acr2.roles = 'Partner Admin';
	update acr2;


	Related_Account__c r = new Related_Account__c(account__c = a2.id, Type__c = 'End User', opportunity__c = o.id);
	insert r;



}
}