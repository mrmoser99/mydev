/**************************************************************************************************************
Name: TestErrorLogger
===============================================================================================================
Purpose: Test class to handle the logicto save Error Log records.
===============================================================================================================
 * Version 1.0 @author Elena Sokolova @date 2021-08-10
***************************************************************************************************************/
@IsTest
public class TestErrorLogger {
    

    @IsTest
    public static void testLogException() {
        Contact contact = new Contact(LastName = 'Test Contact');
        insert contact;

        Test.startTest();
        try {
            contact.LastName = '';
            update contact;
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, contact.Id, true);
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, contact.Id, false);
        }
        Test.stopTest();
               

        Error_Log__c excp = [SELECT Related_To_Number__c, Exception_Message__c, Exception_Type__c, Method_Name__c, Class_Name__c FROM Error_Log__c LIMIT 1];

        System.assertEquals(contact.Id, excp.Related_To_Number__c);
        System.assertEquals(true, excp.Exception_Message__c.contains(contact.Id));
        System.assertEquals('System.DmlException', excp.Exception_Type__c);
        System.assertEquals('testLogException', excp.Method_Name__c);
        System.assertEquals('TestErrorLogger', excp.Class_Name__c);
    }
}