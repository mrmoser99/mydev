@Istest
private class ProgramTriggerHelper_Test {
    @testSetup static void setupData() {
        List<Business_Unit__c> businessUnits = new List<Business_Unit__c>();
        businessUnits.add(new Business_Unit__c(Name='Healthcare'));
        businessUnits.add(new Business_Unit__c(Name='DLL'));
        businessUnits.add(new Business_Unit__c(Name='Unknown'));
        insert businessUnits;
        Business_Unit__c bu = [SELECT Id FROM Business_Unit__c WHERE Name = 'DLL'];
        Business_Unit__c buChild = new Business_Unit__c(Name='Healthcare', Parent_Business_Unit__c = bu.Id);
        insert buChild;
        
        List<Region__c> regions = new List<Region__c>();
        regions.add(new Region__c(Name='United States'));
        regions.add(new Region__c(Name='Unknown'));
        insert regions;
    }
    
    @IsTest static void testTrigger(){
        
        Program__c program = new Program__c();
        program.Business_Unit_Description__c = 'Healthcare';
        program.Region_Description__c = 'US';
        program.Name = 'Test Program';
        insert program;
        program = [Select Business_Unit__c,Region__c FROM Program__c WHERE Id = : program.Id ];
        Test.startTest();
        System.assert(program.Business_Unit__c != null);
        System.assert(program.Region__c != null);
        program.Region_Description__c = '';
        program.Business_Unit_Description__c = '';
        update program;
        program = [Select Business_Unit__r.Name,Region__r.Name FROM Program__c WHERE Id = : program.Id ];
        System.assert(program.Region__r.Name == 'Unknown');
        System.assert(program.Business_Unit__r.Name == 'Unknown');
        Test.stopTest();
    }

    @IsTest static void testLegalName(){

        Program__c program = new Program__c();
        program.Business_Unit_Description__c = 'Healthcare';
        program.Legal_Entity_Description__c = 'DLL';
        program.Region_Description__c = 'US';
        program.Name = 'Test Program';
        insert program;
        program = [Select Business_Unit__c,Region__c FROM Program__c WHERE Id = : program.Id ];
        Test.startTest();
        System.assert(program.Business_Unit__c != null);
        System.assert(program.Region__c != null);
        Business_Unit__c bu = [SELECT Parent_Business_Unit__r.Name, Name FROM Business_Unit__c WHERE Id = :program.Business_Unit__c];
        System.assertEquals(bu.Parent_Business_Unit__r.Name, 'DLL', 'The wrong business Unit was chosen');
        program.Region_Description__c = '';
        program.Business_Unit_Description__c = '';
        update program;
        program = [Select Business_Unit__r.Name,Region__r.Name FROM Program__c WHERE Id = : program.Id ];
        System.assert(program.Region__r.Name == 'Unknown');
        System.assert(program.Business_Unit__r.Name == 'Unknown');
        Test.stopTest();
    }
}