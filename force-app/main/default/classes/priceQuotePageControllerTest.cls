/**
 * Created by ShiqiSun on 1/10/2022.
 */

@IsTest
private class priceQuotePageControllerTest {
    @testSetup static void setup() {

        Account at =new Account();
        at.Name='Portal Account';
        at.RecordTypeId=Schema.SObjectType.account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        insert at;
        System.debug('account:'+at);

        contact ct =new contact();
        ct.LastName='Portal Contact';
        ct.AccountId=at.id;
        insert ct;
        System.debug('contact:'+ct);
    }

    @isTest static void getContact() {
        Test.startTest();
                List<LookupSearchResult> result = priceQuotePageController.searchContacts('Portal Contact');
        Test.stopTest();
        String searchTerm = 'Portal Contact';
        System.assertNotEquals(null, result, 'Contact was not found');
    }
}