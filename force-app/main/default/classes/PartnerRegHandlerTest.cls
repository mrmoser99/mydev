@isTest
private class PartnerRegHandlerTest {

@testSetup static void setup() {
	Profile p = [SELECT Id FROM profile WHERE name='Standard User'];

	user u = New User(
		UserName = 'test_' + math.random() + '@test.com',
		FirstName = 'Test-First',
		LastName = 'Test-Last',
		Alias = 'test',
		email = 'testuser@example.org',
		CommunityNickName = string.valueOf(math.random()).substring(0,6),
		ProfileID = p.id,
		TimeZoneSidKey = 'America/New_York',
		LocaleSidKey = 'en_US',
		EmailEncodingKey = 'UTF-8',
		LanguageLocaleKey = 'en_US',
		Business_Unit__c = 'Other',
		Legal_Entity_Description__c = 'DLL'
		);
	insert u;
}

static testMethod void testCreateUser() {

	PartnerRegHandler handler = new PartnerRegHandler();
	Auth.UserData sampleData = new Auth.UserData('testId', 'testFirst', 'testLast',
	                                             'testFirst testLast', 'testuser@example.org', null, 'testuserlong', 'en_US', 'facebook',
	                                             null, new Map<String, String> {'language' => 'en_US'});
	User u = handler.createUser(null,sampleData);
	system.debug(u);


	handler.canCreateUser(null);
	handler.updateUser(null,null,null);
}

}