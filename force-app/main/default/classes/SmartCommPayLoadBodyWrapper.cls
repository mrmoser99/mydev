/**
* Name: SmartCommPayLoadBodyWrapper 
* Purpose: This class is used as forming the JSON structure in SmartCommRestCallout class for sending payload data in encoded format. 
* 
* Version 1.0 @author Neha Bansal @date 2021-07-21
* */
public class SmartCommPayLoadBodyWrapper { 
    
    public Document Document;
    public String docName;
    public String doctype;
    
    public class Document {
        public SmartComm SmartComm;
        public DocumentInfo DocumentInfo;
        public Forms Forms;
        public Contract Contract;
    }
    
    public class SmartComm {
        public String TemplateResourceId;
        
        public SmartComm(String TemplateResourceId){
            this.TemplateResourceId = TemplateResourceId;
        }
    }
    
    public class DocumentInfo {
        public String CountryCode;
        public String DocumentTitle;
        public String DocumentType;
        
        public DocumentInfo(String CountryCode,String DocumentTitle, String DocumentType){
            this.CountryCode= CountryCode;
            this.DocumentTitle = DocumentTitle;
        	this.DocumentType = DocumentType;
        }
    }
    
    public class Forms {
        public List<Form> Form;
    }
    
    public class Form {
        public String FormId;
        public String Type;
        public String Code;
        public String Order;
        public String ValidStartDate;
    }
    
    public class Contract {
        public ContractDetails ContractDetails;
        public Party Party;
        public Partner Partner;
        public Guarantors Guarantors;
        public Assets Assets;
        public SpecialConditions SpecialConditions;
    }
    
    public class ContractDetails {
        public String GenerationDate;
        public String OppurtunityName;
        public String VersionNumber;
        public String StartUpFee;
        public String FinanceAmount;
        public String PaymentFrequency;
        public String Term;
        public String RentalAmount;
        public String ExtentionFee;
        public String ReferenceRateName;
        public String ReferenceStartDate;
        public String ReferenceRate;
        public String PaymentTiming;
        public String InsuranceAmount;
        public String TermsandConditionsDocName;
        public String InsuranceCondition;
        public String RateType;
        public String ITADType;
        public String Reference;
        public String CreditCondition;
        public String DownPaymentAmount;
        public String TotalRVAmount;
        public String RentPerMonth;
        
        
    }

    public class Party {
        public String ContactPersonName;
        public String ContactPersonEmail;
        public String ContactPersonPhoneNumber;
        public String CreditAssessmentDate;
        public String LegalName;
        public String FullName;
        public String FirstName;
        public String LastName;
        public InstallationAddress InstallationAddress;
        public InstallationAddress Address;
        public String OrganisationNumber;
        public String PhoneNumber;
        public Signatories Signatories;
    }
    
    public class InstallationAddress {
        public String City;
        public String Country;
        public String County;
        public String FaxNumber;
        public String ExtraAddressLine1;
        public String ExtraAddressLine2;
        public String HouseNumber;
        public String HouseNumberAdd;
        public String PhoneNumber;
        public String POBox;
        public String PostalCode;
        public String Street;
        public String Province;
        public String PropName;
        public String UnitNumber;
        
    }
    
    public class Signatories {
        public List<Signatory> Signatory;
    }
    
    public class Signatory {
        public String FreeText;
        public String FullName;
        public String SSN;
        public String Title;
    }
    
    public class Partner {
      
        public String LogoId;
        public String LegalName;
        public String FullName;
        public String FirstName;
        public String LastName;
        public InstallationAddress Address;
        public String SalesRepresentativeFullName;
        public String WebPage;
        public String OrganisationNumber;
        public String PhoneNumber;
    }
    
    public class Guarantors {
        public List<Guarantor> Guarantor;
    }
    
    public class Guarantor {
        public String FullName;
        public String FirstName;
        public String LastName;
        public InstallationAddress Address;
        public String OrganisationNumber;
        public String PhoneNumber;
        public String GuarantorAmountInWords;
        public String GuarantorAmount;
    }
    
    public class Assets {
        public List<Asset> Asset;
        public List<Asset> ITADAsset;
    }
    
    public class Asset {
        public String ProductName;
        public String ProductDescription;
        public String Type;
        public String Quantity;
    }    
    
    public class SpecialConditions {
        public List<String> Conditions;
        
        public SpecialConditions(List<String> Conditions){
            this.Conditions= Conditions;
            
        }
    }    
    
    /**
    * Method sets class variables.
    * 
    */
    public  void init(Map<String, Object> params) {        
        this.Document = prepareDocumentStructure(params);         
    }
    
    /**
    Name: prepareDocumentStructure
    Purpose: prepare the Document structure object/array in the json
    */
    private Document prepareDocumentStructure(Map<String, Object> params) {
        
        Document doc = new Document();
        doc.SmartComm = new SmartComm((String) params.get('templateId'));
        doc.DocumentInfo = new DocumentInfo((String) params.get('countryCode'),(String)params.get('docName'),(String)params.get('docType'));
        doc.Forms = prepareFormsStructure(params);
        doc.Contract = prepareContractStructure(params);
        
        return doc;
    }
    
    /**
    Name: prepareFormsStructure
    Purpose: prepare the Form structure object/array in the json
    */
    private Forms prepareFormsStructure(Map<String, Object> params) {
       
        Forms forms = new Forms();        
        List<Form> formList= new List<Form>();
        
        for(String tempForm : (List<String>) params.get('forms')){
            List<String> formdtl = tempForm.split('#'); 
            Form form = new Form();
            form.FormId = formdtl[0];
            form.type = formdtl[1];
            form.Order = formdtl[2];
            if(formdtl.size()>3){
                form.code = formdtl[3];
                form.ValidStartDate = formdtl[4];
            }
                
            
            formList.add(Form);
        }
        
        forms.Form = formList;
        return forms;
        
    }   
    
    /**
    Name: prepareContractStructure
    Purpose: prepare the Contract object in the json
    */
    private Contract prepareContractStructure(Map<String, Object> params) {
        
        Contract contract = new Contract();
        contract.ContractDetails = prepareContractDetailsStructure(params);
        contract.Party = preparePartyStructure(params);
        contract.Partner = preparePartnerStructure(params);
        contract.Guarantors = prepareGuarantorsStructure(params);
        contract.Assets = prepareAssetsStructure(params);
        contract.SpecialConditions = new SpecialConditions((List<String>)params.get('contSpecialTnC'));
        
        return contract;
    }
    
    /**
    Name: prepareContractDetailsStructure
    Purpose: prepare the ContractDetail object in the json
    */
    private ContractDetails prepareContractDetailsStructure(Map<String, Object> params) {
        
        ContractDetails contractDtl = new ContractDetails();
        contractDtl.GenerationDate = String.valueOf(System.now());
        contractDtl.OppurtunityName = (String)params.get('oppName');
        contractDtl.VersionNumber = (String)params.get('quoteName');
        contractDtl.StartUpFee = String.valueOf(params.get('statupFee') != null ? params.get('statupFee') : '');
        contractDtl.FinanceAmount = String.valueOf(params.get('financeAmt') != null ? params.get('financeAmt') : 0);
        contractDtl.PaymentFrequency = (String)params.get('paymentFrequency');
        contractDtl.Term = (String)params.get('term');
        contractDtl.RentalAmount =  String.valueOf(params.get('rentalAmt') != null ? params.get('rentalAmt') : 0);
        contractDtl.ExtentionFee =String.valueOf(params.get('extensionFee') != null ? params.get('extensionFee') : '');
        contractDtl.ReferenceRateName = (String)params.get('refRateName');        
        
        contractDtl.ReferenceStartDate = params.get('refStartDate') != null ? String.valueOf(Date.valueOf(params.get('refStartDate'))) : null;
        contractDtl.ReferenceRate =  String.valueOf(params.get('refRate') != null ? params.get('refRate') : 0);
        contractDtl.PaymentTiming = (String)params.get('paymentTiming');
        contractDtl.InsuranceAmount = String.valueOf(params.get('insuranceAmt') != null ? params.get('insuranceAmt') : 0);
        contractDtl.TermsandConditionsDocName = (String)params.get('termsDocName'); 
        contractDtl.InsuranceCondition = (String)params.get('insuranceCondition'); 
        contractDtl.RateType = (String)params.get('rateType'); 
        contractDtl.ITADType = (String)params.get('itadCategory'); 
        contractDtl.Reference = (String)params.get('reference'); 
        
        contractDtl.CreditCondition = (String)params.get('creditCondition'); 
        contractDtl.DownPaymentAmount = (String)params.get('downPaymentAmount');         
        contractDtl.TotalRVAmount =  params.get('totalRVAmount') != null ? String.valueOf(params.get('totalRVAmount')) : null;
      	contractDtl.RentPerMonth = String.valueOf(params.get('rentPerMonth'));   
          
       
        return contractDtl;
    }
    
    /**
    Name: preparePartyStructure
    Purpose: prepare the Party object in the json
    */
    private Party preparePartyStructure(Map<String, Object> params) {
        
        Party partyDtl = new Party();
        partyDtl.ContactPersonName = (String)params.get('partyContName');
        partyDtl.ContactPersonEmail = (String)params.get('partyContEmail');
        partyDtl.ContactPersonPhoneNumber = (String)params.get('partyContPhone');  
        partyDtl.CreditAssessmentDate =params.get('partyCreditAssesmentDate') != null ? String.valueOf(Date.valueOf(params.get('partyCreditAssesmentDate'))) : null;
        partyDtl.LegalName = (String)params.get('partyLegalName');      
        partyDtl.InstallationAddress = prepareAddress((Address)params.get('partyInstallAddress'));  
        partyDtl.Address = prepareAddress((Address)params.get('partyAddress')); 
        partyDtl.OrganisationNumber = (String)params.get('partyOrgNo');       
        partyDtl.Signatories = prepareSignatoriesStructure(params);
        
        return partyDtl;
    }
    
    /**
    Name: preparePartnerStructure
    Purpose: prepare the Partner object in the json
    */
    private Partner preparePartnerStructure(Map<String, Object> params) {
        
        Partner partneryDtl = new Partner();
        partneryDtl.LegalName = (String)params.get('partnerLegalName');
        partneryDtl.FullName = (String)params.get('patnerFullName');             
        partneryDtl.Address = prepareAddress((Address)params.get('partnerAddress'));
        partneryDtl.SalesRepresentativeFullName = (String)params.get('patnerSalesRepFullName');
        partneryDtl.WebPage = (String)params.get('partnerWebPage');
        partneryDtl.OrganisationNumber = (String)params.get('patnerOrgNo');
        partneryDtl.PhoneNumber = (String)params.get('patnerPhone');
        partneryDtl.LogoId = (String)params.get('partnerLogoName');  
        
        return partneryDtl;
        
    }
    
    /**
    Name: prepareGuarantorsStructure
    Purpose: prepare the Gurantor object/Array in the json
    */
    private Guarantors prepareGuarantorsStructure(Map<String, Object> params) {
        
        
        Guarantors guarantors = new Guarantors();
        List<Guarantor> guarantorList = new List<Guarantor>();
        if(params.get('gurantorList')!=null) {
            for(Related_Party__c gurantor:  (List<Related_Party__c>) params.get('gurantorList')){
                Guarantor gurantorDtl = new Guarantor();
                gurantorDtl.FullName = gurantor.Name;
                gurantorDtl.GuarantorAmountInWords = gurantor.Amount_Text__c;
                gurantorDtl.GuarantorAmount = gurantor.Amount__c;                
                gurantorDtl.OrganisationNumber = gurantor.External_Id__c;
                gurantorDtl.PhoneNumber = '';
                
                InstallationAddress address = new InstallationAddress(); 
                address.ExtraAddressLine1 = gurantor.Address_Line__c;
                address.Country = gurantor.Country_Code__c;            
                address.City = gurantor.City__c;  
                address.PostalCode = gurantor.Postal_Code__c;
                
                gurantorDtl.Address = address;
                
                guarantorList.add(gurantorDtl);
            }
            
        }
        
        guarantors.Guarantor = guarantorList;
        return guarantors;
        
    }
    
    /**
    Name: prepareAssetsStructure
    Purpose: prepare the Asset object/Array in the json
    */
    private Assets prepareAssetsStructure(Map<String, Object> params) {
        
        Assets assets = new Assets();
        List<Asset> assetList = new List<Asset>();
        List<Asset> itadAssetList = new List<Asset>();
        if(params.get('assetList')!=null){
            for(QuoteLineItem quoteLine: (List<QuoteLineItem>)params.get('assetList')){
                Asset assetDtl = new Asset();
                assetDtl.ProductName = quoteLine.Product2.name;
                assetDtl.ProductDescription = quoteLine.Description;
                assetDtl.Type = quoteLine.Product2.family; 
                assetDtl.Quantity = String.valueOf(quoteLine.Quantity!=null?quoteLine.Quantity.intValue():0); 
                
                assetList.add(assetDtl);
            }
        }
        
        if(params.get('itadAssetList')!=null){
            for(String prodName: (List<String>)params.get('itadAssetList')){
                Asset itadAassetDtl = new Asset();
                itadAassetDtl.ProductName = prodName;    
                itadAssetList.add(itadAassetDtl);
            }
        }
        
        assets.Asset = assetList;
        assets.ITADAsset = itadAssetList;
        return assets;         
    }
    
    /**
    Name: prepareSignatoriesStructure
    Purpose: prepare the Signatories object/Array in the json
    */
    private Signatories prepareSignatoriesStructure(Map<String, Object> params) {
        
        Signatories signatories = new Signatories();       
        List<Signatory> signatoryList = new  List<Signatory>();
        if(params.get('partySignatoryList')!=null){
            for(Contact con: (List<Contact>)params.get('partySignatoryList')){
                Signatory signatoryData = new Signatory();
                signatoryData.FreeText = con.Authorized_signatory_Text__c;
                signatoryData.FullName = con.Name;
                signatoryData.SSN = null; //con.External_ID__c; hide SSN on document
                signatoryData.Title = con.Title; 
                signatoryList.add(signatoryData);
            }
        }
        
        
        signatories.Signatory = signatoryList;
        return signatories;      
    }
    
    /**
    Name: prepareAddress
    Purpose: prepare the Address object in the json
    */
    private InstallationAddress prepareAddress(Address addr) {
        
        InstallationAddress address = new InstallationAddress(); 
        if(addr!=null){
            address.Country = addr.Country;
            address.County = addr.State;
            address.City = addr.City;        
            address.Street = addr.Street; 
            address.PostalCode = addr.PostalCode;   
        }
        return address;      
    }
    
    /**
    * Method serializes current instance of the class.
    * 
    * @return request body as JSON string
    */
    public String getPayLoadAsString() {
       
        return JSON.serialize(this, true);
    }
    
    
}