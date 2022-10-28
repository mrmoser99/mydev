@isTest
private class CreateQuoteOpportunityTest {


    @testSetup static void setup() {

        User systemAdmin = createUser('System Administrator');

        //testSetupFuture(ct.Id, ct.LastName);//a trigger calls a future method so I cannot set up the data properly

        /*UserRole userRole = [SELECT Id FROM UserRole LIMIT 1];

        User adminUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name='System Administrator' LIMIT 1];

        adminUser.UserRoleId = userRole.Id;
        update adminUser;*/

        System.runAs(systemAdmin) {
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

            User partnerUser = createPartnerUser(ct.id,ct.LastName);
        }
    }
    @isTest static void testNewQuoteMethod() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        Test.startTest();

        CreateQuoteOpportunity.quoteOpportunityLineItem testVar = new CreateQuoteOpportunity.quoteOpportunityLineItem();

        System.runAs(partnerUser) {
            String jsonInput = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(2,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());
        }
        Test.stopTest();
    }
    @isTest static void testNewQuoteMethod2() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        Test.startTest();

        CreateQuoteOpportunity.quoteOpportunityLineItem testVar = new CreateQuoteOpportunity.quoteOpportunityLineItem();

        System.runAs(partnerUser) {
            String jsonInput = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "2",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(2,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());
            String jsonInput2 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper2 = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            try {
                quoteOpportunityWrapper2 = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput2);
            } catch (AuraHandledException e) {
                System.debug('Error thrown and caught from missing nickname');
            }
        }
        Test.stopTest();
    }

    @isTest static void testCloneQuoteMethod() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());

            Test.startTest();

            String jsonInput2 = '{"oppId":"'+ quoteOpportunityWrapper.newOpp.Id + '","financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"36","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper cloneQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            cloneQuoteOpportunityWrapper = CreateQuoteOpportunity.CloneQuoteOption(jsonInput2);
            system.assertEquals(2,cloneQuoteOpportunityWrapper.quoteOpportunityLineItems.size());

            Test.stopTest();
        }
    }

    @isTest static void testCloneQuoteMethod2() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());

            Test.startTest();

            String jsonInput2 = '{"oppId":"'+ quoteOpportunityWrapper.newOpp.Id + '","financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"36","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "2",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper cloneQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            cloneQuoteOpportunityWrapper = CreateQuoteOpportunity.CloneQuoteOption(jsonInput2);
            system.assertEquals(2,cloneQuoteOpportunityWrapper.quoteOpportunityLineItems.size());

            Test.stopTest();
        }
    }

    @isTest static void testCloneQuoteMethod3() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());

            Test.startTest();

            String jsonInput2 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"36","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper cloneQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            try {
                cloneQuoteOpportunityWrapper = CreateQuoteOpportunity.CloneQuoteOption(jsonInput2);
            } catch (AuraHandledException e) {
                System.debug('Error triggered for missing oppId');
            }

            Test.stopTest();
        }
    }

    //test EditQuoteOption function, only change financial structure
    @isTest static void testEditQuoteMethod1() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';      
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());         
        
            Test.startTest();

            String jsonInput2 = '{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id + '","financeType":"FPPO","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Annual","comments":"Comments for DLL","advPayments": "3",\n' +
            '"assets":[{"assetNo":"0", "Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Id + '","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
            '"deleteAssets":[{"Id":null}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper editQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            editQuoteOpportunityWrapper = CreateQuoteOpportunity.EditQuoteOption(jsonInput2);
            system.assertEquals('Annual',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Payment_Frequency__c);
            system.assertEquals('FPPO',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Lease_Type__c);
            system.assertEquals('3',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Advance_Payments__c);
                   
            Test.stopTest();
        }
    }

    //test EditQuoteOption function, only change nickname
    @isTest static void testEditQuoteMethod2() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';      
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());         
        
            
            Test.startTest();

            String jsonInput2 = '{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id + '","financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testChangeNickName","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Id + '","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
            '"deleteAssets":[{"Id":null}]}';  
            CreateQuoteOpportunity.quoteOpportunityWrapper editQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            editQuoteOpportunityWrapper = CreateQuoteOpportunity.EditQuoteOption(jsonInput2);
            system.assertEquals('testChangeNickName',editQuoteOpportunityWrapper.newOpp.Nickname__c);
            for(Integer i=0; i< editQuoteOpportunityWrapper.quoteOpportunityLineItems.size(); i++){
                system.assertEquals('testChangeNickName',editQuoteOpportunityWrapper.quoteOpportunityLineItems[i].quote.Name);
            }

            Test.stopTest();
        }
    }

    //test EditQuoteOption function, change nickname & financial structure
    @isTest static void testEditQuoteMethod3() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';      
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());         
        

            Test.startTest();
            
            String jsonInput2 = '{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id + '","financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testChangeNickName","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "3",\n' +
            '"assets":[{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Id + '","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +  
            '"deleteAssets":[{"Id":null}]}'; 
            CreateQuoteOpportunity.quoteOpportunityWrapper editQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            editQuoteOpportunityWrapper = CreateQuoteOpportunity.EditQuoteOption(jsonInput2);
            system.assertEquals('testChangeNickName',editQuoteOpportunityWrapper.newOpp.Nickname__c);
            for(Integer i=0; i< editQuoteOpportunityWrapper.quoteOpportunityLineItems.size(); i++){
                system.assertEquals('testChangeNickName',editQuoteOpportunityWrapper.quoteOpportunityLineItems[i].quote.Name);
            }
            system.assertEquals('3',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Advance_Payments__c);

            Test.stopTest();
        }
    }

    //test EditQuoteOption function, add assets
    @isTest static void testEditQuoteMethod4() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';      
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());         

            Test.startTest();
            
            String jsonInput2 = '{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id + '","financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"Id":" ","make":"Caterpillar","assetType":"Class-1","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"15000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' + 
            '"deleteAssets":[{"Id":null}]}'; 
            CreateQuoteOpportunity.quoteOpportunityWrapper editQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            editQuoteOpportunityWrapper = CreateQuoteOpportunity.EditQuoteOption(jsonInput2);
            system.assertEquals(2,editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());
            system.assertEquals('Class-1',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[1].Asset_Type_ITA_Class__c);
            
            Test.stopTest();
        }
    }


    //test EditQuoteOption function, modify assets
    @isTest static void testEditQuoteMethod5() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {
            
            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';      
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());         

            Test.startTest();    

            String jsonInput2 = '{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id + '","financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Id + '","make":"Caterpillar","assetType":"Class-3","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper editQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            editQuoteOpportunityWrapper = CreateQuoteOpportunity.EditQuoteOption(jsonInput2);
            system.assertEquals(1,editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());
            system.assertEquals('Class-3',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Asset_Type_ITA_Class__c);
        
            Test.stopTest();
        }
    }

    //test EditQuoteOption function, delete assets
    @isTest static void testEditQuoteMethod6() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {
            
            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';      
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());         

            Test.startTest();    

            String jsonInput2 = '{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id + '","financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"deleteAssets":[{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Id +'"}]}';  
            CreateQuoteOpportunity.quoteOpportunityWrapper editQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            editQuoteOpportunityWrapper = CreateQuoteOpportunity.EditQuoteOption(jsonInput2);
            system.assertEquals(null,editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines);
           
            Test.stopTest();
        }
    }

    @isTest static void testEditQuoteMethod7() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(2,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());

            Test.startTest();

            String assetId = '';
            String accessoryId = '';

            if (quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Related_Asset__c != null) {
                assetId = quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Related_Asset__c;
                accessoryId = quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Id;
            } else {
                assetId = quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[1].Related_Asset__c;
                accessoryId = quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[1].Id;
            }

            String jsonInput2 = '{"Id":"'+ quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id + '","financeType":"FPPO","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Annual","comments":"Comments for DLL","advPayments": "3",\n' +
                    '"assets":[{"assetNo":"0", "Id":"'+ assetId + '","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"deleteAssets":[{"Id":null}],\n' +
                    '"accessories":[{"Id":"' + accessoryId + '", "noOfUnits":"2", "unitSalesPrice":"16000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper editQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            editQuoteOpportunityWrapper = CreateQuoteOpportunity.EditQuoteOption(jsonInput2);
            system.assertEquals('Annual',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Payment_Frequency__c);
            system.assertEquals('FPPO',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Lease_Type__c);
            system.assertEquals('3',editQuoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Advance_Payments__c);

            Test.stopTest();
        }
    }

    //test DeleteQuoteOption function
    @isTest static void testDeleteQuoteMethod1() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            String jsonInput1 = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';      
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput1);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());         

            Test.startTest();  
            //test DeleteQuoteOption function
            CreateQuoteOpportunity.quoteOpportunityWrapper deleteQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            deleteQuoteOpportunityWrapper = CreateQuoteOpportunity.DeleteQuoteOption(quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id);
            system.assertEquals(0,deleteQuoteOpportunityWrapper.quoteOpportunityLineItems.size());
        
            Test.stopTest();
        }
    }

    //delete option till 0
    @isTest static void testDeleteQuoteMethod2() {

        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        System.runAs(partnerUser) {

            Test.startTest();  

            String jsonInput = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
            '"assets":[{"make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}]}';      
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());
            
            CreateQuoteOpportunity.quoteOpportunityWrapper deleteQuoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            deleteQuoteOpportunityWrapper = CreateQuoteOpportunity.DeleteQuoteOption(quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id);
            system.assertEquals(0,deleteQuoteOpportunityWrapper.quoteOpportunityLineItems.size());
            
            Test.stopTest(); 
        }
         
    }

    @IsTest
    static void markQuoteOptionAsPrimaryTest() {
        Opportunity newOpp = new Opportunity();
        newOpp.RecordTypeId = [select Id from RecordType where DeveloperName = 'Retail' AND sObjectType = 'Opportunity' limit 1].Id;
        newOpp.Nickname__c = 'testOpp';
        newOpp.AccountId = [select contact.AccountId from User where Id = :UserInfo.getUserId() Limit 1].Contact.AccountId;
        newOpp.CloseDate = System.today() + 30;
        newOpp.StageName = 'Quoting';
        newOpp.Sub_Stage__c = 'Quoting & Proposal';
        newOpp.ForecastCategoryName = 'Omitted';
        newOpp.Amount = 0;
        newOpp.CurrencyIsoCode = 'USD';

        insert newOpp;

        Quote q = new Quote();
        q.Is_Primary__c = false;
        q.OpportunityId = newOpp.Id;
        q.Name = 'testQuote1';
        Quote q2 = new Quote();
        q2.Is_Primary__c = true;
        q2.OpportunityId = newOpp.Id;
        q2.Name = 'testQuote1';
        Quote q3 = new Quote();
        q3.Is_Primary__c = false;
        q3.OpportunityId = newOpp.Id;
        q3.Name = 'testQuote1';

        List<Quote> qList = new List<Quote>();
        qList.add(q);
        qList.add(q2);
        qList.add(q3);

        insert qList;

        Test.startTest();
        CreateQuoteOpportunity.markQuoteOptionAsPrimary(q.Id, newOpp.Id);
        Test.stopTest();

        List<Quote> qListResults = [SELECT Id, Is_Primary__c
        FROM Quote
        WHERE (Id = :q.Id OR Id = :q2.Id OR Id = :q3.Id)
        AND OpportunityId = :newOpp.Id];

        System.assertEquals(true, qListResults.size() == 3, 'Only three Quotes should be found for this Opportunity.');

        for (Quote quo : qListResults) {
            if (quo.Id == q.Id) {
                System.assertEquals(true, quo.Is_Primary__c, 'This Quote is supposed to be marked as primary.');
            } else if (quo.Id == q2.Id) {
                System.assertEquals(false, quo.Is_Primary__c, 'This Quote is supposed to be no longer marked as primary.');
            } else if (quo.Id == q3.Id) {
                System.assertEquals(false, quo.Is_Primary__c, 'This Quote was never supposed to be marked as primary.');
            }
        }
    }

    @IsTest
    static void markQuoteOptionAsCreditAppSelectionTest() {
        Opportunity newOpp = new Opportunity();
        newOpp.RecordTypeId = [select Id from RecordType where DeveloperName = 'Retail' AND sObjectType = 'Opportunity' limit 1].Id;
        newOpp.Nickname__c = 'testOpp';
        newOpp.AccountId = [select contact.AccountId from User where Id = :UserInfo.getUserId() Limit 1].Contact.AccountId;
        newOpp.CloseDate = System.today() + 30;
        newOpp.StageName = 'Quoting';
        newOpp.Sub_Stage__c = 'Quoting & Proposal';
        newOpp.ForecastCategoryName = 'Omitted';
        newOpp.Amount = 0;
        newOpp.CurrencyIsoCode = 'USD';

        insert newOpp;

        Quote q = new Quote();
        q.Current_Credit_App_Selection__c = false;
        q.OpportunityId = newOpp.Id;
        q.Name = 'testQuote1';
        q.Total_Payment__c = 123.45;
        Quote q2 = new Quote();
        q2.Current_Credit_App_Selection__c = true;
        q2.OpportunityId = newOpp.Id;
        q2.Name = 'testQuote1';
        q2.Total_Payment__c = 123.45;
        Quote q3 = new Quote();
        q3.Current_Credit_App_Selection__c = false;
        q3.OpportunityId = newOpp.Id;
        q3.Name = 'testQuote1';
        q3.Total_Payment__c = 123.45;

        List<Quote> qList = new List<Quote>();
        qList.add(q);
        qList.add(q2);
        qList.add(q3);

        insert qList;

        Test.startTest();
        CreateQuoteOpportunity.markQuoteOptionAsCreditAppSelection(q.Id, newOpp.Id);
        Test.stopTest();

        List<Quote> qListResults = [SELECT Id, Current_Credit_App_Selection__c
        FROM Quote
        WHERE (Id = :q.Id OR Id = :q2.Id OR Id = :q3.Id)
        AND OpportunityId = :newOpp.Id];

        System.assertEquals(true, qListResults.size() == 3, 'Only three Quotes should be found for this Opportunity.');

        System.debug('Quote Results');
        System.debug(qListResults);

        for (Quote quo : qListResults) {
            if (quo.Id == q.Id) {
                System.assertEquals(true, quo.Current_Credit_App_Selection__c, 'This Quote is supposed to be marked as primary.');
            } else if (quo.Id == q2.Id) {
                System.assertEquals(false, quo.Current_Credit_App_Selection__c, 'This Quote is supposed to be no longer marked as primary.');
            } else if (quo.Id == q3.Id) {
                System.assertEquals(false, quo.Current_Credit_App_Selection__c, 'This Quote was never supposed to be marked as primary.');
            }
        }
    }

    @IsTest
    static void saveDataBackToServerTest() {
        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        Test.startTest();
        System.runAs(partnerUser) {
            String jsonInput = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(2,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());

            CreateQuoteOpportunity.saveQuotePricingDataBackToServer(
                    '{"Id":"' + quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id + '","Amount__c":"10000","Total_Payment__c":"123","Interest__c":"9.876023"}');
            Quote q = [SELECT Id, Interest__c, Amount__c, Total_Payment__c FROM Quote WHERE Id = :quoteOpportunityWrapper.quoteOpportunityLineItems[0].quote.Id LIMIT 1];
            System.assertEquals(10000, q.Amount__c, 'Quote amount does not match input');
            System.assertEquals(123, q.Total_Payment__c, 'Quote total payment does not match input');
            System.assertEquals('9.876023', q.Interest__c, 'Quote interest rate does not match input');
        }
        Test.stopTest();
    }

    @IsTest
    static void setProposalForQuoteTest() {
        Opportunity newOpp = new Opportunity();
        newOpp.RecordTypeId = [select Id from RecordType where DeveloperName = 'Retail' AND sObjectType = 'Opportunity' limit 1].Id;
        newOpp.Nickname__c = 'testOpp';
        newOpp.AccountId = [select contact.AccountId from User where Id = :UserInfo.getUserId() Limit 1].Contact.AccountId;
        newOpp.CloseDate = System.today() + 30;
        newOpp.StageName = 'Quoting';
        newOpp.Sub_Stage__c = 'Quoting & Proposal';
        newOpp.ForecastCategoryName = 'Omitted';
        newOpp.Amount = 0;
        newOpp.CurrencyIsoCode = 'USD';

        insert newOpp;

        Quote q = new Quote();
        q.Is_Primary__c = false;
        q.OpportunityId = newOpp.Id;
        q.Name = 'testQuote1';
        Quote q2 = new Quote();
        q2.Is_Primary__c = true;
        q2.OpportunityId = newOpp.Id;
        q2.Name = 'testQuote1';
        Quote q3 = new Quote();
        q3.Is_Primary__c = false;
        q3.OpportunityId = newOpp.Id;
        q3.Name = 'testQuote1';

        List<Quote> qList = new List<Quote>();
        qList.add(q);
        qList.add(q2);
        qList.add(q3);

        insert qList;

        Test.startTest();
        CreateQuoteOpportunity.setProposalForQuote(q.Id, 'true');
        CreateQuoteOpportunity.setProposalForQuote(q2.Id, 'true');
        CreateQuoteOpportunity.setProposalForQuote(q.Id, 'false');
        Test.stopTest();

        List<Quote> quoteList = [SELECT Id, Include_In_Proposal__c FROM Quote WHERE Id = :q.Id OR Id = :q2.Id OR Id = :q3.Id];

        for (Quote ql : quoteList) {
            if (ql.Id == q.Id) {
                System.assertEquals(false, ql.Include_In_Proposal__c, 'This quote was set to false for inclusion in a proposal');
            } else if (ql.Id == q2.Id) {
                System.assertEquals(true, ql.Include_In_Proposal__c, 'This quote was set to true for inclusion in a proposal');
            } else if (ql.Id == q3.Id) {
                System.assertEquals(false, ql.Include_In_Proposal__c, 'This quote was set to false by default for inclusion in a proposal');
            }
        }
    }

    @IsTest
    static void saveQuoteLinePricingDataBackToServerTest() {
        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        Test.startTest();
        System.runAs(partnerUser) {
            String jsonInput = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(2,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());

            CreateQuoteOpportunity.saveQuoteLinePricingDataBackToServer(
                    '[{"Id":"' + quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Id + '","Base_Unit_Sales_Price__c":"10000","Payment_Amount__c":"123"}]');
            Quote_Line__c ql = [SELECT Id, Base_Unit_Sales_Price__c, Payment_Amount__c FROM Quote_Line__c WHERE Id = :quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines[0].Id LIMIT 1];
            System.assertEquals(10000, ql.Base_Unit_Sales_Price__c, 'Quote line base price does not match input');
            System.assertEquals(123, ql.Payment_Amount__c, 'Quote line payment does not match input');
        }
        Test.stopTest();
    }

    @IsTest
    static void saveCustomerCommentsBackToServerTest() {
        User partnerUser =  [Select id FROM User WHERE LastName = 'Portal Contact'];

        Test.startTest();
        System.runAs(partnerUser) {
            String jsonInput = '{"financeType":"Fair Market Value ( FMV )","program":"1.NA.PI.0000105570-0001.1590","nickname":"testQuoteOpportunityPortal","financeTerm":"24,36,48","rateType": "Promo","paymentFrequency": "Monthly","advPayments": "0",\n' +
                    '"assets":[{"assetNo":"0","make":"Caterpillar","assetType":"Class-5","model":"GP25N5","mastType":"Triplex","baseUnitSalesPrice":"30000.00","numberOfUnits":"1","annualHour":"1500","operatingEnvironment":"Normal/Clean","batteryIncluded":"NO"}],\n' +
                    '"accessories":[{"noOfUnits":"1", "unitSalesPrice":"15000", "model":"RNMSTR", "modelId":"123456.34.345.146.242.$1BO.1234","relatedAsset":"0"}]}';
            CreateQuoteOpportunity.quoteOpportunityWrapper quoteOpportunityWrapper = new CreateQuoteOpportunity.quoteOpportunityWrapper();
            quoteOpportunityWrapper = CreateQuoteOpportunity.CreateQuoteOpportunity(jsonInput);
            system.assertEquals('Quoting', quoteOpportunityWrapper.newOpp.StageName);
            system.assertEquals(1,quoteOpportunityWrapper.quoteOpportunityLineItems.size());
            system.assertEquals(2,quoteOpportunityWrapper.quoteOpportunityLineItems[0].quoteLines.size());

            CreateQuoteOpportunity.saveCustomerCommentsToOpp('Test comments', quoteOpportunityWrapper.newOpp.Id);
            Opportunity opp = [SELECT Id, Comments__c FROM Opportunity WHERE Id = :quoteOpportunityWrapper.newOpp.Id LIMIT 1];
            System.assertEquals('Test comments', opp.Comments__c, 'Opp comments do not match input');
        }
        Test.stopTest();
    }

    @IsTest
    static void getSalesRepsByOSIDTest() {
        Account acc = new Account();
        acc.Originating_Site_ID__c = '000001234';
        acc.Name = 'testAcc';
        insert acc;

        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.Role__c = 'Partner Sales Rep';
        con.LastName = 'testContact';
        insert con;

        Test.startTest();
        String result = CreateQuoteOpportunity.getSalesRepsFromReturnedOSID('{ "osidArray" : ["000001234"]}');
        Test.stopTest();

        System.assertEquals(true, result.contains(con.Id), 'The contact should be retrieved by getSalesRepsFromReturnedOSID');
    }

    @Future
    private static void testSetupFuture(String str1, String str2) {
        /*UserRole userRole = [SELECT Id FROM UserRole LIMIT 1];

        User adminUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name='System Administrator' LIMIT 1];

        adminUser.UserRoleId = userRole.Id;
        adminUser.Legal_Entity_Description__c = 'DLL';
        adminUser.ContactId = str1;
        update adminUser;*/

        User systemAdmin = createUser('System Administrator');
        System.runAs(systemAdmin) {
            User partnerUser = createPartnerUser(str1,str2);
        }
    }

    private static user createPartnerUser(ID cId, String Name){
    	Profile p = [SELECT Id,Name from Profile where Name = 'Partner Admin' LIMIT 1];

    	user u = New User(
        	UserName = 'test_' + math.random() + '@test.com',
        	FirstName = 'Test-First',
        	LastName = Name,
        	Alias = 'test',
        	email = 'test' + math.random() + '@test.com',
        	CommunityNickName = string.valueOf(math.random()).substring(0,6),
        	ProfileID = p.id,
        	TimeZoneSidKey = 'America/New_York', 
        	LocaleSidKey = 'en_US', 
        	EmailEncodingKey = 'UTF-8', 
        	LanguageLocaleKey = 'en_US',
            Business_Unit__c = 'Other',
                Legal_Entity_Description__c = 'DLL',
        	ContactID = cId
        	);

    		insert u;

            //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Partner_Quoting'];
            //insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);

    		return u;
	}

    private static User createUser(String profileName) {
        Profile p = [SELECT Id, Name FROM Profile WHERE Name =: profileName];

        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User u = new User(  FirstName = 'user_first_name',
                            LastName = 'user_last_name',
                            Email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            Legal_Entity_Description__c = 'DLL',
                            UserRoleId = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'PPT_Administrator_Lead' LIMIT 1].Id,
                            ProfileId = p.Id);
        return u;
    }
}