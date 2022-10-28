@isTest
public class AARTriggerHelperTest {
@isTest
public static void createInverseRecord() {
	Map<Id, Account_Account_Relationship__c> aarsById = new Map<Id, Account_Account_Relationship__c>([
														 SELECT Id, Account_1__c, Account_2__c, Role__c, InverseRelation__c
														 FROM Account_Account_Relationship__c
														 ORDER BY Role__c
	                                                                                                 ]);



	Account acc1 = new Account(Name = 'Test 1');
	insert acc1;
	Account acc2 = new Account(Name = 'Test 2');
	insert acc2;

	Account_Account_Relationship__c euAAR = new Account_Account_Relationship__c(
		Account_1__c = acc1.Id,
		Account_2__c = acc2.Id,
		Role__c = 'End User'
		);

	Test.startTest();
	insert euAAR;
	Test.stopTest();

	List<Account_Account_Relationship__c> aars = [
		SELECT Id, Account_1__c, Account_2__c, Role__c, InverseRelation__c
		FROM Account_Account_Relationship__c
		WHERE Id NOT IN : aarsById.keySet()
		ORDER BY Role__c
	];

	System.assertEquals(2, aars.size());
	System.assertEquals(aars[0].InverseRelation__c, aars[1].Id);
	System.assertEquals(aars[1].InverseRelation__c, aars[0].Id);
	System.assertEquals(aars[0].Account_1__c, aars[1].Account_2__c);
	System.assertEquals(aars[1].Account_1__c, aars[0].Account_2__c);
}

@isTest
public static void deleteInverseRecord() {
	Map<Id, Account_Account_Relationship__c> aarsById = new Map<Id, Account_Account_Relationship__c>([
														 SELECT Id, Account_1__c, Account_2__c, Role__c, InverseRelation__c
														 FROM Account_Account_Relationship__c
														 ORDER BY Role__c
	                                                                                                 ]);

	Account acc1 = new Account(Name = 'Test 1');
	insert acc1;
	Account acc2 = new Account(Name = 'Test 2');
	insert acc2;

	Account_Account_Relationship__c euAAR = new Account_Account_Relationship__c(
		Account_1__c = acc1.Id,
		Account_2__c = acc2.Id,
		Role__c = 'End User'
		);
	insert euAAR;

	List<Account_Account_Relationship__c> aars = [SELECT Id FROM Account_Account_Relationship__c WHERE Id NOT IN : aarsById.keySet()];
	System.assertEquals(2, aars.size());

	Test.startTest();
	delete euAAR;
	Test.stopTest();

	aars = [SELECT Id FROM Account_Account_Relationship__c];
	System.assertEquals(0, aars.size());
}
@isTest
public static void test3() {
	Map<Id, Account_Account_Relationship__c> aarsById = new Map<Id, Account_Account_Relationship__c>([
														 SELECT Id, Account_1__c, Account_2__c, Role__c, InverseRelation__c
														 FROM Account_Account_Relationship__c
														 ORDER BY Role__c
	                                                                                                 ]);



	Account acc1 = new Account(Name = 'Test 1', Type = 'End User');
	insert acc1;
	Account acc2 = new Account(Name = 'Test 2');
	insert acc2;

	Account_Account_Relationship__c euAAR = new Account_Account_Relationship__c(
		Account_1__c = acc1.Id,

		Account_2__c = acc2.Id,
		Role__c = 'End User'
		);


	insert euAAR;


	Account_Account_Relationship__c euAAR2 = new Account_Account_Relationship__c(
		Account_1__c = acc2.Id,
		Account_2__c = acc1.Id,
		Role__c = 'Vendor'
		);
	insert euAAR2;

}
}