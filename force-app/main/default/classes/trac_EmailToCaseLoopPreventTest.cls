@isTest
private class trac_EmailToCaseLoopPreventTest {
    @isTest static void testInvalidOriginCaseLoop() {
        String caseStaticResource = 'trac_EmailToCaseLoopPreventTest_CaseData';
        List<sObject> caseData = Test.loadData(Case.sObjectType, caseStaticResource);
        List<Case> clist = (List<Case>)caseData;

        Test.startTest();
        Case aCase1 = new Case(Subject = 'Case 1.2', SuppliedEmail = 'case1@email.com', Origin = 'Phone');
        insert aCase1;

        Case aCase2 = new Case(Subject = 'Case 1.3', SuppliedEmail = 'case1@email.com', Origin = 'Phone');
        insert aCase2;
        Test.stopTest();

        Map<Id,Case> allCases = new Map<Id,Case>([SELECT Id, CreatedDate, Don_t_Send_Auto_Response__c FROM Case]);
        System.assertEquals(false, allCases.get(cList[0].Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(false, allCases.get(aCase1.Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(false, allCases.get(aCase2.Id).Don_t_Send_Auto_Response__c);
    }

    @isTest static void testInvalidEmailCaseLoop() {
        String caseStaticResource = 'trac_EmailToCaseLoopPreventTest_CaseData';
        List<sObject> caseData = Test.loadData(Case.sObjectType, caseStaticResource);
        List<Case> clist = (List<Case>)caseData;

        Test.startTest();
        Case aCase1 = new Case(Subject = 'Case 1.2', SuppliedEmail = 'case2@email.com', Origin = 'Email');
        insert aCase1;

        Case aCase2 = new Case(Subject = 'Case 1.3', SuppliedEmail = 'case3@email.com', Origin = 'Email');
        insert aCase2;
        Test.stopTest();

        Map<Id,Case> allCases = new Map<Id,Case>([SELECT Id, CreatedDate, Don_t_Send_Auto_Response__c FROM Case]);
        System.assertEquals(false, allCases.get(cList[0].Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(false, allCases.get(aCase1.Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(false, allCases.get(aCase2.Id).Don_t_Send_Auto_Response__c);
    }

    @isTest static void testValidCaseLoop() {
        String caseStaticResource = 'trac_EmailToCaseLoopPreventTest_CaseData';
        List<sObject> caseData = Test.loadData(Case.sObjectType, caseStaticResource);
        List<Case> clist = (List<Case>)caseData;

        Test.startTest();
        Case aCase1 = new Case(Subject = 'Case 1.2', SuppliedEmail = 'case1@email.com', Origin = 'Email');
        insert aCase1;

        Case aCase2 = new Case(Subject = 'Case 1.3', SuppliedEmail = 'case1@email.com', Origin = 'Email');
        insert aCase2;
        Test.stopTest();

        Map<Id,Case> allCases = new Map<Id,Case>([SELECT Id, CreatedDate, Don_t_Send_Auto_Response__c FROM Case]);
        System.assertEquals(false, allCases.get(cList[0].Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(false, allCases.get(aCase1.Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(true, allCases.get(aCase2.Id).Don_t_Send_Auto_Response__c);
    }

    @isTest static void testValidCustomSetting() {
        Email_To_Case_Loop_Prevent__c loopPreventCustomSetting = new Email_To_Case_Loop_Prevent__c();
        loopPreventCustomSetting.Interval__c = 60;
        insert loopPreventCustomSetting;

        String caseStaticResource = 'trac_EmailToCaseLoopPreventTest_CaseData';
        List<sObject> caseData = Test.loadData(Case.sObjectType, caseStaticResource);
        List<Case> clist = (List<Case>)caseData;


        Test.startTest();
        Case aCase1 = new Case(Subject = 'Case 1.2', SuppliedEmail = 'case1@email.com', Origin = 'Email');
        insert aCase1;


        Case aCase2 = new Case(Subject = 'Case 1.3', SuppliedEmail = 'case1@email.com', Origin = 'Email');
        insert aCase2;
        Test.stopTest();

        Map<Id,Case> allCases = new Map<Id,Case>([SELECT Id, CreatedDate, Don_t_Send_Auto_Response__c FROM Case]);
        System.assertEquals(false, allCases.get(cList[0].Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(false, allCases.get(aCase1.Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(true, allCases.get(aCase2.Id).Don_t_Send_Auto_Response__c);
    }

    @isTest static void testNegativeCustomSetting() {
        Email_To_Case_Loop_Prevent__c loopPreventCustomSetting = new Email_To_Case_Loop_Prevent__c();
        loopPreventCustomSetting.Interval__c = -1;
        insert loopPreventCustomSetting;

        String caseStaticResource = 'trac_EmailToCaseLoopPreventTest_CaseData';
        List<sObject> caseData = Test.loadData(Case.sObjectType, caseStaticResource);
        List<Case> clist = (List<Case>)caseData;

        Test.startTest();
        Case aCase1 = new Case(Subject = 'Case 1.2', SuppliedEmail = 'case1@email.com', Origin = 'Email');
        insert aCase1;


        Case aCase2 = new Case(Subject = 'Case 1.3', SuppliedEmail = 'case1@email.com', Origin = 'Email');
        insert aCase2;
        Test.stopTest();

        Map<Id,Case> allCases = new Map<Id,Case>([SELECT Id, CreatedDate, Don_t_Send_Auto_Response__c FROM Case]);
        System.assertEquals(false, allCases.get(cList[0].Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(false, allCases.get(aCase1.Id).Don_t_Send_Auto_Response__c);
        System.assertEquals(false, allCases.get(aCase2.Id).Don_t_Send_Auto_Response__c);
    }
}