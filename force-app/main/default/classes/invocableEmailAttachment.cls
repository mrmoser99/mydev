global with sharing class invocableEmailAttachment{
    
/**
* @description class to get multiple inputs from flow
*/
    
    global class flowInput 
    {                  
        @InvocableVariable(required=true)
        global String Email;
        
        @InvocableVariable
        global String ccMail;
        
        @InvocableVariable(required=true)
        global String Subject;
        
        @InvocableVariable
        global String Body;
        
        @InvocableVariable
        global string currentRecordId;
        
        @InvocableVariable
        global boolean sendAttachment;
        
        @InvocableVariable
        global String outboundEmail;
        
        @InvocableVariable
        global String contentDocId;
        
        
    }
    
    
    //* @description Used to send email alert along with attachments on the record
    
    @InvocableMethod(label='Email with Attachments' description='Used to send email alert along with attachments on the record.') 
    
    public static void currentRecordID(flowInput[] currentInput)
    {      
        string outboundEmail;
        string contentDocId;
        ID rId;
        boolean sendAttachment;
        for(flowInput singleID :currentInput )
        {
           
            rId = singleID.currentRecordId;                                      
            sobject sO = rId.getSobjectType().newsobject(rId);
            outboundEmail = singleID.outboundEmail;
            contentDocId = singleId.contentDocId;
            sendAttachment = singleId.sendAttachment;
        }
        
        system.debug('outboundEmail => '+outboundEmail);
        system.debug('contentDocId => ' +contentDocId);
        
        Set<String> contentDocumentSet    = new Set<String>();  
        
        //Get all content document link where linkedEntityid=: rID. 
        system.debug('rId==> '+rId);
       // system.debug('rId'+rId);
       
        for(ContentDocumentLink doc : [SELECT ContentDocumentId,ContentDocument.title,Id,LinkedEntityId,ShareType FROM ContentDocumentLink WHERE LinkedEntityId =:rID and ContentDocumentId =:contentDocId] )  
        {
            contentDocumentSet.add(doc.ContentDocumentId);
        }
        system.debug('contentDocumentSet==>'+contentDocumentSet);
        //Get all related contentVersion file
        List<contentVersion> contentVersionFile =  [SELECT VersionData, title, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentSet AND IsLatest = true];
        system.debug('Attachment List = '+ contentDocumentSet +'ContentVersion File = '+contentVersionFile);
        
        //New email message method
        Messaging.SingleEmailMessage mail= new Messaging.SingleEmailMessage();    
        
        //defining list of email attachments
        List< Messaging.EmailFileAttachment> attach= new list< Messaging.EmailFileAttachment>();
        
        
        //For each content version file get the file name, extension, version and add into the attachment list called 'attach'
        for(ContentVersion file : contentVersionFile)
        {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(file.title+'.'+file.FileExtension);
            efa.setBody(file.VersionData);
            attach.add(efa);
        }  
        
        //List of TO email id's 
        List<String> sendTo = new list<String>();
        
        for(String emailId : currentInput[0].Email.split(','))
        {
            if(emailId !=Null)     
            {
                sendTo.add(emailId.trim());
            }
        }    
        
        system.debug('send TO = '+sendTo);  
        mail.setToAddresses(sendTo);
        
        // Sender Name
        OrgWideEmailAddress owea = [Select Id from OrgWideEmailAddress where Address =:outboundEmail limit 1]; 
        mail.setOrgWideEmailAddressId(owea.id); 
        
        //List of CC email id's:
        
        if(currentInput[0].ccMail!=Null  && currentInput[0].ccMail.trim() != '')
        {            
            system.debug('ccMail '+currentInput[0].ccMail );
            List<String> ccSendTo = new list<String>();
            
            for(String ccEmailId : currentInput[0].ccMail.split(','))
            {
                if(ccEmailId!=Null)
                {
                    ccSendTo.add(ccEmailId.trim());
                }
                
            }
            
            mail.setCcAddresses(ccSendTo);
            system.debug('cc : '+ccSendTo);    
        }
        
        //Email Body
        mail.setPlainTextBody(currentInput[0].Body);
        
        //Email subject
        mail.setSubject(currentInput[0].Subject);
        
        //Attachment
        if(currentInput[0].sendAttachment ==True)
        {
            mail.setFileAttachments(attach);  
        }
        
        //Send Email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
    
}