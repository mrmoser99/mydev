@isTest
public class TestAccountBuilder {

    private String name = 'Apple';
    private Id regionId;
    private Id recordTypeId;
    private Id marginMatrixId;
    private String doing_Business_As = 'Apple';
    private String org_No = 'Apple';
    private Integer invoiceFee = 8;
    private Integer startUpAmount = 1;
    private Integer startUpPercent = 6;
    private Integer extentionFee = 10;
    private String billingStreet;
    private String billingCity;
    private String billingPostalCode;
    private String externalId;
    private String FinalId;
	private String goesToDLLpartnerStartup;
    private Decimal startUpFeeSplitPercentage;
    private Boolean insertRecord = false;

    public TestAccountBuilder withRecordType(String recordTypeDeveloperName){
        recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
        return this;
    }

    public TestAccountBuilder withName(String name) {
        this.name = name;
        return this;
    }
    
     public TestAccountBuilder withDoing_Business_As(String doing_Business_As) {
        this.doing_Business_As = doing_Business_As;
        return this;
    }
    
    public TestAccountBuilder withInvoiceFee(Integer invoiceFee) {
        this.invoiceFee = invoiceFee;
        return this;
    }
    
    public TestAccountBuilder withStartUpAmount(Integer startUpAmount) {
        this.startUpAmount = startUpAmount;
        return this;
    }
    
    public TestAccountBuilder withStartUpPercent(Integer startUpPercent) {
        this.startUpPercent = startUpPercent;
        return this;
    }
    
    public TestAccountBuilder withExtentionFee(Integer extentionFee) {
        this.extentionFee = extentionFee;
        return this;
    }
    
     public TestAccountBuilder withOrg_No(String org_No) {
        this.org_No = org_No;
        return this;
    }

    public TestAccountBuilder withRegion(Id regionId) {
        this.regionId = regionId;
        return this;
    }

    public TestAccountBuilder withMarginMatrix(Id marginMatrixId) {
        this.marginMatrixId = marginMatrixId;
        return this;
    }

    public TestAccountBuilder withBillingStreet(String billingStreet) {
        this.billingStreet = billingStreet;
        return this;
    }

    public TestAccountBuilder withBillingCity(String billingCity) {
        this.billingCity = billingCity;
        return this;
    }

    public TestAccountBuilder withBillingPostalCode(String billingPostalCode) {
        this.billingPostalCode = billingPostalCode;
        return this;
    }

    public TestAccountBuilder withExternalId(String externalId) {
        this.externalId = externalId;
        return this;
    }
    
     public TestAccountBuilder withFinalId(String FinalId) {
        this.FinalId = FinalId;
        return this;
    }
    public TestAccountBuilder withGoesToDLLpartnerStartup(String goesToDLLpartnerStartup) {
        this.goesToDLLpartnerStartup = goesToDLLpartnerStartup;
        return this;
    }
    
    public TestAccountBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }


    public Account build(){
        Account testAccount = new Account(
            RecordTypeId = this.recordTypeId,
            Name = this.name,
            Region_Relationship__c = this.regionId,
            Margin_Matrix__c = this.marginMatrixId,
            Doing_Business_As__c = this.doing_Business_As,
            Org_No__c = this.org_No,
            Invoice_Fee_Amount__c = this.invoiceFee,
            //Extension_Fee__c = this.extentionFee,
            Start_Up_Fee_Amount__c = this.startUpAmount,
            Start_Up_Fee_Split_Percentage__c = this.startUpPercent,
            BillingStreet = this.billingStreet,
            BillingCity = this.billingCity,
            BillingPostalCode = this.billingPostalCode,
            External_Identifier__c = this.externalId,
            Final_Id__c = FinalId,
            Goes_to_DLL_partner_Startup__c = goesToDLLpartnerStartup
        );

        if(insertRecord) {
            insert testAccount;
        }

        return testAccount;
    }
}