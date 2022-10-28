/**
 * Class will have the utitlity methods for using across the ragnarok nordics implemetation
 * @author Anujit (Cognizant)
 * @date 2021-03-12
 * 
 * @date 2021-07-27 Elena Sokolova (added methods to create attachments and files for particular record)
 */
public with sharing class GenericUtilityClass {
    

    public static boolean isSafeObject(String objName){
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        return (schemaMap.get(objName).getDescribe().isAccessible() ? true: false); 
    }

    public static boolean isSafeField(String fieldName, String objName){
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        SObjectType myObj = schemaMap.get(objName);
        if (myObj.getDescribe().isAccessible() ) { 
            SObjectField myField = myObj.getDescribe().fields.getMap().get(fieldName);
            return (myField.getDescribe().isAccessible() ? true : false);
        }
         return false;
    }

    /**
     * Name: getSessionId
     * Purpose: Method is called from LWC to return session Id
     * @return String with session Id
     */
    @AuraEnabled(cacheable=true)
    public static String getSessionId() {
        return UserInfo.getSessionId();
    }

    /**
     * Name: createAttachments
     * Purpose: Method creates attachments with pdf file for particular record
     */
    public static void createAttachments(List<AttachmentInfo> attachmentData) {
        List<Attachment> attachments = new List<Attachment>();

        for (AttachmentInfo attachmentDataItem : attachmentData) {
            Attachment attachment = new Attachment();
            attachment.contentType = 'application/pdf';
            attachment.name = attachmentDataItem.name;
            attachment.parentId = attachmentDataItem.parentId;
            attachment.body = EncodingUtil.base64Decode(attachmentDataItem.bodyAsString);
            attachments.add(attachment);
        }
        
        new WoSDMLProcessor().insertRecords(attachments); 
    }
    
     /**
     * Name: deleteAttachments
     * Purpose: Method delete attachments with pdf file from particular record
     */
    public static void deleteAttachments(Set<Id> recordIdsToDelete) {
        List<Attachment> attachments = new List<Attachment>();
        
        List<ContentDocument> contentDocumentIds = new List<ContentDocument>();
        for(ContentDocumentLink con:[select id,LinkedEntityId,ContentDocumentId   from ContentDocumentLink  where LinkedEntityId in :recordIdsToDelete]){
            contentDocumentIds.add(new ContentDocument(id=con.ContentDocumentId));
        }
        new WoSDMLProcessor().deleteRecords(contentDocumentIds); 
    }

    /**
     * Name: findNetworkIdForPartnerUser
     * Purpose: Method finds the network ID for an Experience/partner portal user
    */
    private static string findNetworkIdForPartnerUser(){

        string netId = '';
        string loggedInUserType = userinfo.getUserType(); 
        if(loggedInUserType.equalsIgnoreCase('Power Partner') || loggedInUserType.equalsIgnoreCase('Partner') || loggedInUserType.equalsIgnoreCase('PowerPartner')){
            netId = network.getNetworkId() != null ? network.getNetworkId() : [SELECT NetworkID, MemberID FROM NetworkMember 
                                                                               WHERE memberID =: UserInfo.getuserId() limit 1].NetworkID;
        }
        return netId;
    }

    /**
     * Name: createAndAttachFilesToRecords
     * Purpose: Method creates pdf files for particular records and shares them with all users
     * Params:  List<DocumentInfo> documentsInfo - this list of wrapper contains information about files (see DocumentInfo inner class)
     *          Set<Id> recordIdsToAttach - set of record Id, determines which records the files will be attach to
     */
    public static void createAndAttachFilesToRecords(List<DocumentInfo> documentsInfo, Set<Id> recordIdsToAttach) { 
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        Set<Id> contentVersionIds = new Set<Id>();
        
        for (DocumentInfo documentInfo : documentsInfo) {
            ContentVersion newContent = new ContentVersion();
            newContent.Title = documentInfo.name;
            newContent.Description = documentInfo.name;
            newContent.VersionData = EncodingUtil.base64Decode(documentInfo.bodyAsString);
            newContent.PathOnClient = documentInfo.name + '.pdf';
            // custom field with document type (contract, eod)
            newContent.Document_Type__c = documentInfo.type;
            //NetworkId is required to be filled out when doing inserts on ContentVersion documents when communities are enabled and in a community context           
            newContent.NetworkId = findNetworkIdForPartnerUser() != '' ? findNetworkIdForPartnerUser() : null;
            contentVersions.add(newContent);
        }

        new WoSDMLProcessor().insertRecords(contentVersions); 

        for (ContentVersion contentVersionItem : contentVersions) {
            contentVersionIds.add(contentVersionItem.Id);
        }

        // attach created files to the records
        createAndShareDocumentLinks(contentVersionIds, recordIdsToAttach);
    }

    /**
     * Name: createAndShareDocumentLinks
     * Purpose: Method creates links between files and records (insert ContentDocumentLink object records)
     * Params:  Set<Id> contentVersionIds - this list of content version Ids
     *          Set<Id> recordIdsToAttach - set of record Id, determines which records the files will be attach to
     */
    private static void createAndShareDocumentLinks(Set<Id> contentVersionIds, Set<Id> recordIdsToAttach) {
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds];
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        for (ContentVersion contentVersionItem : contentVersions) {
            contentDocumentLinks.addAll(attachAndShareDocumentLinkWithAllUsers(recordIdsToAttach, contentVersionItem.ContentDocumentId));
        }
		
        new WoSDMLProcessor().insertRecords(contentDocumentLinks); 
    }

    /**
     * Name: attachAndShareDocumentLinkWithAllUsers
     * Purpose: Method creates links between file and records (create ContentDocumentLink object record), and share file with All users
     * Params:  Id contentDocumentId - ContentDocument record Id
     *          recordIds - set of record Id, determines which records the files will be attach to
     */
    private static List<ContentDocumentLink> attachAndShareDocumentLinkWithAllUsers(Set<Id> recordIds, Id contentDocumentId) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        for (Id recordId : recordIds) {
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.LinkedEntityId = recordId;
            docLink.ContentDocumentId = ContentDocumentId;
            docLink.ShareType = 'V';
            docLink.Visibility = 'AllUsers';
            contentDocumentLinks.add(docLink);
        }

        return contentDocumentLinks;
    }

    /**
     * Name: createEmailMessage
     * Purpose: Method creates Messaging.SingleEmailMessage instance, sets recipient email, template id and so on
     * Params:  List<String> addresse - recipient emails
     *          List<Messaging.EmailFileAttachment> attachments - list of attachments
     *          Id templateId - classic email template Id
     *          Id targetObjectId - target object id as a Contact Id
     *          Id whatId - Id of record for merge field
     *          Id emailAddressId - Id of org-wide email associated with outgoing email
     */
    public static Messaging.SingleEmailMessage createEmailMessage(List<String> addresses, List<Messaging.EmailFileAttachment> attachments, Id templateId, Id targetObjectId, Id whatId, Id emailAddressId) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();         
        message.setToAddresses(addresses); // set the recipient email          
        message.setTemplateId(templateId); // set the email template id
        message.setWhatId(whatId); // id of record for merge field    
        message.setSaveAsActivity(false); // do not save email as activity
        message.setOrgWideEmailAddressId(emailAddressId); // id of org-wide email associated with outgoing email
        message.setTreatTargetObjectAsRecipient(false); //set to false, the targetObjectId is supplied as the WhoId field for template rendering but isn’t a recipient of the email
        message.setTargetObjectId(targetObjectId);// set target object id as a contact id. create this contact for MUST in production org and in pre-migration step.
        if (attachments != null) {
            message.setFileAttachments(attachments);
        }

        return message;
    }

    /**
     * Name: getAttachments
     * Purpose: Method creates list of Messaging.EmailFileAttachment instances from map with document name and body
     * Params:  Map<String,String> documentsToAttach - key is name and value is body as a string
     */
    public static List<Messaging.EmailFileAttachment> getAttachments(Map<String,String> documentsToAttach) {
        List<Messaging.EmailFileAttachment> attacments = new List<Messaging.EmailFileAttachment>();

        for (String documentName : documentsToAttach.keySet()) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(documentName + '.pdf');
            attachment.setBody(EncodingUtil.base64Decode(documentsToAttach.get(documentName)));
            attacments.add(attachment);
        }
        
        return attacments;
    }

    /**
     * Name: sendEmailMessages
     * Purpose: Method sends emails and catches exceptions
     */
    public static void sendEmailMessages(List<Messaging.SingleEmailMessage> messages) {
        try {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(messages);
            String errorMessage;

            for (Messaging.SendEmailResult result : results) {
                if (!result.isSuccess()) {
                    for (Messaging.SendEmailError error :result.getErrors()) {
                        errorMessage += error.getMessage() + '\n';
                    }
                }             
            }
        } catch (Exception e) {        
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, null, true); 
        }
    }

    /**
     * Name: getUserInfoById
     * Purpose: Method is called from LWC to return user info by user Id
     * @return JSON String with user info
     */
    @AuraEnabled
    public static String getUserInfoById(Id userId) {
        return JSON.serialize(getUserInfo(userId));
    }

    /**
     * Name: getUserInfo
     * Purpose: returns user info by user Id
     * @return User record with user info
     */
    public static User getUserInfo(Id userId) {
        return [
            SELECT  Profile.Name, Contact.Account.Margin_Matrix__c
            FROM    User
            WHERE   Id = :userId
        ][0];
    }

    /**
     * Inner class to perform DML operation without sharing
     */
    public without sharing class WoSDMLProcessor {

        public void insertRecords(List<SObject> records) {
            insert records;
        }

        public void upsertRecords(List<SObject> records) {
            upsert records;
        }

        public void updateRecords(List<SObject> records) {
            update records;
        }

        public void deleteRecords(List<SObject> records) {
            delete records;
        }
    }

    // Inner wrapper class. It's is used for createAttachments method
    public class AttachmentInfo {
        public Id parentId;
        public String name;
        public String bodyAsString; // String in Base64 format

        public AttachmentInfo(Id parentId, String name, String bodyAsString) {
            this.parentId = parentId;
            this.name = name;
            this.bodyAsString = bodyAsString;
        }
    }

    // Inner wrapper class. It's is used for createAndAttachFilesToRecords method
    public class DocumentInfo {
        public String name;
        public String type;
        public String bodyAsString; // String in Base64 format

        public DocumentInfo(String name, String type, String bodyAsString) {
            this.name = name;
            this.type = type;
            this.bodyAsString = bodyAsString;
        }
    }
}