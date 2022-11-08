/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-07-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class TestCustomerUtils {

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

	Opportunity o = new Opportunity( nickname__c = 'dog1', amount = 10000.00, Name='jack', accountId = v.id, StageName = 'Quoting', CloseDate = date.today().addDays(30));
	o.recordtypeId =  Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Retail').getRecordTypeId();
	system.debug('o is: ' + o);
	insert o;


	Quote q = new Quote (name = 'dog1', opportunityId = o.id, lease_type__c = 'Fair Market Value (FMV)', term__c = '48', payment_frequency__c = 'monthly', payment_timing__c = 'in-arrears');
	insert q;

	Quote_Line__c ql = new Quote_Line__c(quote__c = q.id);
	insert ql;
}

Static testmethod void test1(){

	Account a = [select id from Account where name =  'Test Vendor'];

	Opportunity o = [select id from Opportunity];

	CustomerUtils.getCustomerId(o.id, 0);

	CustomerUtilsWithoutSharing.updateCustomerId(true, o.id,a.id);

	Quote q = [select id from Quote];

	CustomerUtilsWithoutSharing.updateCustomerId(false,q.id,a.id);

	CustomerUtils.getCustomerId(q.id, 999);

	CustomerUtils.quickSearchAll('test');


	CustomerUtils.quickSearchWithSharing c = new CustomerUtils.quickSearchWithSharing('test','king','PA');
	CustomerUtils.quickSearchWithSharingApps c1 = new CustomerUtils.quickSearchWithSharingApps('test','king','PA');
	CustomerUtils.quickSearchWithOutSharingAccts c2 = new CustomerUtils.quickSearchWithOutSharingAccts('test','king','PA');

	CustomerUtils.quickSearch('test ','king ','PA ');

	CustomerUtils.createExternalCustomer(a.id,null);

	CustomerUtils.coverTest();
}


}