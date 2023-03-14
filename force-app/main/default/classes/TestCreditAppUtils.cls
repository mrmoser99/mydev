/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-21-2023
 * @last modified by  : Mark Moser
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
	
	
	
	insert o;

	system.debug('o is: ' + o);
	
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

	List<Account_Account_Relationship__c> aarList = new List<Account_Account_Relationship__c>();

	Account_Account_Relationship__c aar = new Account_Account_Relationship__c(account_2__c = a2.id, account_1__c = a1.Id, role__c = 'End User');
	aarList.add(aar);
	 

	Account_Account_Relationship__c aar2 = new Account_Account_Relationship__c(account_2__c = a2.id, account_1__c = a1a.Id, role__c = 'End User');
	aarList.add(aar2);
	
	insert aarList;

	List<Contact> cList = new List<Contact>();

	Contact c = new Contact(firstName = 'Test', lastName = 'Dog', accountId = a1.id, role__c='Partner Sales Rep');
	cList.add(c);
	 

	Contact c1 = new Contact(firstName = 'Test', lastName = 'Cat', accountId = a1.id, role__c='Partner Sales Rep');
	cList.add(c1);
	 
	insert cList;

	AccountContactRelation acr = [select id from AccountContactRelation where ContactId = : c.id];
	acr.roles = 'Partner Admin';
	update acr;


	AccountContactRelation acr2 = [select id from AccountContactRelation where ContactId = : c1.id];
	acr2.roles = 'Partner Admin';
	update acr2;


	Related_Account__c r = new Related_Account__c(account__c = a2.id, Type__c = 'End User', opportunity__c = o.id);
	insert r;



}
Static testmethod void test3(){

	//test to get opp and quote

	Quote q = [select id, opportunityId, quote_number__c from quote];
	Quote_Line__c ql = new Quote_Line__c (quote__c = q.id);
	insert ql;

	AppUtility.getQuoteOpportunityAndCount(q.quote_number__c);

}

Static testmethod void test3a(){

	//test to just return the appeal option number

	Opportunity o = [Select id, quote_count__c, StageName, CloseDate from Opportunity where nickname__c = 'dog1'];  //source

	system.debug('opp is: ' + o.id);

	Quote q = [select id, opportunityId, quote_number__c from quote];
	
	Quote_Line__c ql = new Quote_Line__c (quote__c = q.id);
	insert ql;
	 
	system.debug('quote is: ' + q.opportunityId);

	system.debug('option is: ' + AppUtility.generateAppealQuoteOption(o.id, o.id, q.quote_number__c, 1));

}

Static testmethod void test4(){

	//test to just return the appeal option number

	Opportunity o = [Select id, quote_count__c, StageName, CloseDate from Opportunity where nickname__c = 'dog1'];  //source

	system.debug('opp is: ' + o.id);

	Quote q = [select id, opportunityId, quote_number__c from quote];
	q.is_Appeal__c = true;
	update 	q;
	Quote_Line__c ql = new Quote_Line__c (quote__c = q.id);
	insert ql;

	system.debug('quote is: ' + q.opportunityId);

	system.debug('option is: ' + AppUtility.generateAppealQuoteOption(o.id, o.id, q.quote_number__c, 1));

}

Static testmethod void test4a(){

	
	//one quote with primary set to true;
	Opportunity o = [Select id, quote_count__c, StageName, CloseDate from Opportunity where nickname__c = 'dog1'];  //source

	system.debug('opp is: ' + o.id);

	Quote q = [select id, opportunityId, quote_number__c from quote];
	q.is_Primary__c = true;
	update 	q;
	Quote_Line__c ql = new Quote_Line__c (quote__c = q.id);
	insert ql;

	system.debug('quote is: ' + q.opportunityId);

	system.debug('option is: ' + AppUtility.generateAppealQuoteOption(o.id, o.id, q.quote_number__c, 1));

}
Static testmethod void test4b(){

	

	Opportunity o = [Select id, quote_count__c, StageName, CloseDate from Opportunity where nickname__c = 'dog1'];  //source

	system.debug('opp is: ' + o.id);
	

	Quote q = [select id, name, opportunityId, quote_number__c from quote];
	q.current_credit_app_selection__c = true;
	update 	q;
	Quote_Line__c ql = new Quote_Line__c (quote__c = q.id);
	insert ql;

	Quote q2 = q;
	q2.id = null;
	q.current_credit_app_selection__c = false;
	insert q2;
	Quote_Line__c ql2 = new Quote_Line__c (quote__c = q2.id);
	insert ql2;

	system.debug('quote is: ' + q.opportunityId);

	system.debug('option is: ' + AppUtility.generateAppealQuoteOption(o.id, o.id, q.quote_number__c, 2));

}


Static testmethod void test5(){

	//test to just return a single primary quote
	Opportunity o = [Select id, quote_count__c, StageName, CloseDate from Opportunity where nickname__c = 'dog1'];  //source

	system.debug('opp id is: ' + o.id);

	ID originalQuoteID = o.id;
	
	 
	Opportunity o2 = o;
	o2.nickname__c = 'Destination';
	o2.id = null;
	insert o2;

	system.debug('opp is: ' + o.id);

	Quote q = [select id, opportunityId, quote_number__c from quote];
	system.debug('q.opp id is: ' + q.opportunityId);
	
	
	q.current_credit_app_selection__c = false;
	update q;

	Quote_Line__c ql = new Quote_Line__c (quote__c = q.id);
	insert ql;
	 
	 

	system.debug('option is: ' + AppUtility.generateAppealQuoteOption(originalQuoteId, o2.id,q.quote_number__c, 1));

}

Static testmethod void test6(){

	//test to just multiple
	Opportunity o = [Select id, quote_count__c, StageName, CloseDate from Opportunity where nickname__c = 'dog1'];  //source
	Opportunity o2 = o;
	o2.nickname__c = 'Destination';
	o2.id = null;
	insert o2;

	system.debug('opp is: ' + o.id);

	Quote q = [select id, name,opportunityId, quote_number__c from quote];
	Quote q2 = q;
	q2.id = null;
	insert q2;

	Quote_Line__c ql = new Quote_Line__c (quote__c = q.id);
	insert ql;

	Quote_Line__c ql2 = new Quote_Line__c (quote__c = q2.id);
	insert ql2;
	 
	 
	//system.debug('option is: ' + AppUtility.generateAppealQuoteOption(o.id, o2.id, q.quote_number__c, 1));

	system.debug('option is: ' + AppUtility.generateAppealQuoteOption(o.id, o2.id, q.quote_number__c, 2));

}

}