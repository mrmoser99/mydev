/**
 * This class is used in RESTCallout service class to handle callout request. 
 * It provides request body wrapper for Send Documents callout
 * 
 * @author Elena Sokolova @date 2021-07-26
 */
public with sharing class SendDocumentsRequestBodyWrapper extends BaseRequestBodyWrapper {
    public Transaction_s Transaction_s;

    /**
     * Method populates request body for both scenarios: 1 main document, 2 SDO, PAdES.
     */
    public override void init(Map<String, Object> params) {
       String documentType = (String) params.get('documentType');
        Map<String,String> documentsBodyByName = (Map<String,String>) params.get('documents');

        Transaction_s transactionItem = new Transaction_s();
        transactionItem.DestinationReference = (String) params.get('oppName') + ((String) params.get('quoteName')).substringAfter('Version');
        transactionItem.Documents = getDocuments(documentsBodyByName, documentType);
       
        Boolean isUnsignedDoc = params.get('type') != null;
        
        //Check if its UnsignedDoc then no Recipient
        if (isUnsignedDoc) {
            transactionItem.Recipients = new List<Recipient>();
        }
        else{            
            transactionItem.Recipients = getRecipients(params);
        }

        this.Transaction_s = transactionItem;
    }


    /**
     * Method create and return list of Documents (every document contains name, type and body).
     * 
     * @return List<Document> (value for "Document" attribute in request structure)
     */
    private List<Document> getDocuments(Map<String,String> documentsBodyByName, String documentType) {
        List<Document> docs = new List<Document>();

        for (String documentName : documentsBodyByName.keySet()) {
            Document mainDocument = new Document();
            mainDocument.DocumentName = documentName;
            //DCV needs PG document type as 'Guarantee Customer'                 
            mainDocument.DocumentType = Constants.SMARTCOMM_DOCTYPE_PG == documentType
                						? Constants.PG_DOCTYPE_DCV
                						: documentType ;
            mainDocument.BinaryDocument = documentsBodyByName.get(documentName);
            mainDocument.DocumentMetaData = new List<DocumentMetaData>();
            docs.add(mainDocument);
        }

        return docs;
    }

    /**
     * Method create and return list of Recipients.
     * 
     * @return List<Recipient> (value for "Recipients" attribute in request structure)
     */
    private List<Recipient> getRecipients(Map<String, Object> params) {
        List<Recipient> recipients = new List<Recipient>();
        Recipient recipient = new Recipient();
        recipient.RecipientID = (String)params.get('recipientID');
        recipient.RecipientName = (String)params.get('recipientName');
        recipient.Email = (String)params.get('email');
        recipient.RecipientType = 'Signer';        
        recipient.DateSigned = params.get('dateSigned') != null ? (DateTime)params.get('dateSigned') : null;     
        recipient.RecipientStatus = 'Completed';

        recipients.add(recipient);
        return recipients;
    }

    public override String getRequestBodyAsString() {
        
        return JSON.serialize(this, true).replace('Transaction_s', 'Transaction');
    }

    public class Transaction_s {
        public String TransactionID;
        public String SourceChannel = 'Esigning';
        public String DistributionStatus;
        public String Country = 'ND';
        public String DestinationSystem;
        public String DestinationReference;
        public DateTime DateReceived = System.now();
        public List<TransactionMetaData> TransactionMetaData = new List<TransactionMetaData>();
        public List<Document> Documents;
        public List<Recipient> Recipients;
    }

    public class TransactionMetaData {
        public String Key;
        public String Value;
    }

    public class Document {
        public String DocumentName;
        public String DocumentType;
        public String BinaryDocument;
        public List<DocumentMetaData> DocumentMetaData = new List<DocumentMetaData>();
    }

    public class DocumentMetaData {
        public String Key;
        public String Value;
    }

    public class Recipient {
        public String RecipientID;
        public String RecipientName;
        public String Email;
        public DateTime DateSigned;
        public String RecipientType;
        public String RecipientStatus;
        public Integer RoutingOrder;
    }

    
}