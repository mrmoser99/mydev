@isTest
global class invocableEmailAttachmentTestClass {
    
   @isTest static void sendEmail1() {
       List<RecordType> rt = [SELECT Id FROM RecordType where SobjectType = 'Case' and DeveloperName = 'Canada'];
       
        Region__c rg = new Region__c();
        rg.Region_Type__c = 'Country';
        rg.name = 'Canada';
        rg.Description__c = 'Canada Region';
        insert rg;
       
       Case cs = new Case();
       cs.Type = 'Contract Activation & Changes';
       cs.Sub_Type__c = 'Contract Activation';
       cs.Department__c = 'Portfolio Services';
       cs.End_User_First_Name__c = 'Test First Name';
       cs.End_User_Last_Name__c = 'Test Last Name';
       cs.End_User_Email__c = 'test@test.com';
       cs.Region__c = rg.id;
       //cs.RecordTypeId = rt[0].id;
       insert cs;
       
       contentversion v1 = new contentversion();
       v1.Title = 'Sample';
       v1.PathOnClient = 'Sample.pdf';
       v1.VersionData = blob.valueOf('Data for test class');
       v1.Origin = 'H';
       insert v1;
      
       contentversion v2 = [Select Id, ContentdocumentId from contentversion where Id =: v1.id and isLatest = true limit 1];
       system.debug('v2==>'+v2);
       contentdocumentLink cdl = new contentDocumentLink();
       cdl.ContentDocumentId = v2.ContentDocumentId;
       cdl.LinkedEntityId = cs.Id;
       cdl.ShareType = 'V';
       
       insert cdl;
       
       system.debug('cdl==>'+cdl);
              
       invocableEmailAttachment.flowInput wrap = new invocableEmailAttachment.flowInput();
       wrap.Email = 'abc@gmail.com';
       wrap.ccMail = 'xyz@gmail.com';
       wrap.Subject = 'Testing Case';
       wrap.Body = 'Testing case Email Attachment';
       wrap.currentRecordId = cs.id;
       wrap.sendAttachment = true;
       wrap.outboundEmail = 'amortteam@leasedirect.com';
       wrap.contentDocId = cdl.ContentDocumentId;
       List<invocableEmailAttachment.flowInput> wraplist = new List<invocableEmailAttachment.flowInput>();
       wraplist.add(wrap);
       
       Test.startTest();
       invocableEmailAttachment.currentRecordID(wraplist);
       test.stopTest();
   }
}