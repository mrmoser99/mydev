@isTest
private class TestPricingUtils {

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

	PricingUtils.getUserSite(Userinfo.getUserId());

	Account v = [select id, originating_Site_Id__c from Account where name = 'Test Vendor'];

	PricingUtils.getSalesReps(v.originating_Site_id__c);

	PricingUtils.getPrograms(v.originating_Site_id__c);

	PricingUtils.getFinancialProducts('3381','FMV', 'New');

	PricingUtils.getFinancialProduct('3381','FMV', 'New');



}

Static testmethod void test2(){


	PricingUtils.getFinancialProduct('3381','FMV','New');

	PricingUtils.getSubSidies('1','2', '3', '4', '5', 8.0, '9','10','New');

	PricingUtils.getMakes('3381');

	PricingUtils.getAssetTypes('3381','2' );

	PricingUtils.getModels('3381','2','1' );

//    PricingUtils.getAccessories('3381','2' );

	PricingUtils.getAsset('3381','2' );

	Quote q = [select id from quote];
	PricingUtils.getPrice(q.id,' 2', '22' );

	PricingUtils.doCallout('[]', '1', '1');

	PricingUtils.byPassCalloutTest();



}


}